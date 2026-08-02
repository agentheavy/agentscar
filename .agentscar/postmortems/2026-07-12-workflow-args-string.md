---
generated: {by: claude-code/opus, at: 2026-07-12}
type: postmortem
status: stable
verified:
  - {by: human:operator, at: 2026-07-12}
applies_to: process
generalize: yes
---

# Workflow args arrived as a JSON string

An orchestration run of a multi-agent build crashed at t=0: the workflow script
received its `args` input as a JSON-encoded STRING instead of an object — `args.tasks`
was undefined and the task loop threw ("undefined is not an object (evaluating
'TASKS')"). Zero agents had run; the whole launch was lost.

**Root cause:** the script trusted the shape of an externally-supplied input at the
trust boundary (tool-call args), with no normalization or validation.

**Fix:** entry guard `const A = typeof args === 'string' ? JSON.parse(args) : args`;
re-launch succeeded.

**Rule:** every orchestration script starts by normalizing and validating its inputs
(parse-if-string, assert required fields) BEFORE any expensive work. Handed off to
the operator's global tooling (generalize: yes).
