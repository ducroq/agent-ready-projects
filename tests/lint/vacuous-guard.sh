#!/usr/bin/env bash
# Lint rule 10 — an ablation that cannot kill anything.
#
# Usage: vacuous-guard.sh <repo-root>
# Violations to stdout, one per line. Coverage note to stderr — the caller must
# assert that line appeared, because a checker that cannot run produces exactly
# the same stdout as a clean one.
# Exit: 0 clean, 1 violations, 2 could not run.
#
# SCOPE, stated because "a check that cannot fail" is undecidable in general and
# this rule does NOT attempt it. Two lexical shapes only, both observed here:
#
#   (a) a mutation whose replacement equals its target modulo whitespace. The
#       ablation applies cleanly, the suite reports it as a passing guard, and it
#       constrains nothing. Observed 2026-08-27: an ablation on the emphasis
#       check rewrote a printf's TEXT while the assertion only tested for
#       non-empty output, so it killed nothing and read as a pass.
#   (b) an ablation declaring an EMPTY expected kill set. An ablation that is
#       expected to break no case is a tautology by construction.
#
# What it cannot see: a mutation that changes something real which no assertion
# happens to measure. That is the larger population and it needs the mutant run,
# not a lexer. This rule is a floor, not a ceiling.
set -u
usage() { printf 'usage: vacuous-guard.sh <repo-root>\n' >&2; exit 2; }
[ $# -eq 1 ] || usage
ROOT="$1"
[ -d "$ROOT" ] || { printf 'vacuous-guard: not a directory: %s\n' "$ROOT" >&2; exit 2; }
cd "$ROOT" || { printf 'vacuous-guard: cannot enter %s\n' "$ROOT" >&2; exit 2; }

FOUND=0
scanned=0
hits=$(mktemp); trap 'rm -f "$hits"' EXIT
while IFS= read -r f; do
  scanned=$((scanned + 1))
  # `ablate "LABEL" 'OLD' 'NEW' "WANT"` — tolerate the line continuations these
  # calls routinely use by joining continued lines before matching.
  awk -v F="$f" '
    { line = $0
      while (line ~ /\\$/ && (getline nxt) > 0) { sub(/\\$/, "", line); line = line nxt }
      if (line !~ /(^|[^A-Za-z_])[A-Za-z_]*ablate[ \t]/) next
      n = split(line, tok, /'"'"'/)          # split on single quotes: tok[2]=OLD, tok[4]=NEW
      if (n >= 5) {
        old = tok[2]; new = tok[4]
        o = old; w = new
        gsub(/[ \t]/, "", o); gsub(/[ \t]/, "", w)
        if (o == w) {
          printf "%s: an ablation mutates %s -> %s, which differ only in whitespace — it kills nothing and reads as a passing guard\n", F, substr(old,1,40), substr(new,1,40)
        }
      }
      # empty expected kill set: the final "" argument
      if (line ~ /ablate[^#]*""[ \t]*$/)
        printf "%s: an ablation declares an EMPTY expected kill set — it is expected to break no case, which is a tautology\n", F
    }
  ' "$f" >>"$hits"
# #125's class, one rule over: `git ls-files` enumerates NOTHING outside a work
# tree — a tarball export, a vendored copy, .git removed — so this rule reported
# "could not run (exit 2)" and the whole suite went red for a reason unrelated to
# any ablation. Unlike rule 1 it failed LOUDLY, which is why it was not the filed
# bug, but a tarball consumer still cannot run the suite. Fall back to `find`.
# The two populations differ: `git ls-files` omits untracked files and `find`
# includes them. That is the safe direction here — an untracked ablation runner is
# still an ablation runner, and this rule's job is to catch one that cannot kill.
done < <(if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
           git ls-files 'tests/**/*.sh' 'tests/*.sh' 2>/dev/null
         else
           find tests -name '*.sh' -type f 2>/dev/null | LC_ALL=C sort
         fi)
cat "$hits"
[ -s "$hits" ] && FOUND=1

printf 'vacuous-guard: %d shell file(s) under tests/ scanned for no-op ablations\n' "$scanned" >&2
[ "$scanned" -gt 0 ] || { printf 'vacuous-guard: scanned nothing — the file list is empty\n' >&2; exit 2; }
exit "$FOUND"
