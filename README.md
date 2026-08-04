# agentscar

**Your coding agent makes the same mistake twice. agentscar makes it the last time.**

Auto-memory remembers. It doesn't *learn*. agentscar runs a blameless postmortem on every agent incident — root-causes it, then writes the guardrail (a hook, a rule, or a skill) so the same failure physically can't happen again.

```bash
agentscar init   # sets up .agentscar/ — log, guardrail templates
agentscar new    # guided postmortem → routed guardrail + log entry
agentscar log    # your agent's scar tissue, greppable
```

Bash + markdown. Zero dependencies. Works with any agent CLI — Claude Code, Codex, OpenCode — it doesn't care.

## Why

Every practitioner running coding agents daily knows the loop: the agent pushes over CI's commits, you add a rule, and three weeks later it happens again — because the rule was prose, buried deep in context, losing the attention war against file dumps and test output.

Notes don't change behavior. **Enforcement does.** A small pre-push hook outperforms any instruction about pushing, because hooks run on `exit 1` and instructions run on attention.

agentscar is the discipline SRE teams use for outages, applied to agents:

1. **What happened** — one honest paragraph.
2. **Root cause** — 3–5 whys. ("Agent is careless" is never a root cause.)
3. **Guardrail** — routed to the *strongest enforcement layer that fits*:

   > **hook** (deterministic block) → **rule** (instruction) → **skill** (procedure) → **test** (regression)

4. **Log entry** — dated, typed, linked to the guardrail it produced.

If a lesson matters, it wants to become a hook.

## vs. what you already have

| | CLAUDE.md / rules | auto-memory | hooks alone | **agentscar** |
|---|---|---|---|---|
| Captures lessons | manually | automatically | no | guided, per incident |
| Changes behavior | if attention holds | no — storage | yes, narrowly | yes — routed to strongest layer |
| Root-cause discipline | no | no | no | yes (blameless postmortem) |
| History you can grep | no | partially | no | `agentscar log` |

agentscar doesn't replace any of these — it's the loop that decides *what goes where, and why*.

## Quickstart

```bash
npm i -g agentscar   # or: pipx install agentscar (or: uv tool install agentscar)
# or from source:
git clone https://github.com/agentheavy/agentscar && cd agentscar && ./install.sh   # or: copy agentscar to PATH
cd your-project
agentscar init
# next time your agent does something you never want repeated:
agentscar new
```

**Windows:** agentscar is a bash script — run it from Git Bash (ships with Git for Windows, which Claude Code already requires) and keep bash on PATH. The npm and pipx installs add shims, but the shims still call bash — if you hit `bash: command not found`, switch to Git Bash.

`agentscar new` walks you through the postmortem and drops:
- an entry in `.agentscar/log.md`
- a guardrail skeleton in `.agentscar/rules/`, with the intended enforcement layer (rule, hook, or test) noted inside

Everything agentscar writes is plain markdown; the minimal frontmatter it carries is [OKF v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog)-compatible, so catalog tooling can index a `.agentscar/` bundle as-is.

**Claude Code users:** `agentscar init --claude` (or plain `init` in a repo that already has `.claude/`) also installs a skill so the agent runs the postmortem flow itself after an incident and proposes the guardrail as a diff — you approve, it lands.

**Other agents (Codex, Cursor, …):** `agentscar init --agentsmd` adds an agentscar section to `AGENTS.md` (created if missing; plain `init` also updates an existing one), pointing anything that reads the file at the postmortem flow.

## The six ways agents fail

Every lesson I've distilled from real agent incidents — 80+ files across two production workspaces, a domain knowledge vault, and a user-level harness — collapses into six types: **wrong-assumption · destructive-action · verification-skip · instruction-drift · spec-drift · context-loss.**

Each type has exactly one guardrail shape that kills it. Full breakdown: [docs/failure-types.md](docs/failure-types.md).

## Included templates

- `hook-push-guard` — fetch + compare before any push; blocks on divergence.
- `hook-confirm-destructive` — force-push / `rm -rf` / hard reset require explicit human approval.
- `rule-skeleton` — constraint / why (incident link) / how-to-apply / last-reviewed.

These aren't examples — they're the hooks I actually run, each born from a real incident.

## FAQ

**Isn't this just "write better CLAUDE.md"?**
No. Prose competes for attention; attention degrades with context length. agentscar's point is routing: most lessons people write as rules wanted to be hooks.

**Does it phone home / need an API key?**
No. It's bash and markdown files in your repo. Nothing leaves your machine.

**Why "agentscar"?**
Scar tissue is permanent memory of damage — grown so the same wound doesn't open twice.

**Roadmap?**
`agentscar lint` (stale-rule detection: `last-reviewed` > 90 days → warn), contradiction checks, shared team logs. One thing at a time.

## License

MIT.
