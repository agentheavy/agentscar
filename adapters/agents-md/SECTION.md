## agentscar — incident postmortems

This repo logs agent incidents with agentscar (blameless postmortems -> enforced
guardrails). After any incident — false "done", destructive command, silently
resolved ambiguity — run `agentscar new`: it interviews for root cause and writes
a log entry plus a guardrail skeleton in `.agentscar/`. Before re-attempting
something that failed before, check `.agentscar/log.md`.
