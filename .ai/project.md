# Project

- importance: 0.95
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-21T00:00:00Z

## Confirmed

- This repository publishes an experimental, types-first Roblox Bundle API.
- Stack: strict Luau, Rojo, Git, Aftman, Selene, and StyLua.
- `src/init.luau` exposes `framework.manifest(value)` and the typed `define()` function.
- `src/types.luau` defines manifest and bundle declaration types, including typed dependency access through `bundle.require(bundle_name, api_name)`.
- `src/type_helpers.luau` supplies the type functions used by the API.
- `example.project.json` is the root-level generic Rojo validation and serving project; `examples/basic/` contains its source.
- `package.project.json` maps only `src/` for package consumers.

## Framework Philosophy

- Bundles compose through explicit, acyclic dependency graphs.
- A bundle exposes narrow public API partitions; other bundles do not require its private implementation modules.
- Explicit entries define the boundary for any future lifecycle behavior; ordinary implementation modules remain ordinary modules.
- A future runtime must preserve server authority and never trust client-provided state.
- Client asset exposure is an optional feature Bundle concern, not a core framework service or requirement.

## Explicit Boundary

- The current implementation is a static typing contract.
- It does not implement runtime loading, lifecycle execution, dependency resolution, networking, or client asset exposure.

## Workflow

- Run `aftman install`, then StyLua, Selene, and the basic Rojo build before publishing changes.
- Maintain only compact framework-specific AI memory under `.ai/`.