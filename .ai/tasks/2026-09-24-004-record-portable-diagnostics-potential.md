# Record Portable Diagnostics Potential

- Status: completed
- importance: 0.72
- confidence: 0.8
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Record a potential, non-binding future feature for framework diagnostics without publishing or implementing it.

## Context

- Generated runtime output may eventually need bundle-oriented error locations, tracebacks, and monitoring information that are more useful than raw generated-script locations.
- The framework direction requires portable code to use serializable inputs and results, while Studio and VS Code remain thin host adapters.
- A Studio plugin can observe Studio output and render a docked diagnostics view, but it cannot replace native Studio Output or globally rewrite Roblox traceback messages.

## Decisions

- Treat portable diagnostics as a potential feature, not a confirmed architecture decision or public API.
- If pursued, separate versioned runtime diagnostic events, semantic view models, and host actions rather than defining a cross-platform pixel/UI toolkit.
- A future Studio plugin may render diagnostics locally and optionally relay structured development-session events to a loopback-only local bridge for a VS Code host.
- Any bridge must be optional, independently reconnectable, bounded, version-negotiated, project-scoped, and authenticated with a per-session token. It must not execute arbitrary received commands.
- Structured runtime events and compiler-generated source mappings should be the primary data source; passively observed Studio output is supplementary and must not be parsed as the authoritative protocol.

## Likely Files

- `src/framework/`
- `src/runtime/`
- `tooling/`
- `editors/vscode/`
- future Studio-plugin host source

## Files Touched

- `.ai/tasks/2026-09-24-004-record-portable-diagnostics-potential.md`
- `.ai/tasks/current.md`

## Summary

- Recorded an exploratory portable diagnostics/view-model direction with optional Studio-to-VS Code live development streaming.
- Preserved current boundaries: no diagnostics protocol, source-map schema, local bridge, Studio plugin, VS Code view, or runtime instrumentation is implemented or publicly documented.

## Validation

- `.ai/tools/archive-tasks.ps1`: passed before recording.
- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed.

## Follow-up / Risks

- Design the diagnostic event schema, mapping metadata, runtime capture boundaries, host capabilities, transport ownership, consent/permissions, and production behavior together before implementation.
- Do not promote this record to `.ai/decision/` or public documentation until the feature scope and contracts are confirmed.