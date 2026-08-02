---
generated: {by: claude-code/fable, at: 2026-07-31}
type: postmortem
status: stable
verified:
  - {by: claude-code/fable, at: 2026-07-31}
applies_to: process
generalize: yes
---

# Winget-installed CLIs are invisible to non-interactive bash

Deploying a project to a Windows machine (via git bundle, 2026-07-31): the test
suite came up 90/91 — a status-reporting test failed. The status hook shells out to
`sqlite3`, every call wrapped in `2>/dev/null`, so a missing binary silently
degraded into "no rows yet" instead of an error. Installing sqlite3 via winget did
NOT fix it: winget drops executables into its package directory and only patches the
*registry* user PATH — a non-interactive `bash` spawned by a running process (pytest
subprocess, agent CLI hook) inherits the parent's stale environment and reads no
profile, so the binary stays invisible.

**Root cause:** two stacked assumptions from the Linux/Mac origin: (1) CLI deps
(`sqlite3`, `jq`) are on PATH everywhere; (2) errors would surface — but the
defensive `2>/dev/null` turns "dependency missing" into plausible-but-wrong output.
Second occurrence of the class: `jq` in a statusline script hit the same winget
PATH gap at migration (2026-07-24).

**Fix:** the statusline's shim pattern, applied to the hook — probe and extend PATH
inline: `command -v sqlite3 >/dev/null 2>&1 || PATH="$PATH:<winget package dir>"`.
No-op on Linux/Mac. Suite green 91/91 after.

**Rule (class >=2 -> ladder):** any script that may run under non-interactive bash on
Windows and shells out to a CLI dep must carry the inline PATH shim for that dep —
profile files and registry PATH edits do not reach hook/subprocess shells. When a
silenced (`2>/dev/null`) external call feeds user-visible output, the fallback text
must be distinguishable from a healthy empty result, or the silencing hides broken
deps as data.
