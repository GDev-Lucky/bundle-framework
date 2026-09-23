# Record Dual Luau Source Environments

- Status: completed
- importance: 0.98
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Description

Record the confirmed `src/` and `tooling/` execution boundaries, shared relative-import convention, and separate Luau-LSP ownership without changing implementation or configuration files.

## Context

- The project has a Roblox runtime and a portable Luau authoring tool, both developed through Rojo synchronization.
- The source-layout, import, and per-root editor-analysis rules had not yet been recorded as a durable decision.
- The user explicitly requested an AI-memory-only update.

## Decisions

- Treat `src/` as the Roblox runtime package, permitted to use Roblox runtime APIs such as `task` and `Instance` values.
- Treat `tooling/` as a standalone-Luau-compatible package that may use portable Luau facilities but no Roblox runtime APIs or values.
- Keep both roots Rojo-synced into Studio while excluding authoring tooling from production runtime mappings.
- Use relative string-path `require()` imports without `.luau` suffixes, resolving directories through `init.luau`.
- Give `src/` and `tooling/` independent Luau-LSP configuration.

## Likely Files

- `.ai/project.md`
- `.ai/decision/`
- `.ai/tasks/`

## Files Touched

- `.ai/project.md`
- `.ai/decision/2026-09-23-004-dual-luau-source-environments.md`
- `.ai/decision/latest.md`
- `.ai/decision/latest/source-environments.md`
- `.ai/tasks/2026-09-23-004-record-dual-luau-source-environments.md`
- `.ai/tasks/current.md`

## Summary

- Recorded the two-package source layout and the Roblox-versus-portable Luau boundary.
- Recorded relative string imports, `init.luau` directory resolution, and independent LSP configuration as project rules.
- Made no changes outside `.ai/`.

## Validation

- `.ai/tools/archive-tasks.ps1`: passed.
- `.ai/tools/retrieve-context.ps1`: completed with the applicable project and decision leads.
- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed; only existing LF-to-CRLF conversion warnings were reported.

## Follow-up / Risks

- Implement the separate Rojo mappings and per-root LSP configuration only in a dedicated implementation task.
- Confirm the exact production and development Rojo project topology before changing project files.