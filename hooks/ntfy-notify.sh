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

# Send notification based on event type
case "$event_type" in
    PermissionRequest)
        tool_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
        send_notification "Claude 需要审批" "$tool_name" "4" "bell"
        ;;
    Stop)
        message=$(echo "$input" | python3 -c "
import sys,json
d=json.load(sys.stdin)
msg = d.get('last_assistant_message','')
print(msg[:100]) if msg else print('')
" 2>/dev/null)
        send_notification "Claude 已停止" "$message" "3" "check"
        ;;
esac
