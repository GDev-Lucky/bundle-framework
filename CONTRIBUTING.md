# Contributing

## Current scope

This repository is an architectural scaffold for an external development tool and a Luau runtime. It does not currently implement the tool, an intermediate representation, dependency resolution, lifecycle execution, networking, client asset exposure, or a public runtime API.

Do not restore or document the removed `manifest()` / `define()` / `bundle.require()` API as current behavior.

## Development setup

1. Install Aftman and run `aftman install` from the repository root.
2. Run the **Format check**, **Build example**, and **Build package** VS Code tasks before opening a pull request.
3. Keep authoring-time responsibilities in the external tool and runtime-only behavior in Luau.

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