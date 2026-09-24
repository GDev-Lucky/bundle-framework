# Build Standalone Windows Lune Tool

- Status: completed
- importance: 0.85
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Add a reproducible Windows x64 build pipeline that bundles the Lune application into one resolved Luau file and compiles it into an executable for the VS Code extension host.

## Context

- `tooling/lune/main.luau` imports portable framework modules with relative string paths and uses Lune built-in modules under `@lune/`.
- Lune 0.10.5 can build standalone executables but does not resolve project-local modules by itself.
- DarkLua supports path-require bundling while excluding Lune built-in imports.

## Decisions

- Pin DarkLua 0.19.0 through Aftman.
- Generate `bin/lune-main.luau`, then compile `bin/lune-main.exe` for `windows-x86_64`.
- Expose the pipeline as the VS Code task `build-lune-windows` and keep generated artifacts untracked.

## Likely Files

- `aftman.toml`
- `.gitignore`
- `.vscode/tasks.json`
- `tooling/lune/darklua.json5`
- `tooling/lune/build-windows.ps1`
- `.ai/tasks/current.md`

## Files Touched

- `aftman.toml`
- `.gitignore`
- `.vscode/tasks.json`
- `tooling/lune/darklua.json5`
- `tooling/lune/build-windows.ps1`
- `.ai/tasks/current.md`
- `.ai/tasks/2026-09-24-001-build-standalone-windows-lune-tool.md`

## Summary

- Added a DarkLua 0.19.0 Aftman pin and path-require bundle configuration that preserves `@lune/**` host imports.
- Added the `build-lune-windows` VS Code build task, which calls `tooling/lune/build-windows.ps1`.
- The build driver emits the resolved bundle to `bin/lune-main.luau` and builds `bin/lune-main.exe` for `windows-x86_64`; `bin/` is ignored as generated output.

## Validation

- `tooling/lune/build-windows.ps1`: passed; produced `bin/lune-main.luau` and `bin/lune-main.exe`.
- Executable smoke test with `{"roots":[],"items":[]}` on standard input: passed.
- Generated-bundle import check: passed; all project-relative imports were resolved and `@lune/stdio` / `@lune/serde` remained host imports.
- `stylua --check src examples tooling`: passed.
- `lune run tooling/naming/tests.luau`: passed.
- `lune run tooling/naming/cli.luau check src examples tooling`: passed for 12 Luau files.
- `.ai/tools/validate-workflow.ps1` and `git diff --check`: passed.

## Follow-up / Risks

- The executable interface is still defined by the evolving `tooling/lune/main.luau` entry point.