---
generated: {by: claude-code/opus, at: 2026-07-12}
type: postmortem
status: stable
verified:
  - {by: human:operator, at: 2026-07-12}
applies_to: process
generalize: no
---

# Task-brief tooling ran before the repo existed

Brief-extraction tooling (`task-brief`) failed 12/12 invocations with "not a git
repository": it derives its workspace from the git root, and the target repo did not
exist yet (the plan's own Task 1 was to create it).

**Root cause:** artifact-generation tooling ran before its environmental precondition
(an initialized repo) — assumption not checked.

**Fix:** `git init` the target first (idempotent; Task 1's own init is a no-op after),
then generate briefs.

**Rule:** before running artifact-generating tooling, verify its environmental
preconditions (repo present, dirs exist) — especially when the plan itself creates
that environment.
