# Task: Add Root npm Workspace

- Status: completed
- importance: 0.88
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Replace the VS Code linter adapter's isolated npm installation with a repository-root npm workspace and shared dependency installation.

## Context

- The only current JavaScript package is the VS Code linter adapter at `tooling/linter/vscode/`, which previously owned its own `node_modules/` and `package-lock.json`.
- The repository needs a single dependency installation location while preserving the adapter's explicit VSCE development dependency.

## Decisions

- Use npm workspaces at the repository root and list `tooling/linter/vscode/` as the current workspace.
- Keep `@vscode/vsce` declared in the adapter manifest, but resolve the installed VSCE executable from root `node_modules/.bin/`.
- Replace nested installation commands with root `npm install` and the root `package:linter-extension` dispatcher script.

## Likely Files

- `package.json`
- `package-lock.json`
- `.gitignore`
- `tooling/linter/vscode/`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/decision/`
- `.ai/tasks/`

## Files Touched

- `package.json`
- `package-lock.json`
- `.gitignore`
- `tooling/linter/vscode/package-lock.json` (removed)
- `tooling/linter/vscode/package-windows.ps1`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/decision/`
- `.ai/tasks/`

## Summary

- Added a private root npm workspace manifest and generated one root lockfile.
- Migrated the linter adapter dependency installation to the shared root `node_modules/` directory.
- Updated packaging, developer documentation, and the durable workspace decision.

## Validation

- Passed: `npm install` and `npm ci --ignore-scripts`.
- Passed: `npm ls --workspaces --depth=0` identified the linter extension workspace and VSCE dependency.
- Passed: root workspace packaging built the Windows linter executable and VSIX, including `extension/bin/bundle-framework-linter.exe`.
- Passed: `node --check tooling/linter/vscode/extension.js`, PowerShell parser check, and `git diff --check`.
- Passed: `.ai/tools/validate-workflow.ps1` after task completion.

## Follow-up / Risks

- Add future Node.js packages to the root workspace list and retain their dependency declarations in their own manifests.
- npm reported that VSCE's optional signing helper has an unapproved install script; packaging and verification remain successful without it.