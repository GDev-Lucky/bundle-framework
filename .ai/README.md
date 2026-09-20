# Project Memory

Persistent, compact context for work on this public Bundle Framework repository. Source code and configuration remain authoritative.

## Index

- [`config.psd1`](config.psd1): retrieval and archive settings.
- [`project.md`](project.md): confirmed repository facts and API boundary.
- [`decision/README.md`](decision/README.md): durable public decision policy.
- [`guides/README.md`](guides/README.md): maintained cross-cutting guidance.
- [`summaries/README.md`](summaries/README.md): implemented-source navigation summaries.
- [`tasks/README.md`](tasks/README.md): task record lifecycle.
- [`tasks/current.md`](tasks/current.md): active or most recent task.
- [`tools/`](tools): archive, retrieval, and workflow-validation scripts.

## Retrieval Limits

Use a 6,000-token soft limit and an 8,000-token hard limit. The default runtime-output limit is 2,500 estimated tokens.

| Category | Tokens |
| --- | ---: |
| Project | 800 |
| Architecture | 1,800 |
| Decisions | 1,200 |
| Previous Work | 1,200 |
| Code | 3,000 |
| **Total** | **8,000** |

Retrieve only information that materially affects the current public-framework task. Do not store or import unrelated application details, private history, or speculative runtime architecture.

## Memory Units

Each `project.md`, dated decision, dated task, guide, and summary requires `importance`, `confidence`, `createdAt`, and `lastUsedAt` metadata. Use ISO-8601 UTC timestamps. Record durable decisions and concise task outcomes; do not duplicate source code or routine tool output.

## Workflow

1. Read the active task, run `tools/archive-tasks.ps1`, then use `tools/retrieve-context.ps1` only when it reduces retrieval cost.
2. Search before broad reads and stop retrieving when evidence is sufficient.
3. Keep task and current-task records synchronized.
4. Run `tools/validate-workflow.ps1` after changing `AGENTS.md` or `.ai/`.