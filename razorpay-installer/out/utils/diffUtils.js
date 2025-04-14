"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.showDiffAndMaybeReplace = showDiffAndMaybeReplace;
const vscode = require("vscode");
const fs = require("fs");
const os = require("os");
const path = require("path");
/**
 * Show a diff between the current file and new content.
 * Returns true if the user chooses to replace the file.
 */
async function showDiffAndMaybeReplace(originalFilePath, newContent, title = 'Proposed Change') {
    const tmpPath = path.join(os.tmpdir(), `diff-${Date.now()}.swift`);
    fs.writeFileSync(tmpPath, newContent, 'utf-8');
    await vscode.commands.executeCommand('vscode.diff', vscode.Uri.file(originalFilePath), vscode.Uri.file(tmpPath), title);
    const choice = await vscode.window.showQuickPick(['✅ Apply Changes', '❌ Discard'], {
        placeHolder: 'Do you want to apply this generated code to your file?'
    });
    if (choice === '✅ Apply Changes') {
        fs.writeFileSync(originalFilePath, newContent, 'utf-8');
        vscode.window.showInformationMessage('✅ File updated.');
        return true;
    }
    vscode.window.showInformationMessage('❌ Changes discarded.');
    return false;
}
