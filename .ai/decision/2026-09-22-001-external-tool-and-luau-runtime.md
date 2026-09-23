# Decision: External Tool and Luau Runtime Boundary

- Date: 2026-09-22
- Topic: Framework architecture
- Decision: Reset the removed Luau-only static API and develop Bundle Framework as an external authoring/development tool that generates a simple intermediate representation for a Luau runtime to consume. The tool owns bundle discovery, dependency enforcement, import and `require` processing, type information, and editor autocomplete support. The runtime owns only Roblox-specific behavior based on generated output.
- Reason: Authoring-time graph analysis, import processing, and type/editor integration are better handled outside the Roblox runtime. A generated intermediate boundary keeps the Luau runtime smaller, deterministic, and free from duplicated project analysis.
- importance: 1.0
- confidence: 1.0
- createdAt: 2026-09-22T00:00:00Z
- lastUsedAt: 2026-09-22T00:00:00Z

## Consequences

- The former `manifest()` / `define()` / `bundle.require()` contract is removed and superseded.
- `src/`, `examples/`, and `tooling/` remain empty until the replacement contracts are designed.
- The intermediate schema, serialization, generator interface, runtime API, and lifecycle are explicitly future design work.
- Dependency-first acyclic composition, narrow public boundaries, explicit ownership, and server authority remain applicable principles.
- This supersedes the current API and architecture direction in the September 21, 2026 decisions without modifying those append-only historical records.