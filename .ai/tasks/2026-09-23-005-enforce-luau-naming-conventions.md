# Enforce Luau Naming Conventions

- Status: completed
- importance: 0.99
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Description

Implement live VS Code and CI enforcement for default Luau naming conventions without adding Selene.

## Context

- StyLua already provides formatting but not identifier or filename naming rules.
- The user rejected Selene because it does not sufficiently support modern Luau features.
- The project requires portable authoring-time Luau tooling with thin editor hosts.

## Decisions

- Use Lune to execute portable `tooling/naming/` analysis in CI and from the editor adapter.
- Keep VS Code code limited to process invocation and diagnostic publication.
- Enforce identifier casing and filename casing; do not infer module export identity from an arbitrary script `return` statement.

## Likely Files

- `aftman.toml`
- `tooling/naming/`
- `editors/vscode/`
- `.vscode/`
- `.github/workflows/ci.yml`
- `CONTRIBUTING.md`
- `README.md`
- `.ai/decision/`
- `.ai/tasks/current.md`

## Files Touched

- `aftman.toml`
- `tooling/naming/Rules.luau`
- `tooling/naming/Lexer.luau`
- `tooling/naming/Analyzer.luau`
- `tooling/naming/cli.luau`
- `tooling/naming/tests.luau`
- `editors/vscode/package.json`
- `editors/vscode/package-lock.json`
- `editors/vscode/extension.js`
- `editors/vscode/LICENSE`
- `.vscode/extensions.json`
- `.vscode/settings.json`
- `.vscode/tasks.json`
- `.github/workflows/ci.yml`
- `.gitignore`
- `CONTRIBUTING.md`
- `README.md`
- `.ai/project.md`
- `.ai/decision/2026-09-23-005-project-naming-diagnostics.md`
- `.ai/decision/latest.md`
- `.ai/decision/latest/project-naming-diagnostics.md`
- `.ai/tasks/2026-09-23-005-enforce-luau-naming-conventions.md`
- `.ai/tasks/current.md`

## Summary

- Added the portable naming analyzer, Lune CLI transport, tests, and a thin locally packaged VS Code diagnostic extension.
- Added live editor settings, a VS Code naming-check task, CI enforcement, and contributor documentation.
- Pinned Lune 0.10.5 through Aftman and preserved StyLua, Luau-LSP, Rojo, and the removal of Selene.

## Validation

- `lune 0.10.5` analyzer tests: passed using the official release binary in the system temporary directory.
- Naming CLI check for `src`, `examples`, and `tooling`: passed for five Luau files.
- JSON document protocol: verified diagnostics for invalid variable, constant, type, type-function, function, parameter, and filename casing.
- `stylua --check src examples tooling`: passed.
- `rojo build example.project.json` and `rojo build package.project.json`: passed with system-temporary outputs removed afterward.
- VS Code adapter: `npm install`, VSIX packaging, and local `code --install-extension ... --force`: passed.
- `git diff --check` and `.ai/tools/validate-workflow.ps1`: passed.

## Follow-up / Risks

- `aftman install` could not create the Lune alias because the pre-existing `C:\Users\Lucky\.aftman\bin\rojo.exe` alias was locked by another process. Close the process holding that executable and run `aftman install`; the repository pin is already configured.