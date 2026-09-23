# Decision: Project-Installed Luau Tooling and Host Adapters

- Date: 2026-09-23
- Topic: Tool distribution and editor-host architecture
- Decision: Bundle Framework will be distributed as project-installed Luau source divided into a shared core, authoring-time tooling, and a Roblox runtime. The VS Code extension and Roblox Studio plugin are thin hosts: they receive platform events, invoke the project's Luau tooling, expose explicit environment capabilities, and apply returned diagnostics, edits, and other abstract results. The shared core and tooling must not directly depend on VS Code APIs, Node.js APIs, Roblox services, `Instance` values, or `plugin`.
- Reason: Project-installed source keeps the runtime and authoring rules versioned with the game, lets both editors execute the same Luau logic, and keeps platform-specific code small. Capability adapters preserve portability while allowing each host to perform native work.
- importance: 1.0
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Consequences

- VS Code must host a Luau runtime and translate VS Code events into calls into the project tooling; its TypeScript code is an adapter rather than the framework's primary logic.
- The Studio plugin may directly require the Rojo-synced shared core and tooling because it runs Luau; it performs the same host role through Roblox-specific adapters.
- Host-to-tooling communication uses explicit, serializable capability requests and platform-neutral document and result data. Native values remain private to their host.
- The Roblox runtime runs independently in the game and consumes generated, validated output. Authoring tooling is excluded from production game mappings and must not become a runtime dependency.
- Rojo's filesystem-to-Studio development synchronization is the supported shared-source workflow. Rojo-managed script sources are edited on disk, typically in VS Code; Studio is not the authoritative source for those files.
- The exact package layout, capability names, intermediate-representation schema, generated-output ownership, and runtime API remain separate design work.
- This supersedes the distribution and host details left open by `2026-09-22-001-external-tool-and-luau-runtime.md` without changing that append-only record.