#!/bin/bash

# Remote approval module for claude-notify-plugin
# Sends notifications with Approve/Deny action buttons,
# subscribes to a response topic, and outputs hookSpecificOutput
# for Claude Code to auto-approve or auto-deny.

# Generate a unique response topic name
# Format: {NTFY_TOPIC}-resp-{timestamp}-{pid}
generate_response_topic() {
    local ts
    ts=$(date +%s)
    echo "${NTFY_TOPIC}-resp-${ts}-$$"
}

# Build the full response topic URL (including host if configured)
# Args: response_topic
get_response_url() {
    local response_topic="$1"
    if [ -n "${NTFY_HOST:-}" ]; then
        echo "${NTFY_HOST}/${response_topic}"
    else
        echo "${response_topic}"
    fi
}

# Send notification with Approve/Deny action buttons via ntfy CLI
# Args: title, body, priority, tags, response_url
send_approval_notification_ntfy() {
    local title="$1"
    local body="$2"
    local priority="$3"
    local tags="$4"
    local response_url="$5"

    local -a args=(--title "${title}" --priority "${priority}" --quiet)
    [ -n "$tags" ] && args+=(--tags "${tags}")

    if [ -n "${NTFY_TOKEN:-}" ]; then
        args+=(--token "${NTFY_TOKEN}")
    fi

    # Build action buttons with auth headers for the response topic
    local token_header=""
    if [ -n "${NTFY_TOKEN:-}" ]; then
        token_header="headers.Authorization=Bearer ${NTFY_TOKEN},"
    fi

    local approve_action="http, Approve, ${response_url}, method=POST, body=approve, ${token_header} clear=true"
    local deny_action="http, Deny, ${response_url}, method=POST, body=deny, ${token_header} clear=true"

    args+=(--actions "${approve_action}; ${deny_action}")

    local topic_url="${NTFY_TOPIC}"
    if [ -n "${NTFY_HOST:-}" ]; then
        topic_url="${NTFY_HOST}/${NTFY_TOPIC}"
    fi

    ntfy publish "${args[@]}" -m "${body}" "${topic_url}"
}

# Send notification with Approve/Deny action buttons via curl
# Args: title, body, priority, tags, response_url
send_approval_notification_curl() {
    local title="$1"
    local body="$2"
    local priority="$3"
    local tags="$4"
    local response_url="$5"

    local url="${NTFY_HOST:-https://ntfy.sh}/${NTFY_TOPIC}"
    local -a curl_args=(-s -o /dev/null)

    curl_args+=(-H "Title: ${title}")
    curl_args+=(-H "Priority: ${priority}")
    [ -n "$tags" ] && curl_args+=(-H "Tags: ${tags}")

    if [ -n "${NTFY_TOKEN:-}" ]; then
        curl_args+=(-H "Authorization: Bearer ${NTFY_TOKEN}")
    fi

    # Build Actions header as JSON array (safe escaping via python3)
    local actions_json
    actions_json=$(echo "$response_url" | ${PYTHON_CMD:-python3} -c "
import sys, json
url = sys.stdin.read().strip()
token = '${NTFY_TOKEN:-}'
actions = [
    {
        'action': 'http', 'label': 'Approve', 'url': url,
        'method': 'POST', 'body': 'approve', 'clear': True,
        **({'headers': {'Authorization': 'Bearer ' + token}} if token else {})
    },
    {
        'action': 'http', 'label': 'Deny', 'url': url,
        'method': 'POST', 'body': 'deny', 'clear': True,
        **({'headers': {'Authorization': 'Bearer ' + token}} if token else {})
    }
]
print(json.dumps(actions))
")

    curl_args+=(-H "Actions: ${actions_json}")

    # Send synchronously (must confirm delivery before subscribing)
    curl "${curl_args[@]}" -d "${body}" "${url}"
}

# Wait for user response on the response topic
# Args: response_url, timeout_seconds
# Returns: "approve", "deny", or "" (timeout/error)
wait_for_response() {
    local response_url="$1"
    local timeout_seconds="${2:-300}"

    local result_file
    result_file=$(mktemp)

    # perl alarm for macOS timeout (no GNU `timeout` available)
    # ntfy subscribe outputs JSON lines; head -1 grabs first; python3 extracts message body
    (perl -e "alarm ${timeout_seconds}; exec @ARGV" ntfy subscribe \
        ${NTFY_TOKEN:+--token "${NTFY_TOKEN}"} \
        "${response_url}" 2>/dev/null \
        | head -1 \
        | ${PYTHON_CMD:-python3} -c "import sys,json; print(json.load(sys.stdin).get('message','').strip())" \
        > "$result_file" 2>/dev/null) || true

    local decision
    decision=$(tr -d '\r\n ' < "$result_file")
    rm -f "$result_file"

    echo "$decision"
}

# Full remote approval workflow
# Args: input_json (the full hook stdin JSON)
# Outputs hookSpecificOutput JSON to stdout if decision received
handle_remote_approval() {
    local input="$1"

    log_debug "Remote approval: starting workflow"

    # Generate unique response topic
    local response_topic
    response_topic=$(generate_response_topic)
    local response_url
    response_url=$(get_response_url "$response_topic")
    log_debug "Remote approval: response_url = ${response_url}"

    # Build notification content (reuse template module)
    local notification
    notification=$(build_permission_notification "$input")
    IFS='|' read -r title body priority tags <<< "$notification"
    log_debug "Remote approval: sending notification with action buttons"

    # Send notification with action buttons
    if [ "${USE_CURL:-false}" = "true" ]; then
        send_approval_notification_curl "$title" "$body" "$priority" "$tags" "$response_url"
    else
        send_approval_notification_ntfy "$title" "$body" "$priority" "$tags" "$response_url"
    fi
    log_debug "Remote approval: notification sent, waiting for response"

    # Wait for response with configurable timeout
    local timeout_seconds="${NTFY_REMOTE_TIMEOUT:-300}"
    local decision
    decision=$(wait_for_response "$response_url" "$timeout_seconds")
    log_debug "Remote approval: decision = '${decision}'"

    # Output hookSpecificOutput based on decision
    case "$decision" in
        approve)
            echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
            log_debug "Remote approval: approved"
            ;;
        deny)
            echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"Denied by user via remote notification"}}}'
            log_debug "Remote approval: denied"
            ;;
        *)
            # Timeout or unexpected response — fall through to normal Claude Code UI
            log_debug "Remote approval: no decision (timeout or error), falling through"
            ;;
    esac
}
