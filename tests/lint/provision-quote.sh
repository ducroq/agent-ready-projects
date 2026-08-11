#!/usr/bin/env bash
# Lint rule 7 — a skill or prompt that PROVISIONS a canonical row must quote it.
#
# The #42 class, and it is one level out from rule 6. Rule 6 compares
# templates/<name>.md against .claude/skills/<name>/SKILL.md; in #42 those two
# agreed with each other and contradicted a THIRD file. audit-context Step 5
# reports the missing memory-index pointer as its finding, an agent adds a row to
# satisfy it, and the only wording available is whatever the finding used — so a
# check phrased as a category ("a row whose trigger fires at session start")
# manufactures category-shaped triggers at scale.
#
# Usage: provision-quote.sh <repo-root>
# Exit:  0 clean · 1 violations on stdout · 2 could not run
# A coverage line always goes to stderr: silence from this script must never be
# readable as "clean", which is the failure mode it exists to catch.
set -u
root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: provision-quote.sh <repo-root>" >&2; exit 2; }

pf="$root/templates/project-file.md"
[ -f "$pf" ] || { echo "cannot read $pf" >&2; exit 2; }

# The canonical trigger is derived, not hardcoded: it is the trigger cell of the
# row whose target cell points at the memory index. Deriving it by prefix instead
# ("Picking up where…") picks a decoy the moment a second situation-shaped row
# starts the same way — and Step 5's own prose invites exactly that.
triggers=$(awk -F'|' '
  /^[ \t]*\|/ {
    if (NF < 3) next
    cell = $2; tgt = $3
    if (tgt !~ /memory\/MEMORY\.md/) next
    gsub(/\*\*/, "", cell)                      # a bolded cell is the same trigger
    gsub(/^[ \t]+|[ \t]+$/, "", cell)
    if (cell == "" || cell ~ /^-+$/) next       # header underline, not a row
    print cell
  }' "$pf")

n=$(printf '%s' "$triggers" | grep -c . || true)
if [ "$n" -eq 0 ]; then
  echo "templates/project-file.md has no row whose target is the memory index — if the row was renamed or removed, this rule and every file that provisions it must move together"
  echo "      0 provisioning file(s) checked; no canonical row to check them against" >&2
  exit 1
elif [ "$n" -gt 1 ]; then
  echo "templates/project-file.md has $n rows targeting the memory index, so there is no single canonical trigger to quote:"
  printf '%s\n' "$triggers" | sed 's/^/        /'
  echo "      0 provisioning file(s) checked; the canonical row is ambiguous" >&2
  exit 1
fi
trigger="$triggers"

# Files that tell an agent to create that row. adopt.md is the primary one — it
# is what creates the project file in the first place — and was missing from the
# first draft of this rule, which then claimed to close the class.
files="templates/audit-context.md .claude/skills/audit-context/SKILL.md adopt.md"

issues=0; checked=0
for rel in $files; do
  f="$root/$rel"
  [ -f "$f" ] || { echo "$rel is missing, but this rule expects it to provision the memory-index row"; issues=$((issues + 1)); continue; }
  # Scope to the SECTION that provisions the row, not the whole file: a file-wide
  # grep passes when the canonical string survives in an unrelated appendix while
  # the instruction itself reverts to a category. Sections are delimited by a
  # markdown heading or by adopt.md's `STEP n —` lines.
  #
  # A provisioning section declares itself with the marker below rather than being
  # inferred from its wording. Inference was tried and refuted by this rule's own
  # fixture: a cue of "names MEMORY.md and mentions a row" fired on four sections
  # that merely discuss reachability. A marker is also self-defending — a section
  # that drops it fails the per-file minimum rather than quietly leaving scope.
  hits=$(awk -v want="$trigger" '
    function flush() {
      if (index(body, "<!-- provisions: memory-index-row -->")) {
        secs++
        if (index(body, want) == 0) print head
      }
      body = ""
    }
    /^#+ / || /^STEP [0-9]/ { flush(); head = $0; body = $0 "\n"; next }
    { body = body $0 "\n" }
    END { flush(); printf "%d\n", secs > "/dev/stderr" }
  ' "$f" 2>"$root/.pq.$$")
  secs=$(cat "$root/.pq.$$" 2>/dev/null | tail -1); rm -f "$root/.pq.$$"
  secs=${secs:-0}
  if [ "$secs" -eq 0 ]; then
    echo "$rel has no section marked \`<!-- provisions: memory-index-row -->\` — either it stopped provisioning the row, or the marker was dropped along with the quote"
    issues=$((issues + 1)); continue
  fi
  checked=$((checked + secs))
  if [ -n "$hits" ]; then
    while IFS= read -r h; do
      [ -n "$h" ] || continue
      echo "$rel provisions the memory-index row under \"$h\" without quoting the canonical trigger \"$trigger\" — an agent satisfying that instruction will write the wording the instruction used"
      issues=$((issues + 1))
    done <<EOF
$hits
EOF
  fi
done

echo "      $checked provisioning section(s) checked against \"$trigger\"" >&2
[ "$issues" -eq 0 ] || exit 1
exit 0
