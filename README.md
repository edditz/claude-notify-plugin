# claude-notify-plugin

Push notifications for Claude Code events via ntfy. Get notified on your phone or watch when Claude needs approval or completes tasks.

## Features

- 🔔 **Permission Alerts** - Get notified when Claude needs your approval
- ✅ **Task Completion** - Know when Claude finishes working
- 📱 **Mobile Notifications** - Receive alerts on your phone/watch
- 🖥️ **Smart Detection** - Skips notifications when you're watching the terminal
- 🏠 **Self-Hosted Support** - Use your own ntfy server
- 🔕 **Easy Toggle** - Enable/disable notifications with one command

## Quick Start

### 1. Add Marketplace

```bash
claude plugin marketplace add git@github.com:edditz/claude-plugins-marketplace.git
```

### 2. Install the Plugin

```bash
claude plugin install claude-notify-plugin@edditz-plugins
```

### 3. Run Setup

```
/claude-notify-plugin:setup
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

Configuration file: `~/.claude/plugins/claude-notify-plugin/config`

```ini
# Required: Your unique notification topic
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

**macOS:**
- Terminal.app
- iTerm2
- Alacritty
- Kitty
- WezTerm
- Ghostty
- Hyper

**Linux:**
- GNOME Terminal
- Konsole
- Alacritty
- Kitty
- WezTerm
- Ghostty
- Hyper
- XTerm

**Windows:**
- Windows Terminal
- PowerShell
- Command Prompt (cmd)
- Git Bash
- WSL (Windows Subsystem for Linux)
- Alacritty
- Kitty
- WezTerm
- Ghostty
- Hyper

## Platform Support

| Platform | Status | Requirements |
|----------|--------|--------------|
| macOS | ✅ Full support | None (bash pre-installed) |
| Linux | ✅ Full support | bash, xdotool or wmctrl (optional) |
| Windows | ✅ Full support | Git Bash, WSL, or PowerShell |

### Windows Requirements

**Option 1: Git Bash (Recommended)**
- Install [Git for Windows](https://gitforwindows.org/)
- bash will be available in PATH

**Option 2: WSL (Windows Subsystem for Linux)**
- Install WSL: `wsl --install`
- bash will be available via WSL

**Option 3: PowerShell (Fallback)**
- Built into Windows
- Uses PowerShell script instead of bash

## Commands

- `/claude-notify-plugin:setup` - Interactive setup wizard
- `/claude-notify-plugin:toggle` - Toggle notifications on/off
- `/claude-notify-plugin:config` - Configure notification settings

## Dependencies

- [ntfy CLI](https://docs.ntfy.sh/) - Recommended
- curl - Alternative if ntfy CLI is not installed
- Python 3 - For JSON parsing
  - macOS: Pre-installed
  - Linux: Usually pre-installed (`python3`)
  - Windows: Install from [python.org](https://www.python.org/downloads/) (use `python` command)

## Troubleshooting

### No notifications?

1. Check ntfy CLI: `ntfy --version`
2. Verify config: `cat ~/.claude/plugins/claude-notify-plugin/config`
3. Test manually: `ntfy publish -m "test" <your-topic>`

### Windows: "bash" not found?

Install one of:
- [Git for Windows](https://gitforwindows.org/) (includes Git Bash)
- [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows Subsystem for Linux)

Or use PowerShell fallback (no additional installation needed).

### Windows: Python not found?

Install Python from [python.org](https://www.python.org/downloads/) or use:
```powershell
# Winget
winget install Python.Python.3

# Chocolatey
choco install python

# Scoop
scoop install python
```

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
- [Marketplace](https://github.com/edditz/claude-plugins-marketplace)
