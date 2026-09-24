# Project

- importance: 0.98
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Confirmed

- This repository is resetting from a Luau-only static API to an external-tool plus Luau-runtime framework.
- The external tool will own authoring-time bundle discovery, dependency enforcement, import and `require` processing, type information, editor autocomplete support, and intermediate-representation generation.
- The Luau runtime will consume the generated intermediate representation and own Roblox-specific runtime behavior.
- Framework releases package the portable authoring compiler for the Lune/VS Code host and Studio plugin. Generated projects receive compiled runtime artifacts rather than authoring-time tooling.
- The VS Code/Lune host and Studio plugin are thin capability hosts. They translate platform events, expose explicit native capabilities, and apply platform-specific results without exposing native values to portable authoring code.
- Rojo filesystem-to-Studio synchronization is the filesystem-owned workflow. Rojo-managed scripts are authored on disk, and the Studio plugin is read-only for that project: it must not create, update, move, or remove managed objects.
- `tooling/` contains repository development tools. It may use Lune host APIs but is excluded from framework/runtime packages and production Rojo mappings.
- `src/framework/` is the portable, pure-Luau framework root. It may not use Roblox APIs, services, `Instance`, `task`, Lune APIs, or `src/runtime/`.
- `src/runtime/` is the Roblox-only runtime root. It may use Roblox APIs and may depend on `src/framework/`; dependencies do not flow in the other direction.
- Future runtime output has `shared`, `server`, and `client` build targets. Server and client targets may depend on shared code only; shared code may depend on neither runtime realm and server/client targets may not depend on each other.
- Dedicated VS Code workspace files isolate Luau-LSP analysis: tooling and framework use the standard platform, and runtime uses the Roblox platform. They must be opened in separate windows because Luau-LSP selects one platform per window.
- Internal package imports use relative string paths with `/`, `./` or `../`, no `.luau` suffix, and directory resolution through `init.luau`.
- Stack currently retained: Roblox, strict Luau when runtime code is added, Rojo, Git, Aftman, StyLua, and Lune for portable authoring-tool execution. Selene is removed.
- `src/framework/` now has an early portable baseline: `Framework` owns a `Workspace`; `Protocol` supplies root/child/source access and a change signal; `SnapshotProtocol` adapts an in-memory JSON-compatible snapshot.
- `tooling/lune/main.luau` currently reads a JSON snapshot from standard input, constructs `SnapshotProtocol` and `Framework`, and has no stable public output protocol.
- `tooling/lune/build-windows.ps1` bundles project-relative imports with DarkLua 0.19.0, preserves `@lune/**` imports, and builds `bin/lune-main.exe` for `windows-x86_64` through Lune 0.10.5. The generated `bin/lune-main.luau` and executable are ignored host-distribution artifacts.
- Project metadata will explicitly record ownership, framework/runtime build version, schema version, and project identity. Studio-owned projects may be changed by the plugin; ambiguous ownership must safely default to read-only behavior.
- `example.project.json` and `package.project.json` are currently deleted in the working tree, so Rojo build validation is blocked until project files are restored or replaced.

## Architecture Boundary

- The external tool is the authoritative authoring-time analysis layer.
- The intermediate representation must be simple, deterministic, and validated before runtime consumption.
- The Luau runtime must not repeat project discovery, dependency analysis, import resolution, or authoring-time type generation.
- Shared framework code must use platform-neutral, serializable inputs and results; it must not directly depend on VS Code, Node.js, Roblox services, `Instance`, `plugin`, or Lune values.
- Dependency-first acyclic composition, narrow public boundaries, explicit ownership, and server authority remain framework principles.
- Bundles will use framework-only dependency declarations that are removed from generated runtime output. Authoring may later provide a custom Studio widget or visual editor, but the exact syntax and storage are not implemented.
- Bundle scripts will distinguish explicit entries, private modules, and public APIs, with `server` and `shared` realms. Server code may consume server or shared code; shared code may consume shared code only.
- The authoring tool will resolve framework imports into generated IDs and enforce dependency/API/realm access before runtime generation.
- Client entries are intended to be explicit execution and exposure boundaries. Starting an entry for a player authorizes generated client code; eligible assets may be delivered lazily and removed after their server-authoritative grants end.
- The tool will attempt whole-project provenance analysis for `asset()` keys through client values, framework networking, and authoritative server state mutations. It must fail closed when it cannot prove eligibility or removal.
- A server-only policy fallback may authorize an otherwise unproven asset grant and revoke its own scoped, reference-counted grant through `context:revoke()`.
- Networking may use generated optimized codecs for proven payloads and supported raw Roblox serialization otherwise; unsupported network values must be reported and client-to-server values remain server-validated.

## Explicit Boundary

- No stable external-tool interface, host capability contract, intermediate schema, runtime API, loader, lifecycle, dependency resolution, networking, or client asset exposure is implemented yet.
- The removed `manifest()` / `define()` / `bundle.require()` static API is not current or supported.
- Exact Rojo project topology, capability names, public CLI, generated runtime-output location, intermediate serialization, runtime lifecycle, bootstrap contract, metadata schema, and asset-delivery lifecycle require separate design decisions. Per-root strict `.luaurc` files and dedicated Luau-LSP workspace platform settings are configured.

## Workflow

- Run `aftman install`, StyLua and naming checks for applicable source directories, and both basic Rojo builds when Rojo project files are available before publishing changes.
- Maintain only compact framework-specific AI memory under `.ai/`.