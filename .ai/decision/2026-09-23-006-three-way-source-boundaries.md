# Decision: Tooling, Framework, and Runtime Source Boundaries

- Date: 2026-09-23
- Topic: Source layout, allowed APIs, dependency direction, imports, and Luau-LSP configuration
- Decision: `tooling/` contains repository development tools and may use Lune host APIs, but framework/runtime source must not import it and it is excluded from production Rojo mappings. `src/framework/` is a portable pure-Luau package and may not use Roblox APIs, services, `Instance`, `task`, Lune APIs, or `src/runtime/`. `src/runtime/` is the Roblox-only package and may use Roblox APIs and depend on `src/framework/`. All internal package imports use forward-slash relative string paths (`./` and `../`), omit `.luau`, and resolve a directory through its `init.luau`. Dedicated VS Code workspaces run tooling/framework with Luau-LSP's standard platform and runtime with its Roblox platform; each must be opened in a separate VS Code window.
- Reason: Project tools have different host dependencies from consumer framework code, while portable framework logic must remain reusable and independently analyzable from Roblox behavior. Luau-LSP 1.70.0 chooses its platform once per VS Code window, so separate workspaces/windows are required for accurate standard and Roblox diagnostics.
- importance: 1.0
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Consequences

- The earlier dual-root decision is superseded for current source layout but remains immutable historical context.
- `.luaurc` files keep each source root strict; workspace settings select the Luau-LSP platform and always-relative completion style.
- Runtime sourcemap generation remains disabled until an explicit runtime Rojo DataModel topology is decided.
- The repository naming extension discovers the repository root from the edited document so it works when any dedicated source workspace is open.