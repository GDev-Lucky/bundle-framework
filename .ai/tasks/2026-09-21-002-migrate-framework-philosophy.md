# Migrate Core Framework Philosophy

- Status: completed
- importance: 0.96
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-21T00:00:00Z

## Description

Document the reusable Bundle framework philosophy in the standalone repository while keeping client asset exposure out of the framework core.

## Context

- The static API already models manifests, declarations, dependency graphs, and environment-partitioned public APIs.
- Historical design material contains reusable composition principles alongside feature-specific client asset delivery mechanisms.
- Client asset exposure must remain an optional Bundle feature rather than a framework responsibility.

## Decisions

- Preserve dependency-first, acyclic composition; explicit entries; public/private module boundaries; and manifest-driven API typing as core direction.
- Treat runtime orchestration, lifecycle execution, and networking as future optional core-runtime concerns only after deliberate implementation.
- Assign client asset exposure, leases, replication, delivery metadata, and client reconstruction to a separate feature Bundle with a public API.

## Likely Files

- `README.md`
- `AGENTS.md`
- `.ai/project.md`
- `.ai/guides/bundle-api.md`
- `.ai/decision/`
- `.ai/tasks/current.md`

## Files Touched

- `README.md`
- `AGENTS.md`
- `CONTRIBUTING.md`
- `.ai/project.md`
- `.ai/guides/bundle-api.md`
- `.ai/decision/2026-09-21-002-core-philosophy-and-asset-feature-boundary.md`
- `.ai/decision/latest.md`
- `.ai/decision/latest/bundle-architecture.md`
- `.ai/tasks/2026-09-21-002-migrate-framework-philosophy.md`
- `.ai/tasks/current.md`

## Summary

- Migrated reusable Bundle philosophy: dependency-first acyclic composition, narrow public contracts, explicit entries, private implementation boundaries, manifest-driven type composition, and server authority for any future runtime.
- Explicitly excluded client asset exposure from the framework core and assigned that concern to a separate optional feature Bundle with its own public API.
- Added append-only decision history and public documentation for the feature boundary without adding runtime behavior.

## Validation

- `.ai/tools/archive-tasks.ps1`: passed before retrieval.
- `.ai/tools/validate-workflow.ps1`: passed.
- `.ai/tools/archive-tasks.ps1 -CheckOnly`: passed.
- `rojo build examples/basic/default.project.json --output bundle-framework-example.rbxlx`: passed; the ignored artifact was removed.
- `git diff --check`: passed.
- Framework isolation scan: passed; no unrelated application paths or topology terms were found.
- Client-asset scan: passed; every reference explicitly identifies client asset exposure as optional and outside the core.

## Follow-up / Risks

- No runtime implementation is added by this documentation/design update.
- The optional client asset exposure Bundle remains a future feature design and implementation task.