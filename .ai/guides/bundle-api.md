# Guide: Bundle API

- importance: 0.96
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-21T00:00:00Z
- Last Verified: 2026-09-21

## Scope

Applies to `src/` and the generic example. It does not define runtime behavior.

## Guidance

- Use `framework.manifest({...})` to create an inferred manifest and typed `define()` function.
- Bundle descriptions contain `entries`, `dependencies`, and `assets`.
- Dependencies must reference manifest entries.
- Call `bundle.require("dependency_name", "api_partition")` only for declared dependencies and existing public API partitions.
- Keep dependency graphs acyclic and require other bundles only through their declared public API partitions.
- Treat explicit `entries` as the only candidates for any future lifecycle behavior; private implementation modules are never implicit entries.
- Keep the API types-first: do not imply `define()` returns a working runtime object.
- Client asset exposure is not a framework-core responsibility. If needed, provide it through a separate feature Bundle and consume that Bundle's public API.
- Luau LSP may offer broad second-argument completion across overloaded dependency APIs; diagnostics and return inference remain authoritative.

## Rationale

The direct manifest-and-definition pairing retains the author-provided structure needed to derive precise dependency API types without generated code. Explicit dependencies and public partitions keep bundle ownership clear while allowing optional features to evolve independently of the core.

## References

- `src/init.luau`
- `src/types.luau`
- `src/type_helpers.luau`
- `examples/basic/src/manifest.luau`

## Update Triggers

- Public API shapes change.
- Type-function behavior changes.
- A runtime is implemented.
- The client asset exposure feature boundary changes.
- Luau LSP behavior changes materially.