# Decision: Dual Luau Source Environments and Relative Imports

- Date: 2026-09-23
- Topic: Source layout, execution environments, imports, and editor configuration
- Decision: The repository has two first-class Luau source roots. `src/` is the Roblox runtime package: it is Rojo-synced into Studio and may use Roblox runtime APIs, including `task`, `Instance` values, services, and other Roblox globals. `tooling/` is the portable authoring package: it is also Rojo-synced into Studio, but must be executable by a standalone Luau runtime and may use only portable Luau facilities such as tables, strings, and coroutines. Tooling must not directly use Roblox runtime APIs or values. Both roots use relative string-path `require()` imports with forward-slash paths, no `.luau` suffix, and directory resolution through `init.luau`; `./` addresses a root or sibling module and `../` addresses a parent module. Each root owns a separate Luau-LSP configuration so its permitted environment is analyzed independently.
- Reason: Keeping both packages Rojo-synced permits shared filesystem authoring and Studio development while preserving a hard portable-tooling boundary. Relative string imports give the same project-local module syntax to Roblox and standalone Luau execution. Separate LSP configuration prevents Roblox-only APIs from silently entering portable tooling and gives runtime code the Roblox analysis it requires.
- importance: 1.0
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Consequences

- `src/` and `tooling/` remain separate packages with their own `init.luau` roots and their own `.luaurc` configuration.
- `src/` may depend on generated runtime output and Roblox APIs, but it must not absorb authoring-time discovery, dependency analysis, import resolution, or editor/type analysis.
- `tooling/` may be hosted in Studio or an external Luau runtime, but all host- and Roblox-specific work must remain outside its portable implementation behind explicit inputs or adapters.
- Internal imports use forms such as `require("./module")`, `require("./package")`, and `require("../module")`; source files never append `.luau` to these paths.
- A directory import resolves that directory's `init.luau`, so package and subpackage entry modules use the same relative-path convention.
- Rojo and editor configuration must map and analyze both roots without placing authoring tooling in a production runtime mapping.
- The exact Rojo project topology, `.luaurc` contents, generated-output location, tooling API, intermediate representation, and runtime lifecycle remain follow-up implementation decisions.