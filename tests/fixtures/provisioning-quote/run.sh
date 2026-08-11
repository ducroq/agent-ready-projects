#!/usr/bin/env bash
# Sensitivity harness for tests/lint/provision-quote.sh (lint rule 7).
#
# A run against this repo finds nothing, because the three provisioning sites all
# quote the canonical row — which is exactly what a disabled check looks like.
# Every case below seeds a defect the rule claims to catch, or a legitimate
# divergence it must NOT report.
#
# The rule's first draft was a whole-file grep for a hardcoded prefix. It passed
# its author's three manual tests and was then refuted three ways: the canonical
# string surviving in an unrelated appendix satisfied it (P2), a second row
# starting with the same words made it quote a decoy (N3), and it never looked at
# adopt.md at all (P3) while its changelog claimed to close the class.
set -u
cd "$(dirname "$0")"
CHECK="$(cd ../../lint && pwd)/provision-quote.sh"
[ -f "$CHECK" ] || { echo "cannot find $CHECK" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A minimal but structurally faithful tree: the canonical row in project-file.md,
# and the three files that tell an agent to create it.
mktree() {  # mktree <root>
  local r="$1"
  mkdir -p "$r/templates" "$r/.claude/skills/audit-context"
  cat > "$r/templates/project-file.md" <<'EOF'
# Project

## Before You Start

| When | Read |
|------|------|
| Picking up where the last session left off | `memory/MEMORY.md` — the index itself |
| Stuck or debugging something weird | `memory/gotcha-log.md` — problem-fix archive |
EOF
  cat > "$r/templates/audit-context.md" <<'EOF'
# Audit Context

## Step 4 — Reference integrity

Check that paths resolve. This step mentions MEMORY.md and a row or two in passing.

## Step 5 — Topic file reachability

<!-- provisions: memory-index-row -->

Verify the project file contains the row `| Picking up where the last session left off | memory/MEMORY.md …`
targeting the memory index. A category-shaped trigger is not an acceptable substitute.

## Step 6 — Something else

Unrelated.
EOF
  cp "$r/templates/audit-context.md" "$r/.claude/skills/audit-context/SKILL.md"
  cat > "$r/adopt.md" <<'EOF'
# Adopt

## 2. Adopt

### Prompt

STEP 3 — Create a gotcha log.
Nothing to do with the index here.

STEP 4 — Create the memory index.
<!-- provisions: memory-index-row -->
Save as `memory/MEMORY.md`. Then add the pointer row that reaches it to the
project file's table — `| Picking up where the last session left off | memory/MEMORY.md …`

STEP 5 — Report.
EOF
}

FAIL=0
run_case() {  # run_case <id> <expect: HIT|CLEAN> <needle> <mutator>
  local id="$1" expect="$2" needle="$3" mut="$4"
  local r="$WORK/$id"
  mkdir -p "$r"; mktree "$r"; "$mut" "$r"
  local out err rc
  err="$WORK/$id.err"
  out="$(bash "$CHECK" "$r" 2>"$err")"; rc=$?
  if [ $rc -gt 1 ]; then
    printf '  FAIL  %s — checker exited %d: %s\n' "$id" "$rc" "$(cat "$err")"; FAIL=1; return
  fi
  # A checker that cannot run prints nothing, which is byte-identical to a clean
  # result. The coverage line on stderr is what separates them, so assert it.
  if ! grep -q 'checked against\|no canonical row\|ambiguous' "$err"; then
    printf '  FAIL  %s — no coverage line; the rule did not run\n' "$id"; FAIL=1; return
  fi
  if [ "$expect" = HIT ]; then
    if printf '%s' "$out" | grep -qF -- "$needle"; then printf '  PASS  %s\n' "$id"
    else printf '  FAIL  %s — expected a violation matching "%s", got: %s\n' "$id" "$needle" "${out:-<none>}"; FAIL=1; fi
  else
    if [ -z "$out" ]; then printf '  PASS  %s\n' "$id"
    else printf '  FAIL  %s — expected no violation, got: %s\n' "$id" "$out"; FAIL=1; fi
  fi
}

echo "positives — drift the rule must report:"

# The #42 defect itself: the check reverts to describing the row by category.
m_category() { python3 - "$1" <<'PY'
import sys,re,io
p=sys.argv[1]+"/templates/audit-context.md"
t=open(p).read()
t=t.replace("Verify the project file contains the row `| Picking up where the last session left off | memory/MEMORY.md …`\ntargeting the memory index.",
            "Verify the project file contains a row whose trigger fires at session start\ntargeting the memory index.")
open(p,'w').write(t)
PY
}
run_case P1-category-wording HIT "without quoting the canonical trigger" m_category

# The refutation of the first draft: a whole-file grep passes when the canonical
# string survives somewhere else in the file while the instruction reverts.
m_appendix() {
  m_category "$1"
  printf '\n## Appendix\n\nHistorically the row read `| Picking up where the last session left off | memory/MEMORY.md |`.\n' >> "$1/templates/audit-context.md"
}
run_case P2-quote-only-in-appendix HIT "Step 5" m_appendix

# adopt.md is the PRIMARY provisioning site and the first draft never read it.
m_adopt() { python3 - "$1" <<'PY'
import sys
p=sys.argv[1]+"/adopt.md"
t=open(p).read()
t=t.replace("Then add the pointer row that reaches it to the\nproject file's table — `| Picking up where the last session left off | memory/MEMORY.md …`",
            "Then add a row whose trigger fires at session start to the\nproject file's table, pointing at memory/MEMORY.md")
open(p,'w').write(t)
PY
}
run_case P3-adopt-md HIT "adopt.md" m_adopt

# The install may drift from the template even when the template is right.
m_install_only() { python3 - "$1" <<'PY'
import sys
p=sys.argv[1]+"/.claude/skills/audit-context/SKILL.md"
t=open(p).read()
t=t.replace("the row `| Picking up where the last session left off | memory/MEMORY.md …`","a row whose trigger fires at session start")
open(p,'w').write(t)
PY
}
run_case P4-install-drift HIT "SKILL.md" m_install_only

# The canonical row renamed: every provisioning site is now stale, and the rule
# must say so rather than comparing against a string nobody uses.
m_renamed() { sed -i 's/^| Picking up where the last session left off |/| Resuming after a break |/' "$1/templates/project-file.md"; }
run_case P5-row-renamed HIT "without quoting the canonical trigger \"Resuming after a break\"" m_renamed

m_deleted() { sed -i '/^| Picking up where the last session left off |/d' "$1/templates/project-file.md"; }
run_case P6-row-deleted HIT "no row whose target is the memory index" m_deleted

# Two rows targeting the index: there is no single canonical trigger, and picking
# the first silently is how the first draft quoted a decoy.
m_two_rows() { sed -i '/^| Picking up where/i | Returning after a week away | `memory/MEMORY.md` — same target |' "$1/templates/project-file.md"; }
run_case P7-ambiguous-canonical HIT "rows targeting the memory index" m_two_rows

m_no_section() { python3 - "$1" <<'PY'
import sys
p=sys.argv[1]+"/adopt.md"
t=open(p).read()
t=t.replace("STEP 4 — Create the memory index.\n<!-- provisions: memory-index-row -->\nSave as `memory/MEMORY.md`. Then add the pointer row that reaches it to the\nproject file's table — `| Picking up where the last session left off | memory/MEMORY.md …`\n","")
open(p,'w').write(t)
PY
}
run_case P8-stopped-provisioning HIT "has no section marked" m_no_section
# Dropping the marker while keeping the prose is the obvious way to silence this
# rule, so it must fail exactly as loudly as dropping the section.
m_marker_gone() { sed -i '/provisions: memory-index-row/d' "$1/adopt.md"; }
run_case P9-marker-removed HIT "has no section marked" m_marker_gone

echo
echo "negatives — legitimate divergence the rule must NOT report:"

m_none() { :; }
run_case N1-clean CLEAN "" m_none

# A second situation-shaped row starting with the same words, pointing somewhere
# else. Step 5's own prose invites equivalents, so this must not be mistaken for
# the canonical row — the first draft's `head -1` quoted it and failed the tree.
m_decoy() { sed -i '/^| Picking up where the last session left off |/i | Picking up where an aborted migration stopped | `docs/work-items/migration.md` |' "$1/templates/project-file.md"; }
run_case N2-decoy-row CLEAN "" m_decoy

# The trigger cell in bold renders identically and is the same row.
m_bold() { sed -i 's/^| Picking up where the last session left off |/| **Picking up where the last session left off** |/' "$1/templates/project-file.md"; }
run_case N3-bolded-cell CLEAN "" m_bold

# A section that merely discusses reachability, mentioning both the index and a
# row, is not a provisioning site. Four of these fired on the first cue.
m_mentions() { printf '\n## Step 7 — Notes\n\nThis step mentions MEMORY.md and a row without provisioning either, and carries no marker.\n' >> "$1/templates/audit-context.md"; }
run_case N4-mere-mention CLEAN "" m_mentions

echo
if [ $FAIL -eq 0 ]; then echo "All provisioning-quote fixture cases passed."; else echo "Fixture failures above."; fi
exit $FAIL
