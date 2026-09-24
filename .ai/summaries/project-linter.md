# Summary: Project Linter

- importance: 0.9
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z
- Source Paths: `tooling/linter/`, `package.json`

## Purpose

Enforce project Luau naming conventions through one portable analyzer used by command-line, CI, and VS Code hosts.

## Important Files

- `tooling/linter/Lexer.luau`, `Rules.luau`, and `Analyzer.luau` implement diagnostics.
- `tooling/linter/cli.luau` provides `document` and `check` commands.
- `tooling/linter/vscode/src/extension.ts` hosts live diagnostics.
- `tooling/linter/build.luau` declares the CLI entry, extension root, and Windows x64 platform.

## Interfaces

- `document` reads `{ path, source }` JSON from standard input and returns a diagnostic array.
- `check [paths...]` scans Luau files, prints diagnostics, and exits nonzero on failure.
- The extension launches its bundled `bin/cli.exe` and publishes VS Code diagnostics.

## Invariants

- Analyzer diagnostics use zero-based ranges and stable `naming/*` codes.
- File traversal skips `.git`, `node_modules`, and `dist`.
- Live linting applies only to file-backed Luau documents in a repository containing `tooling/linter/cli.luau`.
- StyLua remains the formatter; Luau-LSP owns type and built-in language diagnostics.

## Dependencies

Portable Luau analysis; Lune APIs in the CLI; Node.js and VS Code APIs in the thin TypeScript adapter.

## Data Flow

Source text/path → lexer → naming rules → normalized diagnostics → CLI JSON/text → VS Code collection or CI exit status.

## Operational Notes

The extension debounces changes by 150 ms, cancels stale child processes, and resolves the packaged executable through `context.asAbsolutePath()`.

## Update Triggers

Naming rules, diagnostic schema, CLI commands, file discovery, extension activation, or binary packaging changes.

## Last Verified

2026-09-24