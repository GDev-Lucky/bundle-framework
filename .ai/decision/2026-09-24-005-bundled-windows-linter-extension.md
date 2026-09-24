# Decision: Bundled Windows Linter Extension Executable

- Date: 2026-09-24
- Topic: VS Code linter runtime distribution
- Decision: The Bundle Framework VS Code linter extension packages a Windows x64 `bundle-framework-linter.exe` built from `tooling/linter/cli.luau`. The build bundles relative Luau imports with project-pinned DarkLua 0.19.0, retains `@lune/**` imports, and compiles the resolved entry point with Lune 0.10.5. The extension resolves its packaged copy at `bin/bundle-framework-linter.exe` through `context.asAbsolutePath()` and invokes it with the existing `document` stdin/stdout protocol. The development test task runs executable build, VSIX packaging, and forced local installation sequentially.
- Reason: Shipping the executable in the VSIX makes the installed Windows extension self-contained and eliminates its runtime dependency on a user-installed Lune executable or repository-local linter source, while preserving the portable Luau implementation as the source of truth.
- importance: 0.95
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Consequences

- `tooling/linter/build-windows.ps1` produces ignored `bin/bundle-framework-linter.luau` and `bin/bundle-framework-linter.exe` artifacts for `windows-x86_64` and smoke-tests a no-diagnostics document request.
- `tooling/linter/vscode/package-windows.ps1` stages the executable with adapter sources before VSCE creates `bin/bundle-framework-linter.vsix`.
- The extension remains Windows x64-only until additional target artifacts and host-selection behavior are explicitly designed.
- The adapter still discovers a Bundle Framework project root before linting, but only to scope diagnostics; it does not execute that project's linter source.