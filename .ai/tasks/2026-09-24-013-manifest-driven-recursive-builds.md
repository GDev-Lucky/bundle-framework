# Task: Add Manifest-Driven Recursive Builds

- Status: completed
- importance: 0.9
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Replace target-specific Windows build and packaging scripts with one generic build coordinator that discovers buildable projects and extensions from project-local manifests.

## Context

- Native VS Code tasks cannot dynamically scan the filesystem to populate picker options.
- The linter check must validate the compiled executable rather than execute the Luau source CLI.

## Decisions

- Use one `build.luau` per project to declare entries, extension roots, and platforms.
- Use `tooling/build.ps1 <path> <operation> [platform]` for automation and no-argument interactive selection for VS Code.
- Derive artifact names from entry paths and preserve project/platform directories under `build/`.
- Make `npm run check`, the VS Code lint task, and CI build and invoke the compiled linter executable.

## Likely Files

- `tooling/build.ps1`
- `tooling/readBuildManifest.luau`
- project `build.luau` manifests
- `.vscode/tasks.json`
- root npm and CI configuration

## Files Touched

- `tooling/build.ps1`
- `tooling/readBuildManifest.luau`
- project `build.luau` manifests
- root npm, CI, VS Code task, workspace, documentation, and decision records

## Summary

- Removed per-target build/package PowerShell scripts.
- Added recursive manifest and nested-extension discovery, all-platform default behavior, optional platform filtering, VSIX staging, and extension installation.
- Replaced fixed VS Code target tasks with generic interactive build tasks.

## Validation

- Passed: PowerShell parser, manifest parsing, project and recursive all-platform builds, TypeScript compilation, VSIX packaging with `bin/cli.exe`, compiled-binary linter check, and VSIX installation.
- Passed: JSON validation for task/workspace/package configuration, targeted StyLua check for new Luau files, `git diff --check`, and `.ai/tools/validate-workflow.ps1`.

## Follow-up / Risks

- Native executable packaging currently targets Windows x64 because the manifests currently declare only `windows-x86_64`.