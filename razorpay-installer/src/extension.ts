import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { execFile } from 'child_process';
import axios from 'axios';
import { runRAG } from './utils/runRAG';
import { showDiffAndMaybeReplace } from './utils/diffUtils';


var mainContext: vscode.ExtensionContext;
const RAZORPAY_API_BASE = 'http://127.0.0.1:5000';

export function activate(context: vscode.ExtensionContext) {
  mainContext = context;

  const disposable = vscode.commands.registerCommand('extension.installRazorpay', async () => {
    await loginAndConfigureAndContinue();
  });

  context.subscriptions.push(disposable);
}

// ----------------- Main Flow ------------------

async function loginAndConfigureAndContinue() {
  const email = await vscode.window.showInputBox({
    prompt: 'Enter your Razorpay login email',
    ignoreFocusOut: true
  });

  const password = await vscode.window.showInputBox({
    prompt: 'Enter your Razorpay password',
    password: true,
    ignoreFocusOut: true
  });

  if (!email || !password) {
    vscode.window.showErrorMessage('❌ Login cancelled.');
    return;
  }

  const progress = await vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification,
    title: "Logging into Razorpay...",
    cancellable: false
  }, async (progress) => {
    progress.report({ increment: 30, message: "Authenticating..." });
    await new Promise(resolve => setTimeout(resolve, 800));
    
    progress.report({ increment: 40, message: "Validating credentials..." });
    await new Promise(resolve => setTimeout(resolve, 700));
    
    progress.report({ increment: 30, message: "Completing login..." });
    await new Promise(resolve => setTimeout(resolve, 500));
  });

  vscode.window.showInformationMessage(`🔐 Logged in as ${email} (mock)`);

  try {
    const response = await axios.get(`${RAZORPAY_API_BASE}/data`);
    const data = response.data;

    const selectedFlavor = await vscode.window.showQuickPick(
      data.merchant_flavours,
      { placeHolder: 'Select Razorpay SDK flavor for integration' }
    );
    if (!selectedFlavor) {
      vscode.window.showWarningMessage('⚠️ SDK flavor not selected.');
      return;
    }

    const envContent = [
      `RAZORPAY_MERCHANT_KEY=${data.merchant_public_key}`,
      `RAZORPAY_API_SECRET=${data.merchant_secret}`,
      `RAZORPAY_SAMPLE_ORDER_ID=${data.merchant_sample_order_id}`,
      `RAZORPAY_SELECTED_FLAVOR=${selectedFlavor}`
    ].join('\n');

    const storagePath = vscode.extensions.getExtension('nirman.razorpay-installer')?.extensionPath || mainContext.globalStorageUri.fsPath;
    const ragPath = path.join(storagePath, 'out', 'rag');
    if (!fs.existsSync(ragPath)) {
      fs.mkdirSync(ragPath, { recursive: true });
    }
    const envPath = path.join(ragPath, '.razorpay.env');
    fs.writeFileSync(envPath, envContent, 'utf-8');
    vscode.window.showInformationMessage('✅ Credentials saved to .razorpay.env');

    await handlePodfileSetupAndInstall(selectedFlavor, envPath);

  } catch (err: any) {
    vscode.window.showErrorMessage(`❌ Failed to fetch Razorpay config: ${err.message}`);
  }
}

async function handlePodfileSetupAndInstall(flavor: string, envPath: string) {
  const searchRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!searchRoot) {
    vscode.window.showErrorMessage('No valid folder open in workspace.');
    return;
  }

  const podfilePath = findFileByName(searchRoot, 'Podfile', 2);
  let projectDir: string | undefined;
  let podfileTargetPath: string | undefined;

  if (podfilePath) {
    projectDir = path.dirname(podfilePath);
    podfileTargetPath = podfilePath;
  } else {
    const xcodeprojPath = findFileByExtension(searchRoot, '.xcodeproj', 2);
    if (xcodeprojPath) {
      const xcodeDir = path.dirname(xcodeprojPath);
      const podfilePath = path.join(xcodeDir, 'Podfile');
      await new Promise<void>((resolve) => createPodfile(xcodeDir, resolve));
      projectDir = xcodeDir;
      podfileTargetPath = podfilePath;
    } else {
      vscode.window.showErrorMessage('❌ Could not find Podfile or .xcodeproj.');
      return;
    }
  }

  const pods = getPodsForFlavor(flavor);
  injectPodsAndInstall(projectDir!, podfileTargetPath!, pods);

  if (flavor.includes('TurboUI')) {
    addLocationPermissionIfNeeded(projectDir!);
  }

  const selectedFile = await promptForTargetSwiftFile(envPath);

  if (selectedFile) {
    const generatedCode = await vscode.window.withProgress({
      location: vscode.ProgressLocation.Notification,
      title: "🤖 Generating Razorpay Integration Code",
      cancellable: false
    }, async (progress) => {
      progress.report({ message: "Analyzing project context..." });
      await new Promise(resolve => setTimeout(resolve, 500));
      
      progress.report({ message: "Running RAG model..." });
      console.log('✅ Sending to RAG.');
      const code = await runRAG(selectedFile);
      
      progress.report({ message: "Generated Swift code" });
      return code;
    });
    const swiftCodeMatch = generatedCode ? generatedCode.match(/```swift\n([\s\S]*?)\n```/) : null;
    const swiftCode = swiftCodeMatch ? swiftCodeMatch[1] : '';
    await vscode.env.clipboard.writeText(swiftCode);
    vscode.window.showInformationMessage('✅ Generated code copied to clipboard');
    if (swiftCode) {
      const replaced = await showDiffAndMaybeReplace(selectedFile, swiftCode, 'Razorpay Integration Suggestion');
      if (replaced) {
        console.log('✅ Final Swift file updated.');
      }
    }
  }
}

// ----------------- Helpers ------------------

function getPodsForFlavor(flavor: string): string[] {
  const pods = ['pod \'razorpay-pod\''];
  if (flavor.includes('TurboUI')) {
    pods.push('pod \'razorpay-turbo\'');
  }
  return pods;
}

function findFileByName(startDir: string, filename: string, maxDepth = 2): string | null {
  const queue = [{ dir: startDir, depth: 0 }];
  while (queue.length > 0) {
    const { dir, depth } = queue.shift()!;
    if (depth > maxDepth) continue;

    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isFile() && entry.name === filename) return fullPath;
      if (entry.isDirectory()) queue.push({ dir: fullPath, depth: depth + 1 });
    }
  }
  return null;
}

function findFileByExtension(startDir: string, ext: string, maxDepth = 2): string | null {
  const queue = [{ dir: startDir, depth: 0 }];
  while (queue.length > 0) {
    const { dir, depth } = queue.shift()!;
    if (depth > maxDepth) continue;

    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory() && entry.name.endsWith(ext)) return fullPath;
      if (entry.isDirectory()) queue.push({ dir: fullPath, depth: depth + 1 });
    }
  }
  return null;
}

function createPodfile(projectDir: string, callback: () => void) {
  execFile('pod', ['init'], {
    cwd: projectDir,
    env: {
      ...process.env,
      LANG: 'en_US.UTF-8',
      LC_ALL: 'en_US.UTF-8'
    }
  }, (err) => {
    if (err) {
      vscode.window.showErrorMessage('Failed to initialize Podfile.');
    } else {
      callback();
    }
  });
}

function injectPodsAndInstall(projectDir: string, podfilePath: string, pods: string[]) {
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
      indent = line.match(/^(\s*)/)?.[1] ?? '';
    } else if (insideTarget && /^\s*end\s*$/.test(line)) {
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
  } else {
    vscode.window.showErrorMessage('Could not find target block in Podfile.');
  }
}

function runPodInstall(projectDir: string) {
  execFile('pod', ['install'], {
    cwd: projectDir,
    env: {
      ...process.env,
      LANG: 'en_US.UTF-8',
      LC_ALL: 'en_US.UTF-8'
    }
  }, (err, stdout, stderr) => {
    if (err) {
      vscode.window.showErrorMessage(`❌ Pod install failed: ${stderr}`);
      console.error(stderr);
    } else {
      vscode.window.showInformationMessage(`✅ pod install completed.`);
    }
  });
}

function addLocationPermissionIfNeeded(projectDir: string) {
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
  const updated = content.replace(/<\/dict>/, insertion + '</dict>');

  fs.writeFileSync(infoPlistPath, updated, 'utf-8');
  vscode.window.showInformationMessage('✅ Location permission added to Info.plist.');
}

export async function promptForTargetSwiftFile(envPath: string): Promise<string | undefined> {
  vscode.window.showInformationMessage('📄 Please select the Swift file for Razorpay integration.');

  const selectedFileUri = await vscode.window.showOpenDialog({
    title: 'Select a Swift file',
    canSelectFiles: true,
    canSelectFolders: false,
    canSelectMany: false,
    openLabel: 'Use this file',
    filters: { 'Swift Files': ['swift'] }
  });

  if (selectedFileUri && selectedFileUri[0]) {
    const targetFilePath = selectedFileUri[0].fsPath;
    if (!targetFilePath.endsWith('.swift')) {
      vscode.window.showErrorMessage('❌ Please select a valid .swift file.');
      return;
    }

    const filename = path.basename(targetFilePath);
    vscode.window.showInformationMessage(`📝 Selected file: ${filename}`);
    fs.appendFileSync(envPath, `\nRAZORPAY_TARGET_FILE=${targetFilePath}`);
    return targetFilePath;
  } else {
    vscode.window.showWarningMessage('⚠️ No Swift file selected.');
    return undefined;
  }
}
