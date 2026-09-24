# Contributing

## Current scope

This repository is an early implementation of an external development tool and a Luau runtime direction. The portable framework baseline, JSON snapshot protocol, and Windows x64 standalone Lune host build exist; the public tool contract, intermediate representation, dependency resolution, lifecycle execution, networking, client asset exposure, and public runtime API remain incomplete.

Do not restore or document the removed `manifest()` / `define()` / `bundle.require()` API as current behavior.

## Development setup

1. Install Aftman and run `aftman install` from the repository root.
2. Run the **Format check**, **Naming check**, **build-lune-windows**, **Build example**, and **Build package** VS Code tasks applicable to your changes before opening a pull request.
3. Keep authoring-time responsibilities in the external tool and runtime-only behavior in Luau.

## Source boundaries and imports

- `tooling/` contains repository development tools. It may use Lune host APIs, but framework and runtime source must not import it.
- `src/framework/` is portable, strict Luau. Do not use Roblox APIs, services, `Instance` values, `task`, or Lune APIs there.
- `src/runtime/` is strict Roblox Luau. It may depend on `src/framework/` and owns Roblox-only behavior. Future output has shared, server, and client targets: server/client may depend on shared code only.
- `src/framework/` must not depend on `src/runtime/`; dependencies flow from runtime to framework only.
- Use relative string `require()` paths with forward slashes and no `.luau` suffix. `./Directory` resolves through `./Directory/init.luau`.

Use the matching `tooling.code-workspace`, `framework.code-workspace`, or `runtime.code-workspace` file for Luau-LSP. The framework and tooling workspaces use the standard platform; the runtime workspace uses the Roblox platform. They must be opened in separate VS Code windows because Luau-LSP selects one platform per window.

## Luau naming conventions

The project follows default Roblox Luau naming conventions, enforced by the project-owned analyzer in `tooling/naming/`:

- local variables, functions, parameters, loop variables, and members use `camelCase`;
- private names may use `_camelCase`;
- explicit `const` bindings use `LOUD_SNAKE_CASE`;
- types and type functions use `PascalCase`;
- module/class table bindings and `require()` imports may use `PascalCase`; and
- Luau filenames use `camelCase` or `PascalCase`, except `init.luau`.

StyLua remains responsible for formatting, and Luau-LSP remains responsible for type and built-in Luau diagnostics. Selene is not used. The thin VS Code adapter runs the same Luau analyzer while a document is edited. The corresponding CI command is `lune run tooling/naming/cli.luau check src examples tooling`.

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
- Run `tooling/lune/build-windows.ps1`, or the **build-lune-windows** VS Code task, after `aftman install` to create `bin/lune-main.exe` for `windows-x86_64`.
- The build uses project-pinned DarkLua to bundle relative imports and keeps `@lune/**` imports for Lune's standalone host. `bin/lune-main.luau` and `bin/lune-main.exe` are generated, untracked host-distribution artifacts.
- Do not treat this executable as the finalized framework CLI, runtime generator, or Roblox deployment mechanism. Update documentation and the durable distribution decision whenever its host interface or release ownership changes.

## Pull requests

- Format changed Luau with StyLua when Luau source exists.
- Run the retained Rojo build checks.
- Add generic examples when an implemented tool-to-runtime contract is introduced.
- Update public documentation and relevant AI memory when changing the architecture boundary.