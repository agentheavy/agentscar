# BACKLOG — not in v0, on purpose

- `agentscar lint`: rules without `last-reviewed` or older than 90 days -> warn; contradiction detect between rules
- non-interactive `agentscar new` (flags / stdin JSON) for CI and agent use; end state:
  the Claude skill calls the CLI instead of re-implementing the interview in prose
  (consistency — owner leans yes, 04.08; arch-review candidate #2; 04.08 competitive
  sweep: assistant postmortem prompts already exist and stop at the document — the
  interview half is commoditizable, so the CLI-backed loop is the compounding part)
- layer multiselect in `new`: one incident, guardrails on two layers (e.g. rule + test);
  owner keeps coming back to this (04.08)
- auto-wiring hooks into `.git/hooks/` / agent-CLI hook dirs (v0: manual, instructions in each hook header)
- cross-agent-CLI adapter examples (Codex, OpenCode); more adapter targets exist —
  `.github/copilot-instructions.md`, `.cursor/rules`, Aider CONVENTIONS.md — demand-gated;
  emit-registry (arch-review candidate #3) makes each ≈ one table row
- "agentscar for teams": shared log, per-role reviewers
- metrics: failure-type distribution over time
- confirm-destructive denylist: word-boundary matching (current `-f ` pattern misses trailing `-f` and false-positives on e.g. `tar -f x`)
- `init` re-run: guard user-customized templates from silent overwrite (v0 overwrites everything except log.md)
- `init` emits `.agentscar/.okfignore` so fresh bundles lint without orphan INFO noise

- non-interactive `new` (first-user finding 14.08: the interview reads stdin, so the primary user — an agent in a harness — cannot drive it; the skill covers the flow, but the CLI itself should take flags or a heredoc)
- `init --claude --user`: install the skill user-level, not only per-repo (first-user finding 14.08: the skill sat uninstalled for 9 days because init only writes ./.claude/skills/)

- **push-guard misses the failure it was written for (15.08, reproduced; RESOLVED 15.08).** The
  template blocks only non-fast-forward pushes — which git already rejects on its
  own. The actual incident was a conflicted pull resolved with "keep ours": the
  remote commit lands in local history, so `merge-base --is-ancestor` passes, the
  push is a legitimate fast-forward, and the CI bot's regenerated file is silently
  gone from the remote. Repro (bare remote + a bot clone + `checkout --ours`) exits
  0 and the remote ends up holding the pre-CI content. First fix attempt failed and
  was reverted: comparing HEAD against `merge-base HEAD remote/branch` finds
  nothing, because after the merge that base IS the remote tip, so the file list to
  check comes out empty. A working check has to reach the pre-merge side (the other
  parent of the merge that brought the remote in) and compare content there.
  Blocks the launch claim in post -2 ("I wrote the check that day") until fixed.
  **Fixed:** the guard now walks every merge in `remote/branch..HEAD`, splits each
  into its remote-side parent (the one that is an ancestor of the remote tip) and
  local-side parent, and for every file the remote side changed vs the two parents'
  merge base it blocks when the merged blob equals the local parent's (remote's
  distinct change discarded) or the file was deleted while the remote had populated
  it. Ancestry was necessary but not sufficient — it proves the remote commit is in
  history, not that its content survived the tree. See `templates/hook-push-guard.sh`
  and `tests/push-guard.sh` (6 cases, all green).

Every "what if we also..." lands here, not in scope.
