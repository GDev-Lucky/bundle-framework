# Decision: Build Artifact Layout and TypeScript Extension

- Date: 2026-09-24
- Topic: Generated host artifacts and VS Code adapter implementation
- Decision: Repository-generated artifacts are placed under ignored `build/`: `build/js/` for compiled Node.js adapters, `build/luau/` for resolved Luau bundles, `build/bin/` for Windows executables, and `build/vsix/` for installable VS Code packages. The VS Code linter adapter is authored in strict TypeScript under `tooling/linter/vscode/src/` and compiled into `build/js/linter-vscode/`. `tooling/build.ps1` is the reusable coordinator for extension compilation, Luau compilation, extension package/install testing, and the combined build.
- Reason: `build/` accurately covers both intermediates and distributable artifacts while its typed subdirectories make artifact ownership and consumption explicit. TypeScript improves safety at the Node.js/VS Code host boundary without moving portable tooling logic out of Luau.
- importance: 0.92
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Consequences

- `npm run compile:extension` compiles the VS Code adapter; `npm run compile:luau` builds both current Windows Luau hosts; `npm run test:extension` builds, packages, and force-installs the linter extension; and `npm run build` compiles extension plus Luau output.
- The VSIX retains an internal `bin/bundle-framework-linter.exe` path because that is the extension's private runtime layout, while its source executable comes from repository `build/bin/`.
- CI installs the npm workspace and compiles the TypeScript extension before retained Luau checks.