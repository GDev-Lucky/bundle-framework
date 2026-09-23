# Decision: Project-Owned Luau Naming Diagnostics

- Date: 2026-09-23
- Topic: Naming convention enforcement
- Decision: Enforce Bundle Framework's default Luau naming conventions with portable project-owned Luau tooling in `tooling/naming/`. A thin VS Code extension runs that analyzer for each edited Luau document and displays its normalized diagnostics. CI runs the same analyzer through Lune. StyLua remains the formatter, Luau-LSP remains the source of type and built-in Luau diagnostics, and Selene remains excluded.
- Reason: Naming rules are not configurable in Luau's built-in linter or Luau-LSP. Keeping analysis in project-installed portable Luau makes the rule set versioned with the framework and reusable by other thin hosts without introducing Node.js or VS Code dependencies into the analyzer.
- importance: 0.99
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Consequences

- Variables, functions, parameters, loop variables, and members use `camelCase`; private names may use `_camelCase`.
- Explicit `const` bindings use `LOUD_SNAKE_CASE`; types and type functions use `PascalCase`.
- Module/class table bindings and `require()` imports may use either `camelCase` or `PascalCase`; source filenames use either casing style, except `init.luau`.
- `lune run tooling/naming/cli.luau check src examples tooling` is the authoritative non-editor check.
- The VS Code adapter is packaged locally from `editors/vscode/`; it is not a framework runtime dependency and its generated installation artifacts remain ignored.