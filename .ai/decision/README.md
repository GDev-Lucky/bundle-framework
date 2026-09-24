# Decision Store

Durable architecture history. Dated records are append-only; current navigation lives in [`latest.md`](latest.md).

## Record Rules

- Store one decision per `YYYY-MM-DD-NNN-topic.md` file.
- Include `Date`, `Topic`, `Decision`, `Reason`, and all memory metadata.
- Supersede an outdated decision with a new dated record; never rewrite or delete history.
- Update the matching route in [`latest/`](latest/) and its entry in [`latest.md`](latest.md).