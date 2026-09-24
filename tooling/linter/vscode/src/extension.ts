import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";
import * as vscode from "vscode";

interface LinterDiagnostic {
	code: string;
	endCharacter: number;
	endLine: number;
	message: string;
	severity: "error" | "warning";
	startCharacter: number;
	startLine: number;
}

const pending = new Map<string, NodeJS.Timeout>();
const processes = new Map<string, ChildProcessWithoutNullStreams>();

function isSupported(document: vscode.TextDocument): boolean {
	return document.languageId === "luau" && document.uri.scheme === "file";
}

function findProjectRoot(document: vscode.TextDocument): string | undefined {
	let directory = path.dirname(document.uri.fsPath);
	while (true) {
		if (fs.existsSync(path.join(directory, "tooling", "linter", "cli.luau"))) {
			return directory;
		}

		const parent = path.dirname(directory);
		if (parent === directory) return undefined;
		directory = parent;
	}
}

function isEmptyObject(value: unknown): value is Record<string, never> {
	return value !== null && typeof value === "object" && !Array.isArray(value) && Object.keys(value).length === 0;
}

function isLinterDiagnostic(value: unknown): value is LinterDiagnostic {
	if (value === null || typeof value !== "object") return false;

	const item = value as Record<string, unknown>;
	return (
		typeof item.code === "string" &&
		typeof item.endCharacter === "number" &&
		typeof item.endLine === "number" &&
		typeof item.message === "string" &&
		(item.severity === "error" || item.severity === "warning") &&
		typeof item.startCharacter === "number" &&
		typeof item.startLine === "number"
	);
}

function parseDiagnostics(output: string): LinterDiagnostic[] {
	const result: unknown = JSON.parse(output);
	if (isEmptyObject(result)) return [];
	if (!Array.isArray(result) || !result.every(isLinterDiagnostic)) {
		throw new TypeError("expected the linter to return a diagnostic JSON array");
	}
	return result;
}

function errorMessage(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}

function lintDocument(
	document: vscode.TextDocument,
	collection: vscode.DiagnosticCollection,
	executablePath: string
): void {
	if (!isSupported(document)) return;

	const config = vscode.workspace.getConfiguration("bundleFramework.linter", document.uri);
	if (!config.get("enabled", true)) {
		collection.delete(document.uri);
		return;
	}

	const projectRoot = findProjectRoot(document);
	if (!projectRoot) return;

	const key = document.uri.toString();
	processes.get(key)?.kill();

	const child = spawn(executablePath, ["document"], {
		cwd: projectRoot,
		windowsHide: true,
		stdio: ["pipe", "pipe", "pipe"],
	});
	processes.set(key, child);

	let stdout = "";
	let stderr = "";
	child.stdout.setEncoding("utf8");
	child.stderr.setEncoding("utf8");
	child.stdout.on("data", (data: string) => {
		stdout += data;
	});
	child.stderr.on("data", (data: string) => {
		stderr += data;
	});
	child.on("error", (error) => {
		collection.set(document.uri, [
			new vscode.Diagnostic(
				new vscode.Range(0, 0, 0, 1),
				`Linter could not start: ${error.message}`,
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
					`Linter failed: ${stderr.trim() || `exit code ${code}`}`,
					vscode.DiagnosticSeverity.Error
				),
			]);
			return;
		}

		try {
			const diagnostics = parseDiagnostics(stdout).map((item) => {
				const diagnostic = new vscode.Diagnostic(
					new vscode.Range(item.startLine, item.startCharacter, item.endLine, item.endCharacter),
					item.message,
					item.severity === "error" ? vscode.DiagnosticSeverity.Error : vscode.DiagnosticSeverity.Warning
				);
				diagnostic.code = item.code;
				diagnostic.source = "bundle-framework-linter";
				return diagnostic;
			});
			collection.set(document.uri, diagnostics);
		} catch (error) {
			collection.set(document.uri, [
				new vscode.Diagnostic(
					new vscode.Range(0, 0, 0, 1),
					`Linter returned invalid output: ${errorMessage(error)}`,
					vscode.DiagnosticSeverity.Error
				),
			]);
		}
	});
	child.stdin.end(JSON.stringify({ path: document.uri.fsPath, source: document.getText() }));
}

function schedule(
	document: vscode.TextDocument,
	collection: vscode.DiagnosticCollection,
	executablePath: string
): void {
	if (!isSupported(document)) return;

	const key = document.uri.toString();
	const existing = pending.get(key);
	if (existing) clearTimeout(existing);
	pending.set(
		key,
		setTimeout(() => {
			pending.delete(key);
			lintDocument(document, collection, executablePath);
		}, 150)
	);
}

export function activate(context: vscode.ExtensionContext): void {
	const collection = vscode.languages.createDiagnosticCollection("bundle-framework-linter");
	const executablePath = context.asAbsolutePath(path.join("bin", "cli.exe"));
	context.subscriptions.push(collection);
	context.subscriptions.push(
		vscode.workspace.onDidOpenTextDocument((document) => schedule(document, collection, executablePath))
	);
	context.subscriptions.push(
		vscode.workspace.onDidChangeTextDocument((event) => schedule(event.document, collection, executablePath))
	);
	context.subscriptions.push(vscode.workspace.onDidCloseTextDocument((document) => collection.delete(document.uri)));
	context.subscriptions.push(
		vscode.workspace.onDidChangeConfiguration((event) => {
			if (event.affectsConfiguration("bundleFramework.linter")) {
				for (const document of vscode.workspace.textDocuments) schedule(document, collection, executablePath);
			}
		})
	);

	for (const document of vscode.workspace.textDocuments) schedule(document, collection, executablePath);
}

export function deactivate(): void {
	for (const timer of pending.values()) clearTimeout(timer);
	for (const child of processes.values()) child.kill();
	pending.clear();
	processes.clear();
}