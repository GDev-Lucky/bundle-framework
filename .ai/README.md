# Project Memory

Compact, persistent context for Bundle Framework work. Source and configuration are authoritative; memory helps readers find the smallest useful slice of that source.

## Start Here

1. Read [`tasks/current.md`](tasks/current.md) and its linked task.
2. Run [`tools/archive-tasks.ps1`](tools/archive-tasks.ps1).
3. Read [`project.md`](project.md), then retrieve only task-relevant context.
4. Verify memory claims against source before changing them.

## Memory Map

- [`project.md`](project.md) — current state, boundaries, and unresolved contracts.
- [`decision/latest.md`](decision/latest.md) — routes to current durable decisions.
- [`guides/README.md`](guides/README.md) — maintained cross-cutting practices.
- [`summaries/README.md`](summaries/README.md) — compact maps of implemented systems.
- [`tasks/README.md`](tasks/README.md) — task lifecycle and history.
- [`config.psd1`](config.psd1) — retrieval and archival settings.
- [`tools/`](tools) — retrieval, archival, and validation scripts.

## Retrieval Budget

Use a 6,000-token soft limit and an 8,000-token hard limit. The default runtime-output limit is 1,500 estimated tokens.

| Category | Tokens |
| --- | ---: |
| Project | 800 |
| Architecture | 1,800 |
| Decisions | 1,200 |
| Previous Work | 1,200 |
| Code | 3,000 |
| **Total** | **8,000** |

Treat these limits as ceilings. Search before broad reads, prefer [`tools/retrieve-context.ps1`](tools/retrieve-context.ps1) when it reduces context, and stop when evidence is sufficient.

## Record Policy

- `project.md`, dated decisions, dated tasks, guides, and summaries require `importance`, `confidence`, `createdAt`, and `lastUsedAt` metadata in ISO-8601 UTC.
- Keep records factual, compact, and linked to authoritative source paths.
- Record durable decisions and task outcomes; do not duplicate source, speculative APIs, or routine command output.
- Keep [`tasks/current.md`](tasks/current.md) synchronized and run [`tools/validate-workflow.ps1`](tools/validate-workflow.ps1) after changing `AGENTS.md` or `.ai/`.