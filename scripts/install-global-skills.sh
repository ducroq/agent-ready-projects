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
#
# Which skills are global is a framework decision, not a preference — see
# docs/GUIDE.md "Where a skill lives: user-global or project-local".

set -u
SELF=$(readlink -f "$0" 2>/dev/null || echo "$0")
INVOKED_FROM=$PWD          # captured BEFORE the cd: a relative scan root means
                           # relative to where the user ran this, not to the repo
cd "$(dirname "$SELF")/.." || { echo "cannot reach repo root" >&2; exit 2; }
[ -d .claude/skills ] || { echo "not in the agent-ready-projects repo root: $(pwd)" >&2; exit 2; }

GLOBAL_SKILLS="curate audit-context update-drift"     # generic method, relevant in every repo
LOCAL_ONLY="review-changes release test-verify-memory"      # repo-specific, or only meaningful in some repos

DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CHECK_ONLY=0
SCAN_ROOT=""
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    "") echo "empty scan root: pass a directory or omit the argument" >&2; exit 2 ;;
    *) [ -n "$SCAN_ROOT" ] && { echo "only one scan root is supported (got '$SCAN_ROOT' and '$arg')" >&2; exit 2; }
       case "$arg" in /*) SCAN_ROOT=$arg ;; *) SCAN_ROOT=$INVOKED_FROM/$arg ;; esac
       SCAN_ROOT=$(readlink -f "$SCAN_ROOT" 2>/dev/null || echo "$SCAN_ROOT") ;;
  esac
done

ISSUES=0
fail() { printf 'FAIL  %s\n' "$1"; ISSUES=$((ISSUES + 1)); }

if [ "$CHECK_ONLY" -eq 0 ]; then
  echo "Installing global skills into $DEST"
  for s in $GLOBAL_SKILLS; do
    src=".claude/skills/$s/SKILL.md"
    [ -f "$src" ] || { fail "$src missing — nothing to install from"; continue; }
    mkdir -p "$DEST/$s"
    if cmp -s "$src" "$DEST/$s/SKILL.md"; then echo "  $s: already current"
    else cp "$src" "$DEST/$s/SKILL.md"; echo "  $s: installed"; fi
  done
  echo
fi

echo "Verifying"
for s in $GLOBAL_SKILLS; do
  if [ ! -f ".claude/skills/$s/SKILL.md" ]; then fail "tracked source .claude/skills/$s/SKILL.md is missing"
  elif [ -L "$DEST/$s" ] || [ -L "$DEST/$s/SKILL.md" ]; then fail "$s at $DEST is a SYMLINK — a global install must be a real copy derived from the tracked source, or drift becomes structurally undetectable"
  elif [ ! -f "$DEST/$s/SKILL.md" ]; then fail "$s is not installed at $DEST/$s/SKILL.md"
  elif ! cmp -s ".claude/skills/$s/SKILL.md" "$DEST/$s/SKILL.md"; then
    fail "$s at $DEST differs from the tracked copy — run without --check to refresh"
  elif [ "$(head -1 "$DEST/$s/SKILL.md")" != "---" ]; then
    fail "$s at $DEST has no frontmatter — it is installed but will not register"
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
  [ -n "$SCAN_ROOT" ] && echo "Scanning $SCAN_ROOT for inert project-local copies"
  scanned=0
  for s in $GLOBAL_SKILLS; do
    while IFS= read -r hit; do
      scanned=$((scanned + 1))
      repo=${hit%/.claude/skills/$s/SKILL.md}
      [ "$(cd "$repo" 2>/dev/null && pwd -P)" = "$(pwd -P)" ] && continue   # this repo is the source
      fail "inert local copy: $hit (shadowed by $DEST/$s)"
    done < <(find -L "$SCAN_ROOT" -path "*/.claude/skills/$s/SKILL.md" -not -path '*/_archive/*' 2>/dev/null)
  done
  echo "  scanned $scanned candidate path(s); _archive/ is excluded by design and is not checked"
fi

echo
if [ $ISSUES -eq 0 ]; then echo "OK — global skills match the tracked source."; exit 0
else echo "$ISSUES issue(s) found."; exit 1; fi
