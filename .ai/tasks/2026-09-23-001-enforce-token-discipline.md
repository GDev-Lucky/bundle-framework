# Enforce AI Workflow Token Discipline

- Status: completed
- importance: 0.95
- confidence: 1.0
- createdAt: 2026-09-23T00:00:00Z
- lastUsedAt: 2026-09-23T00:00:00Z

## Description

Strengthen repository agent rules so required memory workflow and token-budget practices are explicit, concise, and validated.

## Context

- The user reported excessive token usage and requested stricter AI workflow and budget rules.
- Existing retrieval limits did not enforce response brevity, search-first inspection, batching, or redundant-read avoidance.

## Decisions

- Add mandatory token-discipline rules to `AGENTS.md`.
- Reduce default retrieval output from 2,500 to 1,500 estimated tokens.
- Validate that key token-discipline rules remain present.
- Preserve correctness, required validation, and explicit user requirements over token savings.

## Likely Files

- `AGENTS.md`
- `.ai/README.md`
- `.ai/config.psd1`
- `.ai/tools/validate-workflow.ps1`
- `.ai/tasks/current.md`

## Files Touched

- `AGENTS.md`
- `.ai/README.md`
- `.ai/config.psd1`
- `.ai/tools/validate-workflow.ps1`
- `.ai/tasks/current.md`
- `.ai/tasks/2026-09-23-001-enforce-token-discipline.md`

## Summary

- Required search-first, minimal-range, batched, non-redundant context retrieval.
- Capped plans and progress narration and set a concise default final-response limit.
- Lowered default retrieval output to 1,500 estimated tokens.
- Added validation for durable token-discipline rules.

## Validation

- `.ai/tools/validate-workflow.ps1`: passed.
- `git diff --check`: passed; only existing line-ending conversion warnings were reported.

## Follow-up / Risks

- Token estimates remain approximate; correctness and task-specific requirements take precedence.