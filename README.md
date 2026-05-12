# claude-notify

A tiny macOS notification helper for [Claude Code](https://docs.claude.com/en/docs/claude-code) hooks. Sends a native banner when Claude finishes a turn or asks for input, with **click-to-focus your editor** built in.

## Why this exists

- `terminal-notifier` is broken on macOS Sequoia/Tahoe ([julienXX/terminal-notifier#312](https://github.com/julienXX/terminal-notifier/issues/312)) — it exits 0 but never delivers.
- `osascript display notification` works (after enabling Script Editor in notification settings) but has **no click action**.

This is a ~100-line Swift CLI built around the modern `UserNotifications` framework, packaged as an ad-hoc-signed `.app` so macOS will accept it. Notifications are clickable; the click runs any shell command you pass.

## What you get

- Clickable banners that fire arbitrary shell commands
- Custom icon (coral gradient + SF Symbol, easy to swap)
- Distinct sounds for different events
- No runtime dependencies beyond Apple SDKs

## Install

Requires macOS 13+ and Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/<you>/claude-notify ~/src/claude-notify
cd ~/src/claude-notify
./build.sh
./install.sh
```

`build.sh` compiles the helper, generates the icon, and assembles the `.app` bundle.
`install.sh` copies the bundle to `~/.claude/bin/`, re-registers it with LaunchServices, and fires a test notification.

The first time the helper fires, macOS will prompt **"Claude Code wants to send notifications"** — approve it.

## Wire it into Claude Code

Copy the snippet from [`examples/settings-hooks.json`](examples/settings-hooks.json) into your `~/.claude/settings.json` (merge into existing `hooks` block if present). The example wires two events:

- **`Stop`** — fires when Claude finishes a turn. Banner says "Finished in `<project>`". Glass sound.
- **`Notification`** — fires when Claude needs input (permission prompts, etc.). Banner shows the request message. Funk sound.

Both default to focusing **Visual Studio Code** on click. To use a different editor, change `open -a 'Visual Studio Code'` to e.g. `open -a 'Cursor'`, `open -a 'Sublime Text'`, etc.

> Settings reload note: Claude Code only watches `.claude/settings.json` for changes in sessions where it existed at startup. If hooks don't fire after editing, open `/hooks` once or restart.

## Customize

| Want to change | Edit | Then |
|----------------|------|------|
| Icon glyph | `MakeIcon.swift` — `systemSymbolName: "sparkles"` | `./build.sh && ./install.sh` |
| Icon color | `MakeIcon.swift` — gradient `CGColor` values | `./build.sh && ./install.sh` |
| Click action | Third arg in your hook command | reload hooks |
| Sound | Fifth arg in your hook command (any name from `/System/Library/Sounds`) | reload hooks |
| Bundle ID | `CLAUDE_NOTIFY_BUNDLE_ID=com.foo.bar ./build.sh` | re-install + re-approve notifications |

## CLI

```
ClaudeNotify <title> <body> [click-shell-cmd] [sound-name]
```

The helper stays alive for up to 5 minutes after posting so it can handle a click; if you don't click, it exits silently.

## Troubleshooting

### No banner appears, but exit code is 0
The notification permission prompt only shows once. If you missed it, open **System Settings → Notifications**, scroll for **Claude Code** (or whatever you set `CFBundleDisplayName` to), and enable Allow Notifications. Re-run `./install.sh`.

### Icon shows as a generic gray placeholder
macOS aggressively caches notification icons. Clear them:

```sh
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall iconservicesagent iconservicesd Dock usernoted NotificationCenter
```

Then fire a new notification.

### "ClaudeNotify.app is not open anymore" dialog
You launched a build that exited via `exit(0)` while AppKit was loaded — old artifact. Re-run `./build.sh && ./install.sh`.

### Click opens Cursor instead of VS Code (or vice versa)
VS Code's `code` CLI script delegates to whatever `code` is on `PATH` when `VSCODE_IPC_HOOK_CLI` is set, and Cursor hijacks that name. The example hooks use `open -a 'Visual Studio Code'` to bypass `PATH` and route through LaunchServices. If you switched editors, update the click command.

## License

MIT — see [LICENSE](LICENSE).
