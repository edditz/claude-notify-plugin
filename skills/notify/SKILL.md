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

# Optional: Custom ntfy server URL (default: https://ntfy.sh)
NTFY_HOST=https://ntfy.example.com

# Optional: Authentication token for self-hosted servers
NTFY_TOKEN=your-auth-token
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

## Dependencies

- [ntfy CLI](https://docs.ntfy.sh/) - Required for sending notifications
- Python 3 - Used for JSON parsing (pre-installed on macOS)

## Privacy

- Notifications are sent to your private topic (randomly generated)
- No data is collected or stored by this plugin
- Self-hosted servers provide full control over notification data

## Links

- [ntfy Documentation](https://docs.ntfy.sh/)
- [ntfy GitHub](https://github.com/binwiederhier/ntfy)
- [Claude Code Plugin Documentation](https://docs.anthropic.com/en/docs/claude-code/plugins)
