import * as vscode from 'vscode';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

/**
 * Show a diff between the current file and new content.
 * Returns true if the user chooses to replace the file.
 */
export async function showDiffAndMaybeReplace(
  originalFilePath: string,
  newContent: string,
  title = 'Proposed Change'
): Promise<boolean> {
  const tmpPath = path.join(os.tmpdir(), `diff-${Date.now()}.swift`);
  fs.writeFileSync(tmpPath, newContent, 'utf-8');

  await vscode.commands.executeCommand(
    'vscode.diff',
    vscode.Uri.file(originalFilePath),
    vscode.Uri.file(tmpPath),
    title
  );

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
