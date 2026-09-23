# Decision: Compiler-Inferred Client Asset Exposure

- Date: 2026-09-23
- Topic: Client asset exposure, eligibility, and runtime delivery
- Decision: The authoring tool will analyze the complete bundle project to trace compile-time `asset()` references and their keys through client code, framework networking, and authoritative server state. When it proves the relationship, generated runtime output will acquire and release per-player asset grants as the tracked server state changes. Client entries are explicit code and exposure boundaries: starting an entry grants its client code, while assets are delivered lazily only after server authorization. When the compiler cannot prove eligibility or revocation, compilation must fail unless the author supplies a server-only `asset(...):on(...)` policy. A policy can authorize a scoped grant and later call `context:revoke()`; that operation revokes only its own grant and is idempotent. All grants are server-authoritative and reference counted.
- Reason: Whole-project provenance analysis can make ordinary, statically traceable asset use automatic while minimizing client exposure. A fail-closed policy fallback handles dynamic or opaque state without trusting client requests. Scoped grants preserve cleanup and sharing semantics when multiple entries or policies need the same asset.
- importance: 1.0
- confidence: 0.96
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Consequences

- The tool must analyze imports, calls, field-level values, network boundaries, and authoritative collection mutations rather than infer behavior from function or variable names.
- Proven eligibility examples include an asset key derived from an item replicated from a framework-managed inventory whose server additions and removals are fully traceable.
- The runtime consumes generated IDs, eligibility relationships, and mutation hooks; it does not rediscover source dependencies or perform authoring-time analysis.
- Dynamic asset paths, values that escape into unproven code, and untraceable mutations fail closed. A policy may authorize requests, and explicit `context:revoke()` supplies a removal signal when automatic revocation cannot be inferred.
- A policy is emitted only into server output. It may access permitted server-side bundle code and server-owned context, but cannot capture client-only runtime values, trust client claims, or revoke another policy's grant.
- A client asset request identifies generated asset and session data only. The server validates active entry/session state, generated allowlists, policy results, request limits, and lifecycle generation before delivery.
- Delivered client content can be inspected or extracted by a determined client. This architecture minimizes who receives content and when; it does not make delivered code or assets secret.
- Networking may use generated optimized codecs when payload shape is proven. Otherwise it falls back to supported Roblox remote serialization, reports unsupported runtime values, and still validates all client-to-server input on the server.
- The exact intermediate schema, generated package location, concrete runtime APIs, transport, replication containers, and policy syntax remain implementation design work.