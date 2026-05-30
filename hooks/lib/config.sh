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

# Get Python command (handle Windows naming)
get_python_command() {
    if command -v python3 &> /dev/null; then
        echo "python3"
    elif command -v python &> /dev/null; then
        echo "python"
    else
        echo "Error: Python is not installed." >&2
        echo "Install Python: https://www.python.org/downloads/" >&2
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
            echo "Install ntfy: brew install ntfy (macOS) or https://docs.ntfy.sh/install/" >&2
            echo "Or install curl: usually pre-installed on most systems" >&2
            exit 1
        fi
    else
        export USE_CURL=false
    fi
}

# Export Python command for use in other modules
export PYTHON_CMD
PYTHON_CMD=$(get_python_command)
