---
type: postmortem
generated:
  by: agentscar/0.1.0
  at: 2026-08-02
status: stable
---

# agentscar log

One incident = one entry. An entry does not close without a guardrail;
a guardrail is not written without an incident. Newest first.

## 2026-07-31 · wrong-assumption · medium
**What happened:** After migrating a project to Windows, one status test failed because winget-installed `sqlite3` is invisible to non-interactive bash, and `2>/dev/null` silencing disguised the missing dependency as healthy empty output.
**Root cause:** assumed CLI deps are on PATH everywhere -> winget only patches the registry user PATH, so subprocess shells inherit a stale environment -> silenced stderr turned "binary missing" into plausible data.
**Guardrail:** inline PATH shim + distinguishable fallback text in every script that shells out to a CLI dep (hook layer)
**Status:** shipped · last-reviewed: 2026-07-31
**Postmortem:** [2026-07-31-winget-cli-path-non-interactive-bash](postmortems/2026-07-31-winget-cli-path-non-interactive-bash.md)

## 2026-07-12 · wrong-assumption · high
**What happened:** An autonomous multi-agent run stalled 8 hours on an invisible permission prompt: agents' `git commit` calls hit an unscoped commit-approval gate, and the first exemption fix failed because it stayed silent instead of emitting an explicit allow.
**Root cause:** launch skipped preflighting the permission surface of the commands agents would run -> gate was never scoped -> the exemption's silent exit delegated the decision back to an auto-classifier that said "ask".
**Guardrail:** repo-scoped exemption that emits an EXPLICIT allow decision, pipe-tested on all four paths (hook layer)
**Status:** shipped · last-reviewed: 2026-07-12
**Postmortem:** [2026-07-12-commit-gate-vs-autonomous-run](postmortems/2026-07-12-commit-gate-vs-autonomous-run.md)

## 2026-07-12 · wrong-assumption · medium
**What happened:** An orchestration run crashed at t=0 because the workflow script received its `args` input as a JSON-encoded string instead of an object; zero agents ran and the launch was lost.
**Root cause:** trusted the shape of an externally-supplied input at the trust boundary -> no parse-if-string normalization or field assertion before the task loop.
**Guardrail:** normalize-and-assert entry guard at the top of every orchestration script (rule layer)
**Status:** shipped · last-reviewed: 2026-07-12
**Postmortem:** [2026-07-12-workflow-args-string](postmortems/2026-07-12-workflow-args-string.md)

## 2026-07-12 · wrong-assumption · low
**What happened:** Brief-extraction tooling failed 12/12 invocations with "not a git repository" because it ran before the target repo existed — the plan's own first task was to create it.
**Root cause:** artifact-generation tooling ran before its environmental precondition -> precondition (initialized repo) assumed, not checked.
**Guardrail:** verify environmental preconditions (repo present, dirs exist) before running artifact-generating tooling (rule layer)
**Status:** shipped · last-reviewed: 2026-07-12
**Postmortem:** [2026-07-12-task-brief-needs-repo](postmortems/2026-07-12-task-brief-needs-repo.md)
