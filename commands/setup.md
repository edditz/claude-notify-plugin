# /notify:setup

Setup command for claude-notify-plugin. Guides users through configuring ntfy notifications.

## Instructions

You are helping the user set up push notifications for Claude Code via ntfy. Follow these steps:

### Step 1: Check ntfy CLI installation

First, check if ntfy CLI is installed:

```bash
command -v ntfy && ntfy --version || echo "NOT_INSTALLED"
```

If not installed, guide the user to install it:

**macOS:**
```bash
brew install ntfy
```

**Linux:**
```bash
curl -sSL https://packages.ntfy.sh/KEY.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/ntfy.gpg
echo "deb [signed-by=/etc/apt/keyrings/ntfy.gpg] https://packages.ntfy.sh/stable/ debian main" | sudo tee /etc/apt/sources.list.d/ntfy.list
sudo apt update && sudo apt install ntfy
```

### Step 2: Ask about server configuration

Ask the user:
1. Use public ntfy.sh server? (default: yes)
2. If no, ask for:
   - Server URL (e.g., https://ntfy.example.com)
   - Authentication token (if required)

### Step 3: Generate topic

Generate a random topic name:

```bash
openssl rand -hex 16
```

### Step 4: Create configuration

Create the config directory and file:

```bash
mkdir -p ~/.claude/plugins/claude-notify-plugin
```

Write the configuration to `~/.claude/plugins/claude-notify-plugin/config`:

```ini
NTFY_TOPIC=<generated-topic>
NTFY_ENABLED=true
NTFY_TERMINAL_CHECK=true
NTFY_HOST=<server-url-or-empty>
NTFY_TOKEN=<token-or-empty>
```

### Step 5: Configure Claude Code hooks

The hooks are already configured in the plugin's `hooks/hooks.json` file. No manual configuration needed.

### Step 6: Send test notification

Send a test notification to verify the setup:

```bash
source ~/.claude/plugins/claude-notify-plugin/config
ntfy publish --title "claude-notify-plugin 测试" --priority 3 --quiet -m "通知配置成功！" "$NTFY_TOPIC"
```

### Step 7: Provide subscription instructions

Tell the user how to subscribe to notifications:

**Mobile apps:**
- iOS: Install "ntfy" from App Store
- Android: Install "ntfy" from Google Play

**Subscribe to topic:**
1. Open the ntfy app
2. Add subscription with topic: `<NTFY_TOPIC>`
3. If using custom server, configure server URL in app settings

**Web browser:**
- Visit `https://ntfy.sh/<NTFY_TOPIC>` (or custom server URL)

## Example Output

```
✅ claude-notify-plugin 配置完成！

配置详情:
- 通知频道: claude-a3f8b2c1d4e5f6
- 服务器: https://ntfy.sh
- 配置文件: ~/.claude/plugins/claude-notify-plugin/config

订阅方式:
1. 手机安装 ntfy app (iOS/Android)
2. 添加频道: claude-a3f8b2c1d4e5f6
3. 完成！

测试通知已发送，请检查手机是否收到。
```

## Error Handling

If any step fails:
- Provide clear error message
- Suggest troubleshooting steps
- Offer to retry the failed step
