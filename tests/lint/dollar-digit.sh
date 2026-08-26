#!/usr/bin/env bash
# Lint rule 9 — a bare $0-$9 in a skill body is an ARGUMENT, not a variable.
#
# Skill arguments are substituted into the skill BODY before the model ever sees
# it. Measured 2026-08-25 with `/review-changes worktree probe alpha`, six probe
# forms on separate lines:
#
#     written   delivered   substituted
#     $0        worktree    yes — the first argument word
#     $1        probe       yes — the second
#     $(0)      $(0)        no
#     ${0}      ${0}        no
#     $@        $@          no
#     \$0       $0          no — escaped
#
# `templates/curate.md` and `templates/review-changes.md` embed awk programs in
# which `$0` is the whole-line variable. Delivered, a bare `$0` becomes a
# constant: review-changes' Step 1.5 then examines nothing and prints exactly
# what a clean run prints, and curate's verify runner EXECUTES what it extracts,
# so a table cell's escaped pipes are never un-escaped and the command runs
# mangled. That is #77, and it survived because nothing here could see it —
# rule 6 compares two files carrying the same bare `$0`, which agree; and every
# fixture extracts the program from the file and runs it DIRECTLY, with no
# substitution anywhere on the path. The substitution happens between the file
# and the model, where no in-repo runtime check can reach. A lexical rule is the
# only instrument available, which is the argument for having one.
#
# WHICH SAFE FORM DEPENDS ON THE CONTEXT, and saying otherwise is wrong advice.
# All three survive delivery; only one is valid in each place. Measured on this
# box (mawk 1.3.4, bash 5) — the fixture's T-cases re-run it:
#
#                 in an awk program        in a shell snippet
#     $(N)        correct                  `$(1)` runs `1` as a command:
#                                          empty output, rc 0, SILENT
#     ${N}        SYNTAX ERROR, rc 2       correct
#     \$N         SYNTAX ERROR, rc 2       a literal `$1`, not the parameter
#
# So: `$(N)` in awk, `${N}` in shell, `\$N` in prose and in comments. That also
# keeps this rule consistent with `templates/curate.md`, which says `$(0)` is the
# only form correct on both the delivery path and the fixtures' extraction path.
#
# NO PROSE EXEMPTION, and the day this rule was written is the argument for
# that: the only bare `$N` left in any skill body were four comment lines
# explaining #77 — inside a fenced ```bash block, which is where every real
# occurrence of this defect has been — so the warning against `$0` was itself
# delivered as "`$(0)`, never `worktree`". Whether the substituter skips fenced
# blocks or code spans is UNMEASURED here; requiring the escaped form everywhere
# does not depend on the answer, and cannot rot if it changes. The fixture
# ablates both exemptions a maintainer would plausibly add.
#
# Scope is DERIVED, not listed: a skill body is any `templates/**/*.md` carrying
# a `SAVE AS: ... .claude/skills/` marker (rule 3's own predicate) or any
# `.claude/skills/**/SKILL.md`. The recursion is load-bearing — a maxdepth-1
# glob let `templates/skills/new.md` escape the rule by being one directory
# down, while claiming a new skill could not escape by being new.
# `tests/**` is deliberately out of scope: bash runs those directly, so nothing
# is substituted. `templates/physics-tests/` carries LaTeX math (`$10^4$`) and is
# excluded by the SAVE AS predicate, not by depth.
#
# Usage: dollar-digit.sh <repo-root>
# Exit:  0 clean · 1 violations on stdout · 2 could not run
set -u
root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: dollar-digit.sh <repo-root>" >&2; exit 2; }
cd "$root" || { echo "cannot enter $root" >&2; exit 2; }

# A candidate that cannot be READ is the dangerous case, not a missing one: the
# SAVE AS grep below fails on it exactly as it fails on a non-skill, so an
# unreadable skill body would be dropped from the sweep in silence. Refuse.
# find's reach is itself a measurement, and discarding it re-creates the exact
# bug this file was already fixed for once: an unreadable SUBDIRECTORY makes
# find skip it, print to stderr and exit 1, and a pipeline to sort throws all
# three away. The readability loop below cannot help — it only ever sees the
# candidates find EMITTED, never the ones it could not reach. Measured: a
# chmod-000 `templates/locked/` holding a live `$0` scanned green at rc 0.
# `-H` follows a symlinked START point (a symlinked .claude/skills is otherwise
# not descended, silently), while leaving symlinks inside the tree alone.
_cand=$(mktemp); _ferr=$(mktemp)
trap 'rm -f "$_cand" "$_ferr"' EXIT
_frc=0
[ -d templates ] && { find -H templates -name '*.md' -type f >>"$_cand" 2>>"$_ferr" || _frc=$?; }
[ -d .claude/skills ] && { find -H .claude/skills -name 'SKILL.md' -type f >>"$_cand" 2>>"$_ferr" || _frc=$?; }
if [ "$_frc" -ne 0 ] || [ -s "$_ferr" ]; then
  echo "find could not fully traverse the skill directories — this rule may have missed a body:" >&2
  head -3 "$_ferr" >&2
  exit 2
fi
candidates=$(sort -u < "$_cand")
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -r "$f" ] || { echo "cannot read $f — it may be a skill body and this rule could not tell" >&2; exit 2; }
done <<EOF
$candidates
EOF

list=$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      .claude/skills/*) printf '%s\n' "$f" ;;
      *) grep -q 'SAVE AS:.*\.claude/skills/' "$f" && printf '%s\n' "$f" ;;
    esac
  done <<EOF
$candidates
EOF
)
found=$(printf '%s\n' "$list" | grep -c . || true)

# Zero bodies scanned is byte-identical to a clean sweep, and that specific
# green has already fooled this repo once (rule 6, "0 pair(s) compared"). Refuse
# instead of reporting success.
if [ "${found:-0}" -eq 0 ]; then
  echo "found no skill bodies under templates/ or .claude/skills/ — this rule scanned nothing" >&2
  exit 2
fi

issues=0; scanned=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  # awk's exit status is what says the file was examined at all. The first draft
  # ran it inside `< <(...)`, which DISCARDS that status: a stubbed or missing
  # awk, or an unreadable file, produced zero hits and the rule went green while
  # still printing its coverage line. Rules 6 and 7 both exit non-zero under the
  # same broken PATH; this one did not. Capture it, and count files SCANNED
  # rather than files listed, or the coverage line measures the wrong thing.
  #
  # `./$f` because awk reads an operand containing `=` as a variable assignment;
  # the `./` prefix makes the part before `=` an invalid identifier. ENVIRON
  # rather than `-v F=`, because `-v` escape-processes its value and mangles any
  # path containing a backslash.
  if ! hits=$(F="$f" awk '
    {
      line = $(0)                       # `$(0)` for consistency with the skills
      n = length(line)                  # this rule governs; tests/ is out of scope
      for (i = 1; i <= n; i++) {
        if (substr(line, i, 1) != "$") continue
        d = substr(line, i + 1, 1)
        if (d !~ /^[0-9]$/) continue
        # Count the backslashes immediately before the `$`: an ODD run escapes
        # it, an EVEN run does not. `\$0` is safe; `\\$0` is an escaped
        # backslash followed by a live `$0` and must still fire.
        b = 0; j = i - 1
        while (j >= 1 && substr(line, j, 1) == "\\") { b++; j-- }
        if (b % 2 == 1) continue
        ctx = substr(line, (i > 20 ? i - 20 : 1), 60)
        sub(/^[ \t]+/, "", ctx)
        printf "%s:%d: bare `$%s` in a skill body is delivered as an argument word, not a variable — write `$(%s)` in awk, `${%s}` in shell, `\\$%s` in prose. See #77/#86. Near: %s\n", ENVIRON["F"], FNR, d, d, d, d, ctx
      }
    }
  ' "./$f"); then
    echo "awk failed on $f — this rule did not examine it" >&2
    exit 2
  fi
  scanned=$((scanned + 1))
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    printf '%s\n' "$hit"
    issues=$((issues + 1))
  done <<EOF
$hits
EOF
done <<EOF
$list
EOF

# Silence from a checker that never ran is indistinguishable from a clean
# result, so say how many files were actually SCANNED rather than how many were
# listed. NB the equality below is a cheap invariant, NOT the guard against
# under-scanning: `found` is derived from the same list `scanned` iterates, so
# the two cannot diverge — every path that would separate them already exits 2.
# What actually guards under-scanning is the find-status check at the top and
# the per-file awk status below. Keeping this here only pins that structure.
[ "$scanned" -eq "$found" ] || { echo "scanned $scanned of $found skill bodies — the sweep was incomplete" >&2; exit 2; }
echo "      $scanned skill body(ies) scanned for a bare \$0-\$9" >&2
[ "$issues" -eq 0 ] || exit 1
exit 0
