#!/usr/bin/env bash
# Sensitivity harness for tests/lint/skill-sync.sh (lint rule 6).
#
# A run against this repo finds nothing, because the pairs are in sync — which
# is exactly what a disabled check looks like. Every case below seeds a defect
# the rule claims to catch, or a legitimate divergence it must NOT report.
# Run this after any change to skill-sync.sh.
set -u
cd "$(dirname "$0")"
CHECK="$(cd ../../lint && pwd)/skill-sync.sh"
[ -f "$CHECK" ] || { echo "cannot find $CHECK" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A minimal but structurally faithful pair: H1 + SAVE AS comment + body on the
# template side, real frontmatter + identical body on the install side. The body
# quotes an HTML comment in prose, as audit-context's does.
mkpair() {  # mkpair <root> <name>
  local root="$1" n="$2"
  mkdir -p "$root/templates" "$root/skills/$n"
  cat > "$root/templates/$n.md" <<EOF
# ${n^} Skill

<!-- SAVE AS: .claude/skills/$n/SKILL.md (Claude Code)
     Prose that lives only in the template.
     ---
     name: $n
     description: Does the $n thing
     disable-model-invocation: false
     --- -->

Body first line.

## Step 1 — Something

A step that mentions \`<!-- verify: ... -->\` in running prose.

## Step 2 — Something else

Closing line.
EOF
  cat > "$root/skills/$n/SKILL.md" <<EOF
---
name: $n
description: Does the $n thing
disable-model-invocation: false
---

Body first line.

## Step 1 — Something

A step that mentions \`<!-- verify: ... -->\` in running prose.

## Step 2 — Something else

Closing line.
EOF
}

FAIL=0
run_case() {  # run_case <id> <expect: HIT|CLEAN> <needle> <mutator...>
  local id="$1" expect="$2" needle="$3"; shift 3
  local root="$WORK/$id"
  mkdir -p "$root"; mkpair "$root" demo
  "$@" "$root"
  # Keep stderr and assert the coverage line: a checker that cannot run produces
  # empty stdout, which is indistinguishable from "found nothing". On this
  # harness's first run the check never executed at all — every negative below
  # passed anyway, because "expect no violation" is satisfied byte-for-byte by a
  # checker that did nothing. Only the positives failed.
  local out err rc
  err="$WORK/$id.err"
  out="$(bash "$CHECK" "$root/templates" "$root/skills" 2>"$err")"; rc=$?
  if [ $rc -gt 1 ]; then
    printf '  FAIL  %s — checker exited %d: %s\n' "$id" "$rc" "$(cat "$err")"; FAIL=1; return
  fi
  if ! grep -q 'pair(s) compared' "$err"; then
    printf '  FAIL  %s — checker printed no coverage line; it did not run\n' "$id"; FAIL=1; return
  fi
  if [ "$expect" = HIT ] || [ "$expect" = HIT1 ]; then
    if ! printf '%s' "$out" | grep -qF -- "$needle"; then
      printf '  FAIL  %s — expected a violation matching "%s", got: %s\n' "$id" "$needle" "${out:-<none>}"; FAIL=1
    elif [ "$expect" = HIT1 ] && [ "$(printf '%s\n' "$out" | grep -c .)" -ne 1 ]; then
      # HIT1 asserts the seeded defect produces exactly ONE violation. A plain
      # needle match cannot see extra bogus lines alongside the right one, and
      # that blindness hid a real defect: a truncated SAVE AS comment reported
      # its own accurate diagnostic AND leaked the frontmatter into the body
      # comparison as a second, spurious violation.
      printf '  FAIL  %s — expected exactly 1 violation, got:\n%s\n' "$id" "$out"; FAIL=1
    else printf '  PASS  %s\n' "$id"; fi
  else
    if [ -z "$out" ]; then printf '  PASS  %s\n' "$id"
    else printf '  FAIL  %s — expected no violation, got: %s\n' "$id" "$out"; FAIL=1; fi
  fi
}

# ---- positives: drift the rule must report ----------------------------------

# The founding v1.15.0 defect: description edited on one side only.
m_desc() { sed -i 's/^description: .*/description: Does the demo thing, and more/' "$1/skills/demo/SKILL.md"; }
run_case P1-description HIT "frontmatter" m_desc

# The v1.17.0 defect: a rule written to the template and never to the install.
m_tmpl_only() { printf '\nA rule that landed in the template only.\n' >> "$1/templates/demo.md"; }
run_case P2-template-only HIT "body differs" m_tmpl_only
# An append's first differing line is the blank separator. Without the non-blank
# preference the excerpt reads `first: < ` and says nothing, so assert content.
run_case P2b-first-line-informative HIT "A rule that landed in the template only." m_tmpl_only

m_inst_only() { printf '\nA rule that landed in the install only.\n' >> "$1/skills/demo/SKILL.md"; }
run_case P3-install-only HIT "body differs" m_inst_only

m_step_gone() { sed -i '/^## Step 2/,$d' "$1/skills/demo/SKILL.md"; }
run_case P4-step-deleted HIT "body differs" m_step_gone

m_flag() { sed -i 's/^disable-model-invocation: false/disable-model-invocation: true/' "$1/skills/demo/SKILL.md"; }
run_case P5-invocation-flag HIT "frontmatter" m_flag

# name drift inside the SAVE AS block — rule 4 only checks the install against
# its own directory, so a template naming a different skill passes both today.
m_name() { sed -i 's/^     name: demo/     name: demo-renamed/' "$1/templates/demo.md"; }
run_case P6-name HIT "frontmatter" m_name

# A mid-body edit, not an append — appends and truncations are easy; a changed
# sentence in the middle is the shape real drift takes.
m_midbody() { sed -i 's/^Closing line\./Closing line, revised./' "$1/skills/demo/SKILL.md"; }
run_case P7-mid-body HIT "body differs" m_midbody

m_orphan() { mkdir -p "$1/skills/ghost"; cp "$1/skills/demo/SKILL.md" "$1/skills/ghost/SKILL.md"; }
run_case P8-install-no-template HIT "has no template" m_orphan

# Frontmatter is compared as a whole block, not against a list of known keys —
# these three all passed a three-key allowlist.
m_extra_field() { sed -i 's/^     disable-model-invocation: false/&\n     allowed-tools: Bash, Read/' "$1/templates/demo.md"; }
run_case P9-unknown-field HIT "frontmatter" m_extra_field

m_dup_field() { sed -i 's/^description: Does the demo thing/&\ndescription: a second, wrong one/' "$1/skills/demo/SKILL.md"; }
run_case P10-duplicate-field HIT "frontmatter" m_dup_field

m_quoted() { sed -i 's/^name: demo/name: "demo"/' "$1/skills/demo/SKILL.md"; }
run_case P11-quoting HIT "frontmatter" m_quoted

# A `-->` in the SAVE AS prose closes the comment early. The frontmatter it was
# quoting then reads as empty, which first produced three bogus "field differs"
# lines plus a bogus body diff. One accurate diagnostic instead.
m_early_close() { sed -i 's|     Prose that lives only in the template.|     Flow: template --> install.|' "$1/templates/demo.md"; }
run_case P12-truncated-save-as HIT1 "no frontmatter found between" m_early_close

m_no_h1() { sed -i '1s/^# /## /' "$1/templates/demo.md"; }
run_case P13-no-h1 HIT "has no \`# \` heading" m_no_h1

# A `---` opening a SAVE AS prose line empties the frontmatter region the same
# way a stray `-->` does, so the diagnostic must not name only one cause.
m_hr_in_saveas() { sed -i 's|     Prose that lives only in the template.|     --- see docs/GUIDE.md|' "$1/templates/demo.md"; }
run_case P14-hr-in-save-as HIT1 "no frontmatter found between" m_hr_in_saveas

# A stray `<!--` in template prose ABOVE the SAVE AS block. It is an unterminated
# comment, so it swallows the block in any renderer — the template is genuinely
# malformed and one loud diagnostic is the right answer. It belongs among the
# positives: the earlier draft decided `save` from any line in the block, which
# made this swallow the prose silently and report identical files as body drift.
m_stray_before() { sed -i '2i A note with a stray <!-- glyph.' "$1/templates/demo.md"; }
run_case P15-stray-open-before-block HIT1 "no frontmatter found between" m_stray_before

# ---- negatives: legitimate divergence the rule must NOT report ---------------

m_none() { :; }
run_case N1-clean-pair CLEAN "" m_none

# The two files diverge by design in exactly these places. If any of these fires,
# the rule is permanently red and will be ignored.
m_saveas_reword() { sed -i 's/     Prose that lives only in the template./     Reworded install guidance, template only./' "$1/templates/demo.md"; }
run_case N2-save-as-text CLEAN "" m_saveas_reword

m_h1() { sed -i '1s/.*/# A Completely Different Title/' "$1/templates/demo.md"; }
run_case N3-h1-differs CLEAN "" m_h1

# Trailing blanks on one side, leading blank removed on the other. `0,/^$/s///`
# was the first attempt at the leading half and is a no-op — an empty regex
# reuses the last one, so it substitutes `^$` with nothing. A fixture case that
# mutates nothing is the exact thing this repo's seeded-true-positives rule is
# aimed at, so the deletion is explicit.
m_blanks() { printf '\n\n' >> "$1/skills/demo/SKILL.md"; sed -i '0,/^$/{/^$/d}' "$1/templates/demo.md"; }
run_case N4-edge-blank-lines CLEAN "" m_blanks

# An install that was DELETED looks exactly like one that never existed, so an
# unpaired template is a violation unless it is on the checker's named list.
m_no_install() { cp "$1/templates/demo.md" "$1/templates/lonely.md"; sed -i 's|skills/demo/SKILL.md|skills/lonely/SKILL.md|' "$1/templates/lonely.md"; }
run_case P16-template-no-install HIT1 "reference install is missing" m_no_install

# The one named exception stays a coverage note, not a failure.
m_known_unpaired() { cp "$1/templates/demo.md" "$1/templates/test-verify-memory.md"; sed -i 's|skills/demo/SKILL.md|skills/test-verify-memory/SKILL.md|' "$1/templates/test-verify-memory.md"; }
run_case N5-known-unpaired CLEAN "" m_known_unpaired

# Identical files in CRLF. Rule 4 strips `\r` deliberately; rule 6 must too, or a
# checkout on another platform turns it permanently red.
m_crlf() { sed -i 's/$/\r/' "$1/templates/demo.md" "$1/skills/demo/SKILL.md"; }
run_case N6-crlf CLEAN "" m_crlf

# An unterminated `<!--` in body prose, identical on both sides. Without the awk
# END flush the template body stops there, so the pair reads as drift AND every
# later edit becomes invisible — a false positive hiding true negatives.
m_open_comment() {
  printf '\nAn opening tag like <!-- written alone in prose.\n' >> "$1/templates/demo.md"
  printf '\nAn opening tag like <!-- written alone in prose.\n' >> "$1/skills/demo/SKILL.md"
}
run_case N7-unclosed-comment CLEAN "" m_open_comment


echo
if [ $FAIL -eq 0 ]; then echo "All skill-sync fixture cases passed."; else echo "Fixture failures above."; fi
exit $FAIL
