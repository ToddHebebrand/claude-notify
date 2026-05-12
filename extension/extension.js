const vscode = require('vscode');

function activate(context) {
    context.subscriptions.push(
        vscode.window.registerUriHandler({
            handleUri(uri) {
                const params = new URLSearchParams(uri.query);
                const name = params.get('name');
                if (!name) {
                    vscode.window.showWarningMessage('claude-notify-focus: missing ?name= param');
                    return;
                }
                if (uri.path === '/focus-terminal') {
                    const terminals = vscode.window.terminals;
                    const exact = terminals.find(t => t.name === name);
                    const partial = exact || terminals.find(t => t.name.includes(name));
                    if (partial) {
                        partial.show(false);
                    } else {
                        vscode.window.showInformationMessage(
                            `claude-notify-focus: no terminal named "${name}" in this window`
                        );
                    }
                }
            }
        })
    );
}

function deactivate() {}

module.exports = { activate, deactivate };
