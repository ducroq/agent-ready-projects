#!/usr/bin/env bash
# Sensitivity harness for tests/lint/size-ratchet.sh (lint rule 8).
#
# A run against this repo passes, because the baseline was generated from it —
# which is exactly what a disabled ratchet looks like. Every case below seeds a
# state the rule claims to catch, or one it must not report.
#
# The rule exists because between v1.15.0 and v1.23.0 templates/curate.md grew
# 11,358 -> 37,971 bytes, more than half of it in a single session, and nothing
# in the framework reported it. The failure mode to protect against here is the
# same one: a check that measures nothing and says so quietly.
set -u
cd "$(dirname "$0")"
CHECK="$(cd ../../lint && pwd)/size-ratchet.sh"
[ -f "$CHECK" ] || { echo "cannot find $CHECK" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mktree() {  # mktree <root>
  local r="$1"
  mkdir -p "$r/templates" "$r/tests/lint"
  printf 'aaaaaaaaaa\n' > "$r/templates/one.md"      # 11 bytes
  printf 'bbbbbbbbbbbbbbbbbbbb\n' > "$r/templates/two.md"   # 21 bytes
  bash "$CHECK" "$r" --update >/dev/null
}

FAIL=0
run_case() {  # run_case <id> <expect: HIT|CLEAN> <needle> <mutator>
  local id="$1" expect="$2" needle="$3" mut="$4"
  local r="$WORK/$id"; mkdir -p "$r"; mktree "$r"; "$mut" "$r"
  local out err rc; err="$WORK/$id.err"
  out="$(bash "$CHECK" "$r" 2>"$err")"; rc=$?
  if [ $rc -gt 1 ]; then
    printf '  FAIL  %s — checker exited %d: %s\n' "$id" "$rc" "$(cat "$err")"; FAIL=1; return
  fi
  # A checker that cannot run prints nothing, which is byte-identical to a clean
  # result. The size line on stderr is what separates them.
  if ! grep -q 'template(s) measured' "$err"; then
    printf '  FAIL  %s — no measurement line; the rule did not run\n' "$id"; FAIL=1; return
  fi
  if [ "$expect" = HIT ]; then
    if printf '%s' "$out" | grep -qF -- "$needle"; then printf '  PASS  %s\n' "$id"
    else printf '  FAIL  %s — expected a violation matching "%s", got: %s\n' "$id" "$needle" "${out:-<none>}"; FAIL=1; fi
  else
    if [ -z "$out" ]; then printf '  PASS  %s\n' "$id"
    else printf '  FAIL  %s — expected no violation, got: %s\n' "$id" "$out"; FAIL=1; fi
  fi
}

echo "positives — states the ratchet must report:"

m_grew() { printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n' > "$1/templates/one.md"; }
run_case P1-file-grew HIT "grew 11 -> 31 bytes" m_grew

# Shrinkage is a failure too, deliberately: a gain that is not locked in leaves
# the ratchet loose at the old, higher number, so the next growth back to it is
# invisible. One command fixes it.
m_shrank() { printf 'a\n' > "$1/templates/one.md"; }
run_case P2-shrank-not-locked-in HIT "lock it in" m_shrank

# A new template must be added deliberately, or growth escapes the ratchet
# simply by arriving in a new file — which is how a skill split into two would
# silently double the surface.
m_new_file() { printf 'cccccccccccccccccccc\n' > "$1/templates/three.md"; }
run_case P3-untracked-new-template HIT "not in the size baseline" m_new_file

m_deleted() { rm "$1/templates/two.md"; }
run_case P4-baseline-entry-vanished HIT "no longer exists" m_deleted

echo
echo "negatives — states it must not report:"

m_none() { :; }
run_case N1-unchanged CLEAN "" m_none

# Content may change freely as long as the size does not grow: the rule governs
# cost, not prose. Rewriting a paragraph to the same length is not a finding.
m_rewritten() { printf 'zzzzzzzzzz\n' > "$1/templates/one.md"; }
run_case N2-same-size-different-content CLEAN "" m_rewritten

# Files outside templates/ are not adopter-facing surfaces and are out of scope;
# tests/ and docs/ growing is not what this rule is about.
m_other_dir() { mkdir -p "$1/docs"; printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n' > "$1/docs/big.md"; }
run_case N3-non-template-growth CLEAN "" m_other_dir

# Nested files are not maxdepth-1 templates; a subdirectory of fixtures or
# checklists must not be swept in, or the baseline churns on unrelated edits.
m_nested() { mkdir -p "$1/templates/checklists"; printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n' > "$1/templates/checklists/x.md"; }
run_case N4-nested-template-dir CLEAN "" m_nested

echo
echo "structural:"
# A missing baseline must refuse loudly rather than report a clean tree.
r="$WORK/S1"; mkdir -p "$r/templates" "$r/tests/lint"; printf 'a\n' > "$r/templates/one.md"
out="$(bash "$CHECK" "$r" 2>&1)"; rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'no baseline'; then
  printf '  PASS  S1-missing-baseline refuses (exit 2)\n'
else printf '  FAIL  S1-missing-baseline — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

# --update must round-trip: regenerate, then a compare run is clean.
r="$WORK/S2"; mkdir -p "$r"; mktree "$r"; printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n' > "$r/templates/one.md"
bash "$CHECK" "$r" --update >/dev/null
if [ -z "$(bash "$CHECK" "$r" 2>/dev/null)" ]; then printf '  PASS  S2-update-round-trips\n'
else printf '  FAIL  S2-update-round-trips — compare still reports after --update\n'; FAIL=1; fi

echo
if [ $FAIL -eq 0 ]; then echo "All size-ratchet fixture cases passed."; else echo "Fixture failures above."; fi
exit $FAIL
