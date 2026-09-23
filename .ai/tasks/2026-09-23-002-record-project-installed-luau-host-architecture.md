# Record Project-Installed Luau Host Architecture

- Status: completed
- importance: 0.98
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Description

Record the confirmed framework distribution and editor-host architecture.

## Context

- The framework remains an external authoring layer plus a Roblox runtime.
- The user confirmed that framework consumers install the Luau source in their project.
- The user confirmed that VS Code and Studio should host the same authoring-time Luau tooling, while Roblox executes the runtime.
- Rojo is the normal development path for reflecting filesystem edits in Studio.

## Decisions

- Divide installed source into shared core, authoring-time tooling, and runtime areas.
- Make the VS Code extension and Studio plugin thin platform adapters around the project's Luau tooling.
- Keep native host values out of shared code and expose only explicit capabilities plus normalized serializable data.
- Keep authoring tooling out of production game mappings and retain filesystem-to-Studio Rojo synchronization as the source workflow.

## Likely Files

- `README.md`
- `.ai/project.md`
- `.ai/decision/`
- `.ai/tasks/current.md`

## Files Touched

- `README.md`
- `.ai/project.md`
- `.ai/decision/2026-09-23-002-project-installed-luau-tooling-hosts.md`
- `.ai/decision/latest.md`
- `.ai/decision/latest/tool-runtime-boundary.md`
- `.ai/tasks/2026-09-23-002-record-project-installed-luau-host-architecture.md`
- `.ai/tasks/current.md`

## Summary

- Recorded project-installed shared Luau core, tooling, and runtime source.
- Recorded thin VS Code and Studio host adapters and their portability boundary.
- Recorded Rojo filesystem-to-Studio development flow and exclusion of tooling from production mappings.

## Validation

- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed; only existing LF-to-CRLF conversion warnings were reported.

## Follow-up / Risks

- Define the package layout, host capability contract, intermediate representation, generated-output ownership, and runtime API before implementation.