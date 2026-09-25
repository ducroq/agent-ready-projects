#!/usr/bin/env bash
# Rule 22 — the install paths adopters read agree with the installer (#195).
#
# Usage: scope-surfaces.sh <repo-root>
# Violations to stdout; coverage line to stderr. Exit 0 clean, 1 violations, 2 could not run.
#
# WHY. Rule 16 binds each skill template's SAVE AS header to GLOBAL_SKILLS in
# scripts/install-global-skills.sh. `docs/GUIDE.md`, `templates/README.md` and
# `adopt.md` carry further hand-maintained copies of the same scope fact, and
# #184 started in GUIDE.md. Seeded against rule 16 alone, flipping the scope on
# those surfaces scored 0 disagreements.
#
# What it reads: every PREFIXED install path, `~/.claude/skills/<name>` or
# `<repo>/.claude/skills/<name>`, with or without the trailing slash. A global
# skill must not appear under `<repo>/`, a project-local one must not appear
# under `~/`, and a name the installer lists in neither is reported. Every shipped skill must appear at least once across
# the three files, or the rule has lost its subject for it.
#
# ⚠️ WHAT IT CANNOT SEE. Scope WORDS are not read: "install project-locally"
# beside no path passes, because the surfaces legitimately name both scopes on one
# line ("project-locally … not user-globally"). An unprefixed path
# (`.claude/skills/curate/`, the framework's own source copy) is not an install
# path and is not read. Nor is any file beyond the three.
set -u

root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: scope-surfaces.sh <repo-root>" >&2; exit 2; }
cd "$root" || exit 2

INSTALLER="scripts/install-global-skills.sh"
[ -f "$INSTALLER" ] || { echo "rule 22: $INSTALLER absent — the scope authority is missing, so nothing was checked" >&2; exit 2; }
# Derived, never listed: a second list here is the drift this rule exists to catch.
GLOBALS=$(sed -n 's/^GLOBAL_SKILLS="\([^"]*\)".*/\1/p' "$INSTALLER" | head -1)
LOCALS=$(sed -n 's/^LOCAL_ONLY="\([^"]*\)".*/\1/p' "$INSTALLER" | head -1)
{ [ -n "$GLOBALS" ] && [ -n "$LOCALS" ]; } || { echo "rule 22: could not read GLOBAL_SKILLS and LOCAL_ONLY from $INSTALLER — this rule cannot bind" >&2; exit 2; }

SURFACES="docs/GUIDE.md templates/README.md adopt.md"
for f in $SURFACES; do
  [ -r "$f" ] || { echo "rule 22: $f is absent or unreadable — a surface this rule binds was not checked" >&2; exit 2; }
done

in_list() { for x in $2; do [ "$x" = "$1" ] && return 0; done; return 1; }

n=0; bad=0; seen=" "
# `grep -o` prints each path on its own line with its line number, so two
# mentions on one line are two checks.
while IFS=: read -r f ln path; do
  [ -n "$path" ] || continue
  n=$((n + 1))
  prefix=${path%%/.claude/skills/*}
  name=${path#*/.claude/skills/}; name=${name%/}
  seen="$seen$name "
  if in_list "$name" "$GLOBALS"; then
    [ "$prefix" = "~" ] || { echo "$f:$ln: $name is in GLOBAL_SKILLS but this names \`$path\` — the installer puts it at \`~/.claude/skills/$name/\`"; bad=$((bad + 1)); }
  elif in_list "$name" "$LOCALS"; then
    [ "$prefix" = "<repo>" ] || { echo "$f:$ln: $name is LOCAL_ONLY but this names \`$path\` — a user-global copy shadows every repo's own"; bad=$((bad + 1)); }
  else
    echo "$f:$ln: \`$path\` names a skill the installer lists in neither GLOBAL_SKILLS nor LOCAL_ONLY"; bad=$((bad + 1))
  fi
done < <(grep -noE '(~|<repo>)/\.claude/skills/[a-z0-9-]+/?' $SURFACES)

for s in $GLOBALS $LOCALS; do
  case "$seen" in *" $s "*) ;; *)
    echo "rule 22: $s is shipped but no surface names its install path — its scope is not bound here"; bad=$((bad + 1)) ;;
  esac
done

echo "      $n install path(s) found across $SURFACES, checked against $INSTALLER" >&2
[ "$n" -gt 0 ] || { echo "rule 22: no install path found on any surface — this rule checked nothing" >&2; exit 2; }
[ "$bad" -eq 0 ] || exit 1
exit 0
