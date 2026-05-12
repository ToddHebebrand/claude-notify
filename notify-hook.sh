#!/usr/bin/env bash
# Shared helper for Claude Code Stop / Notification / SessionStart hooks.
# Reads the hook's stdin JSON, computes a deterministic terminal-tab name,
# and either renames the tab (start) or fires a banner (stop/notify).
#
# Usage from settings.json:
#   "command": "$HOME/.claude/bin/notify-hook.sh start"
#   "command": "$HOME/.claude/bin/notify-hook.sh stop Glass"
#   "command": "$HOME/.claude/bin/notify-hook.sh notify Funk"

set -e

event="${1:-stop}"
sound="${2:-Glass}"
editor="${CLAUDE_NOTIFY_EDITOR_APP:-Visual Studio Code}"
ext_id="${CLAUDE_NOTIFY_EXT_ID:-claude-notify.claude-notify-focus}"
notifier="$HOME/.claude/bin/ClaudeNotify.app/Contents/MacOS/ClaudeNotify"

input=$(cat)
d=$(echo "$input" | jq -r '.cwd // "."')
sid=$(echo "$input" | jq -r '.session_id // ""')
msg=$(echo "$input" | jq -r '.message // ""')
proj=$(basename "$d")
short="${sid:0:8}"
tab_name="claude · $proj · $short"

case "$event" in
  start)
    # Rename the VS Code terminal tab via OSC 2 (write to the controlling tty)
    printf '\033]2;%s\007' "$tab_name" > /dev/tty 2>/dev/null || true
    ;;
  stop|notify)
    [[ -x "$notifier" ]] || { exit 0; }
    encoded=$(jq -rn --arg x "$tab_name" '$x|@uri')
    url="vscode://${ext_id}/focus-terminal?name=${encoded}"
    # `open <vscode://...>` activates VS Code via the URL handler. If the
    # extension is installed it focuses the right terminal; if not, you still
    # get VS Code to the front.
    click="open '$url'"

    if [[ "$event" == "stop" ]]; then
      title="Claude Code"
      body="Finished in $proj"
    else
      title="Claude Code — $proj"
      body="${msg:-Needs your attention}"
    fi

    nohup "$notifier" "$title" "$body" "$click" "$sound" >/dev/null 2>&1 &
    ;;
esac
