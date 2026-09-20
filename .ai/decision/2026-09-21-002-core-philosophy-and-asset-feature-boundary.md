# Decision: Core Philosophy and Client Asset Feature Boundary

- Date: 2026-09-21
- Topic: Bundle architecture
- Decision: The framework core owns dependency-first, acyclic bundle composition; explicit declarations and entry points; manifest-driven type composition; and narrow public API boundaries. Client asset exposure is not a core framework concern. It must be provided by a separate optional Bundle feature through that feature's own public API.
- Reason: Composition and contract boundaries are reusable framework concerns. Lease accounting, asset selection, replication, client reconstruction, delivery metadata, and removal policies are domain-specific feature behavior with different operational and security requirements.
- importance: 0.99
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-21T00:00:00Z

## Core Direction

- Bundle dependency graphs must remain acyclic.
- Bundles declare dependencies explicitly and consume only declared public API partitions.
- Private implementation modules are not cross-bundle dependencies.
- Explicit entries are the only modules eligible for any future lifecycle handling.
- A future runtime must preserve server authority and must never trust client-provided state.

## Excluded Feature Behavior

- Client asset exposure, leasing, replication, delivery metadata, dependency masks, reconstruction, and removal are not core APIs or runtime obligations.
- A feature Bundle may implement those concerns later without making them required for ordinary bundles or core framework adoption.