# BACKLOG — not in v0, on purpose

- `agentscar lint`: rules without `last-reviewed` or older than 90 days -> warn; contradiction detect between rules
- non-interactive `agentscar new` (flags / stdin JSON) for CI and agent use
- auto-wiring hooks into `.git/hooks/` / agent-CLI hook dirs (v0: manual, instructions in each hook header)
- cross-agent-CLI adapter examples (Codex, OpenCode)
- "agentscar for teams": shared log, per-role reviewers
- metrics: failure-type distribution over time
- confirm-destructive denylist: word-boundary matching (current `-f ` pattern misses trailing `-f` and false-positives on e.g. `tar -f x`)
- `init` re-run: guard user-customized templates from silent overwrite (v0 overwrites everything except log.md)
- `init` emits `.agentscar/.okfignore` so fresh bundles lint without orphan INFO noise

Every "what if we also..." lands here, not in scope.
