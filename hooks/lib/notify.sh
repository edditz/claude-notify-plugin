#!/bin/bash

# Notification sending module

# Send notification function
send_notification() {
    local title="$1"
    local message="${2:-·}"
    local priority="${3:-3}"
    local tags="${4:-}"

    if [ "${USE_CURL:-false}" = "true" ]; then
        send_via_curl "$title" "$message" "$priority" "$tags"
    else
        send_via_ntfy "$title" "$message" "$priority" "$tags"
    fi
}

# Send notification via curl
send_via_curl() {
    local title="$1"
    local message="$2"
    local priority="$3"
    local tags="$4"

    local url="${NTFY_HOST:-https://ntfy.sh}/${NTFY_TOPIC}"
    local -a curl_args=(-s -o /dev/null)

    # Add headers
    curl_args+=(-H "Title: ${title}")
    curl_args+=(-H "Priority: ${priority}")
    [ -n "$tags" ] && curl_args+=(-H "Tags: ${tags}")

    # Add authentication if token is configured
    if [ -n "${NTFY_TOKEN:-}" ]; then
        curl_args+=(-H "Authorization: Bearer ${NTFY_TOKEN}")
    fi

    # Send notification in background
    curl "${curl_args[@]}" -d "${message}" "${url}" &
}

# Send notification via ntfy CLI
send_via_ntfy() {
    local title="$1"
    local message="$2"
    local priority="$3"
    local tags="$4"

    local -a args=(--title "${title}" --priority "${priority}" --quiet)
    [ -n "$tags" ] && args+=(--tags "${tags}")

    # Add token if configured
    if [ -n "${NTFY_TOKEN:-}" ]; then
        args+=(--token "${NTFY_TOKEN}")
    fi

    # Build topic URL with custom host if specified
    local topic_url="${NTFY_TOPIC}"
    if [ -n "${NTFY_HOST:-}" ]; then
        topic_url="${NTFY_HOST}/${NTFY_TOPIC}"
    fi

    ntfy publish "${args[@]}" -m "${message}" "${topic_url}"
}
