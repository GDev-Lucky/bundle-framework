# Task Store

- Store one record per task as `YYYY-MM-DD-NNN-topic.md`.
- Each record requires Status, memory metadata, Description, Context, Decisions, Likely Files, Files Touched, Summary, Validation, and Follow-up / Risks.
- Use statuses `planned`, `in-progress`, `blocked`, `completed`, or `cancelled`.
- Keep [`current.md`](current.md) synchronized with the active or most recently completed task.
- Run `../tools/archive-tasks.ps1` before prior-work retrieval. Terminal records older than 30 days may be moved to `archive/`.