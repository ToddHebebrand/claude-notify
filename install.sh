#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

[[ -d ClaudeNotify.app ]] || { echo "Run ./build.sh first" >&2; exit 1; }

DEST="$HOME/.claude/bin"
mkdir -p "$DEST"

echo "→ Stopping any running instances..."
pkill -f ClaudeNotify || true
sleep 1

echo "→ Installing ClaudeNotify.app to $DEST..."
rm -rf "$DEST/ClaudeNotify.app"
cp -R ClaudeNotify.app "$DEST/"

echo "→ Installing notify-hook.sh..."
cp notify-hook.sh "$DEST/notify-hook.sh"
chmod +x "$DEST/notify-hook.sh"

LSREG=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
echo "→ Registering with LaunchServices..."
"$LSREG" -u "$DEST/ClaudeNotify.app" 2>/dev/null || true
"$LSREG" -f "$DEST/ClaudeNotify.app"

echo "→ Installing VS Code extension..."
EXT_DEST="$HOME/.vscode/extensions/claude-notify.claude-notify-focus-0.1.0"
if [[ -d "$HOME/.vscode/extensions" ]]; then
    rm -rf "$EXT_DEST"
    cp -R extension "$EXT_DEST"
    echo "  installed to $EXT_DEST"
    echo "  reload VS Code (Cmd+Shift+P → Developer: Reload Window) to activate"
else
    echo "  ~/.vscode/extensions not found — skipping (VS Code not installed?)"
fi

echo "→ Restarting notification daemon..."
killall usernoted NotificationCenter 2>/dev/null || true
sleep 1

echo ""
echo "✓ Installed."
echo ""
echo "Next steps:"
echo "  1. Reload your VS Code window so the extension activates."
echo "  2. Merge examples/settings-hooks.json into ~/.claude/settings.json."
echo "  3. Restart Claude Code (or open /hooks once) so settings.json hooks reload."
echo ""
echo "Firing a test notification..."
"$DEST/ClaudeNotify.app/Contents/MacOS/ClaudeNotify" \
    "Claude Notify" \
    "Click me — should open VS Code" \
    "open -a 'Visual Studio Code' '$PWD'" \
    "Glass" >/dev/null 2>&1 &
