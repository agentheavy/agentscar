---
name: agentscar
description: Run a blameless postmortem after an agent incident — a wrong or destructive action, a false "done", an ignored instruction, wrong scope, or a forgotten decision. Also use when the user says "postmortem this" or "agentscar new".
---

# agentscar — postmortem flow

The log and guardrails live in `.agentscar/` (run `agentscar init` if missing).

When an incident happens (or the user invokes this skill):

1. **Facts first.** One honest sentence about what happened — observable facts, no defense.
2. **Root cause, blameless.** Ask "why" 3–5 times. "The agent was careless" is never a root cause: name a mechanism that can be changed (a missing check, an unstated constraint, prose too far from the action).
3. **Classify** as exactly one of: wrong-assumption · destructive-action · verification-skip · instruction-drift · spec-drift · context-loss (see docs/failure-types.md in the agentscar repo).
4. **Route the guardrail** to the strongest layer that fits: hook > rule > skill > test.
   - destructive-action / instruction-drift -> hook (start from `.agentscar/templates/`)
   - verification-skip -> evidence gate or regression test
   - wrong-assumption / spec-drift / context-loss -> rule (`.agentscar/templates/rule-skeleton.md`)
5. **Propose, never apply.** Show the user (a) the log entry in the exact format below and (b) the guardrail file as a diff. WAIT for explicit approval. Do not write anything before it.
6. **On approval only:** insert the entry at the top of `.agentscar/log.md` (right below the header — newest first), create the guardrail file, set `Status: open`, and remind the user to flip it to `shipped` once the guardrail is wired in.

Log entry format (verbatim):

    ## YYYY-MM-DD · <type> · <low|medium|high>
    **What happened:** <one sentence>
    **Root cause:** <why -> why -> why>
    **Guardrail:** <path> (<layer> layer)
    **Status:** open · last-reviewed: YYYY-MM-DD
