#!/bin/bash

# claude-notify: Push notifications for Claude Code events via ntfy
# Sends notifications when Claude needs approval or completes tasks

# Debug log
echo "$(date): Hook triggered" >> /tmp/claude-notify-debug.log
echo "$(date): Args: $@" >> /tmp/claude-notify-debug.log
echo "$(date): STDIN available: $([ -t 0 ] && echo 'no' || echo 'yes')" >> /tmp/claude-notify-debug.log

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
check_notifications_enabled
validate_config
check_notification_method
check_terminal_focus

# Read stdin (JSON from Claude Code)
input=$(cat)

# Parse event type
event_type=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hook_event_name',''))" 2>/dev/null)

# Process event and send notification
case "$event_type" in
    PermissionRequest)
        notification=$(build_permission_notification "$input")
        IFS='|' read -r title body priority tags <<< "$notification"
        send_notification "$title" "$body" "$priority" "$tags"
        ;;
    Stop)
        notification=$(build_stop_notification "$input")
        IFS='|' read -r title body priority tags <<< "$notification"
        send_notification "$title" "$body" "$priority" "$tags"
        ;;
esac
