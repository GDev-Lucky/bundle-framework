# Summary: Repository Build System

- importance: 0.92
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z
- Source Paths: `tooling/build.ps1`, `tooling/readBuildManifest.luau`, `src/framework/build.luau`, `src/runtime/build.luau`, `tooling/lune/build.luau`, `tooling/linter/build.luau`

## Purpose

Discover buildable projects from local manifests and coordinate Luau, native, TypeScript, VSIX, and installation operations.

## Important Files

- `tooling/build.ps1` discovers projects, selects operations/platforms, builds artifacts, packages extensions, and installs test VSIX files.
- `tooling/readBuildManifest.luau` validates and serializes manifest fields.
- Each project-local `build.luau` declares entries, extension roots, and native platforms.

## Interface

`tooling/build.ps1 <path> <luau|extension|complete|test> [platform]`; omitted arguments enable interactive selection.

## Invariants

- Discovery ignores `.git`, `node_modules`, and `build`.
- Manifest fields are unique arrays of non-empty strings.
- Projects stay inside the repository.
- Generated output remains under ignored `build/` subdirectories.
- Extension packaging uses compiled JavaScript and copies built native entries into the VSIX `bin/` directory.

## Dependencies

PowerShell, Lune, DarkLua, npm workspace tooling, VSCE, and VS Code CLI for installation tests.

## Data Flow

Requested path → discovered manifests → validated JSON metadata → selected operation/platform → generated Luau/native/JavaScript artifacts → optional VSIX package and install.

## Operational Notes

Current native manifests declare `windows-x86_64`. The root `npm run build` performs a recursive complete build.

## Update Triggers

Manifest schema, operations, artifact layout, platform support, project discovery, or extension packaging changes.

## Last Verified

2026-09-24