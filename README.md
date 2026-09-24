# Bundle Framework

Bundle Framework is being reset as an authoring compiler plus Roblox runtime framework:

- A portable **Luau authoring compiler** owns authoring-time analysis and generation, packaged by thin VS Code/Lune and Roblox Studio hosts.
- Compiled **shared, server, and client runtime** artifacts consume the compiler's generated representation inside Roblox.

> **Status:** early implementation. The prior Luau-only static API remains removed. A portable framework baseline, JSON snapshot input, and a Windows x64 standalone Lune host artifact are implemented; the authoring tool contract, intermediate representation, and Roblox runtime remain in design.

## Direction

The external tool will make bundle authoring straightforward while keeping runtime work small and deterministic. Its intended responsibilities include:

- discovering bundles and project structure;
- validating and enforcing an acyclic dependency graph;
- processing framework imports and `require` relationships;
- providing type information and editor autocomplete support; and
- producing a simple, validated intermediate representation for the runtime.

Framework releases package the portable authoring compiler with the VS Code/Lune host and Studio plugin. Generated projects install only versioned runtime artifacts and generated output, not authoring tooling. Hosts adapt their native events and capabilities while portable compiler code uses platform-neutral, serializable data.

During Rojo development, the filesystem is authoritative and synchronizes into Studio. The Studio plugin is read-only for a Rojo-owned project: it may inspect, diagnose, and navigate, but must not create, modify, move, or remove managed objects. In Studio-only projects, the plugin owns the DataModel project instead. Authoring tooling never belongs in production game mappings.

The Luau runtime will consume that generated representation and perform only Roblox-specific runtime behavior. It must not repeat project discovery, dependency-graph analysis, import resolution, or authoring-time type generation.

## Confirmed design direction

The systems below are confirmed architecture, **not implemented APIs**.

- Bundles will have framework-only dependency declarations that the tool validates and removes from generated runtime output. The project may later provide a custom Studio widget and visual editor for those declarations.
- Bundle scripts will distinguish explicit entries, private modules, and public APIs. `server` modules are server-only; `shared` modules may run on both sides. The tool resolves framework imports, enforces declared public access, and prevents shared code from importing server-only code.
- Runtime output will have separate shared, server, and client build targets. Server and client runtime code may depend on shared runtime code, but neither realm may depend on the other and shared code may depend on neither realm. Shared utilities such as `Signal` can therefore be emitted once for both sides when appropriate.
- Client entries are explicit execution and exposure boundaries. A future server-side entry start operation will authorize generated client code for a player. The runtime can then lazily deliver only assets that the active entry is eligible to use.
- The tool will trace statically provable `asset()` keys through client values, framework networking, and authoritative server state. For example, it can associate an inventory item key with an icon asset and generate server-side grant/revocation hooks when fully traced inventory state changes.
- When that relationship cannot be proven, compilation will fail closed unless the author provides a server-only asset authorization policy. Policies can revoke their own scoped grants; grants remain reference-counted so one user cannot remove an asset still required by another active entry or policy.
- This minimizes which clients receive code and assets, but it cannot make content secret after it has been delivered to a client. Critical logic and authoritative decisions remain server-only.
- Canonical assets remain server-owned. The future server/client runtime may deliver authorized per-player copies through `PlayerGui`, but its delivery hierarchy and lifecycle are not yet implemented.
- Networking is intended to generate optimized codecs for proven payload shapes, fall back to supported Roblox remote serialization when shape is unknown, report unsupported values, and validate every client-to-server input on the server.

## Repository layout

- [`tooling/`](tooling): repository development tools and the Lune host entry point, excluded from framework/runtime packages.
- [`src/framework/`](src/framework): portable, pure-Luau baseline containing the framework, workspace, protocol abstraction, snapshot protocol, and signal utility.
- [`src/runtime/`](src/runtime): reserved Roblox-only runtime source, planned to build separate shared, server, and client artifacts and allowed to depend on `src/framework/`.
- [`examples/`](examples): future end-to-end examples.
- [`example.project.json`](example.project.json): intentionally blank Rojo example scaffold.
- [`package.project.json`](package.project.json): intentionally blank Rojo package scaffold.

## Open design work

The following are deliberately not specified or implemented yet:

- the external tool's public command-line interface and configuration format;
- the exact package layout, host capability names, and ownership metadata schema;
- the exact intermediate-representation schema and serialization format;
- the runtime's public Luau API, entry lifecycle model, asset-policy syntax, and replication transport; and
- generated runtime-output locations, bootstrap contract, and deployment workflow.

These decisions must be designed together so that the intermediate boundary is stable, simple, and sufficient for runtime needs.

## Development scaffold

The repository retains Rojo and StyLua, plus a project-owned Luau linter with a thin VS Code diagnostics adapter:

```sh
aftman install
npm install
npm run build
stylua --check src examples tooling
npm run check
rojo build example.project.json --output bundle-framework-example.rbxlx
rojo build package.project.json --output bundle-framework.rbxm
```

### Windows Lune host artifact

`tooling/build.ps1` is the manifest-driven build entry point. Every buildable project owns one adjacent `build.luau` that declares its Luau entries, VS Code extension roots, and supported native platforms. The script recursively discovers those manifests, bundles entries with DarkLua, and invokes Lune for each selected platform.

Use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tooling/build.ps1` without arguments to select a discovered project, operation, and platform interactively. Automation can pass positional arguments, such as `tooling/build.ps1 tooling/lune luau windows-x86_64` or `tooling/build.ps1 tooling/linter test`. If no platform is supplied, every platform listed in the selected manifest is compiled.

After a successful Lune-host build, distribute `build/bin/windows-x86_64/tooling/lune/main.exe` to the Windows host integration that invokes it. `build/luau/tooling/lune/main.luau` is an intermediate resolved bundle retained for inspection; both files are generated and intentionally ignored by Git. Build artifacts are host-distribution inputs only: they do not define the eventual public CLI, generated runtime-output layout, or production Roblox deployment contract.

The current executable reads a JSON snapshot from standard input, constructs `SnapshotProtocol` and `Framework`, and does not yet emit a public result. Its input/output interface is therefore provisional and must evolve with the authoring-tool contract.

Open one of the dedicated VS Code workspaces for Luau-LSP rather than opening the repository folder directly:

- `tooling.code-workspace` analyzes repository tools as standard Luau;
- `framework.code-workspace` analyzes portable framework code as standard Luau; and
- `runtime.code-workspace` analyzes Roblox runtime code with Roblox types.

All framework, runtime, and tool-internal imports use relative string paths such as `require("./Module")` and `require("../Package")`; do not append `.luau`. A directory import resolves its `init.luau`. Luau-LSP cannot use the Roblox and standard platforms in the same VS Code window, so open these workspaces in separate windows when working across boundaries.

To enable live lint diagnostics in VS Code, install the bundled Windows x64 linter extension after running `aftman install`:

```sh
npm install
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tooling/build.ps1 tooling/linter test
```

The repository uses npm workspaces, so run `npm install` once from the root. The VS Code adapter is authored in strict TypeScript and compiles to `build/js/`; resolved Luau is written under `build/luau/`, native artifacts under `build/bin/<platform>/`, and installable extensions to `build/vsix/`. `npm run build` runs the complete recursive build, while `tooling/build.ps1 tooling/linter test` builds, packages, and installs `build/vsix/bundle-framework-linter.vsix`. The package includes its private `bin/cli.exe`, so installed copies do not require Lune or repository source at editor runtime. Reload the VS Code window after installation to activate the new extension version.

## License

Distributed under the [MIT License](LICENSE).