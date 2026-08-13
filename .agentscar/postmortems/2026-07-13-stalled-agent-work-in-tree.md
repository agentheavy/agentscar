---
generated: {by: claude-code/opus, at: 2026-07-13}
type: postmortem
status: stable
applies_to: process
generalize: yes
---

# A "dead" agent's work was already in the tree

Twice in one build day, a background agent that looked dead had in fact already
produced the work: (1) an implementer whose `git commit` sat blocked on an invisible
permission prompt for 8 hours — the commit landed the moment the prompt was released;
(2) a follow-up fixer hit a stream-watchdog stall twice mid-task — but its full edit
set was already sitting uncommitted in the working tree, one commit short of done.

**Root cause:** treating "agent stopped/stalled/failed" as "work lost". Agent
liveness and work state are independent: the artifacts live in the repo, not in the
agent. Recovery decisions made from the agent's status alone (re-dispatch, delete
leftovers, redo) destroy or duplicate real work.

**Fix (both cases):** inspect the tree BEFORE acting — `git status` + `git log`
against the expected deliverable; then (1) release the blocked step instead of
re-implementing, (2) finish the one missing step inline instead of a third dispatch.

**Rule:** when a background agent dies, stalls, or times out, FIRST diff the
workspace against the task's expected deliverable (`git status`, `git log`, report
files). Re-dispatch only for the delta that is genuinely missing; never clean up
"leftovers" before establishing whether they are the finished work. After two
stalls of the same agent on the same step, stop re-dispatching — finish the delta
yourself or restructure the task.

---

**Correction, 2026-08-13.** Case (1) originally continued: "AFTER the controller had
already deleted the 'orphaned' files from the worktree (they were tracked by then; a
`git restore` recovered them)". That clause is unsupported and has been removed. The
ledger written the same evening records the run ending as "resumed from cache,
committed"; the operator — the only human present — does not recognise the deletion;
and no commit in the project history mentions it. What remains is corroborated: the
8-hour blocked commit, and the fixer's uncommitted edit set. The root cause and the
rule stand on those.

This file also carried `verified: {by: human:operator}`. No human ever signed it. That
line was minted mechanically by a frontmatter migration on 2026-07-31 — the retro
pipeline only consumed human-verified lessons, so the migration supplied the signature
the pipeline wanted. It has been removed here and from three sibling entries. A machine
cannot verify its own output; that is the whole argument this tool is built on.
