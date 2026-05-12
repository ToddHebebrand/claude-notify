#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

BUNDLE_ID=${CLAUDE_NOTIFY_BUNDLE_ID:-com.local.claudenotify}
APP=ClaudeNotify.app

rm -rf "$APP" AppIcon.iconset MakeIcon
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "→ Compiling ClaudeNotify..."
xcrun swiftc -O ClaudeNotify.swift -o "$APP/Contents/MacOS/ClaudeNotify"

echo "→ Generating icon..."
xcrun swiftc -O MakeIcon.swift -o MakeIcon
./MakeIcon AppIcon.iconset >/dev/null
iconutil -c icns AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf AppIcon.iconset MakeIcon

echo "→ Writing Info.plist (bundle id: $BUNDLE_ID)..."
sed "s|__BUNDLE_ID__|$BUNDLE_ID|g" Info.plist.in > "$APP/Contents/Info.plist"

echo "→ Ad-hoc signing..."
codesign --force --deep --sign - "$APP" 2>&1 | grep -v 'replacing existing signature' || true

echo "✓ Built $APP"
