#!/usr/bin/env bash
# Rule 17 — a shell option welded to an orphaned comment: `set -u# <text>` (#160).
#
# Usage: opt-comment.sh <repo-root>
# Violations to stdout; coverage line to stderr. Exit 0 clean, 1 violations, 2 could not run.
#
# WHY. `#` opens a comment only at a WORD START, so `set -u# nounset for safety`
# hands `set` a malformed token. ⚠️ **What happens next VARIES, and the variation
# is the reason this is a rule rather than a style note** — measured on GNU bash
# 5.3.9, not verified on dash or zsh:
#   set -u# x          -> `set: -#: invalid option`, u NOT applied, script CONTINUES
#                         at rc 0. Silent, and the guard is absent. The live case.
#   set -eo pipefail#  -> `-e` IS applied, `pipefail` is not, and the script ABORTS
#                         at line 1 with rc 2. Loud, but the options are still wrong.
#   set -ue# x         -> neither applied.
# So the line never does what it reads as doing, and whether you find out depends
# on which option was malformed. A draft of this header said "never applied, the
# script runs on" for all of them; its own fixture case T2 refutes that.
#
# ⚠️ `bash -n` PASSES on it — measured on both files that carried it — so #160's
# proposed `bash -n` sweep does not cover this class; the two are complementary.
# Five instruments were green while it sat in the tree: the runners exited 0,
# `bash -n` passed, lint was 13/13, the fixture runner swallowed the stderr, and
# the author's own "all PASS" report was true. It was found by a lens reading a
# diff, which is the most expensive instrument available. This is the four-line
# grep that replaces it.
#
# Scope is every shell file plus the fenced bash an adopter copies: the defect is
# a typo, and a typo has no respect for which tree it lands in.
#
# ⚠️ WHAT THIS RULE CANNOT SEE, stated because a clean run is otherwise read as
# more than it is. The class is "a `#` that is not at a word start is not a
# comment"; the predicate is `set` at the start of a line. Measured misses, all of
# which `bash -n` also passes: `shopt -s nullglob# x`, `export LC_ALL=C# x`,
# `trap ... EXIT# x`, `readonly X=1# x`, `cd /tmp# x`, and any `set` that is not
# line-initial (`if true; then set -u# x; fi`). `set` is where it has bitten;
# widening to the other builtins needs its own seeded cases, not a guess.
set -u

root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: opt-comment.sh <repo-root>" >&2; exit 2; }
cd "$root" || exit 2

WORK="$(mktemp -d)" || exit 2
trap 'rm -rf "$WORK"' EXIT

# -print0: a path with a space or newline is legal and must not be word-split.
find . -name '.git' -prune -o -type f \( -name '*.sh' -o -name '*.md' -o -name '*.bash' \) -print0 > "$WORK/pop" || exit 2

n=0; bad=0; skipped=0; unread=0
while IFS= read -r -d '' f; do
  n=$((n + 1))
  # An unreadable file prints nothing, which is what a clean file prints. Counting
  # it as "scanned" is the silence this rule family exists to end (#41, rule 9's
  # fixture pins the same guard).
  [ -r "$f" ] || { echo "rule 17: could not read $f — not scanned; this is not a clean result."; unread=$((unread + 1)); bad=$((bad + 1)); continue; }
  # `set`, then ONLY option-shaped words, then a `#` welded to the last of them.
  # Three drafts, each refuted by a seeded case:
  #   1. `set[[:space:]]+-[a-zA-Z]+#` missed `set -eo pipefail# x`, where the `#`
  #      welds to the option NAME rather than the flag run.
  #   2. "any non-space before a `#` on a set line" flagged five legal lines:
  #      `set -x; echo "issue#123"`, `set -- "$@" "#tag"`, vim's
  #      `set statusline=%#WarningMsg#`, `set accent=#ff0000` in prose, and any
  #      `set` inside a heredoc. Ten of this repo's own fixture runners seed
  #      heredocs, so that draft would have fired on the next seeded defect.
  #   3. This one: the token run is constrained, so `;`, `=`, `--` and a quote all
  #      break the match before the `#` is reached.
  # ⚠️ It still cannot tell a heredoc or a fenced example from live shell — that is
  # what the declared exemption below is for.
  while IFS= read -r hit; do
    # Declared, never guessed — the same disposition rules 11 and 13 take. A line
    # that DEMONSTRATES the defect (a fixture seeding it, a doc quoting it) is not
    # the defect, and without this the rule fires on the next seeded case.
    case "$hit" in *"lint-skip: opt-comment"*) skipped=$((skipped + 1)); continue ;; esac
    echo "$f:$hit — a shell option welded to a comment: \`#\` opens a comment only at a word start, so this passes the option as written, errors at rc 2, and the option is NEVER APPLIED. \`bash -n\` passes on it (#160). Put whitespace before the \`#\`."
    bad=$((bad + 1))
  done < <(grep -nE '^[[:space:]]*set([[:space:]]+[-+]?[A-Za-z]+)+#' "$f" 2>/dev/null)
done < "$WORK/pop"

[ "$n" -gt 0 ] || { echo "rule 17: no shell or markdown files found — the population is empty, not clean" >&2; exit 2; }
echo "      $n file(s) found, $((n - unread)) scanned for an option welded to a comment; $bad hit(s), $skipped declared-exempt" >&2
[ "$bad" -eq 0 ] && exit 0
exit 1
