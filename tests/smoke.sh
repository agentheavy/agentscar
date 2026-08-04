#!/usr/bin/env bash
# agentscar smoke tests — init + AGENTS.md adapter.
# Each test runs in a fresh temp dir; prints "ok N desc" / "FAIL N desc".
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/bin/agentscar"
fails=0
dirs=""

cleanup() { [ -n "$dirs" ] && rm -rf $dirs; }
trap cleanup EXIT

fresh() {
  d="$(mktemp -d)"
  dirs="$dirs $d"
  cd "$d"
}

check() { # check N description (asserts $? of the preceding command chain)
  if [ "$3" -eq 0 ]; then
    printf 'ok %s %s\n' "$1" "$2"
  else
    printf 'FAIL %s %s\n' "$1" "$2"
    fails=$((fails + 1))
  fi
}

# t1: plain init, no AGENTS.md -> not created, no AGENTS.md mention in output
fresh
out="$("$BIN" init 2>&1)"
[ ! -f AGENTS.md ] && ! printf '%s\n' "$out" | grep -q 'AGENTS.md'
check 1 "plain init leaves AGENTS.md absent and unmentioned" $?

# t2: init --agents-md, no AGENTS.md -> created with the section
fresh
"$BIN" init --agents-md >/dev/null
[ -f AGENTS.md ] && grep -q '^## agentscar' AGENTS.md
check 2 "init --agents-md creates AGENTS.md with the section" $?

# t3: existing AGENTS.md with trailing newline -> preserved + section appended once
fresh
printf '# My repo\n\nprior content line\n' > AGENTS.md
"$BIN" init >/dev/null
grep -q '^# My repo$' AGENTS.md && grep -q '^prior content line$' AGENTS.md \
  && [ "$(grep -c '^## agentscar' AGENTS.md)" -eq 1 ]
check 3 "existing AGENTS.md preserved, section appended" $?

# t4: existing AGENTS.md WITHOUT trailing newline -> no glued lines
fresh
printf 'prior line without newline' > AGENTS.md
"$BIN" init >/dev/null
grep -q '^prior line without newline$' AGENTS.md && grep -q '^## agentscar' AGENTS.md
check 4 "no trailing newline in prior file, section not glued" $?

# t5: double run -> section exactly once
fresh
"$BIN" init --agents-md >/dev/null
"$BIN" init >/dev/null
"$BIN" init --agents-md >/dev/null
[ "$(grep -c '^## agentscar' AGENTS.md)" -eq 1 ]
check 5 "repeated init keeps exactly one section" $?

# t6: --claude + alias --agentsmd together -> both adapters installed
fresh
"$BIN" init --claude --agentsmd >/dev/null
[ -f .claude/skills/agentscar/SKILL.md ] && grep -q '^## agentscar' AGENTS.md
check 6 "--claude --agentsmd (alias) installs skill and AGENTS.md section" $?

# t7: syntax check + embedded heredoc matches canonical SECTION.md byte-for-byte
fresh
bash -n "$BIN" && "$BIN" init --agents-md >/dev/null \
  && diff "$ROOT/adapters/agents-md/SECTION.md" AGENTS.md >/dev/null
check 7 "bash -n passes and heredoc matches adapters/agents-md/SECTION.md" $?

# t8: same-slug hook guardrails same day -> three distinct files, no overwrite
fresh
git init -q . 2>/dev/null || true
"$BIN" init >/dev/null
newin() { printf 'same incident text\nbecause reasons\n\n2\n2\n1\n3\n'; }
newin | "$BIN" new >/dev/null 2>&1
newin | "$BIN" new >/dev/null 2>&1
newin | "$BIN" new >/dev/null 2>&1
[ "$(ls .agentscar/hooks/same-incident-text* 2>/dev/null | wc -l)" -eq 3 ]
check 8 "three same-slug hook incidents produce three files" $?

# t9: AGENTS.md unwritable (is a directory) -> init --agents-md dies, no false success
fresh
mkdir AGENTS.md
out="$("$BIN" init --agents-md 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ! printf '%s\n' "$out" | grep -q 'created AGENTS.md'
check 9 "unwritable AGENTS.md target dies instead of false success" $?

# t10: unrelated '## agentscar...' heading does not suppress the real section
fresh
printf '# repo\n\n## agentscar notes\nmy own notes\n' > AGENTS.md
"$BIN" init >/dev/null
[ "$(grep -c '^## agentscar — incident postmortems' AGENTS.md)" -eq 1 ] \
  && grep -q '^## agentscar notes$' AGENTS.md
check 10 "marker matches full heading, not user headings with agentscar prefix" $?

exit "$fails"
