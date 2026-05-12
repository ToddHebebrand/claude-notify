# Claude Notify Focus

Tiny VS Code extension that focuses a terminal by name when a `vscode://` URL is opened. Pairs with [claude-notify](https://github.com/ToddHebebrand/claude-notify) so clicking a notification banner focuses the exact integrated terminal where the Claude Code session is running, even across multiple windows or editor-area tabs.

## Usage

```
vscode://claude-notify.claude-notify-focus/focus-terminal?name=<urlencoded-terminal-name>
```

Opening that URL (via `open` on macOS, the address bar, or any handler) activates the matching window and calls `terminal.show()` on the first terminal whose name matches. Exact match first, then substring fallback.

## Install

### Sideload (no marketplace)

```sh
cp -R extension ~/.vscode/extensions/claude-notify.claude-notify-focus-0.1.0
```

Then reload VS Code (Cmd+Shift+P → "Developer: Reload Window").

### Package

```sh
npx vsce package
code --install-extension claude-notify-focus-0.1.0.vsix
```

## License

MIT
