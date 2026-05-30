#!/bin/bash

# Terminal detection module

# Detect if terminal is in foreground (skip notifications when user is watching)
is_terminal_foreground() {
    local os_type
    os_type=$(uname -s 2>/dev/null || echo "Unknown")

    case "$os_type" in
        Darwin)
            # macOS: Use osascript to get frontmost application
            local frontmost
            frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
            local frontmost_lower
            frontmost_lower=$(echo "$frontmost" | tr '[:upper:]' '[:lower:]')
            case "$frontmost_lower" in
                *terminal*|*iterm*|*alacritty*|*kitty*|*wezterm*|*ghostty*|*hyper*) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        Linux)
            # Linux: Check if terminal window is focused using xdotool or wmctrl
            if command -v xdotool &> /dev/null; then
                local active_window
                active_window=$(xdotool getactivewindow getwindowname 2>/dev/null || echo "")
                local active_lower
                active_lower=$(echo "$active_window" | tr '[:upper:]' '[:lower:]')
                case "$active_lower" in
                    *terminal*|*iterm*|*alacritty*|*kitty*|*wezterm*|*ghostty*|*hyper*|*xterm*|*konsole*|*gnome-terminal*) return 0 ;;
                    *) return 1 ;;
                esac
            elif command -v wmctrl &> /dev/null; then
                local active_window
                active_window=$(wmctrl -lx 2>/dev/null | grep -i "$(xdotool getactivewindow 2>/dev/null)" || echo "")
                local active_lower
                active_lower=$(echo "$active_window" | tr '[:upper:]' '[:lower:]')
                case "$active_lower" in
                    *terminal*|*iterm*|*alacritty*|*kitty*|*wezterm*|*ghostty*|*hyper*|*xterm*|*konsole*|*gnome-terminal*) return 0 ;;
                    *) return 1 ;;
                esac
            else
                # Cannot detect on Linux without xdotool or wmctrl
                return 1
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)
            # Windows: Use PowerShell to get foreground window
            if command -v powershell.exe &> /dev/null; then
                local active_window
                active_window=$(powershell.exe -Command "
                    Add-Type @'
                    using System;
                    using System.Runtime.InteropServices;
                    public class Win32 {
                        [DllImport(\"user32.dll\")]
                        public static extern IntPtr GetForegroundWindow();
                        [DllImport(\"user32.dll\", SetLastError=true)]
                        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
                    }
'@
                    \$hwnd = [Win32]::GetForegroundWindow()
                    \$sb = New-Object System.Text.StringBuilder(256)
                    [Win32]::GetWindowText(\$hwnd, \$sb, 256) | Out-Null
                    \$sb.ToString()
                " 2>/dev/null || echo "")
                local active_lower
                active_lower=$(echo "$active_window" | tr '[:upper:]' '[:lower:]')
                case "$active_lower" in
                    *terminal*) return 0 ;;
                    *powershell*) return 0 ;;
                    *cmd*) return 0 ;;
                    *git*bash*) return 0 ;;
                    *wsl*) return 0 ;;
                    *alacritty*) return 0 ;;
                    *kitty*) return 0 ;;
                    *wezterm*) return 0 ;;
                    *ghostty*) return 0 ;;
                    *hyper*) return 0 ;;
                    *) return 1 ;;
                esac
            else
                # Cannot detect on Windows without PowerShell
                return 1
            fi
            ;;
        *)
            # Unknown OS, assume not in foreground
            return 1
            ;;
    esac
}

# Skip notification if terminal is in foreground (when NTFY_TERMINAL_CHECK is enabled)
check_terminal_focus() {
    if [ "${NTFY_TERMINAL_CHECK:-true}" = "true" ] && is_terminal_foreground; then
        exit 0
    fi
}
