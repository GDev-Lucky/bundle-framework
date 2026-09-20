# Flatten Source and Add Root Rojo Projects

- Status: completed
- importance: 0.94
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-21T00:00:00Z

## Description

Flatten the framework package directly into `src`, expose the generic example through root-level `example.project.json`, configure Luau-LSP against that example, and add `package.project.json` for loading the package alone.

## Context

- The package source was unnecessarily nested under `src/framework/`.
- The example Rojo project was nested under `examples/basic/default.project.json`.
- Luau-LSP and repository validation followed the nested example project.
- Consumers need a package-only Rojo project in addition to the full example place.

## Decisions

- Keep the public `framework.manifest()` / `define()` / `bundle.require()` API unchanged.
- Make `src/init.luau` the package root and keep helper modules beside it.
- Preserve the example's Roblox instance names and imports while moving only its project definition to the repository root.
- Use `example.project.json` for workspace source maps and example serving.
- Use `package.project.json` to build or load only the framework ModuleScript package.

## Likely Files

- `src/`
- `example.project.json`
- `package.project.json`
- `.vscode/`
- `.github/workflows/ci.yml`
- `README.md`
- `.ai/`

## Files Touched

- `src/init.luau`
- `src/types.luau`
- `src/type-helpers.luau`
- `example.project.json`
- `package.project.json`
- `.vscode/settings.json`
- `.vscode/tasks.json`
- `.github/workflows/ci.yml`
- `README.md`
- `CONTRIBUTING.md`
- `.ai/project.md`
- `.ai/guides/bundle-api.md`
- `.ai/summaries/static-api.md`
- `.ai/tasks/current.md`

## Summary

- Flattened the framework package from `src/framework/` into `src/` without changing its public static API.
- Replaced the nested example project with root-level `example.project.json`, preserving the example's `ServerStorage.framework`, `manifest`, and `bundles` layout.
- Added `package.project.json`, which maps only the framework ModuleScript package rooted at `src/`.
- Pointed Luau-LSP, VS Code tasks, CI, and maintained documentation at the root-level projects.

## Validation

- `rojo build example.project.json --output bundle-framework-example.rbxlx`: passed; artifact removed.
- `rojo build package.project.json --output bundle-framework.rbxm`: passed; artifact removed.
- `rojo sourcemap example.project.json --output sourcemap.json`: passed.
- JSON parse for both Rojo projects and VS Code configuration: passed.
- `.ai/tools/validate-workflow.ps1`: passed.
- `.ai/tools/archive-tasks.ps1 -CheckOnly`: passed.
- `git diff --check`: passed.
- `stylua --check src examples`: passed using the installed VS Code StyLua extension executable because the Aftman alias directory is locked by active Rojo processes.
- `selene src examples/basic/src`: passed with 0 errors and 0 warnings using the installed VS Code Selene extension executable.
- Added `syntax = "Luau"` to `stylua.toml` and the local `selene-std.yml` custom standard so the existing strict Luau type-function source validates consistently.

## Follow-up / Risks

- The package remains a static typing contract and does not add runtime dependency resolution.