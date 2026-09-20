# Decision: Core Owns Client Asset Exposure

- Date: 2026-09-21
- Topic: Bundle architecture
- Decision: Client asset exposure is part of the Bundle Framework core architecture. A future core runtime will own server-authoritative asset selection, exposure, delivery metadata, client reconstruction support, and removal behavior. This supersedes the asset-boundary portion of `2026-09-21-002-core-philosophy-and-asset-feature-boundary.md`; its remaining composition principles still apply.
- Reason: Asset declarations are already part of bundle descriptions, and exposure is now intended to be a consistent framework capability rather than an independently installed feature Bundle. Core ownership keeps declaration, authority, delivery policy, and lifecycle integration under one framework contract.
- importance: 0.99
- confidence: 1.0
- createdAt: 2026-09-21T12:00:00Z
- lastUsedAt: 2026-09-21T12:00:00Z

## Core Direction

- Client asset exposure belongs to the framework core rather than to an optional feature Bundle.
- Any exposure mechanism must preserve server authority and must not trust client-provided state.
- Concrete APIs, lifecycle rules, replication mechanisms, dependency masks, lease semantics, reconstruction behavior, and removal policy require separate design and validation before documentation may describe them as implemented.
- The current repository remains a static typing contract and does not yet perform client asset exposure or other runtime behavior.

## Preserved Principles

- Bundle dependency graphs remain explicit and acyclic.
- Bundles consume declared public API partitions rather than private implementation modules.
- Explicit entries remain the only candidates for future lifecycle handling.