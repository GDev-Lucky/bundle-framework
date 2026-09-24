# Contributing

## Current scope

This repository is an early implementation of an external development tool and a Luau runtime direction. The portable framework baseline, JSON snapshot protocol, and Windows x64 standalone Lune host build exist; the public tool contract, intermediate representation, dependency resolution, lifecycle execution, networking, client asset exposure, and public runtime API remain incomplete.

Do not restore or document the removed `manifest()` / `define()` / `bundle.require()` API as current behavior.

## Development setup

1. Install Aftman and run `aftman install` from the repository root.
2. Run `npm install` from the repository root when working on JavaScript tooling. npm workspaces install dependencies into the shared root `node_modules/`; each workspace must still declare the dependencies it owns.
3. Run the **Build project...**, **Format check**, and **Lint check** VS Code tasks applicable to your changes before opening a pull request. **Build project...** discovers every `build.luau` manifest automatically, so do not add fixed tasks for new tools.
4. Keep authoring-time responsibilities in the external tool and runtime-only behavior in Luau.

## Source boundaries and imports

- `tooling/` contains repository development tools. It may use Lune host APIs, but framework and runtime source must not import it.
- `src/framework/` is portable, strict Luau. Do not use Roblox APIs, services, `Instance` values, `task`, or Lune APIs there.
- `src/runtime/` is strict Roblox Luau. It may depend on `src/framework/` and owns Roblox-only behavior. Future output has shared, server, and client targets: server/client may depend on shared code only.
- `src/framework/` must not depend on `src/runtime/`; dependencies flow from runtime to framework only.
- Use relative string `require()` paths with forward slashes and no `.luau` suffix. `./Directory` resolves through `./Directory/init.luau`.

Use the matching `tooling.code-workspace`, `framework.code-workspace`, or `runtime.code-workspace` file for Luau-LSP. The framework and tooling workspaces use the standard platform; the runtime workspace uses the Roblox platform. They must be opened in separate VS Code windows because Luau-LSP selects one platform per window.

## Luau naming conventions

The project follows default Roblox Luau naming conventions, enforced by the project-owned linter in `tooling/linter/`:

- local variables, functions, parameters, loop variables, and members use `camelCase`;
- private names may use `_camelCase`;
- explicit `const` bindings use `LOUD_SNAKE_CASE`;
- types and type functions use `PascalCase`;
- module/class table bindings and `require()` imports may use `PascalCase`; and
- Luau filenames use `camelCase` or `PascalCase`, except `init.luau`.

StyLua remains responsible for formatting, and Luau-LSP remains responsible for type and built-in Luau diagnostics. Selene is not used. The thin VS Code adapter in `tooling/linter/vscode/` invokes its bundled Windows x64 linter executable while a document is edited. The corresponding local and CI check is `npm run check`, which builds and executes the compiled linter binary rather than running the source CLI.

## Windows linter extension distribution

- Run `npm install` once at the repository root. `tooling/build.ps1 <path> <luau|extension|complete|test> [platform]` discovers manifests and extensions recursively. Each buildable project has one `build.luau` listing entries, extension roots, and supported platforms.
- `tooling/build.ps1 tooling/linter test` builds the linter executable, compiles and packages its VS Code adapter, and installs `build/vsix/bundle-framework-linter.vsix`. The installed extension resolves its private copy through `context.asAbsolutePath("bin/cli.exe")`; it must not depend on a user-installed Lune binary.
- The VS Code **Build project...** task runs the same script interactively. Reload the VS Code window before manually exercising new extension code.

## Architecture contributions

- Keep the tool-to-runtime intermediate representation explicit, deterministic, and validated by the tool.
- Do not duplicate dependency discovery, dependency enforcement, import processing, or type/editor analysis in the Luau runtime.
- Preserve dependency-first, acyclic composition and server authority when those systems are implemented.
- Make generated output and its ownership clear before adding a generator or runtime consumer.
- Package the authoring compiler with the Lune/VS Code host and Studio plugin; generated projects must receive runtime artifacts rather than authoring-tool dependencies.
- Respect explicit project ownership. Filesystem/Rojo-owned projects are read-only to the Studio plugin; Studio-owned projects are mutable only through the plugin's declared DataModel capabilities.
- Keep client asset exposure fail-closed: authoring-time provenance determines eligible generated grants, while all delivery authorization and revocation remain server-owned.
- Treat client-delivered code and assets as inspectable; do not place critical logic, secrets, or authoritative decisions in client-visible output.
- Keep canonical assets server-owned. A future runtime may place authorized per-player asset copies in `PlayerGui`, but delivery and removal behavior must remain server-authoritative.
- Document durable architectural decisions in `.ai/decision/` when the repository workflow applies.

## Windows Lune host distribution

- `tooling/lune/main.luau` is the current Lune host entry point. It reads a JSON snapshot from standard input and constructs the portable framework through `SnapshotProtocol`; it does not yet expose a stable public result protocol.
- Run `tooling/build.ps1 tooling/lune luau windows-x86_64` after `aftman install` to create `build/bin/windows-x86_64/tooling/lune/main.exe`.
- The build uses project-pinned DarkLua to bundle relative imports and keeps `@lune/**` imports for Lune's standalone host. `build/luau/tooling/lune/main.luau` and `build/bin/windows-x86_64/tooling/lune/main.exe` are generated, untracked host-distribution artifacts.
- Do not treat this executable as the finalized framework CLI, runtime generator, or Roblox deployment mechanism. Update documentation and the durable distribution decision whenever its host interface or release ownership changes.

## Pull requests

- Format changed Luau with StyLua when Luau source exists.
- Run the retained Rojo build checks.
- Add generic examples when an implemented tool-to-runtime contract is introduced.
- Update public documentation and relevant AI memory when changing the architecture boundary.