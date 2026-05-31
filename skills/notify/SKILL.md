# claude-notify-plugin

Push notifications for Claude Code events via ntfy. Get notified on your phone or watch when Claude needs approval or completes tasks.

## Overview

This plugin sends push notifications to your mobile device when:
- **PermissionRequest**: Claude needs your approval for a tool operation
- **Stop**: Claude has finished a task or stopped working

## Quick Setup

Run the setup command:
```
/notify:setup
```

This will guide you through:
1. Installing ntfy CLI (if needed)
2. Configuring notification topic
3. Setting up server (public or self-hosted)
4. Testing the notification

## How It Works

### Terminal Detection

The plugin automatically detects if your terminal is in the foreground. If you're actively watching Claude work, notifications are skipped to avoid interruptions.

Supported terminals:
- Terminal.app
- iTerm2
- Alacritty
- Kitty
- WezTerm
- Ghostty
- Hyper

### Event Types

**PermissionRequest** (Priority 4 - High)
- Triggered when Claude needs approval for a tool
- Shows the tool name in the notification
- Uses bell icon 🔔

**Stop** (Priority 3 - Default)
- Triggered when Claude stops working
- Shows first 100 characters of the last message
- Uses check icon ✅

## Configuration

Configuration file: `~/.claude/plugins/claude-notify-plugin/config`

```ini
# Required: Notification topic/channel name
NTFY_TOPIC=claude-a3f8b2c1d4e5f6

# Optional: Enable/disable notifications (default: true)
NTFY_ENABLED=true

# Optional: Skip notification when terminal has focus (default: true)
# Set to "false" to always send notifications regardless of terminal focus
NTFY_TERMINAL_CHECK=true

# Optional: Custom notification templates
# Available variables:
#   {tool_name} - Tool requesting permission (PermissionRequest only)
#   {message} - Last assistant message (Stop only)
#   {project_name} - Current project directory name
NTFY_PERMISSION_TITLE=Claude 需要审批
NTFY_PERMISSION_BODY={tool_name}
NTFY_STOP_TITLE=Claude 已停止
NTFY_STOP_BODY={message}

# Optional: Custom ntfy server URL (default: https://ntfy.sh)
NTFY_HOST=https://ntfy.example.com

# Optional: Authentication token for self-hosted servers
NTFY_TOKEN=your-auth-token

# Optional: Enable remote approval from phone (default: false)
# When enabled, permission notifications include Approve/Deny buttons
NTFY_REMOTE_APPROVE=false

# Optional: Timeout for remote approval response in seconds (default: 300)
NTFY_REMOTE_TIMEOUT=300
```

### Remote Approval

When enabled, permission notifications include **Approve** and **Deny** buttons. Tap a button on your phone to approve or deny without returning to the terminal.

**Requirements:**
- `NTFY_TOKEN` must be configured (action buttons need auth to publish response)
- Works with both ntfy CLI and curl fallback

**Behavior:**
- **Approve**: Claude proceeds immediately
- **Deny**: Claude is denied with reason "Denied by user via remote notification"
- **Timeout** (no response within `NTFY_REMOTE_TIMEOUT` seconds): Claude Code shows its normal permission UI in terminal

**How it works:**
```
Claude needs approval
  → Notification with Approve/Deny buttons sent to phone
  → User taps button → ntfy publishes to response topic
  → Hook subscribes to response topic, receives decision
  → Hook outputs decision to stdout
  → Claude Code auto-approves or auto-denies
```

### Self-Hosted Server Notes

If using a self-hosted ntfy server:
1. Configure `NTFY_HOST` with your server URL
2. Add `NTFY_TOKEN` if authentication is required
3. For iOS push notifications, ensure server has `upstream-base-url: "https://ntfy.sh"` configured

## Mobile App Setup

### iOS
1. Install "ntfy" from App Store
2. Open app and add subscription
3. Enter your topic name
4. If using custom server, add server URL in settings

### Android
1. Install "ntfy" from Google Play
2. Open app and add subscription
3. Enter your topic name
4. If using custom server, add server URL in settings

### Web Browser
Visit `https://ntfy.sh/<your-topic>` (or your custom server URL)

## Troubleshooting

### No notifications received
1. Check if ntfy CLI is installed: `ntfy --version`
2. Verify configuration: `cat ~/.claude/plugins/claude-notify-plugin/config`
3. Test manually: `ntfy publish -m "test" <your-topic>`
4. Check if terminal is in foreground (notifications are skipped)

### Delayed notifications (self-hosted)
- Configure `upstream-base-url: "https://ntfy.sh"` on your server
- This enables iOS push notification service

### Empty notification messages
- The plugin uses "·" as default message for empty notifications
- This is because ntfy servers fill empty messages with "triggered"

## Commands

- `/notify:setup` - Interactive setup wizard
- `/notify:toggle` - Toggle notifications on/off
- `/notify:config` - Configure notification settings

## Dependencies

- [ntfy CLI](https://docs.ntfy.sh/) - Recommended for sending notifications
- curl - Alternative if ntfy CLI is not installed
- Python 3 - Used for JSON parsing (pre-installed on macOS)

## Privacy

- Notifications are sent to your private topic (randomly generated)
- No data is collected or stored by this plugin
- Self-hosted servers provide full control over notification data

## Links

- [ntfy Documentation](https://docs.ntfy.sh/)
- [ntfy GitHub](https://github.com/binwiederhier/ntfy)
- [Claude Code Plugin Documentation](https://docs.anthropic.com/en/docs/claude-code/plugins)
