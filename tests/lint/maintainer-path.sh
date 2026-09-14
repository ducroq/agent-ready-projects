#!/usr/bin/env bash
# Lint rule 13 — a MAINTAINER-ONLY path referenced from an adopter-installed
# surface (#139, promoted from a review finding per #127).
#
# `docs/rationale/` holds THIS repo's litigation about its OWN skills. Adopters
# never create it: no template tells them to, and `adopt.md` does not ship it.
# A skill body that points there sends every adopter to a path their clone does
# not contain. v1.37.0 shipped five such pointers; v1.38.0's beb37da removed all
# five; a change made HOURS LATER re-created one in the same two files, and it
# took a full review round to find. That is the #127 criterion met exactly — a
# finding that recurred, costing a review each time, where a check costs nothing.
#
# ⚠️ THE DENYLIST IS DECLARED AND DELIBERATELY SHORT. Measured over the current
# adopter-installed surface, in LINES, which is this rule's own unit -- it greps
# with `grep -n -F` and reports one finding per line, so re-derive with
# `grep -c docs/rationale <file>`: `CHANGELOG.md` (12), `tests/lint/run.sh` (1)
# and `tests/fixtures/` are all LEGITIMATE -- an adopter has their own changelog,
# and the guarantee lens names files in the adopter's tree by design. A broad
# "maintainer path" denylist would report every one of them. Add an entry only
# with a measurement showing it is never legitimate here.
# ⚠️ The (3) that stood here for run.sh was never true at any commit (max 1,
# introduced in d73df7e), and it quoted no unit while the two plausible units
# differ: CHANGELOG.md is 12 lines but 17 occurrences.
#
# Exemption is DECLARED, never guessed (rule 11's lesson): put
# `lint-skip: maintainer-path` on the same line.
#
# Exit: 0 clean, 1 findings on stdout, 2 could not run.
set -u
ROOT="${1:-.}"
cd "$ROOT" || { echo "maintainer-path: cannot enter $ROOT" >&2; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "maintainer-path: not a git work tree — population cannot be determined" >&2; exit 2; }

# One entry per line: <path fragment><TAB><why an adopter never has it>
DENY=$(printf '%s\n' \
  "docs/rationale/	holds this repo's own skill litigation; no template creates it")

# Tracked PLUS untracked-not-ignored: a new skill file is covered before it is
# committed. A tracked-only population passed clean over this rule's own fixture.
POP=$( { git ls-files -- templates .claude/skills
         git ls-files --others --exclude-standard -- templates .claude/skills; } | sort -u )
[ -n "$POP" ] || { echo "maintainer-path: EMPTY POPULATION — no adopter-installed files found" >&2; exit 2; }

nfiles=$(printf '%s\n' "$POP" | grep -c .)
npat=$(printf '%s\n' "$DENY" | grep -c .)
found=0; exempted=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  while IFS="$(printf '\t')" read -r pat why; do
    [ -n "$pat" ] || continue
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      # ⚠️ A DECLARED exemption must still be a valid reference, or the escape
      # hatch passes exactly the dead pointer this rule exists to catch. Measured:
      # the bare marker let `See docs/rationale/x.md <!-- lint-skip -->` through in
      # a scratch repo. The only legitimate reason to name this path on an
      # adopter surface is a URL, which resolves for a reader who has no such
      # directory — so the exemption is granted only when the matched path sits
      # inside an `https://` run on the same line.
      case "$hit" in
        *"lint-skip: maintainer-path"*)
          # ⚠️ EVERY occurrence must sit inside a URL run, not merely "a URL is on
          # the line". `grep -F` yields one hit per LINE, so testing for `https://`
          # anywhere let one unrelated URL exempt a second, genuinely dead
          # reference beside it — measured: `Background at https://example.com/ —
          # details in docs/rationale/x.md <marker>` scored rc 0. Stripping the URL
          # runs and re-testing is what closes it.
          stripped=$(printf '%s' "$hit" | sed -E 's#https?://[^[:space:]]*##g')
          case "$stripped" in
            *"$pat"*) printf '%s:%s [INVALID EXEMPTION: the lint-skip is declared, but this reference is not inside a URL — a repo-relative path is dead in every adopter clone, which is what this rule catches]\n' "$f" "$hit" ;;
            *) exempted=$((exempted + 1)); continue ;;
          esac ;;
      esac
      ln=${hit%%:*}
      echo "$f:$ln: references the maintainer-only path '$pat' — $why. An adopter's clone has no such file, so this pointer is dead on every install (#139)"
      found=1
    done <<EOF
$(grep -n -F "$pat" "$f" 2>/dev/null)
EOF
  done <<EOF
$DENY
EOF
done <<EOF
$POP
EOF

echo "maintainer-path: $nfiles adopter-installed file(s) scanned for $npat maintainer-only path(s); $exempted declared-exempt (URL form)" >&2
[ "$found" -eq 0 ] || exit 1
