# Decision: Manifest-Driven Recursive Builds

- Date: 2026-09-24
- Topic: Generic project build discovery, platform selection, and compiled validation
- Decision: Each buildable project owns one `build.luau` manifest declaring only Luau entries, VS Code extension roots, and supported native platforms. `tooling/build.ps1` recursively discovers manifests below a requested path and performs `luau`, `extension`, `complete`, or `test` operations without target-specific PowerShell scripts. Native output is organized under `build/bin/<platform>/<project>/`; direct calls without a platform build every platform declared by the selected manifests, while the no-argument interactive task offers a platform choice. Validation and CI build and invoke the compiled Windows linter executable rather than executing its source CLI.
- Reason: Per-project manifests make new tools discoverable without modifying a centralized target list, while generic artifact paths prevent collisions between entries with common names. Running the compiled linter verifies the actual distributed executable and aligns local, VS Code, and CI checks with the shipped behavior.
- importance: 0.96
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Consequences

- `build-windows.ps1` and `package-windows.ps1` scripts are removed; `build.luau` is the only project-local build declaration.
- VS Code has one generic **Build project...** task. It delegates dynamic project/operation/platform selection to PowerShell because native `tasks.json` pickers cannot discover filesystem targets.
- Declared VS Code roots are searched recursively for extension `package.json` files, so future nested extension projects are built and packaged automatically.
- The linter VSIX embeds `bin/cli.exe`, sourced from `build/bin/windows-x86_64/tooling/linter/cli.exe`.