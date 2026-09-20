# Summary: Static Bundle API

- importance: 0.92
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-21T00:00:00Z
- Source Paths: `src/`
- Last Verified: 2026-09-21

## Purpose

Provides compile-time manifest validation, bundle declaration validation, and typed access to declared dependency API tables.

## Important Files

- `src/init.luau`: public `manifest()` entry point and temporary typed `define()` implementation.
- `src/types.luau`: static manifest, declaration, and bundle object types.
- `src/type_helpers.luau`: type functions for structural validation and overload generation.

## Public Interfaces

- `framework.manifest(value)`.
- The typed `define(description)` returned by `manifest()`.
- `bundle.require(bundle_name, api_name)` on a defined bundle object.

## Invariants

- The public contract is types-only.
- A dependency/API pair must be declared by the bundle description and manifest.

## Dependencies

- Roblox Luau type functions and the new type solver.

## Data Flow

Manifest values inform generic types; declared dependency entries are traversed into intersected `require()` overloads.

## Operational Notes

`define()` currently returns an empty table cast to the derived bundle object type. It has no runtime resolution behavior.

## Related Systems

- `example.project.json` serves the generic example sourced from `examples/basic/`; `package.project.json` builds the package alone.

## Update Triggers

- Changes to public types, type functions, the generic example, or runtime behavior.