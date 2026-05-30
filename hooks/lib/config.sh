#!/bin/bash

# Configuration loading module

# Load configuration from file
load_config() {
    local config_file="${HOME}/.claude/plugins/claude-notify-plugin/config"
    if [ -f "$config_file" ]; then
        source "$config_file"
    fi
}

# Check if notifications are enabled
check_notifications_enabled() {
    if [ "${NTFY_ENABLED:-true}" = "false" ]; then
        exit 0
    fi
}

# Validate required configuration
validate_config() {
    if [ -z "${NTFY_TOPIC:-}" ]; then
        echo "Error: NTFY_TOPIC not configured. Run /notify:setup first." >&2
        exit 1
    fi
}

# Check notification method availability
check_notification_method() {
    if ! command -v ntfy &> /dev/null; then
        if command -v curl &> /dev/null; then
            export USE_CURL=true
        else
            echo "Error: Neither ntfy CLI nor curl is installed." >&2
            echo "Install ntfy: brew install ntfy" >&2
            echo "Or install curl: usually pre-installed on most systems" >&2
            exit 1
        fi
    else
        export USE_CURL=false
    fi
}
