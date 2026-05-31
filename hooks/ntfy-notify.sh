#!/bin/bash

# claude-notify: Push notifications for Claude Code events via ntfy
# Sends notifications when Claude needs approval or completes tasks

# Debug log
DEBUG_LOG="/tmp/claude-notify-debug.log"
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$DEBUG_LOG"
}
log_debug "=== Hook triggered ==="
log_debug "Args: $*"
log_debug "STDIN available: $([ -t 0 ] && echo 'no' || echo 'yes')"
log_debug "CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT:-unset}"
log_debug "SCRIPT_DIR: $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library modules
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/terminal.sh"
source "${SCRIPT_DIR}/lib/notify.sh"
source "${SCRIPT_DIR}/lib/template.sh"

# Initialize
load_config
log_debug "Config loaded - TOPIC: ${NTFY_TOPIC:-unset}, ENABLED: ${NTFY_ENABLED:-unset}, TERMINAL_CHECK: ${NTFY_TERMINAL_CHECK:-unset}"

check_notifications_enabled
log_debug "Notifications enabled check passed"

validate_config
log_debug "Config validated"

check_notification_method
log_debug "Notification method: USE_CURL=${USE_CURL:-false}"

check_terminal_focus
log_debug "Terminal focus check passed (not foreground or check disabled)"

# Read stdin (JSON from Claude Code)
input=$(cat)
log_debug "Input: ${input:0:500}"

# Parse event type
event_type=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hook_event_name',''))" 2>/dev/null)
log_debug "Event type: ${event_type:-empty}"

# Process event and send notification
case "$event_type" in
    PermissionRequest)
        notification=$(build_permission_notification "$input")
        IFS='|' read -r title body priority tags <<< "$notification"
        log_debug "Sending PermissionRequest notification: title=$title, body=$body"
        send_notification "$title" "$body" "$priority" "$tags"
        log_debug "PermissionRequest notification sent"
        ;;
    Stop)
        notification=$(build_stop_notification "$input")
        IFS='|' read -r title body priority tags <<< "$notification"
        log_debug "Sending Stop notification: title=$title, body=$body"
        send_notification "$title" "$body" "$priority" "$tags"
        log_debug "Stop notification sent"
        ;;
    *)
        log_debug "Unknown event type: $event_type"
        ;;
esac
log_debug "=== Hook completed ==="
