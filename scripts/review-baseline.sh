#!/usr/bin/env bash
# review-baseline.sh — review-changes Step 1: resolve the baseline, size the change,
# list the changed files (#333). Moved out of the skill, where every pre-commit
# review paid for ~2k bytes of bash it did not need to read.
#
# Usage: bash review-baseline.sh        (anywhere inside the repo under review)
#
# Report on stdout; BASELINE UNRESOLVED and HEAD IS CONTAINED IN on stderr. The
# last two stdout lines are ROOTFALLBACK=<0|1> and BASE=<ref>, for the caller to
# read: a shell variable set here does not reach the caller's shell. Exit 2: not a
# git repo, or no commits (nothing can be reviewed); BASE= is then not printed.
#
# The editor's notes once lived in docs/rationale/review-changes.md, because the
# skill's bash blocks were loaded on every run. They are back beside their code.
set -u
[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || { echo "review-baseline: not inside a git work tree — nothing can be reviewed" >&2; exit 2; }

# Every arm ends in a success, so a copy run under `set -e` (as this block once
# was) cannot abort before the fallback, the one place reporting the failure.
BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD) ||
# Fully qualified: `rev-parse` resolves refs/heads/ first, so a LOCAL branch named
# `origin/main` would win and silently reintroduce #64.
BASE=$(for c in refs/remotes/origin/main refs/remotes/origin/master main master; do
         git rev-parse --verify --quiet "$c" >/dev/null && { printf %s "$c"; break; }; done) || :
# On the default branch HEAD...HEAD is empty, so the upstream is the baseline.
if [ -n "${BASE:-}" ] && [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" = "${BASE##*/}" ]; then
  BASE=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || printf %s '')
fi
# An empty or dangling BASE diffs to nothing, which is what a clean tree yields.
# The fallback is NOT "the whole branch": three-dot excludes the root's own
# content, so a one-commit repo diffs to NOTHING (#149). No `${BASE:-sentinel}`
# placeholder — any sentinel word is a legal branch name.
ROOTFALLBACK=0
{ [ -n "${BASE:-}" ] && git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; } || {
  # `|| :` keeps the arm a success for the same reason; the abort below says why.
  BASE=$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -1) || :
  [ -n "${BASE:-}" ] || { echo "review-baseline: no commits in this repository — nothing can be reviewed" >&2; exit 2; }
  ROOTFALLBACK=1
  # PRINTED as well as returned: the token is what the skill's terminator keys off.
  { echo "BASELINE UNRESOLVED (ROOTFALLBACK=1) — fell back to root commit $BASE,"
    echo "  whose OWN content \"\$BASE\"...HEAD EXCLUDES. Run 'git show --stat $BASE'"
    echo "  too. Report this as a FINDING, never a clean result — Step 1.5's file"
    echo "  list carries the same term and the same hole."; } >&2
}

# #153 — a baseline can RESOLVE and still leave every term legitimately empty
# (HEAD already contained in $BASE). No other guard fires, so unreviewed commits
# report as a clean review. A diagnostic, not an abort.
# ⚠️ The equality case is EXCLUDED, or this fires on the commonest pre-commit
# state there is, and a guard that cries wolf is skipped.
if git merge-base --is-ancestor HEAD "$BASE" 2>/dev/null &&
   [ "$(git rev-parse HEAD)" != "$(git rev-parse "$BASE^{commit}" 2>/dev/null)" ]; then
  { echo "HEAD IS CONTAINED IN $BASE — nothing on this branch is absent from the"
    echo "  baseline, so an empty diff below is expected and is NOT a clean review."
    echo "  If you expected changes you are not on the branch you think: check"
    echo "  'git branch --show-current' and 'git log --oneline $BASE..<your-branch>'."
    echo "  Report this as a FINDING, never as a clean result."; } >&2
fi

# Unrelated histories: "$BASE"...HEAD fails with no merge base, and every committed
# term would read `none`, a clean result on commits nobody compared.
git merge-base "$BASE" HEAD >/dev/null 2>&1 || {
  echo "BASELINE UNRESOLVED (NO MERGE BASE) — HEAD shares no history with $BASE, so"
  echo "  the committed term is empty. Report this as a FINDING, never a clean result."; } >&2

# ⚠️ ROOT-ANCHORED on purpose: `ls-files` defaults to the CWD SUBTREE while every
# diff term is repo-wide. `core.quotePath=false`: a C-quoted path misses its tier.
top=$(git rev-parse --show-toplevel)
untracked() { git -C "$top" -c core.quotePath=false ls-files "$@" --others --exclude-standard; }

echo "== size: the whole change that will land, all four terms"
term() { _s=$(git diff --shortstat "$@"); printf '%s\n' "${_s:- none}"; }
printf 'committed on this branch:%s' ""; term "$BASE"...HEAD
printf 'unstaged:                %s' ""; term
printf 'staged:                  %s' ""; term --cached
# Untracked lines count too — no diff term sees them (#145). No `xargs`: on empty
# input plain xargs runs `wc -l` on stdin and BLOCKS on a terminal, and `-r` is
# GNU-only. `-z`, because a C-quoted path opens nothing (measured 5 against a true
# 105). Braced, or a broken symlink's failed
# open reports on stderr, the findings channel, before `2>` applies.
printf 'untracked:                %s lines\n' "$(untracked -z | while IFS= read -r -d '' f; do
  { wc -l < "$top/$f"; } 2>/dev/null || echo 0; done | awk '{ n += $(1) } END { print n + 0 }')"

# Renames, modes, binaries and submodules are invisible to --stat, hence --summary.
echo "== changed files: committed (--stat, then --summary -M), unstaged, staged, untracked"
git diff --stat "$BASE"...HEAD
git diff --summary -M "$BASE"...HEAD
git diff --stat
git diff --cached --stat
# #145 — no diff variant lists a file git has not seen, so "any new file in a HIGH
# path" fired on a class this step could not observe. An untracked file gets a tier.
untracked | sed 's/^/untracked: /'

printf 'ROOTFALLBACK=%s\n' "$ROOTFALLBACK"
printf 'BASE=%s\n' "$BASE"
