"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runRAG = runRAG;
const vscode = require("vscode");
const fs = require("fs");
const path = require("path");
const child_process_1 = require("child_process");
const util = require("util");
const execFilePromise = util.promisify(child_process_1.execFile);
/**
 * Pure function: runs RAG on file and returns generated code as string.
 * Does not apply or show changes — that's the caller's responsibility.
 */
async function runRAG(originalFilePath) {
    var _a, _b;
    const ragScriptPath = path.join(__dirname, '..', 'rag', 'run_with_setup.py');
    const workspaceDir = (_b = (_a = vscode.workspace.workspaceFolders) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.uri.fsPath;
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
    }
    catch (err) {
        console.error("❌ [RAG] Failed:", err);
        vscode.window.showErrorMessage(`❌ RAG failed: ${err.message}`);
        return null;
    }
}
