# Project

- importance: 0.98
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-22T00:00:00Z

## Confirmed

- This repository is resetting from a Luau-only static API to an external-tool plus Luau-runtime framework.
- The external tool will own authoring-time bundle discovery, dependency enforcement, import and `require` processing, type information, editor autocomplete support, and intermediate-representation generation.
- The Luau runtime will consume the generated intermediate representation and own Roblox-specific runtime behavior.
- Framework consumers will install the shared core, authoring-time tooling, and runtime as Luau source in their projects.
- The VS Code extension and Studio plugin will be thin hosts for the project's Luau tooling. They translate platform events, expose explicit native capabilities, and apply platform-specific results.
- Rojo filesystem-to-Studio synchronization is the supported development workflow for shared source. Rojo-managed scripts are authored on disk; tooling is excluded from production mappings.
- `src/`, `examples/`, and `tooling/` are intentionally empty scaffold directories.
- Stack currently retained: Roblox, strict Luau when runtime code is added, Rojo, Git, Aftman, and StyLua. Selene is removed.
- `example.project.json` and `package.project.json` are intentionally blank but valid Rojo scaffolds.

## Architecture Boundary

- The external tool is the authoritative authoring-time analysis layer.
- The intermediate representation must be simple, deterministic, and validated before runtime consumption.
- The Luau runtime must not repeat project discovery, dependency analysis, import resolution, or authoring-time type generation.
- Shared core and tooling must use platform-neutral, serializable inputs and results; they must not directly depend on VS Code, Node.js, Roblox services, `Instance`, or `plugin` values.
- Dependency-first acyclic composition, narrow public boundaries, explicit ownership, and server authority remain framework principles.
- Bundles will use framework-only dependency declarations that are removed from generated runtime output. Authoring may later provide a custom Studio widget or visual editor, but the exact syntax and storage are not implemented.
- Bundle scripts will distinguish explicit entries, private modules, and public APIs, with `server` and `shared` realms. Server code may consume server or shared code; shared code may consume shared code only.
- The authoring tool will resolve framework imports into generated IDs and enforce dependency/API/realm access before runtime generation.
- Client entries are intended to be explicit execution and exposure boundaries. Starting an entry for a player authorizes generated client code; eligible assets may be delivered lazily and removed after their server-authoritative grants end.
- The tool will attempt whole-project provenance analysis for `asset()` keys through client values, framework networking, and authoritative server state mutations. It must fail closed when it cannot prove eligibility or removal.
- A server-only policy fallback may authorize an otherwise unproven asset grant and revoke its own scoped, reference-counted grant through `context:revoke()`.
- Networking may use generated optimized codecs for proven payloads and supported raw Roblox serialization otherwise; unsupported network values must be reported and client-to-server values remain server-validated.

## Explicit Boundary

- No external tool, host capability contract, intermediate schema, runtime API, loader, lifecycle, dependency resolution, networking, or client asset exposure is implemented yet.
- The removed `manifest()` / `define()` / `bundle.require()` static API is not current or supported.
- Package layout, capability names, CLI, configuration, generated-output location, intermediate serialization, and runtime lifecycle require separate design decisions.

## Workflow

- Run `aftman install`, StyLua checks for applicable source directories, and both basic Rojo builds before publishing changes.
- Maintain only compact framework-specific AI memory under `.ai/`.