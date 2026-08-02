#!/usr/bin/env bash
# agentscar guardrail: push-guard
# Blocks any push when the remote branch has commits you don't have locally
# (e.g. CI-bot commits). Memory alone did not hold this — so it is enforced here.
# Wire as: .git/hooks/pre-push, or your agent CLI's pre-tool hook.
# Contract: exit 0 = allow, exit 1 = block.
set -u
branch="$(git symbolic-ref --short HEAD 2>/dev/null)" || exit 0
remote="${1:-origin}"
git fetch --quiet "$remote" "$branch" 2>/dev/null || exit 0  # no remote branch yet -> allow
local_ref="$(git rev-parse HEAD 2>/dev/null)" || exit 0
remote_ref="$(git rev-parse "$remote/$branch" 2>/dev/null)" || exit 0
if [ "$local_ref" != "$remote_ref" ] && ! git merge-base --is-ancestor "$remote_ref" "$local_ref"; then
  printf 'push-guard: %s/%s has commits not in your local branch — pull/rebase first.\n' "$remote" "$branch" >&2
  exit 1
fi
exit 0
