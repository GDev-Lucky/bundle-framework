# Contributing

## Current scope

This repository is an architectural scaffold for an external development tool and a Luau runtime. It does not currently implement the tool, an intermediate representation, dependency resolution, lifecycle execution, networking, client asset exposure, or a public runtime API.

Do not restore or document the removed `manifest()` / `define()` / `bundle.require()` API as current behavior.

## Development setup

1. Install Aftman and run `aftman install` from the repository root.
2. Run the **Format check**, **Naming check**, **Build example**, and **Build package** VS Code tasks before opening a pull request.
3. Keep authoring-time responsibilities in the external tool and runtime-only behavior in Luau.

## Source boundaries and imports

- `tooling/` contains repository development tools. It may use Lune host APIs, but framework and runtime source must not import it.
- `src/framework/` is portable, strict Luau. Do not use Roblox APIs, services, `Instance` values, `task`, or Lune APIs there.
- `src/runtime/` is strict Roblox Luau. It may depend on `src/framework/` and owns Roblox-only behavior.
- `src/framework/` must not depend on `src/runtime/`; dependencies flow from runtime to framework only.
- Use relative string `require()` paths with forward slashes and no `.luau` suffix. `./Directory` resolves through `./Directory/init.luau`.

Use the matching `bundle-framework-*.code-workspace` file for Luau-LSP. The framework and tooling workspaces use the standard platform; the runtime workspace uses the Roblox platform. They must be opened in separate VS Code windows because Luau-LSP selects one platform per window.

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
- Keep client asset exposure fail-closed: authoring-time provenance determines eligible generated grants, while all delivery authorization and revocation remain server-owned.
- Treat client-delivered code and assets as inspectable; do not place critical logic, secrets, or authoritative decisions in client-visible output.
- Document durable architectural decisions in `.ai/decision/` when the repository workflow applies.

## Pull requests

- Format changed Luau with StyLua when Luau source exists.
- Run the retained Rojo build checks.
- Add generic examples when an implemented tool-to-runtime contract is introduced.
- Update public documentation and relevant AI memory when changing the architecture boundary.