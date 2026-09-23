# Record Compiler-Inferred Asset Exposure Design

- Status: completed
- importance: 0.98
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Description

Record the confirmed asset-eligibility, lazy-delivery, policy-fallback, and revocation architecture without implementing runtime behavior.

## Context

- Client asset exposure is a future core-runtime responsibility and must remain server-authoritative.
- The project is an architectural scaffold; its tool, IR, runtime, networking, and asset system are not implemented.
- The user confirmed compiler provenance analysis as the normal path and server-only policy revocation as the fallback.

## Decisions

- Trace asset keys through client/network/server value flow and authoritative mutations rather than function names.
- Use client entries as code and exposure boundaries, lazy server-authorized delivery, and reference-counted scoped grants.
- Fail closed when eligibility cannot be proven; allow server-only `asset(...):on(...)` policies and idempotent `context:revoke()` for explicit lifecycle control.
- Permit raw supported remote serialization only when optimized payload encoding cannot be proven; diagnose unsupported network values and retain server validation.

## Likely Files

- `.ai/project.md`
- `.ai/decision/`
- `.ai/tasks/`
- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`

## Files Touched

- `.ai/decision/2026-09-23-003-compiler-inferred-asset-exposure.md`
- `.ai/decision/latest.md`
- `.ai/decision/latest/client-asset-exposure.md`
- `.ai/project.md`
- `.ai/tasks/2026-09-23-003-record-asset-exposure-design.md`
- `.ai/tasks/current.md`
- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`

## Summary

- Recorded compiler-inferred asset eligibility as the normal path, including provenance through framework networking and authoritative state mutations.
- Recorded client entries as exposure boundaries, lazy server-authorized delivery, reference-counted grants, and the server-only `asset(...):on(...)` plus `context:revoke()` fallback.
- Updated project memory, current-decision navigation, public architecture documentation, contribution guidance, and changelog without adding runtime implementation.

## Validation

- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed; only existing LF-to-CRLF conversion warnings were reported.
- `stylua --check src examples tooling`: passed.
- `rojo build example.project.json --output <temporary file>`: passed.
- `rojo build package.project.json --output <temporary file>`: passed.

## Follow-up / Risks

- Define the IR schema, authoring syntax, policy restrictions, runtime transport, generated package placement, and replication behavior before implementation.