#!/usr/bin/env bash
# agentscar guardrail: confirm-destructive
# Irreversible commands require an explicit human token.
# Wire as a command wrapper or your agent CLI's pre-tool hook; pass the
# proposed command as arguments:  hook-confirm-destructive.sh git push --force
# Contract: exit 0 = allow, exit 1 = block.
set -u
cmd="$*"
pattern='--force|-f |force-push|--hard|rm -rf|clean -fd|branch -D|drop table|drop database'
if printf '%s' "$cmd" | grep -Eiq -e "$pattern"; then
  if [ "${AGENTSCAR_APPROVE:-}" = "yes" ]; then
    exit 0
  fi
  printf 'confirm-destructive: "%s" looks irreversible.\n' "$cmd" >&2
  printf 're-run with AGENTSCAR_APPROVE=yes after a human has read the command.\n' >&2
  exit 1
fi
exit 0
