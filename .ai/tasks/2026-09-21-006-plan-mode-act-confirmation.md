# Require Act-Mode Confirmation After Planning

- Status: completed
- importance: 0.82
- confidence: 1.0
- createdAt: 2026-09-21T12:00:00Z
- lastUsedAt: 2026-09-21T12:00:00Z

## Description

Require agents to fully investigate and plan requests received in Plan mode, then ask the user to switch to Act mode before implementing changes.

## Context

- The user explicitly requested this Plan-mode workflow rule.
- `AGENTS.md` is the repository guidance file for agent behavior.

## Decisions

- Plan-mode work must not implement changes.
- The agent must ask the user to toggle to Act mode after presenting the complete implementation plan.

## Likely Files

- `AGENTS.md`
- `.ai/tasks/current.md`
- `.ai/tasks/2026-09-21-006-plan-mode-act-confirmation.md`

## Files Touched

- `AGENTS.md`
- `.ai/tasks/current.md`
- `.ai/tasks/2026-09-21-006-plan-mode-act-confirmation.md`

## Summary

- Added an explicit rule requiring complete planning in Plan mode and an Act-mode switch request before implementation.

## Validation

- `git diff --check`: passed.
- `.ai/tools/validate-workflow.ps1`: passed.

## Follow-up / Risks

- None.