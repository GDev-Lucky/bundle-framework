const path = require("node:path");
const fs = require("node:fs");
const { spawn } = require("node:child_process");
const vscode = require("vscode");

const pending = new Map();
const processes = new Map();

function isSupported(document) {
    return document.languageId === "luau" && document.uri.scheme === "file";
}

function findProjectRoot(document) {
    let directory = path.dirname(document.uri.fsPath);
    while (true) {
        if (fs.existsSync(path.join(directory, "tooling", "naming", "cli.luau"))) {
            return directory;
        }

        const parent = path.dirname(directory);
        if (parent === directory) return undefined;
        directory = parent;
    }
}

function lintDocument(document, collection) {
    if (!isSupported(document)) return;

    const config = vscode.workspace.getConfiguration("bundleFramework.naming", document.uri);
    if (!config.get("enabled", true)) {
        collection.delete(document.uri);
        return;
    }

    const projectRoot = findProjectRoot(document);
    if (!projectRoot) return;

    const script = path.join(projectRoot, "tooling", "naming", "cli.luau");
    const lunePath = config.get("lunePath", "lune");
    const key = document.uri.toString();
    const existing = processes.get(key);
    if (existing) existing.kill();

    const child = spawn(lunePath, ["run", script, "document"], {
        cwd: projectRoot,
        windowsHide: true,
        stdio: ["pipe", "pipe", "pipe"],
    });
    processes.set(key, child);

    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (data) => {
        stdout += data;
    });
    child.stderr.on("data", (data) => {
        stderr += data;
    });
    child.on("error", (error) => {
        collection.set(document.uri, [
            new vscode.Diagnostic(
                new vscode.Range(0, 0, 0, 1),
                `Naming analyzer could not start: ${error.message}`,
                vscode.DiagnosticSeverity.Error
            ),
        ]);
    });
    child.on("close", (code) => {
        if (processes.get(key) !== child) return;
        processes.delete(key);

        if (code !== 0) {
            collection.set(document.uri, [
                new vscode.Diagnostic(
                    new vscode.Range(0, 0, 0, 1),
                    `Naming analyzer failed: ${stderr.trim() || `exit code ${code}`}`,
                    vscode.DiagnosticSeverity.Error
                ),
            ]);
            return;
        }

        try {
            const result = JSON.parse(stdout);
            // Lune 0.10.5 encodes an empty Luau table as `{}`. Accept that
            // legacy response while the project CLI guarantees `[]` going
            // forward, then reject every other non-array protocol response.
            const items = Array.isArray(result) ? result : isEmptyObject(result) ? [] : undefined;
            if (!items) {
                throw new TypeError("expected the naming analyzer to return a JSON array");
            }
            const diagnostics = items.map((item) => {
                const diagnostic = new vscode.Diagnostic(
                    new vscode.Range(item.startLine, item.startCharacter, item.endLine, item.endCharacter),
                    item.message,
                    item.severity === "error" ? vscode.DiagnosticSeverity.Error : vscode.DiagnosticSeverity.Warning
                );
                diagnostic.code = item.code;
                diagnostic.source = "bundle-framework-naming";
                return diagnostic;
            });
            collection.set(document.uri, diagnostics);
        } catch (error) {
            collection.set(document.uri, [
                new vscode.Diagnostic(
                    new vscode.Range(0, 0, 0, 1),
                    `Naming analyzer returned invalid output: ${error.message}`,
                    vscode.DiagnosticSeverity.Error
                ),
            ]);
        }
    });
    child.stdin.end(JSON.stringify({ path: document.uri.fsPath, source: document.getText() }));
}

function isEmptyObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value) && Object.keys(value).length === 0;
}

function schedule(document, collection) {
    if (!isSupported(document)) return;

    const key = document.uri.toString();
    clearTimeout(pending.get(key));
    pending.set(
        key,
        setTimeout(() => {
            pending.delete(key);
            lintDocument(document, collection);
        }, 150)
    );
}

function activate(context) {
    const collection = vscode.languages.createDiagnosticCollection("bundle-framework-naming");
    context.subscriptions.push(collection);
    context.subscriptions.push(vscode.workspace.onDidOpenTextDocument((document) => schedule(document, collection)));
    context.subscriptions.push(vscode.workspace.onDidChangeTextDocument((event) => schedule(event.document, collection)));
    context.subscriptions.push(vscode.workspace.onDidCloseTextDocument((document) => collection.delete(document.uri)));
    context.subscriptions.push(
        vscode.workspace.onDidChangeConfiguration((event) => {
            if (event.affectsConfiguration("bundleFramework.naming")) {
                for (const document of vscode.workspace.textDocuments) schedule(document, collection);
            }
        })
    );

    for (const document of vscode.workspace.textDocuments) schedule(document, collection);
}

function deactivate() {
    for (const timer of pending.values()) clearTimeout(timer);
    for (const child of processes.values()) child.kill();
    pending.clear();
    processes.clear();
}

module.exports = { activate, deactivate };