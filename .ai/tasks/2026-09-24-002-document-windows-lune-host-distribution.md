# Document Windows Lune Host Distribution

- Status: completed
- importance: 0.8
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Synchronize public documentation and compact project memory with the implemented portable framework baseline and Windows standalone Lune host build.

## Context

- The prior README described `src/framework/` as future-only and left deployment details open even though the snapshot protocol, framework baseline, and executable build were committed.
- The checked-in build driver bundles relative imports, preserves Lune host imports, and emits ignored Windows x64 artifacts under `bin/`.

## Decisions

- Document the executable as a current Windows host-distribution artifact, not a finalized public CLI, generated-runtime contract, or Roblox deployment mechanism.
- Record the build boundary in a new append-only durable decision and route it through the latest-decision index.

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
- `.ai/decision/2026-09-24-001-windows-lune-host-build-distribution.md`
- `.ai/decision/latest.md`
- `.ai/decision/latest/windows-lune-host-build.md`
- `.ai/tasks/2026-09-24-002-document-windows-lune-host-distribution.md`
- `.ai/tasks/current.md`

## Summary

- Documented the current framework baseline, JSON snapshot input, build command, generated artifact paths, Windows x64 target, and VS Code task.
- Clarified the boundary between the implemented host executable and still-undesigned public CLI, runtime-output, and Roblox deployment contracts.
- Added durable distribution memory without changing the earlier project-installed source and thin-host architecture decision.

## Validation

- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed.
- `tooling/lune/build-windows.ps1`: passed; regenerated the ignored resolved bundle and Windows x64 executable.
- Executable smoke test with `{"roots":[],"items":[]}` on standard input: passed.

## Follow-up / Risks

- Update this record and supersede the build decision when the executable protocol, targets, artifact publishing, or host ownership becomes stable.