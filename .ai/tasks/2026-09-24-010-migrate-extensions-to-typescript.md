# Task: Migrate Extensions to TypeScript

- Status: completed
- importance: 0.92
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Migrate the VS Code linter adapter from JavaScript to TypeScript and consolidate generated host artifacts under a reusable build layout.

## Context

- The VS Code linter adapter was the only authored JavaScript source.
- Existing generated Luau bundles, Windows executables, and VSIX files were rooted under `bin/`.

## Decisions

- Use ignored `build/js/`, `build/luau/`, `build/bin/`, and `build/vsix/` directories for repository-generated outputs.
- Keep the VSIX-internal executable at `bin/bundle-framework-linter.exe` because it is a private extension package path.
- Use strict TypeScript in `tooling/linter/vscode/src/` and a local `tsconfig.json` that emits to `build/js/linter-vscode/`.
- Expose `compile:extension`, `compile:luau`, `test:extension`, and combined `build` root npm scripts through `tooling/build.ps1`.

## Likely Files

- `tooling/build.ps1`
- `tooling/linter/vscode/`
- `tooling/linter/build-windows.ps1`
- `tooling/lune/build-windows.ps1`
- `package.json`
- `package-lock.json`
- `.github/workflows/ci.yml`
- `.vscode/tasks.json`
- `.gitignore`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/decision/`
- `.ai/tasks/`

## Files Touched

- `tooling/build.ps1`
- `tooling/linter/vscode/src/extension.ts`
- `tooling/linter/vscode/extension.js` (removed)
- `tooling/linter/vscode/tsconfig.json`
- `tooling/linter/vscode/package.json`
- `tooling/linter/vscode/package-windows.ps1`
- `tooling/linter/build-windows.ps1`
- `tooling/lune/build-windows.ps1`
- `package.json`
- `package-lock.json`
- `.github/workflows/ci.yml`
- `.vscode/tasks.json`
- `.gitignore`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/decision/`
- `.ai/tasks/current.md`

## Summary

- Replaced the linter adapter JavaScript source with a strict TypeScript implementation and runtime validation of linter diagnostic responses.
- Added the reusable `tooling/build.ps1` coordinator and root npm scripts for extension compilation, Luau compilation, extension testing, and combined builds.
- Moved repository artifacts from `bin/` into typed `build/` subdirectories and updated packaging, CI, VS Code tasks, and documentation.

## Validation

- Passed: `npm install --ignore-scripts`.
- Passed: PowerShell parser checks for all modified build scripts.
- Passed: `npm run compile:extension`.
- Passed: `npm run compile:luau`, including linter executable document-protocol smoke test.
- Passed: `npm run test:extension`; VSCE packaged `build/vsix/bundle-framework-linter.vsix` with compiled `extension.js` and private `bin/bundle-framework-linter.exe`, then `code --install-extension --force` succeeded.
- Passed: `lune run tooling/linter/tests.luau` and `lune run tooling/linter/cli.luau check src examples tooling`.

## Follow-up / Risks

- The VSCE dependency emits a Node.js `url.parse()` deprecation warning during packaging; package and installation complete successfully.
- Current extension testing installs the VSIX locally but does not automate interactive diagnostic behavior inside a running VS Code window.