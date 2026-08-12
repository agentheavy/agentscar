# The six ways coding agents fail

Taxonomy distilled from blameless postmortems on real agent incidents. Every incident behind it fits one of these six. Each type has one guardrail shape that actually kills it — and several that only feel like they do.

## 1. wrong-assumption

**Symptom:** the agent silently resolves an ambiguity and sprints. You asked for "cleanup"; it decided that meant deleting the legacy adapter.
**Root-cause shape:** no forced surfacing of assumptions before irreversible work.
**Guardrail:** a pre-work gate — assumptions listed explicitly; any assumption not grounded in the request becomes a question. (Rule/skill layer; can't be a hook — it's semantic.)
**What doesn't work:** "be careful" instructions. Care is not a mechanism.

## 2. destructive-action

**Symptom:** force-push, `rm -rf`, `git reset --hard`, overwriting files it never read.
**Root-cause shape:** no deterministic check between intent and irreversible action.
**Guardrail:** hooks. Always hooks. A denylist with an explicit human-approval escape hatch.
**What doesn't work:** rules. This is the one type where prose is *negligent* — the failure costs too much to run on attention.

## 3. verification-skip

**Symptom:** "Done — tests pass!" Nothing was run. Or tests pass and the behavior is still wrong, because the agent wrote the tests to match its own bug.
**Root-cause shape:** claims accepted without evidence attached.
**Guardrail:** evidence-attached claims — "works" must arrive with the command + output, or a behavioral diff against the base branch. (Skill/test layer + a commit-gate hook that asks "where's the evidence?")
**What doesn't work:** asking "are you sure?" — you'll get confident yes.

## 4. instruction-drift

**Symptom:** the rule existed. The agent even followed it last week. Then 60k tokens of file dumps happened, and the rule lost.
**Root-cause shape:** enforcement placed in prose, far from the action.
**Guardrail:** relocation, not repetition — move the constraint into the enforcement point: the hook, the pre-commit, the template being filled. If it must stay prose, it moves next to where the decision is made.
**What doesn't work:** writing the rule AGAIN, in caps, higher in the file. (Everyone tries. It's rain-dancing.)

## 5. spec-drift

**Symptom:** you asked for X; you got X′ — plus an unrequested refactor, minus the edge case you explicitly named.
**Root-cause shape:** no external definition of done; the author grades its own homework.
**Guardrail:** acceptance criteria written *before* work, checked by a *different context* after (fresh-context judge or a checklist the human walks).
**What doesn't work:** longer task descriptions. Detail ≠ enforcement.

## 6. context-loss

**Symptom:** a decision made three sessions ago quietly reverses today — the agent that made it no longer exists.
**Root-cause shape:** decisions living only in conversation context.
**Guardrail:** durable notes with pointers — one decision, one file, linked from where the next session will look. Storage is the right tool *here* — this is the one type auto-memory genuinely helps with.
**What doesn't work:** trusting the session summary to carry load-bearing decisions.

## The meta-pattern

The distribution of *incidents* and the distribution of *fix value* don't match. Types 1 and 4 are the most frequent; a handful of type-2 hooks deliver the most value — because hooks are the only layer whose enforcement doesn't degrade as context grows.

Rank enforcement, then route: **hook → rule → skill → test.** The strongest layer that fits, every time.

---
*Built from real incidents. Got a failure type that doesn't fit these six? Open an issue — I collect them.*
