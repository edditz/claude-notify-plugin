# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin that pushes mobile notifications (via ntfy) when Claude needs approval (`PermissionRequest`) or finishes working (`Stop`). Users subscribe to a topic in the ntfy mobile app to receive alerts on their phone/watch.

## Architecture

**Event flow**: Claude Code hook → `hooks/ntfy-notify.sh` → library modules → ntfy CLI/curl → mobile device

The main script (`hooks/ntfy-notify.sh`) is modular — it sources four libraries from `hooks/lib/`:

| Module | Purpose |
|--------|---------|
| `config.sh` | Loads config from `~/.claude/plugins/claude-notify-plugin/config`, validates `NTFY_TOPIC`, detects Python |
| `terminal.sh` | Cross-platform foreground detection (macOS/Linux/Windows) — skips notifications when terminal is active |
| `notify.sh` | Sends via ntfy CLI (preferred) or curl fallback; handles custom servers/tokens via temp config files |
| `template.sh` | Builds notification title/body with variable replacement (`{project_name}`, `{tool_name}`, `{message}`) |

**Key design decisions**:
- Hooks run `async: true` to avoid blocking Claude Code
- `CLAUDE_PLUGIN_ROOT` variable provides portable paths in `hooks.json`
- Windows has separate `ntfy-notify.ps1` and `ntfy-notify.cmd` fallback scripts
- JSON parsing uses Python (both `python3` and `python` are checked)
- curl mode sends notifications in background (`&`) to avoid blocking; ntfy CLI mode waits to ensure temp config cleanup

## Plugin Structure

- `.claude-plugin/plugin.json` — Plugin manifest (name, version, author)
- `hooks/hooks.json` — Declares `PermissionRequest` and `Stop` hook handlers
- `commands/` — Slash commands (`/notify:setup`, `/notify:config`, `/notify:toggle`)
- `skills/notify/SKILL.md` — Skill documentation loaded by Claude Code

## Configuration

Stored at `~/.claude/plugins/claude-notify-plugin/config` (sourced as shell variables):
- `NTFY_TOPIC` (required) — notification channel name (randomly generated during setup)
- `NTFY_HOST` (optional) — custom ntfy server URL (default: `https://ntfy.sh`)
- `NTFY_TOKEN` (optional) — auth token for self-hosted servers
- `NTFY_ENABLED` / `NTFY_TERMINAL_CHECK` — feature toggles
- `NTFY_PERMISSION_TITLE`, `NTFY_PERMISSION_BODY`, `NTFY_STOP_TITLE`, `NTFY_STOP_BODY` — custom templates

## Publishing Workflow

After pushing this plugin to its remote repository, you MUST also sync the marketplace registry at `/Users/eddie/github-projects/claude-plugins-marketplace`:

1. Push this repo: `git push origin main`
2. Get the latest commit SHA: `git rev-parse HEAD`
3. Update the plugin's `sha` field in `/Users/eddie/github-projects/claude-plugins-marketplace/.claude-plugin/marketplace.json` (under `plugins[].source.sha`)
4. Commit and push the marketplace repo:
   ```bash
   cd /Users/eddie/github-projects/claude-plugins-marketplace
   git add .claude-plugin/marketplace.json
   git commit -m "chore: Update claude-notify-plugin SHA to <short-sha>"
   git push origin main
   ```

The marketplace uses the SHA to pin which commit of this plugin users install.

## Development Notes

- There is no build step, test suite, or package manager — this is a pure shell plugin
- To test manually: `echo '{"hook_event_name":"Stop","last_assistant_message":"test"}' | bash hooks/ntfy-notify.sh`
- Debug logs are written to `/tmp/claude-notify-debug.log`
- The handoff document (`claude-notify-handoff.md`) contains historical design context in Chinese
- Notification priorities: PermissionRequest=4 (high), Stop=3 (default)
