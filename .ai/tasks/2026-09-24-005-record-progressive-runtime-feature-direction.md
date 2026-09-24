# Record Progressive Runtime Feature Direction

- Status: completed
- importance: 0.9
- confidence: 0.96
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Record the confirmed direction for optional managed assets, native Roblox interoperability, generated client placement, typed primitives, and structured development output without changing public documentation or implementation.

## Context

- The framework's asset-exposure system is a core differentiator, but ordinary Roblox Instance/service access must remain available for gradual adoption and unmanaged projects.
- Generated client placement, managed code delivery, and asset exposure solve separate problems and must not force one another.
- The future development tool needs richer, source-aware output and benchmarks than raw formatted console text can provide.

## Decisions

- Preserve native Roblox/Luau access and make compiler-aware features additive opt-ins.
- Support future unmanaged, preload-all, manual, and compiler-managed asset modes independently from client placement and delivery modes.
- Permit future conventional generated DataModel placement and automatic client bootstrapping while preserving project ownership rules.
- Direct future typed networking, local event/signal, registry aggregation, and structured development-output work through explicit compiler/runtime contracts.

## Likely Files

- `.ai/decision/`
- `.ai/tasks/current.md`
- future `src/framework/`
- future `src/runtime/`
- future `tooling/`
- future host integrations

## Files Touched

- `.ai/decision/2026-09-24-003-progressive-runtime-features-and-structured-development-output.md`
- `.ai/decision/latest.md`
- `.ai/decision/latest/client-asset-exposure.md`
- `.ai/decision/latest/progressive-runtime-features-and-development-output.md`
- `.ai/tasks/2026-09-24-005-record-progressive-runtime-feature-direction.md`
- `.ai/tasks/current.md`

## Summary

- Recorded an additive, independently configurable feature direction while preserving normal Roblox development patterns.
- No public documentation, runtime source, tooling source, or generated output changed.

## Validation

- `.ai/tools/archive-tasks.ps1`: passed; no records were eligible for archival.
- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed.
- No source code changed, so StyLua, naming, runtime build, and Rojo build checks were not applicable.

## Follow-up / Risks

- Design public configuration, generated layouts, runtime APIs, source mappings, and instrumentation semantics together before implementation.
- Keep native access distinct from compiler-recognized contracts so unsupported dynamic behavior degrades clearly instead of appearing managed.
