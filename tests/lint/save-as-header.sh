#!/usr/bin/env bash
# Rule 16 — a skill template's SAVE AS header agrees with how the skill is installed (#184).
#
# Usage: save-as-header.sh <repo-root>
# Violations to stdout; coverage line to stderr. Exit 0 clean, 1 violations, 2 could not run.
#
# WHY. `docs/GUIDE.md` told adopters to copy `templates/<name>.md` to a SKILL.md
# path. That file's frontmatter sits INSIDE the SAVE AS comment, so a literal copy
# registers as nothing and **fails by doing nothing** — the silent class. It took
# three review rounds to stop finding instances: round 1 found the one being
# written, round 2 found the third in the same list the first two were fixed in,
# round 3 found the fourth, which by then contradicted a line round 2 had written.
# Each round fixed what it was shown; none asked how many there were.
#
# ⚠️ NO EXISTING RULE REACHES THIS. Rule 3 checks only that `name:`/`description:`
# exist inside the comment; rule 6 excludes the SAVE AS block from its comparison
# by construction. So both copies agree with each other while contradicting five
# other surfaces — an instrument that agrees with itself is not evidence.
#
# Two halves, and (b) is the one nothing else approaches:
#   (a) the do-not-copy-verbatim clause is present
#   (b) the stated SCOPE agrees with $GLOBAL_SKILLS in scripts/install-global-skills.sh —
#       a global skill says `~/.claude/skills/` and USER-GLOBAL, a project-local one
#       says `<repo>/.claude/skills/` and PROJECT-LOCAL.
# The install script is the authority for (b), never a list repeated here: a second
# list is the drift this rule exists to catch, one file over.
#
# ⚠️ WHAT THIS RULE DOES NOT COVER, and it is most of #184's blast radius. It binds
# the TEMPLATE HEADER and nothing else. The instruction that originated #184 lived
# in `docs/GUIDE.md`, and `templates/README.md` and `docs/GUIDE.md` each carry a
# further hand-maintained list of the same scope fact. Seeded and measured: flipping
# the scope in both of those files scores 0 disagreements here. So three of the five
# surfaces the gotcha row names are still unbound — a rule for them needs its own
# seeded cases and is not this one.
set -u

root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: save-as-header.sh <repo-root>" >&2; exit 2; }
cd "$root" || exit 2

INSTALLER="scripts/install-global-skills.sh"
[ -f "$INSTALLER" ] || { echo "rule 16: $INSTALLER absent — the scope authority is missing, so nothing was checked" >&2; exit 2; }

# Derived, never listed. A literal copy here drifts the first time a skill changes scope.
GLOBALS=$(sed -n 's/^GLOBAL_SKILLS="\([^"]*\)".*/\1/p' "$INSTALLER" | head -1)
[ -n "$GLOBALS" ] || { echo "rule 16: could not read GLOBAL_SKILLS from $INSTALLER — this rule cannot bind" >&2; exit 2; }

n=0; bad=0; seen=""
# W4 — a template whose SAVE AS is deleted or moved off line 3 simply leaves the
# population, and the rule reports one fewer file at rc 0. Rule 3 skips it too, so
# a template with no install header at all passed both. The floor below is DERIVED:
# every skill the installer ships globally must still have a template carrying one.
for f in templates/*.md; do
  [ -f "$f" ] || continue
  [ -r "$f" ] || { echo "$f: could not be read — not checked; this is not a clean result."; bad=$((bad + 1)); continue; }
  line3=$(sed -n '3p' "$f")
  case "$line3" in *"SAVE AS"*".claude/skills/"*) ;; *) continue ;; esac
  n=$((n + 1))
  name=$(basename "$f" .md)
  seen="$seen $name"
  head16=$(sed -n '1,16p' "$f")

  case "$head16" in
    *"do not copy this file verbatim"*) ;;
    *) echo "$f:3: SAVE AS names a SKILL.md path but the header omits the do-not-copy-verbatim clause — a literal copy carries the frontmatter inside a comment and registers as nothing, silently (#184)"
       bad=$((bad + 1)) ;;
  esac

  is_global=0
  for g in $GLOBALS; do [ "$g" = "$name" ] && is_global=1; done
  if [ "$is_global" -eq 1 ]; then
    case "$line3" in
      *"~/.claude/skills/$name/"*) ;;
      *) echo "$f:3: $name is in GLOBAL_SKILLS but its SAVE AS path is not \`~/.claude/skills/$name/\` — the installer and the header disagree about where it lives"; bad=$((bad + 1)) ;;
    esac
    case "$head16" in
      *USER-GLOBAL*) ;;
      *) echo "$f:3: $name is installed user-globally but its header does not say USER-GLOBAL"; bad=$((bad + 1)) ;;
    esac
    # Presence alone passes a header asserting BOTH scopes, which reads as
    # authoritative in either direction (measured: such a header scored 0).
    case "$head16" in *PROJECT-LOCAL*) echo "$f:3: $name is user-global but its header also says PROJECT-LOCAL — a reader takes whichever half they saw first"; bad=$((bad + 1)) ;; esac
  else
    case "$line3" in
      *"<repo>/.claude/skills/$name/"*) ;;
      *) echo "$f:3: $name is NOT in GLOBAL_SKILLS but its SAVE AS path is not \`<repo>/.claude/skills/$name/\` — a project-local skill written as a global one installs into the wrong tree, where it shadows every repo's copy"; bad=$((bad + 1)) ;;
    esac
    case "$head16" in
      *PROJECT-LOCAL*) ;;
      *) echo "$f:3: $name is project-local but its header does not say PROJECT-LOCAL"; bad=$((bad + 1)) ;;
    esac
    case "$head16" in *USER-GLOBAL*) echo "$f:3: $name is project-local but its header also says USER-GLOBAL"; bad=$((bad + 1)) ;; esac
  fi
done

[ "$n" -gt 0 ] || { echo "rule 16: no template carries a SAVE AS naming a .claude/skills/ path — the population is empty, not clean" >&2; exit 2; }
for g in $GLOBALS; do
  case " $seen " in
    *" $g "*) ;;
    *) echo "templates/$g.md: $g is in GLOBAL_SKILLS but no template of that name carries a SAVE AS naming a .claude/skills/ path — a deleted or relocated header drops the file out of this rule's population silently, and rule 3 skips it too"
       bad=$((bad + 1)) ;;
  esac
done
echo "      $n skill template(s) checked against GLOBAL_SKILLS ($GLOBALS); $bad disagreement(s)" >&2
[ "$bad" -eq 0 ] && exit 0
exit 1
