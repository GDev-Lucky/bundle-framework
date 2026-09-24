# Latest Project Linter Diagnostics Decision

- [`2026-09-24-005-bundled-windows-linter-extension.md`](../2026-09-24-005-bundled-windows-linter-extension.md): package the Windows x64 linter executable inside the VSIX and launch its installed copy for live diagnostics.
- [`2026-09-24-004-tool-owned-host-layout.md`](../2026-09-24-004-tool-owned-host-layout.md): colocate portable lint logic and its VS Code adapter under `tooling/linter/`, retain the separate host under `tooling/lune/`, and emit generated host artifacts into `bin/`.
- [`2026-09-23-005-project-naming-diagnostics.md`](../2026-09-23-005-project-naming-diagnostics.md): enforce the current default Luau naming rules through the project-owned linter, with StyLua and Luau-LSP retaining their existing responsibilities.
