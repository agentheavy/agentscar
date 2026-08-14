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

- non-interactive `new` (dogfood 14.08: the interview reads stdin, so the primary user — an agent in a harness — cannot drive it; the skill covers the flow, but the CLI itself should take flags or a heredoc)
- `init --claude --user`: install the skill user-level, not only per-repo (dogfood 14.08: the skill sat uninstalled for 9 days because init only writes ./.claude/skills/)

Every "what if we also..." lands here, not in scope.
