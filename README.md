# claude-notify

A tiny macOS notification helper for [Claude Code](https://docs.claude.com/en/docs/claude-code) hooks. Native banners when Claude finishes a turn or asks for input, **click-to-focus the exact VS Code terminal** where the session lives — via a small companion VS Code extension.

## Why this exists

- `terminal-notifier` is broken on macOS Sequoia/Tahoe ([julienXX/terminal-notifier#312](https://github.com/julienXX/terminal-notifier/issues/312)) — it exits 0 but never delivers.
- `osascript display notification` works (after enabling Script Editor in notification settings) but has no click action.
- VS Code 1.119+ stopped exporting `VSCODE_IPC_HOOK_CLI` in local integrated terminals, so the obvious "send focus to this window" CLI route doesn't work either.

The fix is a 100-line Swift CLI using `UserNotifications`, plus a 20-line VS Code extension that handles a `vscode://` URL and calls `terminal.show()`.

## What you get

- Clickable banners that focus the exact terminal where Claude is running, even across multiple VS Code windows or editor-area tabs
- Custom icon (coral gradient + SF Symbol, easy to swap)
- Distinct sounds for "finished" vs "needs input"
- Tab auto-naming: `claude · <project> · <session-id>` so you can also visually identify the session
- No runtime dependencies beyond Apple SDKs

## Install

Requires macOS 13+ and Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/ToddHebebrand/claude-notify ~/src/claude-notify
cd ~/src/claude-notify
./build.sh && ./install.sh
```

This compiles `ClaudeNotify.app` and installs:

- `~/.claude/bin/ClaudeNotify.app` — notification helper
- `~/.claude/bin/notify-hook.sh` — hook glue
- `~/.vscode/extensions/claude-notify.claude-notify-focus-0.1.0/` — the focus extension

After install:

1. **Reload VS Code** (Cmd+Shift+P → "Developer: Reload Window") so the extension activates.
2. **Merge `examples/settings-hooks.json` into `~/.claude/settings.json`** (or copy if you have no existing hooks).
3. **Restart Claude Code** (or open `/hooks` once) so the new hooks load.

First time the helper fires, macOS asks **"Claude Code wants to send notifications"** — approve it. After that you're done.

## How click-to-focus works

The Stop and Notification hooks compute a deterministic terminal name for your session: `claude · <project> · <first-8-chars-of-session-id>`. The `SessionStart` hook writes that name to the controlling terminal via OSC 2, so VS Code displays it as the tab title.

The notification's click action opens `vscode://claude-notify.claude-notify-focus/focus-terminal?name=<encoded>`. The extension finds the terminal by that exact name and calls `terminal.show()`, which switches the window and the terminal tab.

Multi-window safe (any window can own the terminal). If the extension isn't installed, opening the URL still brings VS Code to the front — you just lose the precise tab focus.

## Customize

| Want to change | Where | Then |
|----------------|------|------|
| Icon glyph | `MakeIcon.swift` — `systemSymbolName: "sparkles"` | `./build.sh && ./install.sh` |
| Icon color | `MakeIcon.swift` — gradient `CGColor` values | `./build.sh && ./install.sh` |
| Editor for fallback focus | `CLAUDE_NOTIFY_EDITOR_APP` env (default `Visual Studio Code`) | edit `notify-hook.sh` invocation |
| Sound | Second arg to `notify-hook.sh` (any name from `/System/Library/Sounds`) | edit `~/.claude/settings.json` |
| Tab name format | `notify-hook.sh` — `tab_name=...` line | reinstall hook script |
| Bundle ID | `CLAUDE_NOTIFY_BUNDLE_ID=com.foo.bar ./build.sh` | reinstall + re-approve notifications |

## Files

```
.
├── ClaudeNotify.swift          # the notification helper
├── MakeIcon.swift              # icon generator
├── Info.plist.in               # bundle metadata template
├── notify-hook.sh              # hook glue (called from settings.json)
├── build.sh                    # compile + iconset + sign
├── install.sh                  # copy everything to ~/.claude/bin and ~/.vscode/extensions
├── examples/
│   └── settings-hooks.json     # SessionStart + Stop + Notification hooks
└── extension/
    ├── package.json            # VS Code extension manifest
    ├── extension.js            # vscode://...focus-terminal handler
    └── README.md
```

## Troubleshooting

### Click brings VS Code forward but doesn't focus the right terminal
Extension didn't load. Reload VS Code (Cmd+Shift+P → "Developer: Reload Window"). To verify it's registered, run `code --list-extensions | grep claude-notify`.

### Tab isn't renamed
The OSC sequence requires `/dev/tty` to be writable from the hook subprocess. If you launched Claude Code via something that detaches from the terminal (e.g., a wrapper script with `&`), the rename will silently no-op. Launch Claude Code directly from the integrated terminal.

### Notifications exit silently with no banner
The permission prompt only shows once. If you missed it: System Settings → Notifications → scroll to **Claude Code** → enable Allow Notifications.

### Icon shows as a generic gray placeholder
macOS aggressively caches notification icons. Clear them:

```sh
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall iconservicesagent iconservicesd Dock usernoted NotificationCenter
```

Then trigger a fresh notification.

### "ClaudeNotify.app is not open anymore" dialog
You launched an older build. Re-run `./build.sh && ./install.sh`.

### Click opens Cursor instead of VS Code (or vice versa)
The example uses `open -a 'Visual Studio Code'` as the LaunchServices target — bypasses `PATH` (which Cursor often hijacks). Set `CLAUDE_NOTIFY_EDITOR_APP=Cursor` in the hook env if you want Cursor instead.

## License

MIT — see [LICENSE](LICENSE).
