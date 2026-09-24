# Decision: Tool-Owned Host Layout

- Date: 2026-09-24
- Topic: Authoring-tool source and generated host artifact layout
- Decision: Authoring-tool hosts are colocated with the portable tool they expose. The naming-rule implementation is generalized as the Bundle Framework linter in `tooling/linter/`, and its thin VS Code adapter lives in `tooling/linter/vscode/`. The separate Lune host remains in `tooling/lune/`. Generated host artifacts are written to the ignored root `bin/` directory.
- Reason: Colocation makes ownership explicit, avoids a disconnected top-level editor tree, and allows each portable tool to carry its platform adapters without moving platform-specific APIs into portable Luau modules. A single generated-output root keeps installable packages and executables out of source directories.
- importance: 0.96
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Consequences

- `tooling/linter/` owns lint rules, the Lune CLI transport, tests, and `vscode/` adapter source.
- The current linter initially enforces naming conventions, but its name and ownership permit additional project lint rules without another structural rename.
- `tooling/linter/vscode/` may use Node.js and VS Code APIs only as a thin adapter; portable lint logic remains outside that subdirectory.
- Packaging the adapter produces `bin/bundle-framework-linter.vsix`; dependencies remain local and ignored under `tooling/linter/vscode/node_modules/`.
- `tooling/lune/` owns the separate Lune host source and continues to produce `bin/lune-main.luau` and `bin/lune-main.exe`.
- This supersedes the source locations in `2026-09-23-005-project-naming-diagnostics.md` without changing its naming-rule policy.
