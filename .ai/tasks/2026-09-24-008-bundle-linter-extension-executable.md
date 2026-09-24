# Task: Bundle Linter Extension Executable

- Status: completed
- importance: 0.93
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Compile the project-owned Luau linter into a Windows executable, package that executable in the local VS Code extension, and provide a development task that builds, packages, and installs the extension in order.

## Context

- The adapter previously spawned `lune run tooling/linter/cli.luau`, making installed-editor diagnostics depend on Lune and repository source at runtime.
- The repository already pins DarkLua and Lune and uses the same bundle-then-build pattern for a separate Windows host artifact.

## Decisions

- Build `tooling/linter/cli.luau` through DarkLua and Lune for `windows-x86_64` into ignored root `bin/` artifacts.
- Stage the generated executable inside the VSIX at `extension/bin/bundle-framework-linter.exe`.
- Resolve the installed executable with VS Code's `context.asAbsolutePath()`; retain project-root discovery only for diagnostic scoping.
- Make **Test linter extension** execute **Build linter executable**, **Build linter extension**, then **Install linter extension** sequentially.

## Likely Files

- `tooling/linter/`
- `tooling/linter/vscode/`
- `.vscode/tasks.json`
- `.vscode/settings.json`
- `tooling.code-workspace`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/decision/`
- `.ai/tasks/`

## Files Touched

- `tooling/linter/darklua.json5`
- `tooling/linter/build-windows.ps1`
- `tooling/linter/vscode/package-windows.ps1`
- `tooling/linter/vscode/extension.js`
- `tooling/linter/vscode/package.json`
- `.vscode/tasks.json`
- `.vscode/settings.json`
- `tooling.code-workspace`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/project.md`
- `.ai/decision/`
- `.ai/tasks/current.md`

## Summary

- Added reproducible DarkLua and Lune compilation of the linter CLI to `bin/bundle-framework-linter.exe`, including a document-protocol smoke test.
- Added staging-based VSIX packaging so the extension contains its own executable.
- Updated the adapter to launch the installed executable and removed the obsolete `lunePath` configuration.
- Added build, package, install, and ordered test tasks for local extension development.

## Validation

- Passed: PowerShell parser checks for both new build scripts.
- Passed: `node --check tooling/linter/vscode/extension.js` and JSON manifest parsing.
- Passed: `lune run tooling/linter/tests.luau` and `stylua --check tooling/linter`.
- Passed: executable build and no-diagnostics document-protocol smoke test.
- Passed: VSIX package; VSCE confirmed `extension/bin/bundle-framework-linter.exe` is included.
- Passed: `code --install-extension bin/bundle-framework-linter.vsix --force`.
- Passed: `git diff --check` and `.ai/tools/validate-workflow.ps1`.

## Follow-up / Risks

- The installed artifact targets Windows x64 only. macOS, Linux, web extension support, executable signing, artifact publishing, and versioned multi-platform selection require future decisions.
- Reload VS Code after installation before manually checking newly installed extension behavior.