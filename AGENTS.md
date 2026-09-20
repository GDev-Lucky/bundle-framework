# AGENTS.md

## Project

- Stack: Roblox, strict Luau, Rojo, Git, Aftman, Selene, and StyLua.

- Treat source and tool configuration as authoritative; inspect relevant files before editing.
- Keep the documented runtime boundary accurate: no loader, lifecycle execution, networking, client asset exposure, or runtime dependency resolution exists unless source and validation prove otherwise.
- Preserve dependency-first acyclic composition, narrow public API boundaries, explicit entry ownership, server authority, and core-owned client asset exposure as framework direction.

## Memory Workflow

1. Read `.ai/tasks/current.md` and its task record on resumption.
2. Run `.ai/tools/archive-tasks.ps1` before retrieving prior work.
3. Read `.ai/README.md`, then load only task-relevant project, decision, guide, summary, and source context.
4. Keep task records and `.ai/tasks/current.md` synchronized.
5. Validate with StyLua, Selene, the basic Rojo build, `git diff --check`, and `.ai/tools/validate-workflow.ps1` when applicable
6.. Use `.ai/tools/retrieve-context.ps1` when ever it can possibly save tokens


## Rules

- When the user makes a request in Plan mode, fully investigate and plan all changes needed, then ask the user to toggle to Act mode before implementation.
- Keep public examples generic; do not add unrelated application details or private project hist
-No editing src files unless explicity asked by user . you may edit ai memory without explicit permissio
-  OAlways take the path that will spend least tokens while providing accurate resuts

- Use strict Luau and preserve the `manifest()` / `define()` / `bundle.require()` contract unless an intentional, documented API change is requested.
- Do not add dependencies, remotes, assets, or runtime architecture without explicit justification.
- Record confirmed durable decisions in `.ai/decision/`; dated decision files are append-only.
- Do not commit generated source maps, place builds, secrets, or machine-specific files.
