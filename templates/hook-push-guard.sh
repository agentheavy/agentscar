#!/usr/bin/env bash
# agentscar guardrail: push-guard
# Blocks a push that would silently drop remote work:
#  (1) a non-fast-forward (remote has commits you don't have), and
#  (2) a merge in the pushed range that discarded the remote side's change to a
#      file — e.g. a conflicted pull resolved "keep ours" over a CI-bot's
#      regenerated file. Fast-forward alone does not prove the remote's content
#      survived: the bot commit can be in your history yet gone from your tree.
# Memory alone did not hold this — so it is enforced here.
# Wire as: .git/hooks/pre-push, or your agent CLI's pre-tool hook.
# Contract: exit 0 = allow, exit 1 = block.
set -u
branch="$(git symbolic-ref --short HEAD 2>/dev/null)" || exit 0
remote="${1:-origin}"
git fetch --quiet "$remote" "$branch" 2>/dev/null || exit 0  # no remote branch yet -> allow
local_ref="$(git rev-parse HEAD 2>/dev/null)" || exit 0
remote_ref="$(git rev-parse "$remote/$branch" 2>/dev/null)" || exit 0

# (1) Non-fast-forward. Git rejects this too, but flag it early with a clear reason.
if [ "$local_ref" != "$remote_ref" ] && ! git merge-base --is-ancestor "$remote_ref" "$local_ref"; then
  printf 'push-guard: %s/%s has commits not in your local branch — pull/rebase first.\n' "$remote" "$branch" >&2
  exit 1
fi

# (2) Dropped remote content. Walk every merge between the remote tip and HEAD.
# A merge that pulled the remote line in has one parent on the remote side (an
# ancestor of the remote tip) and one on the local side; a purely local merge has
# neither and is skipped. For each file the remote side changed relative to the two
# parents' merge base, block if the merged tree took the local version (remote's
# distinct change dropped) or deleted a file the remote had populated. Comparing
# blob ids is content equality; an empty id means the path is absent.
while IFS= read -r merge; do
  [ -n "$merge" ] || continue
  remote_parent="" ; local_parent=""
  for p in $(git log -1 --format=%P "$merge"); do
    if git merge-base --is-ancestor "$p" "$remote_ref"; then
      remote_parent="$p"
    else
      local_parent="$p"
    fi
  done
  [ -n "$remote_parent" ] && [ -n "$local_parent" ] || continue
  base="$(git merge-base "$local_parent" "$remote_parent" 2>/dev/null)" || continue
  while IFS= read -r -d '' path; do
    rmt="$(git rev-parse -q --verify "$remote_parent:$path" 2>/dev/null || true)"
    [ -n "$rmt" ] || continue  # remote deleted this path — not a content loss
    res="$(git rev-parse -q --verify "$merge:$path" 2>/dev/null || true)"
    loc="$(git rev-parse -q --verify "$local_parent:$path" 2>/dev/null || true)"
    if [ -z "$res" ]; then
      printf 'push-guard: merge %s deletes %s which %s/%s populated — remote work dropped.\n' "${merge:0:9}" "$path" "$remote" "$branch" >&2
      exit 1
    fi
    if [ "$res" = "$loc" ] && [ "$res" != "$rmt" ]; then
      printf 'push-guard: merge %s kept local %s and dropped the %s/%s change — re-resolve keeping remote.\n' "${merge:0:9}" "$path" "$remote" "$branch" >&2
      exit 1
    fi
  done < <(git diff --no-renames --name-only -z "$base" "$remote_parent")
done < <(git rev-list --merges "$remote_ref..$local_ref")

exit 0
