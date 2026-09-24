# Decision: Root npm Workspace

- Date: 2026-09-24
- Topic: JavaScript dependency installation layout
- Decision: The repository uses npm workspaces rooted at `package.json`. Node.js packages are installed with one root `npm install`, creating the shared root `node_modules/` and `package-lock.json`. The current VS Code linter adapter is the workspace at `tooling/linter/vscode/`.
- Reason: A shared installation and lockfile avoid per-tool dependency trees while preserving explicit dependency ownership in every package manifest.
- importance: 0.9
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Consequences

- Add future JavaScript packages to the root workspace list and retain their own `dependencies` or `devDependencies` declarations.
- Root scripts dispatch workspace-specific operations; `package:linter-extension` packages the VS Code linter adapter.
- The adapter packaging script resolves VSCE from the root workspace installation.