#!/usr/bin/env bash
# Compares each skill template against its reference install and reports divergence.
#
# Usage: skill-sync.sh <templates-dir> <skills-dir>
#
# Violations go to stdout, one per line, for the caller to count. Coverage notes
# (how many pairs were compared, which templates have no install) go to stderr —
# the caller must assert that line appeared rather than reading empty stdout as
# "clean", because a checker that cannot run produces exactly the same stdout.
#
# Exit: 0 clean, 1 violations found, 2 could not run (bad arguments).
#
# Why this exists: rule 3 checks a template CARRIES installable frontmatter and
# rule 4 checks an install CAN REGISTER. Neither compares the two, and the drift
# that gap allows has landed twice — two `description:` fields in v1.15.0, and
# v1.17.0's gotcha-length rule written to templates/curate.md but not to its
# install. Both were found by hand. `install-global-skills.sh --check` cannot see
# either: it compares the global install against the tracked one, so both read as
# current while diverging from the template. Background: issue #23.
set -u

usage() { printf 'usage: skill-sync.sh <templates-dir> <skills-dir>\n' >&2; exit 2; }
[ $# -eq 2 ] || usage
TDIR="$1"
SDIR="$2"
# A missing directory must be loud. Silently comparing nothing exits 0, which is
# the failure mode this whole check exists to make impossible.
[ -d "$TDIR" ] || { printf 'skill-sync: templates dir not found: %s\n' "$TDIR" >&2; exit 2; }
[ -d "$SDIR" ] || { printf 'skill-sync: skills dir not found: %s\n' "$SDIR" >&2; exit 2; }

FOUND=0
violation() { printf '%s\n' "$1"; FOUND=1; }

# Drop leading and trailing blank lines. Applied to both sides, so the blank line
# conventionally following the install's closing `---` is not a difference. This
# is the ONLY normalization applied to body content — nothing rewrites a
# character inside a line, so a `→` that became `->` still reports.
trim_blank() {
  awk 'NF{p=1} p{buf = buf $0 "\n"; if (NF) {printf "%s", buf; buf=""}}'
}

# Template body: everything after the H1, minus the SAVE AS comment block.
# Other comment blocks are kept — they exist verbatim in the install too, and
# both audit-context and curate quote `<!-- verify: -->` in running prose.
# An unterminated `<!--` flushes at END rather than swallowing the rest of the
# file: silently truncating the comparison would make every later edit invisible.
# `save` is decided by the OPENING line alone, not by any line in the block. All
# six skill templates open with `<!-- SAVE AS:` on one line (measured). Scanning
# the whole block instead meant a stray `<!--` anywhere in the prose *above* the
# real block swallowed everything up to it — identical prose on both sides
# reported as drift.
template_body() {
  tr -d '\r' < "$1" | awk '
    !h1 { if ($0 ~ /^# /) h1=1; next }
    /<!--/ && !inc { inc=1; buf=""; save=($0 ~ /SAVE AS:/) }
    inc {
      buf = buf $0 "\n"
      if ($0 ~ /-->/) { inc=0; if (!save) printf "%s", buf }
      next
    }
    { print }
    END { if (inc) printf "%s", buf }
  ' | trim_blank
}

# Install body: everything after the closing `---` of the frontmatter.
install_body() {
  tr -d '\r' < "$1" | awk '
    NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm {print}
  ' | trim_blank
}

# The frontmatter region inside the SAVE AS comment: the lines between the two
# `---` markers the templates use to quote the frontmatter an adopter must write.
# Both sides are indented differently by construction — the template quotes its
# frontmatter inside a comment, five spaces in — so leading indentation and
# trailing whitespace are stripped and blank lines dropped before comparing.
# That is the one place a character *inside* a line is touched, and it means a
# multi-line block scalar whose continuation indent differs between the two
# files reads as equal. Nothing else here rewrites content.
template_fields() {
  tr -d '\r' < "$1" | awk '
    /<!--/ && !inc { inc=1; save=($0 ~ /SAVE AS:/) }
    inc && save {
      if ($0 ~ /^[[:space:]]*---([[:space:]]|$)/) { d++; if (d==1) next }
      if (d==1) print
    }
    inc && /-->/ { if (save) exit; inc=0 }
  ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$'
}

install_fields() {
  tr -d '\r' < "$1" | awk '
    NR==1 && $0=="---" {next} /^[[:space:]]*---([[:space:]]|$)/{exit} {print}
  ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$'
}

# First differing line that actually carries content — an append's first diff
# line is the blank separator, which says nothing.
first_real_diff() {
  diff "$1" "$2" | grep -m1 '^[<>].*[^[:space:]<>]' || diff "$1" "$2" | grep -m1 '^[<>]'
}

PAIRS=0
for d in "$SDIR"/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  inst="${d}SKILL.md"
  tmpl="$TDIR/$name.md"

  [ -f "$inst" ] || continue          # rule 4's job, not this one
  if [ ! -f "$tmpl" ]; then
    violation "$inst has no template at $tmpl — a shipped skill with no adopter-facing source"
    continue
  fi
  PAIRS=$((PAIRS + 1))

  # --- frontmatter -----------------------------------------------------------
  # Compared as whole blocks rather than a fixed list of keys, so a field nobody
  # thought of (allowed-tools, model, argument-hint) and a duplicated key are
  # both caught. A key list would silently pass anything outside it.
  tf=$(mktemp); inf=$(mktemp)
  template_fields "$tmpl" > "$tf"
  install_fields "$inst" > "$inf"
  parsed=1
  if [ ! -s "$tf" ]; then
    # Commonest cause is a `-->` in the comment's own prose, which closes it
    # early; a prose line starting `---` does it too. Either way the template
    # cannot be parsed, so the body comparison below is skipped rather than
    # allowed to report the leaked frontmatter as a body difference.
    parsed=0
    violation "$name: no frontmatter found between the \`---\` markers in $tmpl's SAVE AS comment — check for a \`-->\` or a leading \`---\` in the comment prose"
  elif ! diff -q "$tf" "$inf" >/dev/null; then
    while IFS= read -r l; do
      case "$l" in
        '<'*) violation "$name: frontmatter — template has \`${l#< }\`, install does not" ;;
        '>'*) violation "$name: frontmatter — install has \`${l#> }\`, template does not" ;;
      esac
    done < <(diff "$tf" "$inf" | grep '^[<>]')
  fi
  rm -f "$tf" "$inf"

  # --- body ------------------------------------------------------------------
  [ "$parsed" -eq 1 ] || continue
  tb=$(mktemp); ib=$(mktemp)
  template_body "$tmpl" > "$tb"
  install_body "$inst" > "$ib"
  if [ ! -s "$tb" ]; then
    violation "$name: $tmpl has no \`# \` heading, so no body could be extracted"
  elif ! diff -q "$tb" "$ib" >/dev/null; then
    # Reported per side. A single `grep -c '^[<>]'` counts a modified line twice
    # — nine drifted lines in audit-context reported as eighteen.
    only_t=$(diff "$tb" "$ib" | grep -c '^<')
    only_i=$(diff "$tb" "$ib" | grep -c '^>')
    first=$(first_real_diff "$tb" "$ib")
    violation "$name: body differs from $tmpl — $only_t line(s) only in the template, $only_i only in the install; first: ${first:0:120}"
  fi
  rm -f "$tb" "$ib"
done

# A skill template with no reference install is not drift, but it is also not
# checked — and an install that is *deleted* looks exactly like one that never
# existed. So the exceptions are named rather than tolerated as a class: a
# missing install is a violation unless the template is on this list. That is
# the same "explicit allowlists, not blanket skips" rule the rest of this lint
# follows. `test-verify-memory` is a behavioural-test pattern, not a skill this
# repo runs; whether it should have an install is a separate decision.
KNOWN_UNPAIRED=" test-verify-memory "
unpaired=""
for f in "$TDIR"/*.md; do
  [ -f "$f" ] || continue
  grep -q 'SAVE AS:.*\.claude/skills/' "$f" || continue
  n=$(basename "$f" .md)
  [ -f "$SDIR/$n/SKILL.md" ] && continue
  case "$KNOWN_UNPAIRED" in
    *" $n "*) unpaired="$unpaired $n" ;;
    *) violation "$n: $TDIR/$n.md is a skill template but $SDIR/$n/SKILL.md does not exist — the reference install is missing" ;;
  esac
done
printf '      %d template/install pair(s) compared' "$PAIRS" >&2
[ -n "$unpaired" ] && printf '; no install to compare against:%s' "$unpaired" >&2
printf '\n' >&2

exit $FOUND
