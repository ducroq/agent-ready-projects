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
# line-initial (`if true; then set -u# x; fi`). `set` is where it has bitten.
# WIDENED (#160) by a second predicate, welded_builtin() below, with its own
# seeded cases: all eight of those shapes now report, and the legal lines that
# kept the first predicate narrow stay quiet. What it still cannot see: a builtin
# reached through `command`/`builtin`/`env`, and any other command.
set -u

root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: opt-comment.sh <repo-root>" >&2; exit 2; }
cd "$root" || exit 2

WORK="$(mktemp -d)" || exit 2
trap 'rm -rf "$WORK"' EXIT

# -print0: a path with a space or newline is legal and must not be word-split.
find . -name '.git' -prune -o -type f \( -name '*.sh' -o -name '*.md' -o -name '*.bash' \) -print0 > "$WORK/pop" || exit 2

# ⚠️ SELF-REFERENCE, and it is a known axis in this repo (#174): a marker cannot be
# written ABOUT in its own syntax. This file defines the marker string and its
# fixture constructs it, so every mention there reads as a stale declaration. Both
# are skipped from the STALE scan only — the defect scan still covers them, which
# is the half that matters, since the original instance was in two fixture runners.
# ⚠️ ONE predicate for both halves, and this is the blocker that made it so. The
# marker used to be honoured everywhere while the stale scan covered only shell,
# so a marker in markdown was never policed AND still suppressed the real defect
# that landed on its line — measured in a `templates/*.md` fenced block, the exact
# surface adopters copy. "The defect scan still covers markdown in full" was false
# for precisely the lines the trade gave up. Now: where a marker is not policed, it
# is not honoured. A demonstration in markdown is reported — noise, not silence.
policed() {
  case "$1" in
    *.sh|*.bash) ;;
    *) return 1 ;;
  esac
  # The definition and its test write the marker without meaning it. A closed set:
  # both are shell, both are policed for defects, neither is policed for staleness.
  case "$1" in
    */tests/lint/opt-comment.sh|*/tests/fixtures/opt-comment/run.sh) return 1 ;;
  esac
  return 0
}

# Second predicate (#160). A `#` welded to the end of a word in a segment whose
# command is one of these builtins, followed by whitespace or end of line, is not
# a comment: the text is passed on as arguments. Quote-aware; stops at a real
# comment; skips `$#`, `${#` and `=#` (a value), and a `#` inside a word (`a#b`).
# `set` is read here only when it is NOT the first command on the line, and only
# with option-shaped words, since the first predicate already owns that case and
# vim `set statusline=%#W#` must stay quiet. Prints `<line>:<text>` like grep -n.
welded_builtin() {
  awk '
    BEGIN { split("shopt export readonly declare local typeset trap cd umask set", b, " ")
            for (k in b) isb[b[k]] = 1 }
    function segcheck() {
      if (!isb[cmd]) return 0
      if (cmd != "set") return 1
      if (segno == 1) return 0
      return (substr(line, cstart, i - cstart) ~ /^set([ \t]+[-+]?[A-Za-z]+)+$/)
    }
    { line = $0; n = length(line); q = ""; segno = 0; newseg = 1; cmd = ""; cstart = 0; wstart = 1; inw = 0
      for (i = 1; i <= n; i++) {
        c = substr(line, i, 1)
        if (q != "") { if (c == q) q = ""; else if (c == "\\" && q == "\"") i++; continue }
        if (c == "\\") { i++; wstart = 0; continue }
        if (c == "\"" || c == "\047") { q = c; wstart = 0; continue }
        if (c == " " || c == "\t") { wstart = 1; continue }
        # `(` after `=` or `$` opens an array or a substitution INSIDE the word,
        # so its `)` is no boundary: `arr=(a b)# x` welds the # (review finding).
        if (c == "(" && (substr(line, i - 1, 1) == "=" || substr(line, i - 1, 1) == "$")) { inw++; wstart = 0; continue }
        if (c == ")" && inw > 0) { inw--; wstart = 0; continue }
        if (c == ";" || c == "&" || c == "|" || c == "(" || c == ")" || c == "{" || c == "}") {
          newseg = 1; wstart = 1; continue }
        if (c == "#") {
          if (wstart) break
          p = substr(line, i - 1, 1); nx = substr(line, i + 1, 1)
          if (p == "$" || p == "{" || p == "=") { wstart = 0; continue }
          if ((nx == "" || nx == " " || nx == "\t") && segcheck()) { print NR ":" line; break }
          wstart = 0; continue
        }
        if (wstart && newseg) {
          w = substr(line, i); sub(/[ \t;&|(){}].*/, "", w)
          if (w != "then" && w != "do" && w != "else" && w != "if" && w != "while" && w != "until" && w != "!") {
            segno++; cmd = w; cstart = i; newseg = 0 }
        }
        wstart = 0
      } }' "$1" 2>/dev/null
}

stale_scan() {
  # ⚠️ The stale scan fired on FOUR self-reference sites in a row — this rule, its
  # fixture, its catalog row and a work-item paragraph — because every document
  # that WRITES the marker carries it on a line with no defect. Patching them one
  # at a time is whack-a-mole. That is #174's axis: change where the marker is
  # read, not what it is.
  policed "$1" || return 0
  # Line 0 is a sentinel: with an EMPTY first file, awk NR == FNR is true for
  # every stdin line too, and the stale scan would print nothing, silently.
  { echo 0; welded_builtin "$1" | cut -d: -f1; } > "$WORK/wb.lines"
  grep -n 'lint-skip: opt-comment' "$1" 2>/dev/null |
    grep -vE '^[0-9]+:[[:space:]]*set([[:space:]]+[-+]?[A-Za-z]+)+#' |
    awk -F: 'NR == FNR { w[$1] = 1; next } !($1 in w)' "$WORK/wb.lines" -
}

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
    if policed "$f"; then
      case "$hit" in *"lint-skip: opt-comment"*) skipped=$((skipped + 1)); continue ;; esac
    fi
    echo "$f:$hit — a shell option welded to a comment: \`#\` opens a comment only at a word start, so this passes the option as written, errors at rc 2, and the option is NEVER APPLIED. \`bash -n\` passes on it (#160). Put whitespace before the \`#\`."
    bad=$((bad + 1))
  done < <(grep -nE '^[[:space:]]*set([[:space:]]+[-+]?[A-Za-z]+)+#' "$f" 2>/dev/null)
  while IFS= read -r hit; do
    if policed "$f"; then
      case "$hit" in *"lint-skip: opt-comment"*) skipped=$((skipped + 1)); continue ;; esac
    fi
    echo "$f:$hit — a \`#\` welded to a word is not a comment: \`#\` opens one only at a word start, so the word and the text after it are passed as ARGUMENTS. \`bash -n\` passes on it (#160). Put whitespace before the \`#\`."
    bad=$((bad + 1))
  done < <(welded_builtin "$f")
  # ⚠️ A marker on a line the predicate does not match is STALE: it exempts
  # nothing today and whatever is written on that line tomorrow. Same rule the
  # prior art carries, and the same one rule 14's exemption was tightened to.
  while IFS= read -r stale; do
    case "$stale" in
      *"lint-skip: opt-comment"*)
        printf '%s:%s [STALE EXEMPTION: the line carries `lint-skip: opt-comment` but no welded option is present — remove it, or it licenses whatever lands here next]\n' "$f" "$stale"
        bad=$((bad + 1)) ;;
    esac
  done < <(stale_scan "$f")
done < "$WORK/pop"

[ "$n" -gt 0 ] || { echo "rule 17: no shell or markdown files found — the population is empty, not clean" >&2; exit 2; }
echo "      $n file(s) found, $((n - unread)) scanned for an option welded to a comment; $bad hit(s), $skipped declared-exempt" >&2
[ "$bad" -eq 0 ] && exit 0
exit 1
