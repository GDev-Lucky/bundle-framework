# Task: Add VS Code Build Target Selector

- Status: completed
- importance: 0.65
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Let developers choose whether VS Code compiles the extension, compiles Luau, tests the extension, or runs the combined build instead of implicitly running every build target.

## Context

- Root npm scripts already expose `compile:extension`, `compile:luau`, `test:extension`, and `build`.
- VS Code already exposes direct tasks for the individual operations but has no default prompted build task.

## Decisions

- Add a default build task backed by a VS Code `pickString` input.
- Keep the existing direct extension, Luau, and extension-test tasks for quick repeated execution.
- Retain the combined `build` script as an explicit selector option rather than removing it.

## Likely Files

- `.vscode/tasks.json`
- `.ai/tasks/`

## Files Touched

- `.vscode/tasks.json`
- `.ai/tasks/2026-09-24-011-add-vscode-build-target-selector.md`
- `.ai/tasks/current.md`

## Summary

- Added a default VS Code build task that prompts for extension compilation, Luau compilation, extension testing, or the combined build.
- Preserved the existing direct tasks for quickly rerunning a specific target.

## Validation

- Passed: parsed .vscode/tasks.json with PowerShell JSON conversion.
- Passed: verified each selector option maps to an existing root npm script.
- Passed: .ai/tools/validate-workflow.ps1.
- Passed: git diff --check.

## Follow-up / Risks

- VS Code displays npm script identifiers in the selector because `pickString` task inputs use string options.
