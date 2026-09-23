# Configure Three-Way Luau Boundaries

- Status: completed
- importance: 1.0
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Description

Configure separate repository tooling, portable framework, and Roblox runtime source boundaries with correct Luau-LSP platform isolation and extensionless relative string imports.

## Context

- A workspace-wide standard Luau-LSP setting prevented Roblox analysis for runtime code.
- Luau-LSP 1.70.0 creates one global server per VS Code window, so standard and Roblox analysis cannot coexist in one window.
- The repository already has project-owned naming diagnostics that must operate from each focused source workspace.

## Decisions

- `tooling/` is repository-only tooling; `src/framework/` is portable Luau; and `src/runtime/` is Roblox-only.
- Dependencies flow from runtime to framework only; neither package imports tooling.
- Use dedicated VS Code workspaces/windows for Luau-LSP platform isolation and retain strict `.luaurc` files per source root.

## Likely Files

- `.vscode/settings.json`
- `framework.code-workspace`
- `runtime.code-workspace`
- `tooling.code-workspace`
- `src/framework/.luaurc`
- `src/runtime/.luaurc`
- `tooling/.luaurc`
- `editors/vscode/extension.js`
- `AGENTS.md`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/`

## Files Touched

- `.vscode/settings.json`
- `tooling.code-workspace`
- `framework.code-workspace`
- `runtime.code-workspace`
- `src/framework/.luaurc`
- `src/runtime/.luaurc`
- `tooling/.luaurc`
- `editors/vscode/extension.js`
- `AGENTS.md`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/project.md`
- `.ai/decision/2026-09-23-006-three-way-source-boundaries.md`
- `.ai/decision/latest/source-environments.md`
- `.ai/tasks/2026-09-23-006-configure-three-way-luau-boundaries.md`
- `.ai/tasks/current.md`

## Summary

- Split the source layout into repository-only tooling, portable framework, and Roblox runtime roots.
- Added strict per-root `.luaurc` files and separate standard/Roblox Luau-LSP workspace files with always-relative require completion.
- Removed incompatible root-wide Luau-LSP platform and sourcemap settings, and made naming diagnostics find the repository root from a document in any source workspace.

## Validation

- VS Code workspace and `.luaurc` JSON parsing: passed.
- `node --check editors/vscode/extension.js`: passed.
- `npm --prefix editors/vscode run package`: passed.
- `stylua --check src examples tooling`: passed.
- `lune run tooling/naming/tests`: passed.
- `lune run tooling/naming/cli check src examples tooling`: passed for five Luau files.
- Luau-LSP standalone analyzer help confirmed platform-specific `analyze --platform` support.
- `.ai/tools/validate-workflow.ps1` and `git diff --check`: passed.
- Rojo builds were not run because the pre-existing uncommitted deletion of `example.project.json` and `package.project.json` leaves no project files to build.

## Follow-up / Risks

- Do not enable runtime sourcemap generation until an explicit Rojo DataModel topology is designed.
- Restore or replace the deleted Rojo project files before resuming Rojo build validation.