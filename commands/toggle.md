# /notify:toggle

Toggle notifications on or off for claude-notify-plugin.

## Instructions

You are helping the user toggle notifications for Claude Code. Follow these steps:

### Step 1: Read current configuration

Read the configuration file:

```bash
cat ~/.claude/plugins/claude-notify-plugin/config 2>/dev/null || echo "CONFIG_NOT_FOUND"
```

### Step 2: Determine current state

Check if `NTFY_ENABLED` is set:
- If `NTFY_ENABLED=false` → notifications are disabled
- If `NTFY_ENABLED=true` or not set → notifications are enabled

### Step 3: Toggle the state

**If currently enabled (or not set):**
```bash
# Add or update NTFY_ENABLED=false in config
if grep -q "NTFY_ENABLED=" ~/.claude/plugins/claude-notify-plugin/config; then
    sed -i '' 's/NTFY_ENABLED=.*/NTFY_ENABLED=false/' ~/.claude/plugins/claude-notify-plugin/config
else
    echo "NTFY_ENABLED=false" >> ~/.claude/plugins/claude-notify-plugin/config
fi
```

**If currently disabled:**
```bash
# Update NTFY_ENABLED=true in config
sed -i '' 's/NTFY_ENABLED=.*/NTFY_ENABLED=true/' ~/.claude/plugins/claude-notify-plugin/config
```

### Step 4: Confirm the change

Tell the user the new state:

**If now disabled:**
```
🔕 通知已关闭

Claude Code 不会再发送推送通知。
如需重新开启，运行: /notify:toggle
```

**If now enabled:**
```
🔔 通知已开启

Claude Code 将在以下情况发送推送通知:
- 需要审批时
- 任务完成时

如需关闭，运行: /notify:toggle
```

## Error Handling

If configuration file doesn't exist:
```
❌ 请先运行 /notify:setup 配置通知
```
