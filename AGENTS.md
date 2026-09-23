# AGENTS.md

## Project

- Direction: an external authoring/development tool produces a simple intermediate representation consumed by a Luau runtime.
- Current state: architectural scaffold. `tooling/` contains repository development tools; `src/framework/` and `src/runtime/` are intentionally implementation-free package roots.
- Retained tooling: Roblox, strict Luau when runtime code is added, Rojo, Git, Aftman, and StyLua.

- Treat source and tool configuration as authoritative; inspect relevant files before editing.
- Preserve a narrow tool-to-runtime boundary. The external tool owns discovery, dependency enforcement, import processing, and type/editor analysis. The runtime consumes generated output and performs Roblox-only behavior.
- Keep dependency-first acyclic composition, explicit ownership, narrow public API boundaries, and server authority as framework direction.
- Do not invent a runtime API, generator schema, tool language, lifecycle model, networking, or asset system without an explicit, documented design decision.
- Keep dependencies one-way: `tooling/` is not framework code, `src/framework/` is portable Luau and may not depend on Roblox or `src/runtime/`, and `src/runtime/` may depend on `src/framework/` but owns Roblox-only behavior.
- Use relative string-path `require()` calls with forward slashes and no `.luau` suffix; directory imports resolve through `init.luau`.

## Memory Workflow

1. Read `.ai/tasks/current.md` and its task record on resumption.
2. Run `.ai/tools/archive-tasks.ps1` before retrieving prior work.
3. Read `.ai/README.md`, then load only task-relevant project, decision, guide, summary, and source context.
4. Keep task records and `.ai/tasks/current.md` synchronized.
5. Validate with applicable StyLua and Rojo checks, `git diff --check`, and `.ai/tools/validate-workflow.ps1` when applicable.
6. Use `.ai/tools/retrieve-context.ps1` whenever it can save tokens.

## Token Discipline

- Treat `.ai/config.psd1` limits as ceilings, not targets. Use the smallest sufficient context and stop retrieving as soon as the task is understood.
- Search before reading broadly. Read only relevant line ranges, batch independent reads and checks, and never reread unchanged content without a specific need.
- Use `.ai/tools/retrieve-context.ps1` instead of manually loading multiple memory files whenever prior context is needed and retrieval can reduce tokens.
- Keep plans to at most five concise steps. Keep progress updates to one or two sentences and report only decisions, blockers, or validation results.
- Do not paste large file contents, diffs, search results, or routine command output into responses. Summarize them and cite file paths or line ranges.
- Default to a concise final response of at most 400 words unless the user requests detail or additional explanation is necessary for correctness.
- Do not sacrifice correctness, required validation, or explicit user requirements to save tokens.

## Rules

- When the user makes a request in Plan mode, fully investigate and plan all changes needed, then ask the user to toggle to Act mode before implementation.
- Keep public examples generic; do not add unrelated application details or private history.
- Do not edit `src/` unless explicitly asked by the user. AI memory may be updated when needed to preserve the workflow.
- Follow the Memory Workflow and Token Discipline sections for every repository task.
- Record confirmed durable decisions in `.ai/decision/`; dated decision files are append-only.
- Do not commit generated source maps, place builds, secrets, or machine-specific files.