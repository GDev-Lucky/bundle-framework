# Record Runtime Builds and Project Ownership

- Status: completed
- importance: 0.9
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Record the confirmed runtime build targets and host ownership model without creating runtime implementation.

## Context

- The project needs server, client, and shared runtime artifacts so Roblox realm boundaries remain explicit while shared utilities can be reused.
- The Lune/VS Code host can configure filesystem projects, Rojo, and Luau-LSP, whereas a Studio plugin can only manage DataModel objects.
- Rojo synchronization and Studio-side mutations must not compete for ownership of the same project objects.

## Decisions

- Package the portable compiler with the Lune/VS Code host and Studio plugin; generated projects receive runtime artifacts rather than authoring tooling.
- Use separate shared, server, and client runtime build targets, with server/client depending only on shared code.
- Use explicit host capabilities and project ownership metadata; make the Studio plugin read-only for Rojo-owned projects.
- Preserve server authority for future asset delivery and retain `PlayerGui` only as a probable per-player delivery destination, not an implemented transport contract.

## Likely Files

- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `.ai/project.md`
- `.ai/decision/`
- `.ai/tasks/current.md`

## Files Touched

- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `.ai/project.md`
- `.ai/decision/2026-09-24-002-runtime-builds-and-project-ownership.md`
- `.ai/decision/latest.md`
- `.ai/decision/latest/runtime-builds-and-project-ownership.md`
- `.ai/tasks/2026-09-24-003-record-runtime-builds-and-project-ownership.md`
- `.ai/tasks/current.md`

## Summary

- Recorded the separate runtime build targets, host capability boundary, compiler packaging, and Rojo/Studio ownership model.
- Clarified that runtime loaders, artifact paths, bootstrap APIs, and asset delivery lifecycle remain intentionally unimplemented.

## Validation

- `.ai/tools/archive-tasks.ps1`: passed; no records were eligible for archival.
- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed.
- No source code changed, so StyLua, naming, runtime build, and Rojo build checks were not applicable.

## Follow-up / Risks

- Design the concrete Rojo topology, runtime build entry points, artifact locations, metadata schema, and bootstrap contract before adding runtime implementation.