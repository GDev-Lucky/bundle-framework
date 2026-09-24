# Decision: Windows Standalone Lune Host Build

- Date: 2026-09-24
- Topic: Current host-build and distribution implementation
- Decision: The current Windows VS Code host artifact is built from `tooling/lune/main.luau` by bundling project-relative imports with project-pinned DarkLua 0.19.0, preserving `@lune/**` imports, then building the resolved bundle with Lune 0.10.5 for `windows-x86_64`. The reproducible entry point is `tooling/lune/build-windows.ps1`, also exposed as the `build-lune-windows` VS Code task. It produces ignored `bin/lune-main.luau` and `bin/lune-main.exe` artifacts. The executable is a host-distribution input, not a committed release artifact or final public CLI/runtime deployment contract.
- Reason: Lune's standalone builder does not resolve repository-local modules itself. Bundling first creates a self-contained project module graph while retaining Lune host modules for the executable runtime. Keeping artifacts untracked makes builds reproducible from project-pinned tools and prevents machine-generated binaries from becoming source of truth.
- importance: 0.9
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Consequences

- A Windows host distributor builds or obtains `bin/lune-main.exe`; consumers of the source repository can reproduce it after `aftman install`.
- `bin/lune-main.luau` is an inspectable build intermediate, and `bin/lune-main.exe` is the executable supplied to the Windows host; neither is committed.
- The present entry point accepts a JSON snapshot through standard input and constructs `SnapshotProtocol` plus `Framework`. It does not yet establish a stable input/output protocol for host integrations.
- The prior project-installed-source and thin-host decision remains in force. This record only specifies the currently implemented Windows host build and artifact boundary.
- A future public CLI, non-Windows targets, artifact publishing process, host invocation contract, generated runtime-output ownership, and Roblox deployment flow require explicit superseding decisions.