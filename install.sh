#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

[[ -d ClaudeNotify.app ]] || { echo "Run ./build.sh first" >&2; exit 1; }

DEST="$HOME/.claude/bin"
mkdir -p "$DEST"

echo "→ Stopping any running instances..."
pkill -f ClaudeNotify || true
sleep 1

echo "→ Copying to $DEST/ClaudeNotify.app..."
rm -rf "$DEST/ClaudeNotify.app"
cp -R ClaudeNotify.app "$DEST/"

echo "→ Registering with LaunchServices..."
LSREG=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
"$LSREG" -u "$DEST/ClaudeNotify.app" 2>/dev/null || true
"$LSREG" -f "$DEST/ClaudeNotify.app"

echo "→ Restarting notification daemon..."
killall usernoted NotificationCenter 2>/dev/null || true
sleep 1

echo "✓ Installed."
echo ""
echo "Firing a test notification — first run will prompt for permission."
"$DEST/ClaudeNotify.app/Contents/MacOS/ClaudeNotify" \
    "Claude Notify" \
    "Installation test — click to open this folder" \
    "open '$PWD'" \
    "Glass" >/dev/null 2>&1 &
echo ""
echo "Next: see examples/settings-hooks.json to wire into ~/.claude/settings.json."
