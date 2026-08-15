#!/usr/bin/env bash
# agentscar push-guard tests — the hook must block a push that silently drops
# remote work, and allow honest history. Each case builds a bare remote, a bot
# clone, and a work clone in a fresh temp dir; runs the hook in the work clone
# (which fetches origin itself, exactly as a pre-push hook does) and asserts its
# exit code. Prints "ok N desc" / "FAIL N desc".
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$ROOT/templates/hook-push-guard.sh"
export GIT_EDITOR=true GIT_TERMINAL_PROMPT=0
fails=0
dirs=""

cleanup() { [ -n "$dirs" ] && rm -rf $dirs; }
trap cleanup EXIT

check() { # check N description (asserts $? of the preceding command)
  if [ "$3" -eq 0 ]; then
    printf 'ok %s %s\n' "$1" "$2"
  else
    printf 'FAIL %s %s\n' "$1" "$2"
    fails=$((fails + 1))
  fi
}

setid() { # deterministic identity + no CRLF/gpg surprises
  git config user.email t@t
  git config user.name t
  git config core.autocrlf false
  git config commit.gpgsign false
}

# scenario -> sets BARE, BOT, WORK to absolute paths; seeds main with the given
# "name=content" files in one initial commit that both clones share. The seed pins
# "* -text" so no clone rewrites line endings (Windows autocrlf would otherwise
# fork identical content into two blob ids and make every merge conflict).
scenario() {
  local d; d="$(mktemp -d)"; dirs="$dirs $d"
  BARE="$d/remote.git"; BOT="$d/bot"; WORK="$d/work"
  git init -q --bare "$BARE"
  git --git-dir="$BARE" symbolic-ref HEAD refs/heads/main
  git init -q "$d/seed"; ( cd "$d/seed"; setid
    git symbolic-ref HEAD refs/heads/main
    printf '* -text\n' > .gitattributes
    local kv; for kv in "$@"; do printf '%s\n' "${kv#*=}" > "${kv%%=*}"; done
    git add -A; git commit -qm c0; git remote add origin "$BARE"; git push -q -u origin main )
  git clone -q -c core.autocrlf=false "$BARE" "$BOT"; ( cd "$BOT"; setid )
  git clone -q -c core.autocrlf=false "$BARE" "$WORK"; ( cd "$WORK"; setid )
}

setfile() { printf '%s\n' "$2" > "$1"; git add -A; git commit -qm "$3"; }

# A) the incident: bot regenerates X on the remote; work has its own X; conflicted
#    pull resolved "keep ours" -> fast-forward push that erases the bot's X. BLOCK,
#    and the bot's content must still stand on the remote.
scenario "X=v0" "keep=const"
( cd "$BOT"; setfile X vbot bot-regen; git push -q origin main )
( cd "$WORK"
  setfile X vlocal local-edit
  git fetch -q origin main
  git merge origin/main >/dev/null 2>&1        # conflict on X
  git checkout --ours -- X; git add X
  git commit -q -m "merge keep-ours" )
( cd "$WORK"; bash "$GUARD" >/dev/null 2>&1 ); rc=$?
remote_x="$(git --git-dir="$BARE" show main:X 2>/dev/null)"
[ "$rc" -eq 1 ] && [ "$remote_x" = "vbot" ]
check 1 "keep-ours over bot's file is blocked; remote keeps bot content" $?

# B) honest merge: work changed A, bot changed B, both preserved. ALLOW.
scenario "A=a0" "B=b0"
( cd "$BOT"; setfile B bbot bot-B; git push -q origin main )
( cd "$WORK"
  setfile A alocal local-A
  git fetch -q origin main
  git merge origin/main -m "honest merge" >/dev/null 2>&1 )
( cd "$WORK"; bash "$GUARD" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 0 ]
check 2 "honest merge preserving both sides is allowed" $?

# C) plain non-fast-forward: work diverges, never pulls. BLOCK (existing check).
scenario "X=v0"
( cd "$BOT"; setfile X vbot bot-regen; git push -q origin main )
( cd "$WORK"; setfile X vlocal local-edit )   # no pull, no merge
( cd "$WORK"; bash "$GUARD" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 1 ]
check 3 "plain non-fast-forward is blocked" $?

# D) remote changed X, merge result deletes X entirely. BLOCK.
scenario "X=v0"
( cd "$BOT"; setfile X vbot bot-regen; git push -q origin main )
( cd "$WORK"
  setfile X vlocal local-edit
  git fetch -q origin main
  git merge origin/main >/dev/null 2>&1        # conflict on X
  git rm -q -f X
  git commit -q -m "merge delete X" )
( cd "$WORK"; bash "$GUARD" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 1 ]
check 4 "deleting a remote-populated file in the merge is blocked" $?

# E) plain fast-forward, no remote changes. ALLOW.
scenario "X=v0"
( cd "$WORK"; setfile X vlocal local-edit )    # remote still at c0
( cd "$WORK"; bash "$GUARD" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 0 ]
check 5 "plain fast-forward with no remote change is allowed" $?

# F) two merges in the pushed range; only the OLDER one drops remote work. BLOCK.
scenario "A=a0" "B=b0"
( cd "$BOT"; setfile A abot1 bot-A1; git push -q origin main )         # remote R1
( cd "$WORK"
  setfile A alocal local-A
  git fetch -q origin main
  git merge origin/main >/dev/null 2>&1                                 # conflict on A
  git checkout --ours -- A; git add A
  git commit -q -m "M1 keep-ours" )                                     # BAD merge M1
( cd "$BOT"; setfile B bbot2 bot-B2; git push -q origin main )         # remote R2 (parent R1)
( cd "$WORK"
  git fetch -q origin main
  git merge origin/main -m "M2 honest" >/dev/null 2>&1 )                # HONEST merge M2
( cd "$WORK"; bash "$GUARD" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 1 ]
check 6 "older drop-remote merge is caught behind a later honest merge" $?

exit "$fails"
