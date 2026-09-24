# Task Store

One compact record per task, named `YYYY-MM-DD-NNN-topic.md`.

## Lifecycle

- Status is `planned`, `in-progress`, `blocked`, `completed`, or `cancelled`.
- [`current.md`](current.md) points to the active task or most recently completed task.
- Run [`../tools/archive-tasks.ps1`](../tools/archive-tasks.ps1) before prior-work retrieval. Terminal records older than 30 days may move to [`archive/`](archive/).

## Required Sections

Each task includes Status, memory metadata, Description, Context, Decisions, Likely Files, Files Touched, Summary, Validation, and Follow-up / Risks.