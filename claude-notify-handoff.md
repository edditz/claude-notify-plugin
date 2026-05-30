# claude-notify 插件开发交接文档

## 背景

将 Claude Code 的工作状态（需要审批、任务完成）通过 ntfy 推送到手机/手表，让用户可以离开终端。

## 插件结构

```
claude-notify/
├── .claude-plugin/
│   └── plugin.json              # 插件元数据清单
├── commands/
│   └── setup.md                 # /notify:setup 命令，引导用户配置
├── skills/
│   └── notify/
│       └── SKILL.md             # 说明文档
├── hooks/
│   └── ntfy-notify.sh           # 通知 hook 脚本
└── config                        # 本地配置（不进 git，由 setup 命令生成）
```

## 配置文件格式

位置：`~/.claude/plugins/claude-notify/config`

```ini
NTFY_TOPIC=claude-a3f8b2c1d4e5f6
NTFY_HOST=https://ntfy.sh
NTFY_TOKEN=
```

- `NTFY_TOPIC`：必填，通知频道名称
- `NTFY_HOST`：可选，默认 `https://ntfy.sh`，自建服务器时填写
- `NTFY_TOKEN`：可选，自建服务器需要认证时填写

## Hook 脚本核心逻辑

```bash
#!/bin/bash

# 读取配置
CONFIG_FILE="${HOME}/.claude/plugins/claude-notify/config"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# 检测终端是否在前台，在前台则跳过通知
is_terminal_foreground() {
    if [[ "$(uname)" == "Darwin" ]]; then
        frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
        frontmost_lower=$(echo "$frontmost" | tr '[:upper:]' '[:lower:]')
        case "$frontmost_lower" in
            *terminal*|*iterm*|*alacritty*|*kitty*|*wezterm*|*ghostty*|*hyper*) return 0 ;;
            *) return 1 ;;
        esac
    fi
    return 1
}

if is_terminal_foreground; then
    exit 0
fi

# 读取 stdin（Claude Code 传入的 JSON）
input=$(cat)

# 解析事件类型
event_type=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hook_event_name',''))" 2>/dev/null)

# 发送通知函数
send_notification() {
    local title="$1"
    local message="${2:-·}"
    local priority="${3:-3}"
    local tags="${4:-}"

    local -a args=(--title "${title}" --priority "${priority}" --quiet)
    [ -n "$tags" ] && args+=(--tags "${tags}")

    # 如果配置了自建服务器，覆盖默认
    [ -n "$NTFY_HOST" ] && args+=("--config" <(echo "default-host: ${NTFY_HOST}"))
    [ -n "$NTFY_TOKEN" ] && export NTFY_TOKEN

    ntfy publish "${args[@]}" -m "${message}" "${NTFY_TOPIC}" &
}

# 根据事件类型发送通知
case "$event_type" in
    PermissionRequest)
        tool_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
        send_notification "Claude 需要审批" "$tool_name" "4" "bell"
        ;;
    Stop)
        message=$(echo "$input" | python3 -c "
import sys,json
d=json.load(sys.stdin)
msg = d.get('last_assistant_message','')
print(msg[:100]) if msg else print('')
" 2>/dev/null)
        send_notification "Claude 已停止" "$message" "3" "check"
        ;;
esac
```

## setup 命令设计

`/notify:setup` 命令需要做的事：

1. 检测 ntfy CLI 是否安装
2. 询问用户：
   - 使用公共 ntfy.sh 还是自建服务器？
   - 如果自建：服务器地址和 token
3. 生成随机 topic（`openssl rand -hex 16`）
4. 写入配置文件
5. 往 `~/.claude/settings.json` 注入 hook 配置：

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "command": "bash ~/.claude/plugins/claude-notify/hooks/ntfy-notify.sh",
            "type": "command"
          }
        ],
        "matcher": "*"
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "command": "bash ~/.claude/plugins/claude-notify/hooks/ntfy-notify.sh",
            "type": "command"
          }
        ]
      }
    ]
  }
}
```

6. 发送测试通知验证

## ntfy CLI 依赖

用户需要先安装 ntfy CLI：

```bash
# macOS
brew install ntfy

# Linux
curl -sSL https://packages.ntfy.sh/KEY.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/ntfy.gpg
echo "deb [signed-by=/etc/apt/keyrings/ntfy.gpg] https://packages.ntfy.sh/stable/ debian main" | sudo tee /etc/apt/sources.list.d/ntfy.list
sudo apt update && sudo apt install ntfy
```

客户端配置文件位置：
- macOS: `~/Library/Application Support/ntfy/client.yml`
- Linux: `~/.config/ntfy/client.yml`

自建服务器时需要配置 `default-host`，公共 ntfy.sh 不需要。

## 已知问题

1. **自建服务器 iOS 推送**：需要在服务器配置 `upstream-base-url: "https://ntfy.sh"`，否则通知延迟很大
2. **ntfy CLI `--server` 参数不存在**：服务器地址只能通过 client.yml 配置
3. **空消息问题**：ntfy 服务器会把空消息填充为 "triggered"，所以用 `·` 作为默认消息
4. **大小写问题**：`osascript` 返回的进程名可能是小写（如 `ghostty`），匹配时需要忽略大小写

## 参考资源

- [ntfy 官方文档](https://docs.ntfy.sh/)
- [Claude Code 插件开发文档](https://zread.ai/anthropics/claude-code/7-plugin-structure-and-manifest)
- [ntfy GitHub 仓库](https://github.com/binwiederhier/ntfy)
