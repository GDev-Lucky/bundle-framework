# Bundle Framework

An experimental, types-first Luau API for declaring Roblox bundles and accessing declared dependency APIs with precise inferred types.

> **Status:** pre-1.0 static API. This project does not currently implement bundle loading, lifecycle execution, networking, client asset exposure, or runtime dependency resolution.

## What it provides

- `framework.manifest(value)` validates a manifest shape while preserving its inferred type.
- The returned `define(description)` validates a bundle declaration.
- `bundle.require(bundleName, apiName)` derives overloads from declared dependencies and public API partitions.

## Design philosophy

- **Dependency-first composition:** bundles declare their dependencies explicitly; dependency graphs must be acyclic.
- **Narrow contracts:** a bundle may expose public API partitions such as `server`, `client`, or `shared`. Consumers depend on those contracts, not private modules.
- **Explicit activation boundary:** declared `entries` identify the only modules that a future runtime could treat as lifecycle entries. Ordinary modules remain private implementation details.
- **Optional features over core coupling:** core composition and typing should not require every bundle to adopt unrelated services.
- **Server authority:** any future runtime must preserve server authority and must not trust client-provided state.

### Client asset exposure is a core responsibility

Client asset exposure is part of the Bundle Framework core architecture. A future core runtime will own the server-authoritative mechanisms for selecting declared assets, exposing them to clients, communicating delivery metadata, supporting client reconstruction, and removing exposure when it is no longer needed. The concrete runtime API and lifecycle remain to be designed, implemented, and validated; the current static API does not perform asset exposure.

## Example

```luau
local manifest, define = framework.manifest({
	catalog = {
		bundle = bundles.catalog,
		api = {
			server = require(bundles.catalog.public.server),
		},
	},
})

return define({
	entries = {},
	dependencies = {
		catalog = manifest.catalog,
	},
	assets = {},
})
```

Inside a bundle that declares `catalog` as a dependency:

```luau
local catalog = bundle.require("catalog", "server")
```

The generic example source is in [`examples/basic`](examples/basic) and is served from the repository root with `example.project.json`.

## Requirements

- Roblox Studio and a current Luau language server with the new type solver enabled.
- [Aftman](https://github.com/LPGhatguy/aftman) to install the pinned development tools.

## Development

```sh
aftman install
stylua --check src examples
selene src examples/basic/src
rojo build example.project.json --output bundle-framework-example.rbxlx
rojo build package.project.json --output bundle-framework.rbxm
```

The workspace includes matching VS Code tasks and points Luau-LSP at `example.project.json`. Use `rojo serve example.project.json` for example development. Use `package.project.json` when building or loading only the framework package.

## Known editor limitation

The two-argument form `bundle.require(bundleName, apiName)` preserves valid dependency/API pairs and exact return types. Luau LSP may still suggest API names belonging to another dependency while completing the second argument. Diagnostics and inferred return types remain authoritative.

## Roadmap

Potential runtime behavior is intentionally out of scope until it is separately designed, implemented, and tested. Any future core runtime should preserve the design philosophy above and include server-authoritative client asset exposure as a core subsystem. The current project should be used as a static declaration and type-inference contract only.

## License

Distributed under the [MIT License](LICENSE).