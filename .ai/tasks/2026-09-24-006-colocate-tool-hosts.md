# Task: Colocate Tool Hosts

- Status: completed
- importance: 0.9
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Move editor-host source under its owning tool, rename the naming analyzer to the linter, and place generated host artifacts in the root `bin/` directory.

## Context

The VS Code adapter was separated under `editors/vscode/` even though it exclusively hosts the project-owned naming tool. The Lune host was already colocated under `tooling/lune/` and emitted generated artifacts to `bin/`.

## Decisions

- Use `linter` as the broader, behavior-appropriate name for diagnostic rule enforcement.
- Place the VS Code adapter at `tooling/linter/vscode/`.
- Package the extension as `bin/bundle-framework-linter.vsix`.
- Keep the separate Lune host in `tooling/lune/` with its existing `bin/` outputs.

## Likely Files

- `tooling/linter/`
- `.vscode/`
- `.github/workflows/ci.yml`
- `README.md`
- `CONTRIBUTING.md`
- `.gitignore`
- `.ai/decision/`

## Files Touched

- `tooling/linter/`
- `editors/vscode/` (removed after relocation)
- `tooling/naming/` (removed after relocation)
- `.vscode/settings.json`
- `.vscode/tasks.json`
- `tooling.code-workspace`
- `.github/workflows/ci.yml`
- `.gitignore`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/project.md`
- `.ai/decision/`
- `.ai/tasks/current.md`

## Summary

- Renamed the portable naming analyzer to the Bundle Framework linter at `tooling/linter/`.
- Moved the thin VS Code host into `tooling/linter/vscode/` and renamed its package/settings/diagnostic source to `bundle-framework-linter` and `bundleFramework.linter`.
- The extension package now builds to ignored `bin/bundle-framework-linter.vsix`; the existing separate Lune host remains in `tooling/lune/` and continues using `bin/`.
- Updated active CI, VS Code tasks/workspace settings, docs, ignore rules, and decision index; historical dated records intentionally retain their original paths.

## Validation

- Passed: `node --check tooling/linter/vscode/extension.js`.
- Passed: `npm --prefix tooling/linter/vscode run package`; created ignored `bin/bundle-framework-linter.vsix` (4,502 bytes).
- Passed: `lune run tooling/linter/tests.luau`.
- Passed: `lune run tooling/linter/cli.luau check src examples tooling` (12 Luau files).
- Passed: `stylua --check tooling/linter` after formatting the relocated Luau files.
- Passed: `.ai/tools/validate-workflow.ps1`.
- Passed: `git diff --check`.
- Repository-wide `stylua --check src examples tooling` remains blocked by unrelated pre-existing CRLF formatting differences under `src/framework/` and `tooling/lune/`; no unrelated formatting was changed.

## Follow-up / Risks

- The linter currently implements naming rules only; additional lint rules require explicit design and tests.
