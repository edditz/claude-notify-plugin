# /notify:config

Configure notification settings for claude-notify-plugin.

## Instructions

You are helping the user configure notification settings for Claude Code. Follow these steps:

### Step 1: Read current configuration

Read the configuration file:

```bash
cat ~/.claude/plugins/claude-notify-plugin/config 2>/dev/null || echo "CONFIG_NOT_FOUND"
```

### Step 2: Display current settings

Show the user their current configuration:

```
当前配置:
- 通知状态: 启用/禁用
- 终端检查: 启用/禁用
- 通知频道: <topic>
- 服务器: <host>
- 远程审批: 启用/禁用 (超时: <timeout>s)
```

### Step 3: Ask what to configure

Ask the user which setting they want to change:

1. **通知开关** - 启用/禁用所有通知
2. **终端检查** - 是否在终端有焦点时跳过通知
3. **通知内容** - 自定义通知标题和正文
4. **通知频道** - 更改通知频道名称
5. **服务器设置** - 更改 ntfy 服务器地址
6. **远程审批** - 从手机批准/拒绝 Claude 的权限请求

### Step 4: Apply changes

**For 通知开关 (NTFY_ENABLED):**
```bash
# Toggle NTFY_ENABLED
if grep -q "NTFY_ENABLED=false" ~/.claude/plugins/claude-notify-plugin/config; then
    sed -i '' 's/NTFY_ENABLED=false/NTFY_ENABLED=true/' ~/.claude/plugins/claude-notify-plugin/config
    echo "✅ 通知已启用"
else
    if grep -q "NTFY_ENABLED=" ~/.claude/plugins/claude-notify-plugin/config; then
        sed -i '' 's/NTFY_ENABLED=.*/NTFY_ENABLED=false/' ~/.claude/plugins/claude-notify-plugin/config
    else
        echo "NTFY_ENABLED=false" >> ~/.claude/plugins/claude-notify-plugin/config
    fi
    echo "🔕 通知已禁用"
fi
```

**For 终端检查 (NTFY_TERMINAL_CHECK):**
```bash
# Toggle NTFY_TERMINAL_CHECK
if grep -q "NTFY_TERMINAL_CHECK=false" ~/.claude/plugins/claude-notify-plugin/config; then
    sed -i '' 's/NTFY_TERMINAL_CHECK=false/NTFY_TERMINAL_CHECK=true/' ~/.claude/plugins/claude-notify-plugin/config
    echo "✅ 终端检查已启用（终端有焦点时跳过通知）"
else
    if grep -q "NTFY_TERMINAL_CHECK=" ~/.claude/plugins/claude-notify-plugin/config; then
        sed -i '' 's/NTFY_TERMINAL_CHECK=.*/NTFY_TERMINAL_CHECK=false/' ~/.claude/plugins/claude-notify-plugin/config
    else
        echo "NTFY_TERMINAL_CHECK=false" >> ~/.claude/plugins/claude-notify-plugin/config
    fi
    echo "✅ 终端检查已禁用（始终发送通知）"
fi
```

**For 远程审批 (NTFY_REMOTE_APPROVE):**

Show current state:
```
当前状态: 启用/禁用
超时时间: 300s
认证令牌: 已配置/未配置

远程审批允许你在手机上通过通知按钮批准或拒绝 Claude 的权限请求。
Remote approval lets you approve/deny Claude permission requests via notification buttons on your phone.

请选择:
1. 启用远程审批
2. 禁用远程审批
3. 更改超时时间
```

**For enabling:**
```bash
# Check token exists
if ! grep -q "NTFY_TOKEN=" ~/.claude/plugins/claude-notify-plugin/config || grep -q "NTFY_TOKEN=$" ~/.claude/plugins/claude-notify-plugin/config; then
    echo "⚠️ 远程审批需要认证令牌 (NTFY_TOKEN)。请先在服务器设置中配置令牌。"
    echo "Remote approval requires an auth token. Please configure the token in server settings first."
else
    if grep -q "NTFY_REMOTE_APPROVE=" ~/.claude/plugins/claude-notify-plugin/config; then
        sed -i '' 's/NTFY_REMOTE_APPROVE=.*/NTFY_REMOTE_APPROVE=true/' ~/.claude/plugins/claude-notify-plugin/config
    else
        echo "NTFY_REMOTE_APPROVE=true" >> ~/.claude/plugins/claude-notify-plugin/config
    fi
    echo "✅ 远程审批已启用"
    echo ""
    echo "行为:"
    echo "- Claude 需要审批时，你会收到带有「Approve/Deny」按钮的通知"
    echo "- 点击按钮即可远程决策，无需回到终端"
    echo "- 如果超时未响应，Claude Code 会显示正常的审批界面"
fi
```

**For disabling:**
```bash
if grep -q "NTFY_REMOTE_APPROVE=" ~/.claude/plugins/claude-notify-plugin/config; then
    sed -i '' 's/NTFY_REMOTE_APPROVE=.*/NTFY_REMOTE_APPROVE=false/' ~/.claude/plugins/claude-notify-plugin/config
else
    echo "NTFY_REMOTE_APPROVE=false" >> ~/.claude/plugins/claude-notify-plugin/config
fi
echo "✅ 远程审批已禁用"
```

**For changing timeout:**
```bash
echo "当前超时: $(grep NTFY_REMOTE_TIMEOUT ~/.claude/plugins/claude-notify-plugin/config 2>/dev/null | cut -d= -f2 || echo 300)s"
echo "请输入新的超时时间（秒）:"
read new_timeout
if [[ "$new_timeout" =~ ^[0-9]+$ ]]; then
    if grep -q "NTFY_REMOTE_TIMEOUT=" ~/.claude/plugins/claude-notify-plugin/config; then
        sed -i '' "s/NTFY_REMOTE_TIMEOUT=.*/NTFY_REMOTE_TIMEOUT=$new_timeout/" ~/.claude/plugins/claude-notify-plugin/config
    else
        echo "NTFY_REMOTE_TIMEOUT=$new_timeout" >> ~/.claude/plugins/claude-notify-plugin/config
    fi
    echo "✅ 超时时间已更新为 ${new_timeout}s"
else
    echo "❌ 无效输入，请输入数字"
fi
```

**For 通知内容 (Notification Content):**

Show available variables:
```
📝 自定义通知内容

可用变量:
- {tool_name} - 请求审批的工具名称
- {message} - 最后一条消息（截取前100字符）
- {project_name} - 当前项目目录名
```

Show current configuration:
```
当前配置:
- 审批标题: Claude 需要审批
- 审批内容: {tool_name}
- 完成标题: Claude 已停止
- 完成内容: {message}
```

Ask if user wants to customize:
```
是否要自定义通知内容？(y/n):
```

If yes, guide through customization:

**Step 1: Configure PermissionRequest notification**
```
🔧 配置审批通知

当前标题: Claude 需要审批
当前内容: {tool_name}

请输入新的标题（直接回车保持不变）:
> [{project_name}] 需要审批

请输入新的内容（直接回车保持不变）:
> 工具: {tool_name}

预览:
┌────────────────────────────────────┐
│ 🔔 [claude-notify-plugin] 需要审批 │
│ 工具: Bash                         │
└────────────────────────────────────┘

确认保存？(y/n):
```

**Step 2: Configure Stop notification**
```
🔧 配置完成通知

当前标题: Claude 已停止
当前内容: {message}

请输入新的标题（直接回车保持不变）:
> [{project_name}] 已完成

请输入新的内容（直接回车保持不变）:
> {message}

预览:
┌────────────────────────────────────────┐
│ ✅ [claude-notify-plugin] 已完成       │
│ 任务已完成！文件已保存到指定目录...     │
└────────────────────────────────────────┘

确认保存？(y/n):
```

**Step 3: Save configuration**

Update the config file with new values:
```bash
# Update or add NTFY_PERMISSION_TITLE
if grep -q "NTFY_PERMISSION_TITLE=" ~/.claude/plugins/claude-notify-plugin/config; then
    sed -i '' "s/NTFY_PERMISSION_TITLE=.*/NTFY_PERMISSION_TITLE=$title/" ~/.claude/plugins/claude-notify-plugin/config
else
    echo "NTFY_PERMISSION_TITLE=$title" >> ~/.claude/plugins/claude-notify-plugin/config
fi

# Update or add NTFY_PERMISSION_BODY
if grep -q "NTFY_PERMISSION_BODY=" ~/.claude/plugins/claude-notify-plugin/config; then
    sed -i '' "s/NTFY_PERMISSION_BODY=.*/NTFY_PERMISSION_BODY=$body/" ~/.claude/plugins/claude-notify-plugin/config
else
    echo "NTFY_PERMISSION_BODY=$body" >> ~/.claude/plugins/claude-notify-plugin/config
fi

# Update or add NTFY_STOP_TITLE
if grep -q "NTFY_STOP_TITLE=" ~/.claude/plugins/claude-notify-plugin/config; then
    sed -i '' "s/NTFY_STOP_TITLE=.*/NTFY_STOP_TITLE=$title/" ~/.claude/plugins/claude-notify-plugin/config
else
    echo "NTFY_STOP_TITLE=$title" >> ~/.claude/plugins/claude-notify-plugin/config
fi

# Update or add NTFY_STOP_BODY
if grep -q "NTFY_STOP_BODY=" ~/.claude/plugins/claude-notify-plugin/config; then
    sed -i '' "s/NTFY_STOP_BODY=.*/NTFY_STOP_BODY=$body/" ~/.claude/plugins/claude-notify-plugin/config
else
    echo "NTFY_STOP_BODY=$body" >> ~/.claude/plugins/claude-notify-plugin/config
fi
```

Show completion message:
```
✅ 通知内容配置完成！

新的配置:
- 审批标题: [{project_name}] 需要审批
- 审批内容: 工具: {tool_name}
- 完成标题: [{project_name}] 已完成
- 完成内容: {message}

配置已保存到: ~/.claude/plugins/claude-notify-plugin/config
```

### Step 5: Confirm changes

Show the updated configuration and explain the behavior:

**If NTFY_TERMINAL_CHECK=true:**
```
终端检查已启用

行为: 当终端有焦点时，不会发送通知。
适合: 单屏幕用户，或希望在看终端时不被打扰。
```

**If NTFY_TERMINAL_CHECK=false:**
```
终端检查已禁用

行为: 无论终端是否有焦点，都会发送通知。
适合: 多屏幕用户，或希望始终收到通知。
```

## Error Handling

If configuration file doesn't exist:
```
❌ 请先运行 /notify:setup 配置通知
```
