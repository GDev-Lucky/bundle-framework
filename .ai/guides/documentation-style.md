# Guide: Documentation Style

- importance: 0.78
- confidence: 0.95
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Scope

Maintained Markdown under `.ai/` and concise repository workflow documentation.

## Guidance

- Open with one sentence that states purpose and authority.
- Put the reader's next action or navigation near the top.
- Use short, descriptive headings and small focused sections.
- Prefer linked indexes over repeating details across files.
- Separate implemented facts, confirmed direction, and unresolved design.
- Use bullets for parallel facts, numbered lists for sequences, and tables only for genuinely tabular data.
- Use badges, icons, and callouts sparingly when they clarify status or navigation; they should never carry the document.
- Name authoritative source paths and include a verification date in maintained guides and summaries.
- Preserve history in dated records; update current-state routes and summaries instead of rewriting historical context.

## Rationale

Useful open-source documentation gets readers to the right page quickly, keeps prerequisite material near the top, and reserves detail for the pages that need it. The aim here is a clear project voice, not a uniform template.

## References

- Repository workflow: [`../README.md`](../README.md), [`../../AGENTS.md`](../../AGENTS.md)
- Style review completed 2026-09-24: Rust, Kubernetes, ripgrep, and Visual Studio Code contributor documentation.

## Update Triggers

- Memory directory structure or required metadata changes.
- Validation rules introduce a new documentation requirement.
- Repeated documentation drift reveals a missing convention.

## Last Verified

2026-09-24