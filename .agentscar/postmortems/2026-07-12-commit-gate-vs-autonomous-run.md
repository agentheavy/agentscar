---
generated: {by: claude-code/opus, at: 2026-07-12}
type: postmortem
status: stable
applies_to: process
generalize: yes
---

# Commit gate vs. autonomous run

An autonomous multi-agent build run stalled on manual permission prompts: implementer
agents' `git commit` calls hit the operator-level commit-approval gate (ask-rule +
pre-tool hook) mid-run. The human had to intervene — the opposite of an autonomous
run's contract.

**Root cause:** the run was launched without preflighting the permission surface of
the exact command classes its agents would execute (the commit gate existed for good
reasons — an earlier incident — but was never scoped).

**Fix:** repo-scoped exemption in the commit gate (an exempt-repos list) + removal of
the global ask-rule, gate preserved for all non-exempt repos; pipe-tests for both paths.

**Recurrence (same day):** the exemption exited SILENTLY (exit 0), which under an
auto-classifying permission mode means "no opinion" — the classifier still emitted
"ask" on one commit, and the headless run stalled on the invisible prompt for 8 hours.
Escalated fix: the exemption now emits an EXPLICIT allow decision, verified by
pipe-tests on all four paths (exempt cwd, non-exempt cwd, `git -C` form, non-commit).

**Rule:** before launching an autonomous run, enumerate the command classes agents
will execute and preflight them against current permission rules and hooks; resolve
gates (scoped, never blanket) BEFORE launch, not mid-run. For a hook-based exemption,
"stay silent" is NOT "allow" — silence delegates to whatever default/classifier sits
behind it; autonomous paths need an explicit allow decision.
