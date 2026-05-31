# /notify:setup

Setup command for claude-notify-plugin. Guides users through configuring ntfy notifications.

## Instructions

You are helping the user set up push notifications for Claude Code via ntfy. Follow these steps:

### Step 0: Check for existing configuration

First, check if a configuration file already exists:

```bash
cat ~/.claude/plugins/claude-notify-plugin/config 2>/dev/null || echo "CONFIG_NOT_FOUND"
```

If configuration exists, also check ntfy CLI configuration:

```bash
# Check ntfy CLI config
cat ~/.config/ntfy/client.yml 2>/dev/null || echo "NTFY_CLI_CONFIG_NOT_FOUND"
```

Compare the two configurations and show to the user:

```
📋 检测到现有配置

插件配置:
- 通知频道: <NTFY_TOPIC>
- 服务器: <NTFY_HOST>
- 通知状态: <NTFY_ENABLED>
- 终端检查: <NTFY_TERMINAL_CHECK>

ntfy CLI 配置:
- 服务器: <ntfy-cli-default-host> 或 "未配置"

⚠️ 配置不一致！
插件配置的服务器与 ntfy CLI 配置的服务器不同。
建议更新 ntfy CLI 配置以保持一致。

请选择:
1. 使用现有配置并更新 ntfy CLI 配置 (推荐)
2. 使用现有配置（不更新 ntfy CLI）
3. 重新配置 (覆盖现有配置)

请输入选项 (1-3):
```

**If configurations are consistent:**

```
📋 检测到现有配置

插件配置:
- 通知频道: <NTFY_TOPIC>
- 服务器: <NTFY_HOST>
- 通知状态: <NTFY_ENABLED>
- 终端检查: <NTFY_TERMINAL_CHECK>

ntfy CLI 配置:
- 服务器: <ntfy-cli-default-host>

✅ 配置一致

请选择:
1. 使用现有配置 (推荐)
2. 重新配置 (覆盖现有配置)

请输入选项 (1-2):
```

**If user chooses 1 (Use existing configuration and update ntfy CLI):**

```
✅ 使用现有配置

配置详情:
- 通知频道: <NTFY_TOPIC>
- 服务器: <NTFY_HOST>
- 配置文件: ~/.claude/plugins/claude-notify-plugin/config

正在更新 ntfy CLI 配置...
```

Update ntfy CLI configuration:
```bash
mkdir -p ~/.config/ntfy
cat > ~/.config/ntfy/client.yml << EOF
default-host: <NTFY_HOST>
token: <NTFY_TOKEN>
EOF
```

```
✅ ntfy CLI 配置已更新

测试现有配置...
```

Then skip to Step 6 (Send test notification).

**If user chooses 2 (Use existing configuration without updating ntfy CLI):**

```
✅ 使用现有配置

配置详情:
- 通知频道: <NTFY_TOPIC>
- 服务器: <NTFY_HOST>
- 配置文件: ~/.claude/plugins/claude-notify-plugin/config

测试现有配置...
```

Then skip to Step 6 (Send test notification).

**If user chooses 3 (Reconfigure):**

Continue to Step 1.

### Step 1: Check ntfy CLI installation

First, check if ntfy CLI is installed:

```bash
command -v ntfy && ntfy --version || echo "NOT_INSTALLED"
```

If not installed, show options to the user:

```
⚠️ 检测到未安装 ntfy CLI

ntfy CLI 是发送通知的推荐方式，但不是必须的。

请选择:
1. 安装 ntfy CLI (推荐)
2. 使用 curl 备选方案 (无需安装)

请输入选项 (1-2):
```

**If user chooses 1 (Install ntfy CLI):**

Show installation instructions for different platforms:

```
📦 安装 ntfy CLI

请选择你的操作系统:

macOS (Homebrew):
  brew install ntfy

macOS (MacPorts):
  sudo port install ntfy

Linux (Debian/Ubuntu):
  curl -sSL https://packages.ntfy.sh/KEY.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/ntfy.gpg
  echo "deb [signed-by=/etc/apt/keyrings/ntfy.gpg] https://packages.ntfy.sh/stable/ debian main" | sudo tee /etc/apt/sources.list.d/ntfy.list
  sudo apt update && sudo apt install ntfy

Linux (Fedora/RHEL):
  sudo dnf install ntfy

Linux (Arch):
  yay -S ntfy

Windows (Scoop):
  scoop install ntfy

Windows (Chocolatey):
  choco install ntfy

Windows (Winget):
  winget install ntfy

安装完成后，请重新运行 /notify:setup
```

**If user chooses 2 (Use curl):**

```
✅ 使用 curl 备选方案

curl 通常已预装在大多数系统中。插件将使用 curl 发送通知。

注意: curl 方案功能较少，但基本通知功能正常。
```

Then continue to Step 2, but set a flag to use curl instead of ntfy CLI.

### Step 2: Ask about server configuration

Ask the user:
1. Use public ntfy.sh server? (default: yes)
2. If no, ask for:
   - Server URL (e.g., https://ntfy.example.com)
   - Authentication token (if required)

**If using ntfy CLI and custom server:**

Configure ntfy CLI to use the custom server:

```bash
# Create ntfy client config directory
mkdir -p ~/.config/ntfy

# Write client configuration
cat > ~/.config/ntfy/client.yml << EOF
default-host: <server-url>
EOF
```

Or use environment variable:
```bash
export NTFY_HOST=<server-url>
```

Note: The plugin uses `--token` flag and full URL (`${NTFY_HOST}/${NTFY_TOPIC}`) to send notifications, so CLI configuration is optional. But configuring it makes manual testing easier.

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

### Step 5.5: Remote Approval Configuration

Ask the user:

```
是否启用远程审批？(Enable remote approval?)

当 Claude 需要审批时，你可以在手机上直接批准或拒绝，无需回到终端。
When Claude needs approval, you can approve or deny directly from your phone without returning to the terminal.

注意: 需要配置 NTFY_TOKEN (认证令牌) 才能使用远程审批。
Note: NTFY_TOKEN (authentication token) is required for remote approval.

启用远程审批？(Enable remote approval?) (y/n, default: n):
```

**If yes:**
1. Verify NTFY_TOKEN is set (if not, prompt for it and update config)
2. Add to config file:
```bash
echo "NTFY_REMOTE_APPROVE=true" >> ~/.claude/plugins/claude-notify-plugin/config
echo "NTFY_REMOTE_TIMEOUT=300" >> ~/.claude/plugins/claude-notify-plugin/config
```
3. Explain:
```
✅ 远程审批已启用

行为:
- Claude 需要审批时，你会收到带有「Approve/Deny」按钮的通知
- 点击按钮即可远程决策，无需回到终端
- 如果超时未响应（默认5分钟），Claude Code 会显示正常的审批界面
```

**If no:**
```bash
echo "NTFY_REMOTE_APPROVE=false" >> ~/.claude/plugins/claude-notify-plugin/config
```

### Step 6: Send test notification

Send a test notification to verify the setup:

**If using ntfy CLI:**
```bash
source ~/.claude/plugins/claude-notify-plugin/config
if [ -n "${NTFY_TOKEN:-}" ]; then
    ntfy publish --token "$NTFY_TOKEN" --title "claude-notify-plugin 测试" --priority 3 --quiet -m "通知配置成功！" "${NTFY_HOST:-https://ntfy.sh}/${NTFY_TOPIC}"
else
    ntfy publish --title "claude-notify-plugin 测试" --priority 3 --quiet -m "通知配置成功！" "${NTFY_HOST:-https://ntfy.sh}/${NTFY_TOPIC}"
fi
```

**If using curl:**
```bash
source ~/.claude/plugins/claude-notify-plugin/config
curl -H "Title: claude-notify-plugin 测试" -H "Priority: default" -H "Authorization: Bearer $NTFY_TOKEN" -d "通知配置成功！" "$NTFY_HOST/$NTFY_TOPIC"
```

**If using existing configuration:**

Check which notification method is available and send test accordingly:

```bash
# Read plugin config
source ~/.claude/plugins/claude-notify-plugin/config

# Detect notification method
if command -v ntfy &> /dev/null; then
    # Use ntfy CLI
    if [ -n "${NTFY_TOKEN:-}" ]; then
        ntfy publish --token "$NTFY_TOKEN" --title "claude-notify-plugin 测试" --priority 3 --quiet -m "通知配置成功！" "${NTFY_HOST:-https://ntfy.sh}/${NTFY_TOPIC}"
    else
        ntfy publish --title "claude-notify-plugin 测试" --priority 3 --quiet -m "通知配置成功！" "${NTFY_HOST:-https://ntfy.sh}/${NTFY_TOPIC}"
    fi
else
    # Use curl fallback
    if [ -n "${NTFY_TOKEN:-}" ]; then
        curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -H "Title: claude-notify-plugin 测试" -H "Priority: default" -H "Authorization: Bearer $NTFY_TOKEN" -d "通知配置成功！" "${NTFY_HOST:-https://ntfy.sh}/${NTFY_TOPIC}"
    else
        curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -H "Title: claude-notify-plugin 测试" -H "Priority: default" -d "通知配置成功！" "${NTFY_HOST:-https://ntfy.sh}/${NTFY_TOPIC}"
    fi
fi
```

**If configurations match:**
```
✅ 测试通知已发送！

配置详情:
- 通知频道: <NTFY_TOPIC>
- 服务器: <NTFY_HOST>
- ntfy CLI 配置: ✅ 一致

订阅方式:
1. 手机安装 ntfy app (iOS/Android)
2. 添加频道: <NTFY_TOPIC>
3. 配置服务器: <NTFY_HOST>
4. 完成！

测试通知已发送，请检查手机是否收到。
```

**If configurations don't match:**
```
⚠️ 配置不一致！

插件配置:
- 服务器: <NTFY_HOST>

ntfy CLI 配置:
- 服务器: <NTFY_CLI_HOST>

建议: 运行 /notify:setup 并选择"使用现有配置并更新 ntfy CLI 配置"

测试通知已发送，请检查手机是否收到。
```

Note: If using public ntfy.sh server, the URL is `https://ntfy.sh/$NTFY_TOPIC`

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
