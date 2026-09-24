# Summary: Portable Framework Baseline

- importance: 0.9
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z
- Source Paths: `src/framework/`, `tooling/lune/main.luau`

## Purpose

Provide a platform-neutral framework shell over host-supplied project data.

## Important Files

- `src/framework/init.luau` constructs `Framework` and its `Workspace`.
- `src/framework/Protocol/init.luau` defines host items, change signaling, and abstract access methods.
- `src/framework/Protocol/Protocols/SnapshotProtocol.luau` indexes an in-memory snapshot.
- `src/framework/Workspace/init.luau` retains the protocol boundary.
- `tooling/lune/main.luau` adapts JSON standard input into the framework.

## Interfaces

- `Framework.new(protocol)` creates a framework with one workspace.
- `Protocol` exposes `getRootItems`, `getChildren`, `readSource`, and `onChanged`.
- `SnapshotProtocol.new(snapshot)` accepts root IDs and snapshot items with optional source.

## Invariants

- Framework code is strict, portable Luau and has no Roblox or Lune dependency.
- Item IDs are unique; unknown roots, parents, or source requests fail explicitly.
- The current workspace stores the protocol but exposes no public traversal API.

## Dependencies

Internal relative Luau modules only. The Lune host supplies `@lune/stdio` and `@lune/serde` outside the framework package.

## Data Flow

JSON standard input → decoded snapshot → `SnapshotProtocol` indexes → `Framework.new` → `Workspace` retains protocol.

## Operational Notes

The Lune entry returns an empty string and does not define a stable public result protocol.

## Update Triggers

Protocol methods, snapshot shape, workspace behavior, host input/output, or framework entry behavior changes.

## Last Verified

2026-09-24