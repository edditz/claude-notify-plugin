#!/bin/bash

# claude-notify: Push notifications for Claude Code events via ntfy
# Sends notifications when Claude needs approval or completes tasks

set -euo pipefail

# Read configuration
CONFIG_FILE="${HOME}/.claude/plugins/claude-notify-plugin/config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Check if notifications are disabled
if [ "${NTFY_ENABLED:-true}" = "false" ]; then
    exit 0
fi

# Validate required configuration
if [ -z "${NTFY_TOPIC:-}" ]; then
    echo "Error: NTFY_TOPIC not configured. Run /notify:setup first." >&2
    exit 1
fi

# Check if ntfy CLI is installed
if ! command -v ntfy &> /dev/null; then
    echo "Error: ntfy CLI not installed. Install with: brew install ntfy" >&2
    exit 1
fi

# Detect if terminal is in foreground (skip notifications when user is watching)
is_terminal_foreground() {
    if [[ "$(uname)" == "Darwin" ]]; then
        frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
        frontmost_lower=$(echo "$frontmost" | tr '[:upper:]' '[:lower:]')
        case "$frontmost_lower" in
            *terminal*|*iterm*|*alacritty*|*kitty*|*wezterm*|*ghostty*|*hyper*) return 0 ;;
            *) return 1 ;;
        esac
    fi
    return 1
}

# Skip notification if terminal is in foreground (when NTFY_TERMINAL_CHECK is enabled)
if [ "${NTFY_TERMINAL_CHECK:-true}" = "true" ] && is_terminal_foreground; then
    exit 0
fi

# Read stdin (JSON from Claude Code)
input=$(cat)

# Parse event type
event_type=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hook_event_name',''))" 2>/dev/null)

# Send notification function
send_notification() {
    local title="$1"
    local message="${2:-·}"
    local priority="${3:-3}"
    local tags="${4:-}"

    local -a args=(--title "${title}" --priority "${priority}" --quiet)
    [ -n "$tags" ] && args+=(--tags "${tags}")

    # Configure custom server if specified
    if [ -n "${NTFY_HOST:-}" ]; then
        # Create temporary config for custom host
        local temp_config
        temp_config=$(mktemp)
        echo "default-host: ${NTFY_HOST}" > "$temp_config"
        args+=("--config" "$temp_config")
    fi

    # Set token if configured
    if [ -n "${NTFY_TOKEN:-}" ]; then
        export NTFY_TOKEN
    fi

    # Send notification in background
    ntfy publish "${args[@]}" -m "${message}" "${NTFY_TOPIC}" &

    # Cleanup temp config if created
    if [ -n "${temp_config:-}" ] && [ -f "${temp_config:-}" ]; then
        rm -f "$temp_config"
    fi
}

# Get project directory name
get_project_name() {
    basename "$(pwd)"
}

# Replace variables in template
replace_variables() {
    local template="$1"
    local project_name
    project_name=$(get_project_name)

    # Replace {project_name} with actual project name
    echo "${template//\{project_name\}/$project_name}"
}

# Send notification based on event type
case "$event_type" in
    PermissionRequest)
        tool_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)

        # Get title and body templates (with defaults)
        title_template="${NTFY_PERMISSION_TITLE:-Claude 需要审批}"
        body_template="${NTFY_PERMISSION_BODY:-{tool_name}}"

        # Replace variables
        title=$(replace_variables "$title_template")
        body=$(replace_variables "$body_template")

        # Replace {tool_name} with actual tool name
        body="${body//\{tool_name\}/$tool_name}"

        send_notification "$title" "$body" "4" "bell"
        ;;
    Stop)
        message=$(echo "$input" | python3 -c "
import sys,json
d=json.load(sys.stdin)
msg = d.get('last_assistant_message','')
print(msg[:100]) if msg else print('')
" 2>/dev/null)

        # Get title and body templates (with defaults)
        title_template="${NTFY_STOP_TITLE:-Claude 已停止}"
        body_template="${NTFY_STOP_BODY:-{message}}"

        # Replace variables
        title=$(replace_variables "$title_template")
        body=$(replace_variables "$body_template")

        # Replace {message} with actual message
        body="${body//\{message\}/$message}"

        send_notification "$title" "$body" "3" "check"
        ;;
esac
