#!/bin/bash

# Terminal detection module

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
check_terminal_focus() {
    if [ "${NTFY_TERMINAL_CHECK:-true}" = "true" ] && is_terminal_foreground; then
        exit 0
    fi
}
