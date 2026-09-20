# Decision Store

- Store one durable public decision per `YYYY-MM-DD-NNN-topic.md` file.
- Include `Date`, `Topic`, `Decision`, `Reason`, `importance`, `confidence`, `createdAt`, and `lastUsedAt`.
- Dated records are append-only. Add a superseding record instead of rewriting history.
- Route current decisions through [`latest.md`](latest.md) and topic files in `latest/`.