# Task: Add Cline Mode Gate

- Status: completed
- importance: 0.86
- confidence: 1.0
- createdAt: 2026-09-24T00:00:00Z
- lastUsedAt: 2026-09-24T00:00:00Z

## Description

Add a Cline-specific workspace rule that keeps Plan mode read-only and requires an explicit override before standalone research or discussion is handled in Act mode.

## Context

- `AGENTS.md` already requires full planning and an Act-mode switch before implementation for Plan-mode requests.
- The user requested an additional inverse gate: research, discussion, planning, or exploration received in Act mode must instead request a switch to Plan mode unless the user explicitly allows handling it in Act mode.

## Decisions

- Store Cline-only behavior in `.clinerules/mode-workflow.md` rather than duplicating it in the cross-agent `AGENTS.md`.
- Permit read-only context gathering in Act mode when directly necessary to an explicitly requested implementation.
- Validate that the Cline rule exists and retains its Plan-mode, Act-mode, switch, and explicit-override requirements.

## Likely Files

- `.clinerules/mode-workflow.md`
- `.ai/tools/validate-workflow.ps1`
- `.ai/tasks/current.md`
- `.ai/tasks/2026-09-24-007-add-cline-mode-gate.md`

## Files Touched

- `.clinerules/mode-workflow.md`
- `.ai/tools/validate-workflow.ps1`
- `.ai/tasks/current.md`
- `.ai/tasks/2026-09-24-007-add-cline-mode-gate.md`

## Summary

- Added a repository-scoped Cline mode rule with a read-only Plan-mode gate and an explicit-override requirement for standalone Act-mode research and discussion.
- Extended workflow validation to protect the mode-gate rule from accidental removal.

## Validation

- Passed: `.ai/tools/validate-workflow.ps1`.
- Passed: PowerShell parser check for `.ai/tools/validate-workflow.ps1`.
- Passed: `git diff --check` (only unrelated existing LF-to-CRLF warnings).

## Follow-up / Risks

- Cline provides the active mode in the conversation metadata; the rule cannot enforce a mode that is not exposed to the agent.