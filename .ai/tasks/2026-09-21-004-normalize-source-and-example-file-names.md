# Normalize Source and Example File Names

- Status: completed
- importance: 0.72
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-21T00:00:00Z

## Description

Replace hyphens in filenames under `src/` and `examples/` with underscores.

## Context

- Filename inventory found `src/type-helpers.luau` as the only hyphenated file in the requested trees.
- No filenames under `examples/` contained hyphens.

## Decisions

- Rename `src/type-helpers.luau` to `src/type_helpers.luau`.
- Update the framework's child-module require so the Rojo ModuleScript child name remains resolvable.
- Update generated and maintained path references; retain completed historical task records unchanged.

## Likely Files

- `src/type-helpers.luau`
- `src/init.luau`
- `sourcemap.json`
- `.ai/`

## Files Touched

- `src/type_helpers.luau`
- `src/init.luau`
- `.ai/project.md`
- `.ai/guides/bundle-api.md`
- `.ai/summaries/static-api.md`
- `.ai/tasks/current.md`
- `.ai/tasks/2026-09-21-004-normalize-source-and-example-file-names.md`

## Summary

- Renamed the only hyphenated requested filename, `src/type-helpers.luau`, to `src/type_helpers.luau`.
- Updated the framework require, generated source map, and maintained source-path documentation.
- Confirmed `examples/` did not contain hyphenated filenames.

## Validation

- `rojo sourcemap example.project.json --output sourcemap.json`: passed; generated child name and file path use `type_helpers`.
- `rojo build example.project.json --output bundle-framework-example.rbxlx`: passed; artifact removed.
- `rojo build package.project.json --output bundle-framework.rbxm`: passed; artifact removed.
- Filename inventory: passed; no hyphenated names remain under `src/` or `examples/`.
- Active-reference scan: passed; no non-historical `type-helpers` references remain.
- `.ai/tools/validate-workflow.ps1`, `.ai/tools/archive-tasks.ps1 -CheckOnly`, and `git diff --check`: passed.
- StyLua and Selene were not run: `aftman install` could not install their aliases because `C:\Users\Lucky\.aftman\bin\rojo.exe` is locked by another process; no standalone extension executables were available.

## Follow-up / Risks

- Run `aftman install`, then `stylua --check src examples` and `selene src examples/basic/src` after the process locking the Aftman alias directory is closed.