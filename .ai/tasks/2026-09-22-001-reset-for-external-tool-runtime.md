# Reset Repository for External Tool and Luau Runtime

- Status: completed
- importance: 1.0
- confidence: 1.0
- createdAt: 2026-09-22T00:00:00Z
- lastUsedAt: 2026-09-22T00:00:00Z

## Description

Reset the former Luau-only Bundle Framework scaffold for a future external development tool and Luau runtime.

## Context

- The former static API was backed up before this destructive reset.
- The external tool will handle authoring-time dependency enforcement, import processing, type information, autocomplete support, and generation of simple runtime input.
- The Luau runtime will consume generated intermediate output.

## Decisions

- Preserve Rojo, StyLua, Aftman, CI, VS Code, Git, license, and AI workflow infrastructure.
- Remove Selene and its configuration, commands, and references from active tooling and documentation.
- Clear existing implementation and example source while preserving `src/` and `examples/` with `.gitkeep` files.
- Add empty `tooling/` with `.gitkeep`.
- Keep valid, blank Rojo project scaffolds.

## Likely Files

- `src/`
- `examples/`
- `tooling/`
- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `AGENTS.md`
- `.ai/`
- development tooling and CI configuration

## Files Touched

- `src/`
- `examples/`
- `tooling/`
- `selene.toml`
- `selene-std.yml`
- `aftman.toml`
- `.github/workflows/ci.yml`
- `.vscode/tasks.json`
- `example.project.json`
- `package.project.json`
- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `AGENTS.md`
- `.ai/`

## Summary

- Removed the former Luau-only static implementation and examples, retaining empty `src/` and `examples/` directories with `.gitkeep` files.
- Added empty `tooling/` for the future external tool.
- Removed Selene from Aftman, CI, VS Code tasks, and active documentation.
- Replaced both Rojo project mappings with valid blank scaffolds.
- Documented the external-tool plus Luau-runtime boundary and added a superseding dated architecture decision.

## Validation

- `.ai/tools/archive-tasks.ps1`: passed; no task records were eligible for archival.
- `aftman install`: passed; StyLua 2.1.0 installed successfully.
- `stylua --check src examples tooling`: passed.
- `rojo build example.project.json`: passed with output written to and removed from the system temporary directory.
- `rojo build package.project.json`: passed with output written to and removed from the system temporary directory.
- Rojo project JSON parsing: passed.
- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed.
- Current-reference scan: passed; old static API and source-path references remain only in preserved historical task and decision records.

## Follow-up / Risks

- The tool implementation, intermediate format, generated-output workflow, and runtime API remain unimplemented and require separate design work.