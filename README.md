# claude-notify

Push notifications for Claude Code events via ntfy. Get notified on your phone or watch when Claude needs approval or completes tasks.

## Features

- 🔔 **Permission Alerts** - Get notified when Claude needs your approval
- ✅ **Task Completion** - Know when Claude finishes working
- 📱 **Mobile Notifications** - Receive alerts on your phone/watch
- 🖥️ **Smart Detection** - Skips notifications when you're watching the terminal
- 🏠 **Self-Hosted Support** - Use your own ntfy server

## Quick Start

### 1. Install the Plugin

```bash
claude plugin install claude-notify
```

### 2. Run Setup

```
/notify:setup
```

This will guide you through:
- Installing ntfy CLI (if needed)
- Configuring your notification topic
- Testing the notification

### 3. Subscribe on Mobile

Install the ntfy app on your phone:
- **iOS**: [App Store](https://apps.apple.com/app/ntfy/id1625396347)
- **Android**: [Google Play](https://play.google.com/store/apps/details?id=io.heckel.ntfy)

Add your topic name to receive notifications.

## How It Works

```
Claude Code Event → Hook Script → ntfy Server → Your Phone
```

1. Claude Code triggers a hook event (PermissionRequest or Stop)
2. The hook script checks if your terminal is in the foreground
3. If you're away, it sends a notification via ntfy
4. You receive the notification on your phone

## Configuration

Configuration file: `~/.claude/plugins/claude-notify/config`

```ini
# Required: Your unique notification topic
NTFY_TOPIC=claude-a3f8b2c1d4e5f6

# Optional: Custom ntfy server (default: https://ntfy.sh)
NTFY_HOST=https://ntfy.example.com

# Optional: Authentication token
NTFY_TOKEN=your-auth-token
```

## Self-Hosted Server

For privacy or enterprise use, you can run your own ntfy server:

```bash
# Using Docker
docker run -p 80:80 -it binwiederhier/ntfy serve
```

Then configure:
```ini
NTFY_HOST=http://your-server:80
NTFY_TOPIC=your-private-topic
NTFY_TOKEN=your-auth-token
```

## Supported Terminals

The plugin detects if these terminals are in the foreground:
- Terminal.app
- iTerm2
- Alacritty
- Kitty
- WezTerm
- Ghostty
- Hyper

## Commands

- `/notify:setup` - Interactive setup wizard

## Dependencies

- [ntfy CLI](https://docs.ntfy.sh/) - Required
- Python 3 - For JSON parsing (pre-installed on macOS)

## Troubleshooting

### No notifications?

1. Check ntfy CLI: `ntfy --version`
2. Verify config: `cat ~/.claude/plugins/claude-notify/config`
3. Test manually: `ntfy publish -m "test" <your-topic>`

### Delayed notifications (self-hosted)?

Add to your ntfy server config:
```yaml
upstream-base-url: "https://ntfy.sh"
```

## License

MIT

## Links

- [ntfy Documentation](https://docs.ntfy.sh/)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
