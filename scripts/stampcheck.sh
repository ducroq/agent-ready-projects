#!/usr/bin/env bash
# stampcheck.sh — are this machine's global skills the version this repo pins?
# A curate verify probe: <!-- verify: FRAMEWORK=~/repos/agent-ready-projects bash ~/repos/agent-ready-projects/scripts/stampcheck.sh -->
#
# Run from inside the adopter repo. FRAMEWORK must name a git clone of this
# framework, with tags fetched. Reads the version stamp from the repo's
# CLAUDE.md, derives the global-skill list from the installer AT THAT TAG
# (never restated here, #200), and compares each installed
# ~/.claude/skills/<name>/SKILL.md byte for byte with the tag's REFERENCE
# INSTALL (.claude/skills/<name>/SKILL.md), never templates/<name>.md, whose
# header differs by construction.
#
# Exit: 0 verified, 1 drift, 2 undecided. Undecided is NOT a pass: success is
# gated on a count of what was compared. Every exit prints a line, and an
# undecided one starts CANNOT VERIFY, which curate's runner scores as such.
#
# Global skills are shared by every repo on the machine, so a repo pinned to an
# older version than the installed skills reports DRIFT by design.
#
# Moved out of templates/curate.md Step 0 sub-step 3 on 2026-10-27, logic
# unchanged (`return` became `exit`) but for one fix: undecided lines now print
# after DRIFT lines, so a drift is never masked. History: #136, #200.
R=$(git rev-parse --show-toplevel 2>/dev/null) ||
  { echo "CANNOT VERIFY: not in a git repo"; exit 2; }
[ -n "${FRAMEWORK:-}" ] && [ -d "$FRAMEWORK/.git" ] ||
  { echo "CANNOT VERIFY: FRAMEWORK is unset or is not a git clone"; exit 2; }
# Five of the six stamp shapes in `update-drift` Step 0; bare prose is undecidable.
P=$(grep -oE "agent-ready-projects[^0-9]{0,40}v?[0-9]+\.[0-9]+\.[0-9]+" \
      "$R/CLAUDE.md" 2>/dev/null | head -1 |
    grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+$" | sed "s/^v*/v/")
[ -n "$P" ] || { echo "CANNOT VERIFY: no framework stamp in CLAUDE.md"; exit 2; }
# Derive the list at the stamped tag, never restate it (#200). `${P}`, not `$P`, before a colon (zsh).
git -C "$FRAMEWORK" rev-parse -q --verify "${P}^{commit}" >/dev/null ||
  { echo "CANNOT VERIFY: $P is not in the framework clone — fetch tags"; exit 2; }
t=$(git -C "$FRAMEWORK" show "${P}:scripts/install-global-skills.sh" 2>/dev/null) ||
  { echo "CANNOT VERIFY: no installer at $P (it predates v1.15.0, or moved)"; exit 2; }
want=$(printf '%s\n' "$t" | sed -n 's/^GLOBAL_SKILLS="\([^"]*\)".*/\1/p')
k=$(echo $want | wc -w | tr -d ' ')
c=$(printf '%s\n' "$t" | grep -o 'GLOBAL_SKILLS+\{0,1\}=' | wc -l | tr -d ' ')
[ "$k" -gt 0 ] && [ "$c" = 1 ] ||
  { echo "CANNOT VERIFY: $P's installer sets GLOBAL_SKILLS $c times, not once"; exit 2; }
n=0; d=0; u=""
# Undecided lines are held back and printed after any DRIFT line: the runner
# scores on the FIRST stdout line, so a leading CANNOT VERIFY would hide a drift.
for s in $(echo $want); do   # $(…) splits in zsh too; a bare $want does not
  i="$HOME/.claude/skills/$s/SKILL.md"
  [ -f "$i" ] || { u="${u}CANNOT VERIFY: $s is not installed
"; continue; }
  # Split, not piped: a failed `git show` must not become diff's verdict.
  t=$(git -C "$FRAMEWORK" show "${P}:.claude/skills/$s/SKILL.md" 2>/dev/null) ||
    { u="${u}CANNOT VERIFY: $s is not in $P
"; continue; }
  printf '%s\n' "$t" | diff -q - "$i" >/dev/null ||
    { echo "DRIFT: $s differs from $P"; d=1; }
  n=$((n + 1))
done
printf "%b" "$u"
[ "$d" = 0 ] || exit 1
[ "$n" = "$k" ] || { echo "CANNOT VERIFY: compared $n of $k skills"; exit 2; }
echo "$k global skills byte-identical to $P: $want"
