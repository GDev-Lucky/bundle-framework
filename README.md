# Bundle Framework

Bundle Framework is being reset as a two-part Roblox framework:

- A project-installed **Luau authoring tool** owns authoring-time analysis and generation, hosted by thin VS Code and Roblox Studio integrations.
- A **Luau runtime** consumes the tool's generated intermediate representation inside Roblox.

> **Status:** architectural scaffold. The prior Luau-only static API has been removed. The external tool, intermediate representation, and replacement runtime are not implemented yet.

## Direction

The external tool will make bundle authoring straightforward while keeping runtime work small and deterministic. Its intended responsibilities include:

- discovering bundles and project structure;
- validating and enforcing an acyclic dependency graph;
- processing framework imports and `require` relationships;
- providing type information and editor autocomplete support; and
- producing a simple, validated intermediate representation for the runtime.

Framework projects will install the shared Luau core, authoring-time tooling, and runtime source. The VS Code extension hosts the tooling in a Luau runtime and adapts VS Code events and capabilities; the Studio plugin directly hosts the same Rojo-synced tooling through Roblox-specific capabilities. Shared tooling uses platform-neutral, serializable data rather than VS Code or Roblox-native values.

During development, Rojo synchronizes the filesystem source—normally edited in VS Code—into Studio. Tooling belongs only in development mappings; production game mappings include the runtime and generated runtime output, not authoring tooling.

The Luau runtime will consume that generated representation and perform only Roblox-specific runtime behavior. It must not repeat project discovery, dependency-graph analysis, import resolution, or authoring-time type generation.

## Confirmed design direction

The systems below are confirmed architecture, **not implemented APIs**.

- Bundles will have framework-only dependency declarations that the tool validates and removes from generated runtime output. The project may later provide a custom Studio widget and visual editor for those declarations.
- Bundle scripts will distinguish explicit entries, private modules, and public APIs. `server` modules are server-only; `shared` modules may run on both sides. The tool resolves framework imports, enforces declared public access, and prevents shared code from importing server-only code.
- Client entries are explicit execution and exposure boundaries. A future server-side entry start operation will authorize generated client code for a player. The runtime can then lazily deliver only assets that the active entry is eligible to use.
- The tool will trace statically provable `asset()` keys through client values, framework networking, and authoritative server state. For example, it can associate an inventory item key with an icon asset and generate server-side grant/revocation hooks when fully traced inventory state changes.
- When that relationship cannot be proven, compilation will fail closed unless the author provides a server-only asset authorization policy. Policies can revoke their own scoped grants; grants remain reference-counted so one user cannot remove an asset still required by another active entry or policy.
- This minimizes which clients receive code and assets, but it cannot make content secret after it has been delivered to a client. Critical logic and authoritative decisions remain server-only.
- Networking is intended to generate optimized codecs for proven payload shapes, fall back to supported Roblox remote serialization when shape is unknown, report unsupported values, and validate every client-to-server input on the server.

## Repository layout

- [`tooling/`](tooling): repository development tools, run through Lune and excluded from framework/runtime packages.
- [`src/framework/`](src/framework): future portable, pure-Luau framework package.
- [`src/runtime/`](src/runtime): future Roblox-only runtime package, which may depend on `src/framework/`.
- [`examples/`](examples): future end-to-end examples.
- [`example.project.json`](example.project.json): intentionally blank Rojo example scaffold.
- [`package.project.json`](package.project.json): intentionally blank Rojo package scaffold.

## Open design work

The following are deliberately not specified or implemented yet:

- the external tool's implementation language, command-line interface, and configuration format;
- the exact package layout and host capability contract;
- the exact intermediate-representation schema and serialization format;
- the runtime's public Luau API, entry lifecycle model, asset-policy syntax, and replication transport; and
- generated-file locations, ownership, and deployment workflow.

These decisions must be designed together so that the intermediate boundary is stable, simple, and sufficient for runtime needs.

## Development scaffold

The repository retains Rojo and StyLua, plus a project-owned Luau naming analyzer with a thin VS Code diagnostics adapter:

```sh
aftman install
stylua --check src examples tooling
lune run tooling/naming/cli.luau check src examples tooling
rojo build example.project.json --output bundle-framework-example.rbxlx
rojo build package.project.json --output bundle-framework.rbxm
```

The Rojo projects contain no source mappings until the replacement systems are implemented.

Open one of the dedicated VS Code workspaces for Luau-LSP rather than opening the repository folder directly:

- `bundle-framework-tooling.code-workspace` analyzes repository tools as standard Luau;
- `bundle-framework-framework.code-workspace` analyzes portable framework code as standard Luau; and
- `bundle-framework-runtime.code-workspace` analyzes Roblox runtime code with Roblox types.

All framework, runtime, and tool-internal imports use relative string paths such as `require("./Module")` and `require("../Package")`; do not append `.luau`. A directory import resolves its `init.luau`. Luau-LSP cannot use the Roblox and standard platforms in the same VS Code window, so open these workspaces in separate windows when working across boundaries.

To enable live naming diagnostics in VS Code, package and install the local adapter once after running `aftman install`:

```sh
cd editors/vscode
npm install
npx vsce package --no-dependencies --out bundle-framework-naming.vsix
code --install-extension bundle-framework-naming.vsix --force
```

## License

Distributed under the [MIT License](LICENSE).