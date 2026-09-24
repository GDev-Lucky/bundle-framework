# Project

- importance: 0.98
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Current State

- Bundle Framework is an early external-authoring-tool plus Luau-runtime project. The removed `manifest()` / `define()` / `bundle.require()` API is not current.
- `src/framework/` contains a portable strict-Luau baseline: `Framework` owns a `Workspace`; `Protocol` defines host item access and change signaling; `SnapshotProtocol` adapts JSON-compatible snapshots.
- `src/runtime/` is reserved for Roblox-only runtime behavior and currently has no runtime entry.
- `tooling/lune/main.luau` reads a JSON snapshot from standard input, constructs the portable framework, and has no stable public output protocol.
- `tooling/linter/` contains the project-owned Luau naming analyzer, CLI, tests, and strict-TypeScript VS Code adapter.
- `tooling/build.ps1` recursively discovers project-local `build.luau` manifests and coordinates Luau builds, extension builds, packaging, and installation tests.
- Generated artifacts are ignored under `build/js/`, `build/luau/`, `build/bin/<platform>/`, and `build/vsix/`. Current native manifests target Windows x64.
- The repository uses a root npm workspace for the linter extension. `npm run check` builds and runs the compiled linter executable.
- `example.project.json` and `package.project.json` are absent in the current working tree, so the documented Rojo build checks are unavailable until project files are restored or replaced.

## Boundaries

- The external tool will own authoring-time bundle discovery, dependency enforcement, import and `require` processing, type information, editor autocomplete support, and intermediate-representation generation.
- The Luau runtime will consume the generated intermediate representation and own Roblox-specific runtime behavior.
- `tooling/` contains repository development tools. It may use Lune host APIs but is excluded from framework/runtime packages and production Rojo mappings.
- `src/framework/` is the portable, pure-Luau framework root. It may not use Roblox APIs, services, `Instance`, `task`, Lune APIs, or `src/runtime/`.
- `src/runtime/` is the Roblox-only runtime root. It may use Roblox APIs and may depend on `src/framework/`; dependencies do not flow in the other direction.
- Dedicated VS Code workspace files isolate Luau-LSP analysis: tooling and framework use the standard platform, and runtime uses the Roblox platform. They must be opened in separate windows because Luau-LSP selects one platform per window.
- Internal package imports use relative string paths with `/`, `./` or `../`, no `.luau` suffix, and directory resolution through `init.luau`.

## Confirmed Direction

- Framework releases package the portable compiler with thin Lune/VS Code and Studio hosts. Generated projects receive runtime artifacts, not authoring tooling.
- The VS Code/Lune host and Studio plugin translate native events and capabilities without exposing native values to portable authoring code.
- Rojo-managed projects are filesystem-owned and read-only to the Studio plugin. Studio-owned projects may be changed only through explicit plugin capabilities.
- Future runtime output has shared, server, and client targets with one-way realm dependencies and server authority.
- Dependency-first acyclic composition, narrow public boundaries, explicit ownership, fail-closed client asset exposure, and server validation remain architectural principles.

## Not Yet Defined

- No stable public tool interface, host capability contract, intermediate schema, generator format, runtime API, loader, lifecycle, networking protocol, asset-delivery lifecycle, or production deployment topology exists.
- Exact bundle syntax, metadata schema, generated placement, Studio authoring experience, and public CLI require explicit design decisions before implementation.

## Working Practice

- Treat source and configuration as authoritative; use memory as navigation.
- Validate applicable Luau with StyLua and the compiled project linter, run Rojo checks only when project files exist, then run `git diff --check` and `.ai/tools/validate-workflow.ps1`.