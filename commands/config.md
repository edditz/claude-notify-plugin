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
```

### Step 3: Ask what to configure

Ask the user which setting they want to change:

1. **通知开关** - 启用/禁用所有通知
2. **终端检查** - 是否在终端有焦点时跳过通知
3. **通知频道** - 更改通知频道名称
4. **服务器设置** - 更改 ntfy 服务器地址

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
