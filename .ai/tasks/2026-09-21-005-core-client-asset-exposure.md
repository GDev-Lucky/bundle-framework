# Move Client Asset Exposure Into Core

- Status: completed
- importance: 0.98
- confidence: 1.0
- createdAt: 2026-09-21T12:00:00Z
- lastUsedAt: 2026-09-21T12:00:00Z

## Description

Update public documentation and project memory so client asset exposure is a core-framework responsibility rather than an optional feature Bundle concern.

## Context

- The current implementation remains a static typing contract and does not perform runtime asset exposure.
- Existing documentation and memory consistently placed client asset exposure outside the core.
- Dated decision records are append-only, so the previous boundary decision must be superseded rather than rewritten.

## Decisions

- Make server-authoritative client asset exposure part of the future core runtime architecture.
- Do not claim that an exposure API, lifecycle, networking mechanism, or runtime implementation currently exists.
- Preserve the existing dependency, public API, explicit-entry, and server-authority principles.

## Likely Files

- `README.md`
- `CONTRIBUTING.md`
- `AGENTS.md`
- `.ai/project.md`
- `.ai/guides/bundle-api.md`
- `.ai/decision/`
- `.ai/tasks/current.md`

## Files Touched

- `README.md`
- `CONTRIBUTING.md`
- `AGENTS.md`
- `.ai/project.md`
- `.ai/guides/bundle-api.md`
- `.ai/decision/2026-09-21-003-core-client-asset-exposure.md`
- `.ai/decision/latest/bundle-architecture.md`
- `.ai/tasks/2026-09-21-005-core-client-asset-exposure.md`
- `.ai/tasks/current.md`

## Summary

- Updated public documentation and maintained project guidance so client asset exposure is a core-framework responsibility for a future runtime.
- Added an append-only decision that supersedes the previous optional-feature boundary without rewriting historical records.
- Preserved the current implementation boundary: no client asset exposure, networking, lifecycle, loader, or runtime dependency resolution is implemented yet.

## Validation

- `.ai/tools/validate-workflow.ps1`: passed.
- `.ai/tools/archive-tasks.ps1 -CheckOnly`: passed.
- Active-guidance scan: passed; no non-historical documentation still assigns client asset exposure to an optional feature Bundle.
- `rojo build example.project.json`: passed with output in the system temporary directory.
- `rojo build package.project.json`: passed with output in the system temporary directory.
- `git diff --check`: passed.
- StyLua and Selene were not run because their executables are not installed in `C:\Users\Lucky\.aftman\bin`; only Aftman and Rojo are currently available.
- No source files were changed by this task; the pre-existing `src/init.luau` modification was preserved.
## Follow-up / Risks

- The core exposure runtime and public API still require separate design, implementation, and validation.