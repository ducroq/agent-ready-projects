#!/usr/bin/env bash
# Install (or verify) the user-global agent-ready-projects skills.
#
# Why this exists: ~/.claude/ is not a repository. A skill authored directly
# there has no history, no review, and no restore path — and because a global
# skill SHADOWS a project-local one of the same name, it is also the copy every
# repo silently uses. So the global install must be DERIVED from the tracked
# copies in this repo's .claude/skills/, never edited in place.
#
#   ./scripts/install-global-skills.sh            # install/refresh, then verify
#   ./scripts/install-global-skills.sh --check     # verify only, exit 1 on drift
#   ./scripts/install-global-skills.sh --check ~/repos   # also scan for inert local copies
#   ./scripts/install-global-skills.sh --force     # install from this tree even if unreleased
#
# Which skills are global is a framework decision, not a preference — see
# docs/GUIDE.md "Where a skill lives: user-global or project-local".
#
# The copy is taken from the WORKING TREE, so "derived from the tracked source"
# above means the tracked *path*, and used to say nothing about the *content*.
# On 2026-08-08 a global `curate` carried an uncommitted draft for ~42 minutes,
# and the text it carried was refuted before release (#33) — for that window the
# skill every repo loaded instructed the opposite of the shipped rule. `--check`
# could not see it: it compares the install against the same working tree.
#
# So the install path refuses unless each source is what the HIGHEST release tag
# reachable from HEAD holds — highest, not nearest; see the tag selection below.
# Three limits worth stating: it compares against a LOCAL tag, so a tag that was
# never pushed still passes; it says nothing about whether the released content
# is correct; and it proves that the worktree *cleans to* the released blob, so
# a path with a lossy checkout filter is refused rather than compared.

set -u
SELF=$(readlink -f "$0" 2>/dev/null || echo "$0")
INVOKED_FROM=$PWD          # captured BEFORE the cd: a relative scan root means
                           # relative to where the user ran this, not to the repo
cd "$(dirname "$SELF")/.." || { echo "cannot reach repo root" >&2; exit 2; }
[ -d .claude/skills ] || { echo "not in the agent-ready-projects repo root: $(pwd)" >&2; exit 2; }

GLOBAL_SKILLS="curate audit-context update-drift"     # generic method, relevant in every repo
LOCAL_ONLY="review-changes release test-verify-memory"      # repo-specific, or only meaningful in some repos

# `set -u` would otherwise abort here with bash's own message and exit 1 — this
# script's "N issue(s) found" code — under cron, systemd or `env -i`.
[ -n "${CLAUDE_SKILLS_DIR:-}" ] || [ -n "${HOME:-}" ] || {
  echo "neither CLAUDE_SKILLS_DIR nor HOME is set: nowhere to install to" >&2; exit 2; }
DEST="${CLAUDE_SKILLS_DIR:-${HOME:-}/.claude/skills}"
CHECK_ONLY=0
FORCE=0
SCAN_ROOT=""
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    --force) FORCE=1 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    "") echo "empty scan root: pass a directory or omit the argument" >&2; exit 2 ;;
    *) [ -n "$SCAN_ROOT" ] && { echo "only one scan root is supported (got '$SCAN_ROOT' and '$arg')" >&2; exit 2; }
       case "$arg" in /*) SCAN_ROOT=$arg ;; *) SCAN_ROOT=$INVOKED_FROM/$arg ;; esac
       SCAN_ROOT=$(readlink -f "$SCAN_ROOT" 2>/dev/null || echo "$SCAN_ROOT") ;;
  esac
done

ISSUES=0
fail() { printf 'FAIL  %s\n' "$1"; ISSUES=$((ISSUES + 1)); }

# First line without a trailing CR. `head -1` on a CRLF checkout yields `---\r`,
# which is not `---`, so the frontmatter check below reported a correctly
# installed skill as unregistrable. Lint rules 4 and 6 strip `\r` deliberately;
# this script did not. Builtins only, so a missing external cannot empty it.
first_line() { local l=""; IFS= read -r l < "$1"; printf '%s' "${l%$'\r'}"; }

# ---- release-state guard (#33) ----------------------------------------------
# Scoped to the files the install actually copies. Widening it to all of
# `.claude/skills/` would refuse whenever a project-local skill is mid-edit,
# which is most of a working session — and a guard that is routinely --force'd
# has stopped being one.
SOURCES=()
for s in $GLOBAL_SKILLS; do SOURCES+=(".claude/skills/$s/SKILL.md"); done

unreleased=""      # non-empty = the reason the sources are not a released state
detail=""          # one line per source that is not what the release holds
TAG=""

# Accumulate with builtins only. An earlier draft funnelled the findings through
# `printf | grep .` to tidy blank lines, which made a missing `grep` empty the
# findings and let the install proceed — the one external command in the guard
# whose failure turned it OFF. list_detail below skips blank lines instead.
add_detail() { detail=$(printf '%s\n%s' "$detail" "$1"); }

if ! command -v git >/dev/null 2>&1; then
  unreleased="git is not available here, so the released state cannot be determined"
elif [ "$(git rev-parse --show-toplevel 2>/dev/null)" != "$(pwd -P)" ]; then
  # Not `--is-inside-work-tree`: that answers true for a checkout sitting INSIDE
  # some other repository, whose tags have nothing to do with these skills. Both
  # this arm and the one above are load-bearing for the DIAGNOSIS rather than the
  # verdict — the comparison below refuses those states anyway, with a worse
  # message. Ablating either changes what the fixture reads, not what it ships.
  unreleased="$(pwd -P) is not the root of a git work tree, so the released state cannot be determined"
else
  # The highest release version reachable from HEAD — NOT `git describe
  # --abbrev=0`, which `templates/release.md` Step 1 specifically forbids: it
  # returns the *nearest* tag, so after a hotfix tagged v1.0.1 merges in behind
  # v1.1.0 it answers v1.0.1, and the guard would then measure a correct tree
  # against a superseded release. The SORT ORDER is the release procedure's; the
  # three filters were not — its own `git tag --sort=-v:refname | head -1` would
  # return a prerelease, a scratch tag, or a tag on an unmerged branch. Step 1
  # now carries the same three filters, so the guard and the procedure answer
  # the same question (#41). They are deliberately not shared code: this runs
  # under `set -u` in a script, Step 1 is a command a human reads and checks.
  #
  # The `case` filter drops prereleases and scratch tags (v1.2.3-rc1, v2-spike)
  # in shell rather than through `grep`, per add_detail's note. It also drops
  # hyphenated CalVer (v2026-08-11); a project tagging that way must widen it.
  while IFS= read -r t; do
    case "$t" in *-*) continue ;; esac
    TAG=$t; break
  done < <(git tag --sort=-v:refname --merged HEAD --list 'v[0-9]*' 2>/dev/null)

  if [ -z "$TAG" ]; then
    # `--tags` and `--unshallow` are not interchangeable, and this line named
    # both states while advising only the remedy for one. A shallow clone
    # may carry tag refs it cannot reach, and a plain `--depth 1` clone starts
    # with none at all. `git fetch --tags` adds refs, not history: `--merged HEAD`
    # walks history, which is precisely what the truncation removed. Measured —
    # 37 tags present after `git fetch --tags`, selector still empty, guard
    # still refusing. That matters more than a wrong word: someone following
    # printed advice that visibly fails reaches for --force next, which is the
    # outcome this whole line exists to prevent.
    # `--is-shallow-repository` is git >= 2.15; the marker file is the fallback,
    # and it is the ONLY arm on older git. `--git-common-dir` (git >= 2.5, so
    # older than the gap it covers), not `--git-dir`: in a linked worktree the
    # latter answers `.git/worktrees/<name>`, where `shallow` does not live, and
    # the branch would then print the tagless remedy — this defect exactly.
    if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ] \
       || [ -f "$(git rev-parse --git-common-dir 2>/dev/null)/shallow" ]; then
      unreleased="no release tag is reachable from HEAD: this clone is shallow, so the tags may be present while the history that would reach them is not. Run \`git fetch --unshallow\`, not --force"
    else
      unreleased="no release tag is reachable from HEAD (v[0-9]* without a hyphen). A tagless clone needs \`git fetch --tags\`, not --force"
    fi
  else
    # Compare the BYTES `cp` would copy against the bytes the release holds, one
    # source at a time — via git's own object ids, so the comparison is filter
    # aware. Two predicates were tried and refuted before this one:
    #
    #   `git diff --name-only <tag>` + `git ls-files --others` asks "does git
    #   think this path changed", which is a different question: --assume-unchanged
    #   and --skip-worktree make git report a modified file clean by request, an
    #   untracked path is invisible to diff, and a symlinked file — or a symlinked
    #   parent DIRECTORY — is compared as a link while `cp` follows it.
    #
    #   `git show <tag>:<path>` against the file on disk compares the raw blob to
    #   a SMUDGED working tree, so a pristine checkout refuses under
    #   core.autocrlf=true (the Git-for-Windows default) or any .gitattributes
    #   filter. `git hash-object --path` applies the clean filter instead, which
    #   is content-preserving for eol, so a correct checkout compares equal. It
    #   is NOT a true inverse — an earlier draft of this comment claimed it was,
    #   which is what the lossy-filter arm below exists to cover.
    # `hash-object` proves clean(disk) == the released blob. `clean` is not
    # always injective, so that is weaker than "these are the released bytes":
    # with `ident`, anything inside a `$Id: ... $` expansion cleans back to
    # `$Id$` and compares equal. The eol/`text` filter — the one that actually
    # occurs on markdown, and the reason a raw-blob comparison was rejected — is
    # content-preserving, so the comparison holds there. Where it does not hold,
    # refuse rather than compare: `git cat-file --filters` is the other side of
    # the same coin and gets `text` wrong (measured), so there is no single
    # command that answers both.
    lossy_filter() {  # 0 = this path's checkout filter can hide an edit
      local a
      a=$(git check-attr ident filter -- "$1" 2>/dev/null) || return 0
      case "$a" in *"ident: set"*) return 0 ;; esac
      case "$a" in
        *"filter: unspecified"*|*"filter: unset"*) return 1 ;;
        *"filter: "*) return 0 ;;
      esac
      return 1
    }

    for src in "${SOURCES[@]}"; do
      # A missing source is the install loop's report to make, not the guard's.
      [ -e "$src" ] || continue
      # `cd -P` + `pwd -P` rather than `readlink -f`: BSD and older macOS
      # `readlink` have no -f, and an arm built on it refused a CLEAN released
      # tree there, claiming all three sources were symlinked — on the very
      # platform line 33 already accommodates for $0. `-L` catches a symlinked
      # leaf; the canonicalised-directory comparison catches a symlinked ancestor.
      if [ -L "$src" ] || [ "$(cd -P "${src%/*}" 2>/dev/null && pwd -P)/${src##*/}" != "$(pwd -P)/$src" ]; then
        # Covers a symlinked leaf and a symlinked ancestor. Refused even when the
        # target happens to match: git holds a link at this path, cp would copy
        # something else, and the two agreeing today is not a property anything
        # checks. Same argument the verify loop makes about a symlinked
        # destination. --force is the escape if you mean it.
        add_detail "$src (reaches its bytes through a symlink — git holds a link here, cp would copy the target)"
      elif lossy_filter "$src"; then
        add_detail "$src (a lossy checkout filter — \`ident\`, or a custom filter driver — is configured for this path, so what git stores cannot be compared with what cp would copy)"
      elif ! want=$(git rev-parse --verify --quiet "$TAG:$src") || [ -z "$want" ]; then
        add_detail "$src (no such path in $TAG, or its object could not be read)"
      elif ! have=$(git hash-object --path="$src" -- "$src" 2>/dev/null) || [ -z "$have" ]; then
        add_detail "$src (could not be read for comparison)"
      elif [ "$want" != "$have" ]; then
        add_detail "$src (differs from $TAG)"
      fi
    done
    [ -n "$detail" ] && unreleased="they are not what $TAG contains — the highest release reachable from HEAD"
  fi
fi

# `printf '%s'` here drops the final line: with no trailing newline `read`
# returns non-zero on it and the loop body never runs FOR THAT LINE. Every
# refusal here lists one path per source, so the last one was always the missing
# one, and with a single offending source the list was empty while the headline
# still read correctly — found by the fixture, not by reading this.
list_detail() { printf '%s\n' "$detail" | while IFS= read -r p; do [ -n "$p" ] && printf '%s%s\n' "$1" "$p"; done; }

REFUSED=0
AHEAD=0            # skills whose install matches the release while the tree moved on (#49)
REFRESH_HINT="run without --check to refresh"
[ -n "$unreleased" ] && REFRESH_HINT="the tracked copy is itself unreleased (see above), so a refresh is refused; tag the release first, or re-run with --force"

if [ -n "$unreleased" ]; then
  if [ "$CHECK_ONLY" -eq 1 ]; then
    printf 'WARN  the global skill sources are not confirmed as released: %s\n' "$unreleased"
    list_detail '        '
    printf '      Anything installed from this tree cannot be shown to match a release.\n'
    printf '      Not counted as an issue below — --check asks whether the install matches the\n'
    printf '      tracked source, which is a separate question (it is how #33 went unnoticed).\n\n'
  elif [ "$FORCE" -eq 1 ]; then
    printf 'WARN  installing from an unreleased tree because --force was passed: %s\n' "$unreleased"
    list_detail '        '
    printf '      Re-run without --force after the release to put %s back on released content.\n\n' "$DEST"
  else
    REFUSED=1
    printf 'REFUSING to install: the global skill sources are not confirmed as released.\n'
    printf '  %s\n' "$unreleased"
    list_detail '    '
    printf '\nA global skill shadows every repo'"'"'s own copy, so installing now would make\n'
    printf 'unreleased content the version every session loads (#33 — it happened).\n'
    printf 'Release first — tag, push, verify the push — then re-run; or pass --force to\n'
    printf 'install from this tree deliberately. Nothing is written to %s.\n' "$DEST"
    printf 'The read-only checks below still run, so this reports the current state.\n\n'
  fi
fi

# Refusing the install must not cancel the checks that write nothing. An earlier
# draft exited here, which meant `install-global-skills.sh ~/repos` on an
# unreleased tree performed no verification and no estate scan at all — a guard
# for #33 silently suppressing the #36/#37 scan.
if [ "$CHECK_ONLY" -eq 0 ] && [ "$REFUSED" -eq 0 ]; then
  echo "Installing global skills into $DEST"
  for s in $GLOBAL_SKILLS; do
    src=".claude/skills/$s/SKILL.md"
    [ -f "$src" ] || { fail "$src missing — nothing to install from"; continue; }
    mkdir -p "$DEST/$s" || { fail "$s: could not create $DEST/$s"; continue; }
    if cmp -s "$src" "$DEST/$s/SKILL.md"; then echo "  $s: already current"
    # `cp`'s status was discarded, so an unwritable destination printed
    # "installed" for every skill while the verify pass below contradicted it.
    elif cp "$src" "$DEST/$s/SKILL.md"; then echo "  $s: installed"
    else fail "$s: could not copy to $DEST/$s/SKILL.md"; fi
  done
  echo
fi

echo "Verifying"
for s in $GLOBAL_SKILLS; do
  if [ ! -f ".claude/skills/$s/SKILL.md" ]; then fail "tracked source .claude/skills/$s/SKILL.md is missing"
  elif [ -L "$DEST/$s" ] || [ -L "$DEST/$s/SKILL.md" ]; then fail "$s at $DEST is a SYMLINK — a global install must be a real copy derived from the tracked source, or drift becomes structurally undetectable"
  elif [ ! -f "$DEST/$s/SKILL.md" ]; then fail "$s is not installed at $DEST/$s/SKILL.md"
  elif ! cmp -s ".claude/skills/$s/SKILL.md" "$DEST/$s/SKILL.md"; then
    # Two states reach this branch and only one is a defect (#49):
    #
    #   install != latest release              genuinely stale — act        exit 1
    #   install == latest release, tree ahead  correct — nothing to do      exit 0
    #
    # The second holds on this repo's own machine on any day with an unreleased
    # skill edit, which during active development is most of them. Reporting it
    # as an issue makes --check return failure daily for a healthy install —
    # the cries-wolf class that v1.15.1 and v1.23.0 each spent a release
    # removing. The exit code is what a hook or wrapper reads; prose is not
    # available to it, so the machine-readable half has to agree with the
    # human-readable half. Reported by an adopter (ovr.news), v1.24.0 triage.
    # Keyed on `$unreleased`, NOT on `$REFUSED`. `REFUSED` is set only on the
    # install path — under `--check` it stays 0, so a guard keyed on it can
    # never fire in the mode this defect was reported in. (The check further
    # down IS keyed on `REFUSED`, deliberately: its comment says the WARN
    # covers the `--check` case. This one is the opposite — `--check` is the
    # only mode where it matters.)
    relblob=""; instblob=""
    if [ -n "$unreleased" ] && [ -n "$TAG" ]; then
      relblob=$(git rev-parse --verify --quiet "$TAG:.claude/skills/$s/SKILL.md")
      instblob=$(git hash-object --path=".claude/skills/$s/SKILL.md" -- "$DEST/$s/SKILL.md" 2>/dev/null)
    fi
    # `[ "$relblob" = "$instblob" ]` alone is satisfied by BOTH being empty —
    # a skill absent from the tag and an unhashable install would then read as
    # healthy. Require a real blob on each side before believing the match.
    if [ -n "$relblob" ] && [ -n "$instblob" ] && [ "$relblob" = "$instblob" ]; then
      printf 'OK    %s at %s matches %s; the tracked copy is ahead of the release, so there is nothing to refresh yet\n' "$s" "$DEST" "$TAG"
      AHEAD=$((AHEAD + 1))
    else
      # The hint has to agree with the guard above, or it sends you straight into
      # a refusal: for an unreleased tree, refreshing is exactly what is blocked.
      fail "$s at $DEST differs from the tracked copy — $REFRESH_HINT"
    fi
  elif [ "$(first_line "$DEST/$s/SKILL.md")" != "---" ]; then
    fail "$s at $DEST has no frontmatter — it is installed but will not register"
  elif [ "$REFUSED" -eq 1 ] && [ -n "$TAG" ] &&
       [ "$(git rev-parse --verify --quiet "$TAG:.claude/skills/$s/SKILL.md")" != \
         "$(git hash-object --path=".claude/skills/$s/SKILL.md" -- "$DEST/$s/SKILL.md" 2>/dev/null)" ]; then
    # The install matches the tracked source and both are unreleased — which is
    # #33 having already happened, and the check above cannot see it because it
    # compares the two copies to each other. Without this, the report on a
    # refusing run reads "0 issue(s)" while $DEST carries the draft.
    #
    # Only on the refusal path. Under --force the warning above has already said
    # it and the install was asked for, so repeating it as an issue would make a
    # deliberate --force exit non-zero; under --check the same WARN covers it,
    # and turning --check red on every unreleased tree is what the WARN exists to
    # avoid.
    fail "$s at $DEST does not match $TAG — an install taken from an unreleased tree is already in place; re-run after the release to replace it"
  fi
done

# A globally-installed name must NOT also exist globally for local-only skills:
# that would shadow every repo's own version with one generic copy.
for s in $LOCAL_ONLY; do
  { [ -e "$DEST/$s" ] || [ -L "$DEST/$s" ]; } && fail "$s is installed globally but is project-local by design — it shadows every repo's own copy"
done

# Inert local copies: a repo holding its own copy of a global skill. The local
# file is never loaded, so it drifts unnoticed and still reads as authoritative.
if [ -n "$SCAN_ROOT" ]; then
  echo
  if [ ! -d "$SCAN_ROOT" ]; then fail "scan root does not exist: $SCAN_ROOT"; SCAN_ROOT=""; fi
fi
# Guarded separately: the check above can blank SCAN_ROOT, and the loop below
# must not then run `find -L ""` — which reports a phantom unreadable path and
# double-counts an error already reported.
if [ -n "$SCAN_ROOT" ]; then
  echo "Scanning $SCAN_ROOT for inert project-local copies"
  scanned=0
  unreadable=0
  benign=0
  # An unwritable or full TMPDIR must not silently disable the scan. Without
  # this branch `finderr` is empty, `2>>""` fails to open, find never runs at
  # all, and the script prints `scanned 0` and `OK` — the #36 defect with a
  # wider blast radius, since it loses every real hit rather than one subtree.
  if ! finderr=$(mktemp 2>/dev/null); then
    fail "could not create a temp file for the scan (TMPDIR unwritable or full) — the estate scan did NOT run"
    SCAN_ROOT=""
  else
    trap 'rm -f "$finderr"' EXIT
  fi
fi
if [ -n "$SCAN_ROOT" ]; then
  for s in $GLOBAL_SKILLS; do
    # -print0: a path containing a newline is otherwise consumed as two records,
    # which reports two bogus inert copies for one real file, inflates `scanned`,
    # and — because neither fragment strips the suffix — defeats the
    # this-repo-is-the-source exclusion below, so the tracked skills could be
    # reported as inert and the user told to delete them (#37).
    while IFS= read -r -d '' hit; do
      scanned=$((scanned + 1))
      repo=${hit%/.claude/skills/$s/SKILL.md}
      [ "$(cd "$repo" 2>/dev/null && pwd -P)" = "$(pwd -P)" ] && continue   # this repo is the source
      fail "inert local copy: $hit (shadowed by $DEST/$s)"
    done < <(LC_ALL=C find -L "$SCAN_ROOT" -path "*/.claude/skills/$s/SKILL.md" -not -path '*/_archive/*' -print0 2>>"$finderr")
  done
  # A subtree find cannot read contributes zero hits and, with stderr discarded,
  # zero warnings — so an unscannable estate and a clean one printed the same
  # `scanned 0` and the same exit 0 (#36).
  #
  # But "find wrote to stderr" is NOT the same predicate as "coverage was lost",
  # and treating them as one makes the check red on ordinary estates. Under -L,
  # a filesystem loop is *handled*: find skips the cycle, keeps walking, and
  # misses nothing — yet it warns, and a virtualenv's `bin/local -> .` or a
  # `docs/current -> ..` is enough to trigger it. A path that vanishes mid-walk
  # (a build, a git clean, an npm install running in a scanned repo) likewise
  # warns without losing ground. Only a permission error means real lost
  # coverage. Unrecognized messages count as lost, because assuming otherwise
  # is how a silent miss gets built. LC_ALL=C above keeps these strings stable.
  #
  # find runs once per global skill, so one bad directory produces one identical
  # error per skill; deduplicate, or the count reads as N times the real ground.
  if [ -s "$finderr" ]; then
    while IFS= read -r line; do
      case "$line" in
        *"Permission denied"*)
          unreadable=$((unreadable + 1))
          [ "$unreadable" -le 10 ] && fail "scan could not read: $line" ;;
        *"File system loop detected"*|*"No such file or directory"*)
          benign=$((benign + 1)) ;;
        *)
          unreadable=$((unreadable + 1))
          [ "$unreadable" -le 10 ] && fail "scan reported an unrecognized error, treating as lost coverage: $line" ;;
      esac
    done < <(sed 's/^find: //' "$finderr" | sort -u)
    # Uncapped, a mid-scan `git clean` over thousands of directories buries every
    # other finding. The count still reflects all of them.
    [ "$unreadable" -gt 10 ] && fail "...and $((unreadable - 10)) further unreadable path(s), not listed"
  fi
  echo "  scanned $scanned candidate path(s), $unreadable unreadable, $benign skipped (loops/transient); _archive/ is excluded by design and is not checked"
fi

echo
if [ "$REFUSED" -eq 1 ]; then
  # Exit 2, not 1: the install was refused, which is a different outcome from
  # "ran and found N problems" — and $ISSUES here counts the consequences of not
  # having installed, so a 0 must not read as success.
  printf 'REFUSED — nothing was installed (see the top of this report). %s issue(s) reported by the read-only checks.\n' "$ISSUES"
  exit 2
elif [ $ISSUES -eq 0 ] && [ "$AHEAD" -gt 0 ]; then
  # Do not claim they match the tracked source when at least one matches the
  # RELEASE and the tracked copy has moved on. Both are healthy; they are not
  # the same statement, and the summary is the line most likely to be the only
  # one read.
  printf 'OK — %s global skill(s) match %s, with the tracked copy ahead; the rest match the tracked source. Nothing to refresh until the release is tagged.\n' "$AHEAD" "$TAG"
  exit 0
elif [ $ISSUES -eq 0 ]; then echo "OK — global skills match the tracked source."; exit 0
else echo "$ISSUES issue(s) found."; exit 1; fi
