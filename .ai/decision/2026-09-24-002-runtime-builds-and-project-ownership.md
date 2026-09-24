# Decision: Runtime Builds and Project Ownership

- Date: 2026-09-24
- Topic: Runtime artifact targets, host capabilities, and Rojo/Studio ownership
- Decision: Bundle Framework releases will package the portable authoring framework/compiler for the Lune/VS Code host and the Roblox Studio plugin host. Generated projects will receive compiled Roblox runtime artifacts rather than authoring-tool source. The runtime has separate `shared`, `server`, and `client` build targets: server and client targets may depend on shared code; shared code may not depend on either realm; and server/client targets may not depend on one another. The portable authoring framework exposes operations through explicitly supplied host capabilities. The Lune host may manage filesystem source, Rojo configuration, Luau-LSP configuration, generated output, runtime artifacts, and bootstrap files. The Studio plugin may manage equivalent DataModel objects only for Studio-owned projects. A Rojo-owned project is filesystem-authoritative and puts the Studio plugin in read-only mode: it may inspect, diagnose, and navigate but must not create, update, move, or remove managed project objects. Project metadata explicitly records the owner, framework/runtime build version, schema version, and project identity. Canonical bundle assets remain server-owned; later server/client runtime behavior may deliver authorized per-player asset copies through `PlayerGui`.
- Reason: Separating runtime realms prevents server implementation from entering client artifacts while allowing one reusable shared runtime layer. Capability-driven operations let both hosts use the same authoring logic without giving portable code direct filesystem, plugin, or Roblox dependencies. Explicit ownership prevents Rojo synchronization and Studio plugin mutations from creating duplicate or competing project state. Packaging compiler logic with its hosts prevents generated games from carrying authoring-time dependencies.
- importance: 1.0
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Consequences

- Runtime bundling will eventually produce one artifact per realm target. Shared utilities such as `Signal` belong in the shared target when both server and client need them; the final build pipeline may inline very small utilities when that is simpler.
- Server, client, and shared runtime entry points, their public APIs, generated-output paths, and DarkLua build scripts remain implementation work. This decision does not introduce a runtime loader or bootstrap API.
- The Studio plugin must ship or otherwise receive a compatible prebuilt runtime set because it cannot invoke the external DarkLua executable inside Studio. The Lune host and plugin must install matching versioned runtime builds.
- Studio-only projects are DataModel-authoritative. Rojo-owned projects are filesystem-authoritative and must be configured explicitly, with read-only behavior as the safe fallback when ownership is absent or ambiguous.
- The exact `PlayerGui` delivery hierarchy, authorization protocol, replication/removal lifecycle, and client reconstruction behavior remain runtime design work. Server authority and fail-closed eligibility remain required.
- This supersedes the project-installed-source and direct Rojo-synced-tooling portions of `2026-09-23-002-project-installed-luau-tooling-hosts.md`. Its thin-host and explicit-capability principles remain in force.