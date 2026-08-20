#!/usr/bin/env bash
# agentscar smoke tests — init + AGENTS.md adapter.
# Each test runs in a fresh temp dir; prints "ok N desc" / "FAIL N desc".
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/bin/agentscar"
MARKER='## agentscar — incident postmortems'
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

# t2: init --agentsmd, no AGENTS.md -> created with the section
fresh
"$BIN" init --agentsmd >/dev/null
[ -f AGENTS.md ] && grep -q "^$MARKER" AGENTS.md
check 2 "init --agentsmd creates AGENTS.md with the section" $?

# t3: existing AGENTS.md with trailing newline -> preserved + section appended once
fresh
printf '# My repo\n\nprior content line\n' > AGENTS.md
"$BIN" init >/dev/null
grep -q '^# My repo$' AGENTS.md && grep -q '^prior content line$' AGENTS.md \
  && [ "$(grep -c "^$MARKER" AGENTS.md)" -eq 1 ]
check 3 "existing AGENTS.md preserved, section appended" $?

# t4: existing AGENTS.md WITHOUT trailing newline -> no glued lines
fresh
printf 'prior line without newline' > AGENTS.md
"$BIN" init >/dev/null
grep -q '^prior line without newline$' AGENTS.md && grep -q "^$MARKER" AGENTS.md
check 4 "no trailing newline in prior file, section not glued" $?

# t5: double run -> section exactly once
fresh
"$BIN" init --agentsmd >/dev/null
"$BIN" init >/dev/null
"$BIN" init --agentsmd >/dev/null
[ "$(grep -c "^$MARKER" AGENTS.md)" -eq 1 ]
check 5 "repeated init keeps exactly one section" $?

# t6: --claude + alias --agents-md together -> both adapters installed
fresh
"$BIN" init --claude --agents-md >/dev/null
[ -f .claude/skills/agentscar/SKILL.md ] && grep -q "^$MARKER" AGENTS.md
check 6 "--claude --agents-md (alias) installs skill and AGENTS.md section" $?

# t7: syntax check + embedded heredoc matches canonical SECTION.md byte-for-byte
fresh
bash -n "$BIN" && "$BIN" init --agentsmd >/dev/null \
  && diff "$ROOT/adapters/agents-md/SECTION.md" AGENTS.md >/dev/null
check 7 "bash -n passes and heredoc matches adapters/agents-md/SECTION.md" $?

# t8: same-slug hook guardrails same day -> three distinct files, no overwrite
fresh
"$BIN" init >/dev/null
newin() { printf 'same incident text\nbecause reasons\n\n2\n2\n1\n3\n'; }
newin | "$BIN" new >/dev/null 2>&1
newin | "$BIN" new >/dev/null 2>&1
newin | "$BIN" new >/dev/null 2>&1
[ "$(ls .agentscar/hooks/same-incident-text* 2>/dev/null | wc -l)" -eq 3 ]
check 8 "three same-slug hook incidents produce three files" $?

# t9: AGENTS.md unwritable (is a directory) -> init --agentsmd dies, no false success
fresh
mkdir AGENTS.md
out="$("$BIN" init --agentsmd 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ! printf '%s\n' "$out" | grep -q 'created AGENTS.md'
check 9 "unwritable AGENTS.md target dies instead of false success" $?

# t10: unrelated '## agentscar...' heading does not suppress the real section
fresh
printf '# repo\n\n## agentscar notes\nmy own notes\n' > AGENTS.md
"$BIN" init >/dev/null
[ "$(grep -c "^$MARKER" AGENTS.md)" -eq 1 ] \
  && grep -q '^## agentscar notes$' AGENTS.md
check 10 "marker matches full heading, not user headings with agentscar prefix" $?

# t11: unknown init flag -> die before doing any work
fresh
out="$("$BIN" init --agents 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'unknown option' && [ ! -d .agentscar ]
check 11 "unknown init flag dies before creating anything" $?

# t12: re-init reports refreshed (not created) for tool-owned files
fresh
"$BIN" init --claude >/dev/null
out="$("$BIN" init --claude 2>&1)"
printf '%s\n' "$out" | grep -q 'refreshed .agentscar/index.md' \
  && printf '%s\n' "$out" | grep -q 'skill refreshed' \
  && ! printf '%s\n' "$out" | grep -q 'created .agentscar/index.md'
check 12 "re-init says refreshed for index.md and the skill" $?

# t13: --severity accepts the 1/2/3 vocabulary the 'new' interview asks for,
# instead of silently printing an empty log (which reads as "no such incidents").
fresh
"$BIN" init >/dev/null
printf 'high sev incident\nbecause reasons\n\n1\n3\n2\n' | "$BIN" new >/dev/null 2>&1
"$BIN" log --severity 3 2>/dev/null | grep -q 'high sev incident'
check 13 "numeric --severity matches the same entries as the word" $?

# t14: misspelled --type must die, not return a silent empty result
fresh
"$BIN" init >/dev/null
printf 'some incident\nbecause reasons\n\n1\n2\n2\n' | "$BIN" new >/dev/null 2>&1
out="$("$BIN" log --type verification-skipped 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'unknown failure type'
check 14 "misspelled --type dies instead of printing an empty log" $?

# t15: unknown severity value must die, not return a silent empty result
fresh
"$BIN" init >/dev/null
printf 'some incident\nbecause reasons\n\n1\n2\n2\n' | "$BIN" new >/dev/null 2>&1
out="$("$BIN" log --severity critical 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'unknown severity'
check 15 "unknown --severity dies instead of printing an empty log" $?

# t16: embedded template heredocs match the canonical files in templates/
# byte-for-byte. templates/ is the copy that gets reviewed and tested; the
# heredoc is the copy that reaches the user. They drifted once already.
fresh
"$BIN" init >/dev/null
diff "$ROOT/templates/hook-push-guard.sh"          .agentscar/templates/hook-push-guard.sh >/dev/null \
  && diff "$ROOT/templates/hook-confirm-destructive.sh" .agentscar/templates/hook-confirm-destructive.sh >/dev/null \
  && diff "$ROOT/templates/rule-skeleton.md"       .agentscar/templates/rule-skeleton.md >/dev/null
check 16 "embedded templates match templates/ byte-for-byte" $?

exit "$fails"
