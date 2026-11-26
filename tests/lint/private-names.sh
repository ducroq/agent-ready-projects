#!/usr/bin/env bash
# Rule 12: no private project name in a tracked file.
#
# Usage: private-names.sh <repo-root> [name-file]
#        private-names.sh --commits <range> [name-file]   (in a repo: each commit message)
#        private-names.sh --text <file> [name-file]       (one message: the commit-msg hook)
#
# A commit message is as public as a file once pushed, and `git commit --amend
# --no-edit` keeps the old message after the file is fixed (#247). A PR title and
# body are not scanned: CI has no name list, since the list cannot be tracked.
#
# Violations go to stdout, one per line, for the caller to count. Coverage notes
# (how many names were checked over how many files) go to stderr — the caller
# must assert that line appeared rather than reading empty stdout as "clean",
# because a checker with an empty name list produces exactly the same stdout.
#
# Exit: 0 clean, 1 violations found, 2 could not run (bad arguments, no list).
#
# WHY THIS EXISTS. This repo is public and its author works in an estate of
# private repos. Adopter names reached SHIPPED templates (`templates/curate.md`
# used a real private repo as its cross-repo example), released CHANGELOG
# entries, and test fixtures — and `memory/gotcha-log.md` had already recorded
# the lesson, prescribing "neutral placeholders" and naming this rule as the
# missing piece, one release before it happened again.
#
# ⚠️ THE NAME LIST IS NOT TRACKED, and that is the whole design problem. A
# tracked denylist of private names publishes exactly what it protects. So the
# list lives outside the repo, the rule reports SKIPPED when it is absent, and
# the runner counts that as not-run rather than as a pass — "a rung you cannot
# run is not a pass" (templates/audit-context.md). Regenerate it with:
#
#     gh repo list --limit 300 --json name,visibility \
#       -q '.[] | select(.visibility != "PUBLIC") | .name' > ~/.config/agent-ready/private-names
#
# and add any local-only project directory that has no GitHub repo at all —
# those are invisible to `gh` and two of them leaked here.
#
# ⚠️ THE POPULATION IS TRACKED **PLUS UNTRACKED-NOT-IGNORED**, so a name in a
# brand-new file is caught before it is committed rather than one commit later.
# Measured the hard way: a tracked-only first draft passed clean over this rule's
# own fixture, then reported it the moment it was committed. Gitignored files stay
# out — `memory/` here is maintainer-local and legitimately full of these names.
#
# ⚠️ SHORT AND GENERIC NAMES ARE REJECTED, not matched. A private repo called
# `infra`, `docs` or `config` would match this repo's own prose everywhere; a
# sweep over 356 estate directory names found the overwhelming majority to be
# ordinary English words. Names under MINLEN characters, and names on the
# generic list below, are reported to stderr as UNCHECKED so the gap is visible
# rather than silently absent. This trades recall for a usable signal, exactly
# the trade the retired dead-reference extractor had to make (#51).
set -u

MINLEN=6

usage() { printf 'usage: private-names.sh <repo-root> | --commits <range> | --text <file>  [name-file]\n' >&2; exit 2; }
[ $# -ge 1 ] || usage
MSGDIR="" KIND="a tracked file"
case "$1" in
  --commits|--text)
    [ $# -ge 2 ] || usage
    MSGDIR=$(mktemp -d) || exit 2; trap 'rm -rf "$MSGDIR"' EXIT
    if [ "$1" = --text ]; then
      # git drops `#` lines and everything under the `git commit -v` scissors, so a
      # branch name in the template is not a leak. A `-F` message keeps its `#` lines;
      # rule 12's --commits scan reads the stored message and still catches those.
      [ -r "$2" ] || usage
      sed '/^# -\{24\} >8 -\{24\}$/,$d; /^#/d' -- "$2" > "$MSGDIR/message" || exit 2
      KIND="the commit message"
    else
      KIND="a commit message"
      revs=$(git rev-list "$2" 2>/dev/null) || { printf 'private-names: cannot list commits %s\n' "$2" >&2; exit 2; }
      for c in $revs; do git log -1 --format=%B "$c" > "$MSGDIR/commit $c" || exit 2; done
    fi
    shift 2; set -- . "$@" ;;
esac
ROOT="$1"
[ -d "$ROOT" ] || usage
NAMEFILE="${2:-${AGENT_READY_PRIVATE_NAMES:-$HOME/.config/agent-ready/private-names}}"

cd "$ROOT" || exit 2
GF=-niIF   # -F: a name may hold regex metacharacters. -i: an agent id arrives lowercased.
population() {  # NUL-separated paths to scan
  if [ -n "$MSGDIR" ]; then (cd "$MSGDIR" && find . -type f -print0); else git ls-files -z --cached --others --exclude-standard; fi
}

if [ ! -f "$NAMEFILE" ]; then
  printf 'private-names: SKIPPED — no name list at %s, so NOTHING was checked. See the header for how to generate one.\n' "$NAMEFILE" >&2
  exit 2
fi

# Generic words that would match this repo's own vocabulary. A private repo
# whose name is on this list cannot be checked by a substring rule at all; it is
# reported as UNCHECKED rather than skipped in silence.
GENERIC='^(agents?|infra|docs?|config|content|core|data|design|guide|ideas|model|network|notes|output|papers|personal|probe|prompts|public|research|sandbox|server|skills|sources|specs|static|storage|temp|tools|topics|training|utils|website)$'

names=0; unchecked=0; violations=0
while IFS= read -r name; do
  name="${name%%[[:space:]]*}"
  [ -n "$name" ] || continue
  case "$name" in \#*) continue;; esac
  if [ "${#name}" -lt "$MINLEN" ]; then
    printf 'private-names: UNCHECKED (shorter than %d chars, would match ordinary prose): %s\n' "$MINLEN" "$name" >&2
    unchecked=$((unchecked + 1)); continue
  fi
  if printf '%s' "$name" | tr 'A-Z' 'a-z' | grep -qE "$GENERIC"; then
    printf 'private-names: UNCHECKED (generic word, would match this repo everywhere): %s\n' "$name" >&2
    unchecked=$((unchecked + 1)); continue
  fi
  names=$((names + 1))
  while IFS= read -r hit; do
    printf '%s: private project name in %s: %s\n' "${hit#./}" "$KIND" "$name"
    violations=$((violations + 1))
  done < <(population | { [ -z "$MSGDIR" ] || cd "$MSGDIR"; xargs -0 grep $GF -- "$name" /dev/null 2>/dev/null; } | cut -d: -f1,2)
done < "$NAMEFILE"

files=$(population | tr -cd '\0' | wc -c | tr -d ' ')
[ -n "$MSGDIR" ] && what="message(s)" || what="tracked file(s)"
printf 'private-names: %d name(s) checked against %d %s; %d unchecked (too short or generic)\n' \
  "$names" "$files" "$what" "$unchecked" >&2

[ "$names" -gt 0 ] || { printf 'private-names: SKIPPED — the name list yielded 0 usable names, so NOTHING was checked.\n' >&2; exit 2; }
[ "$violations" -eq 0 ] && exit 0 || exit 1
