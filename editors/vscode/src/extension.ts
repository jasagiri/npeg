import * as path from 'path';
import * as fs from 'fs';
import * as vscode from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext) {
  console.log('NPeg Language Support is now active');

  // Register commands
  context.subscriptions.push(
    vscode.commands.registerCommand('npeg.visualizeGrammar', visualizeGrammar),
    vscode.commands.registerCommand('npeg.validateGrammar', validateGrammar),
    vscode.commands.registerCommand('npeg.generateParser', generateParser)
  );

  // Start the language server if enabled
  const config = vscode.workspace.getConfiguration('npeg');
  if (config.get<boolean>('languageServer.enable')) {
    startLanguageServer(context);
  }
}

function startLanguageServer(context: vscode.ExtensionContext) {
  // Get the server path from settings or use default
  const config = vscode.workspace.getConfiguration('npeg');
  let serverPath = config.get<string>('languageServer.path');

  if (!serverPath) {
    // Try to find server in common locations
    const possiblePaths = [
      '/usr/local/bin/npeg-lsp',
      '/usr/bin/npeg-lsp',
      path.join(process.env.HOME || '', '.local', 'bin', 'npeg-lsp'),
      // Add Windows paths if needed
    ];

    for (const path of possiblePaths) {
      if (fs.existsSync(path)) {
        serverPath = path;
        break;
      }
    }
  }

  if (!serverPath) {
    vscode.window.showWarningMessage(
      'NPeg language server not found. Some features may not work. Install with `nim c -r src/npeg/lsp/install.nim`'
    );
    return;
  }

  // Configure the server
  const serverOptions: ServerOptions = {
    run: { command: serverPath, transport: TransportKind.stdio },
    debug: { command: serverPath, transport: TransportKind.stdio }
  };

  // Options to control the language client
  const clientOptions: LanguageClientOptions = {
    // Register the server for npeg files
    documentSelector: [{ scheme: 'file', language: 'npeg' }],
    synchronize: {
      // Notify the server about file changes
      fileEvents: vscode.workspace.createFileSystemWatcher('**/*.npeg')
    }
  };

  // Create and start the client
  client = new LanguageClient(
    'npegLanguageServer',
    'NPeg Language Server',
    serverOptions,
    clientOptions
  );

  // Start the client and add to subscriptions
  context.subscriptions.push(client.start());
}

// Command to visualize the grammar as a railroad diagram
async function visualizeGrammar() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showErrorMessage('No active editor!');
    return;
  }

  const document = editor.document;
  if (document.languageId !== 'npeg') {
    vscode.window.showErrorMessage('Not a NPeg grammar file!');
    return;
  }

  // This is a placeholder. In a real extension, this would:
  // 1. Parse the grammar
  // 2. Generate a railroad diagram using a library
  // 3. Display it in a webview

  // For now, just show a message
  vscode.window.showInformationMessage(
    'Railroad diagram visualization is not implemented yet.'
  );
}

// Command to validate the grammar
async function validateGrammar() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showErrorMessage('No active editor!');
    return;
  }

  const document = editor.document;
  if (document.languageId !== 'npeg') {
    vscode.window.showErrorMessage('Not a NPeg grammar file!');
    return;
  }

  // This would normally call a validation function
  // For now, let's simulate validation
  const text = document.getText();
  
  // Simple validation: check matching brackets and arrows
  let openBrackets = 0;
  let hasRules = false;
  
  for (let i = 0; i < text.length; i++) {
    if (text[i] === '(') openBrackets++;
    if (text[i] === ')') openBrackets--;
    
    // Check for rule definitions (very simple)
    if (i < text.length - 2 && text.substring(i, i+2) === '<-') {
      hasRules = true;
    }
  }
  
  if (openBrackets !== 0) {
    vscode.window.showErrorMessage('Grammar validation failed: Unbalanced parentheses');
  } else if (!hasRules) {
    vscode.window.showErrorMessage('Grammar validation failed: No rule definitions found');
  } else {
    vscode.window.showInformationMessage('Grammar validation passed!');
  }
}

// Command to generate Nim parser code from the grammar
async function generateParser() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showErrorMessage('No active editor!');
    return;
  }

  const document = editor.document;
  if (document.languageId !== 'npeg') {
    vscode.window.showErrorMessage('Not a NPeg grammar file!');
    return;
  }

  const grammar = document.getText();
  
  // This would normally call a code generation function
  // For now, generate a skeleton
  
  // Get the first rule name (simplistic)
  const match = grammar.match(/([a-zA-Z_][a-zA-Z0-9_]*)\s*<-/);
  const ruleName = match ? match[1] : 'doc';
  
  const nimCode = `import npeg, strutils

let parser = peg "${ruleName}":
  # Grammar generated from ${document.fileName}
  ${grammar}

# Example usage
let input = "your input here"
let result = parser.match(input)

if result.ok:
  echo "Parsing succeeded!"
  if result.captures.len > 0:
    echo "Captures: ", result.captures
else:
  echo "Parsing failed at position ", result.matchMax
`;

  // Create a new document with the generated code
  const newDocument = await vscode.workspace.openTextDocument({
    language: 'nim',
    content: nimCode
  });
  
  await vscode.window.showTextDocument(newDocument);
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
}