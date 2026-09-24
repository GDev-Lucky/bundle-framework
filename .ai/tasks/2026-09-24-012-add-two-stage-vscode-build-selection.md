# Task: Add Two-Stage VS Code Build Selection

- Status: completed
- importance: 0.72
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Make VS Code first ask which operation to perform and then ask which concrete Luau or extension target should be built or tested.

## Context

- The repository currently has one VS Code extension, the linter extension.
- Luau compilation currently produces both the Lune host executable and the linter executable.
- VS Code task inputs cannot conditionally change one picker based on another picker value.

## Decisions

- Represent the first stage with three build tasks: compile Luau, compile extension, and test extension.
- Give each operation its own target-specific `pickString` input.
- Preserve broad root npm scripts while allowing the build coordinator to execute one concrete target.
- Name the current Lune executable target `Lune VS Code host`; it is not yet a standalone VS Code extension package.

## Likely Files

- `.vscode/tasks.json`
- `tooling/build.ps1`
- `.ai/tasks/`

## Files Touched

- `.vscode/tasks.json`
- `tooling/build.ps1`
- `.ai/tasks/2026-09-24-012-add-two-stage-vscode-build-selection.md`
- `.ai/tasks/current.md`

## Summary

- Replaced the single broad build selector with separate Compile Luau, Compile extension, and Test extension build tasks.
- Added operation-specific target pickers and target-aware build routing so unrelated targets are not built.
- Preserved the existing root npm scripts with their all-target behavior.

## Validation

- Passed: PowerShell parser check for tooling/build.ps1.
- Passed: VS Code task JSON and required picker validation.
- Passed: npm run compile:extension backward-compatibility build.
- Passed: individual Linter executable Luau build and smoke test.
- Passed: individual Lune VS Code host build.
- Passed: selected linter extension build, VSIX packaging, and forced local installation.
- Passed: git diff --check.
- Passed: .ai/tools/validate-workflow.ps1.

## Follow-up / Risks

- The extension pickers currently contain only the linter extension plus an all-extensions option; future extension packages must be added to the coordinator and picker lists.
