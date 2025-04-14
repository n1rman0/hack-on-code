"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.promptForTargetSwiftFile = promptForTargetSwiftFile;
const vscode = require("vscode");
const fs = require("fs");
const path = require("path");
const child_process_1 = require("child_process");
var mainContext;
function activate(context) {
    mainContext = context;
    const disposable = vscode.commands.registerCommand('extension.installRazorpay', async (uri) => {
        var _a, _b;
        const flavor = await vscode.window.showQuickPick(['Standard', 'Standard + TurboUI'], { placeHolder: 'Select Razorpay SDK flavor' });
        if (!flavor)
            return;
        const searchRoot = (uri === null || uri === void 0 ? void 0 : uri.fsPath) || ((_b = (_a = vscode.workspace.workspaceFolders) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.uri.fsPath);
        if (!searchRoot) {
            vscode.window.showErrorMessage('No valid folder selected or open in workspace.');
            return;
        }
        const podfilePath = findFileByName(searchRoot, 'Podfile', 2);
        const pods = getPodsForFlavor(flavor);
        if (podfilePath) {
            const projectDir = path.dirname(podfilePath);
            injectPodsAndInstall(projectDir, podfilePath, pods);
            if (flavor === 'Standard + TurboUI') {
                addLocationPermissionIfNeeded(projectDir);
            }
        }
        else {
            const xcodeprojPath = findFileByExtension(searchRoot, '.xcodeproj', 2);
            if (xcodeprojPath) {
                const xcodeDir = path.dirname(xcodeprojPath);
                const podfilePath = path.join(xcodeDir, 'Podfile');
                createPodfile(xcodeDir, () => {
                    injectPodsAndInstall(xcodeDir, podfilePath, pods);
                    if (flavor === 'Standard + TurboUI') {
                        addLocationPermissionIfNeeded(xcodeDir);
                    }
                });
            }
            else {
                vscode.window.showErrorMessage('Could not find Podfile or .xcodeproj in selected folder.');
            }
        }
    });
    context.subscriptions.push(disposable);
}
// ----------------- Helpers ------------------
function getPodsForFlavor(flavor) {
    const pods = ['pod \'razorpay-pod\''];
    if (flavor === 'Standard + TurboUI') {
        pods.push('pod \'razorpay-turbo\'');
    }
    return pods;
}
function findFileByName(startDir, filename, maxDepth = 2) {
    const queue = [{ dir: startDir, depth: 0 }];
    while (queue.length > 0) {
        const { dir, depth } = queue.shift();
        if (depth > maxDepth)
            continue;
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            if (entry.isFile() && entry.name === filename) {
                return fullPath;
            }
            if (entry.isDirectory()) {
                queue.push({ dir: fullPath, depth: depth + 1 });
            }
        }
    }
    return null;
}
function findFileByExtension(startDir, ext, maxDepth = 2) {
    const queue = [{ dir: startDir, depth: 0 }];
    while (queue.length > 0) {
        const { dir, depth } = queue.shift();
        if (depth > maxDepth)
            continue;
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            if (entry.isDirectory() && entry.name.endsWith(ext)) {
                return fullPath;
            }
            if (entry.isDirectory()) {
                queue.push({ dir: fullPath, depth: depth + 1 });
            }
        }
    }
    return null;
}
function createPodfile(projectDir, callback) {
    (0, child_process_1.execFile)('pod', ['init'], {
        cwd: projectDir,
        env: {
            ...process.env,
            LANG: 'en_US.UTF-8',
            LC_ALL: 'en_US.UTF-8'
        }
    }, (err) => {
        if (err) {
            vscode.window.showErrorMessage('Failed to initialize Podfile.');
        }
        else {
            callback();
        }
    });
}
function injectPodsAndInstall(projectDir, podfilePath, pods) {
    var _a, _b;
    const content = fs.readFileSync(podfilePath, 'utf-8');
    const lines = content.split('\n');
    const newPods = pods.filter(p => !content.includes(p));
    if (newPods.length === 0) {
        vscode.window.showInformationMessage('Pods already present.');
        return runPodInstall(projectDir);
    }
    let insideTarget = false;
    let insertIndex = -1;
    let indent = '';
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (/^\s*target\s+['"][^'"]+['"]\s+do\s*$/.test(line)) {
            insideTarget = true;
            indent = (_b = (_a = line.match(/^(\s*)/)) === null || _a === void 0 ? void 0 : _a[1]) !== null && _b !== void 0 ? _b : '';
        }
        else if (insideTarget && /^\s*end\s*$/.test(line)) {
            insertIndex = i;
            break;
        }
    }
    if (insertIndex !== -1) {
        const toInsert = newPods.map(p => indent + '  ' + p);
        lines.splice(insertIndex, 0, ...toInsert);
        fs.writeFileSync(podfilePath, lines.join('\n'), 'utf-8');
        vscode.window.showInformationMessage('Pods added inside target block.');
        runPodInstall(projectDir);
    }
    else {
        vscode.window.showErrorMessage('Could not find target block in Podfile.');
    }
}
function runPodInstall(projectDir) {
    (0, child_process_1.execFile)('pod', ['install'], {
        cwd: projectDir,
        env: {
            ...process.env,
            LANG: 'en_US.UTF-8',
            LC_ALL: 'en_US.UTF-8'
        }
    }, async (err, stdout, stderr) => {
        var _a;
        if (err) {
            vscode.window.showErrorMessage(`❌ Pod install failed: ${stderr}`);
            console.error(stderr);
        }
        else {
            vscode.window.showInformationMessage(`✅ pod install completed.`);
            // 🌱 Collect RAG config from user
            const merchantKey = await vscode.window.showInputBox({
                prompt: 'Enter your Razorpay Merchant Key',
                placeHolder: 'rzp_test_...',
                ignoreFocusOut: true
            });
            const apiSecret = await vscode.window.showInputBox({
                prompt: 'Enter your Razorpay API Secret',
                placeHolder: 'shh_this_is_secret',
                password: true,
                ignoreFocusOut: true
            });
            const orderId = await vscode.window.showInputBox({
                prompt: 'Enter a sample Order ID',
                placeHolder: 'order_ABC123XYZ',
                ignoreFocusOut: true
            });
            const envContent = [
                `RAZORPAY_MERCHANT_KEY=${merchantKey !== null && merchantKey !== void 0 ? merchantKey : ''}`,
                `RAZORPAY_API_SECRET=${apiSecret !== null && apiSecret !== void 0 ? apiSecret : ''}`,
                `RAZORPAY_SAMPLE_ORDER_ID=${orderId !== null && orderId !== void 0 ? orderId : ''}`
            ].join('\n');
            const storagePath = ((_a = vscode.extensions.getExtension('nirman.razorpay-installer')) === null || _a === void 0 ? void 0 : _a.extensionPath) || mainContext.globalStorageUri.fsPath;
            const envPath = path.join(storagePath, '.razorpay.env');
            fs.writeFileSync(envPath, envContent, 'utf-8');
            vscode.window.showInformationMessage(`✅ Credentials saved to .razorpay.env`);
            const selectedFile = await promptForTargetSwiftFile(envPath);
        }
    });
}
function addLocationPermissionIfNeeded(projectDir) {
    const infoPlistPath = findFileByName(projectDir, 'Info.plist', 2);
    if (!infoPlistPath) {
        vscode.window.showWarningMessage('Info.plist not found to add location permission.');
        return;
    }
    let content = fs.readFileSync(infoPlistPath, 'utf-8');
    if (content.includes('NSLocationWhenInUseUsageDescription')) {
        vscode.window.showInformationMessage('Location permission already present in Info.plist.');
        return;
    }
    const insertion = `  <key>NSLocationWhenInUseUsageDescription</key>\n  <string>because I said so</string>\n`;
    // Insert just before the last </dict>
    const updated = content.replace(/<\/dict>/, insertion + '</dict>');
    fs.writeFileSync(infoPlistPath, updated, 'utf-8');
    vscode.window.showInformationMessage('✅ Location permission added to Info.plist.');
}
async function promptForTargetSwiftFile(envPath) {
    vscode.window.showInformationMessage('📄 Please select the Swift file where Razorpay SDK integration code should be inserted.');
    const selectedFileUri = await vscode.window.showOpenDialog({
        title: 'Select a Swift file for Razorpay integration',
        canSelectFiles: true,
        canSelectFolders: false,
        canSelectMany: false,
        openLabel: 'Use this file',
        filters: {
            'Swift Files': ['swift']
        }
    });
    if (selectedFileUri && selectedFileUri[0]) {
        const targetFilePath = selectedFileUri[0].fsPath;
        if (!targetFilePath.endsWith('.swift')) {
            vscode.window.showErrorMessage('❌ Please select a valid .swift file.');
            return undefined;
        }
        const filename = path.basename(targetFilePath);
        vscode.window.showInformationMessage(`📝 Selected file for integration: ${filename}`);
        // Save to .env
        fs.appendFileSync(envPath, `\nRAZORPAY_TARGET_FILE=${targetFilePath}`);
        return targetFilePath;
    }
    else {
        vscode.window.showWarningMessage('⚠️ No Swift file selected.');
        return undefined;
    }
}
