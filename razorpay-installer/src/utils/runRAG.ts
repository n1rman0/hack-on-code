import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { execFile } from 'child_process';
import * as util from 'util';

const execFilePromise = util.promisify(execFile);

/**
 * Pure function: runs RAG on file and returns generated code as string.
 * Does not apply or show changes — that's the caller's responsibility.
 */
export async function runRAG(originalFilePath: string): Promise<string | null> {
  const ragScriptPath = path.join(__dirname, '..', 'rag', 'run_with_setup.py');
  const workspaceDir = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;

  if (!fs.existsSync(originalFilePath)) {
    vscode.window.showErrorMessage(`❌ File not found: ${originalFilePath}`);
    return null;
  }

  try {
    console.log(`🚀 [RAG] Running on: ${originalFilePath}`);

    const { stdout, stderr } = await execFilePromise('python3', [ragScriptPath, '--file', originalFilePath], {
      cwd: workspaceDir,
      env: {
        ...process.env,
        LANG: 'en_US.UTF-8',
        LC_ALL: 'en_US.UTF-8'
      },
      maxBuffer: 1024 * 1024
    });

    if (stderr) {
      console.warn("⚠️ [RAG] STDERR:\n", stderr);
    }

    const match = stdout.match(/✅ Generated Swift Code:\n([\s\S]*)$/);
    if (!match || !match[1]) {
      vscode.window.showErrorMessage('⚠️ RAG ran but did not return valid code.');
      return null;
    }

    return match[1].trim();

  } catch (err: any) {
    console.error("❌ [RAG] Failed:", err);
    vscode.window.showErrorMessage(`❌ RAG failed: ${err.message}`);
    return null;
  }
}
