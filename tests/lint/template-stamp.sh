#!/usr/bin/env bash
# Rule 21 — #171. A scaffolding template's `framework:` stamp names the release it
# ships in. The v1.41.0 tag shipped two templates stamped v1.40.0: the bump landed
# in the wrap-up commit AFTER the tag, and templates/release.md Step 5 had named
# this exact class in prose and not prevented it.
#
# Population: every templates/*.md line `framework: agent-ready-projects vX.Y.Z`.
# Three checks, by which state the repo is in:
#   1. Top CHANGELOG.md block DATED (a release commit): every stamp equals its
#      version. Needs no tags, so it runs in CI. This is the commit a tag points
#      at, and the one v1.41.0 got wrong.
#   2. Top block a candidate (between releases): every stamp equals the highest
#      release tag reachable from HEAD.
#   3. The highest reachable tag's OWN templates carry its version, read with
#      `git show`, not from the working tree. A probe that read the working tree
#      was green on the run that found #171.
# Checks 2 and 3 need tags; with none (a CI checkout fetches none) they are
# SKIPPED, and if check 1 did not run either, the whole rule exits 3.
#
# Exit 0 clean, 1 findings, 2 cannot run, 3 SKIPPED.
#
# ⚠️ What it cannot see: a tag older than the highest reachable one (v1.41.0 is
# permanently wrong and no longer checked), a stamp in any other shape, and a
# template that carries no stamp at all.
set -u
root="${1:?usage: template-stamp.sh <repo-root>}"
cd "$root" || exit 2
[ -f CHANGELOG.md ] || { echo "template-stamp: no CHANGELOG.md in $root" >&2; exit 2; }

STAMP_RE='^framework: agent-ready-projects v[0-9]+\.[0-9]+\.[0-9]+'
stamp_of() { grep -m1 -oE "$STAMP_RE" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+$'; }

files=$(grep -lE "$STAMP_RE" templates/*.md 2>/dev/null)
[ -n "$files" ] || { echo "template-stamp: no stamped template found under templates/ — this rule checked nothing" >&2; exit 2; }
nf=$(printf '%s\n' "$files" | grep -c .)

# The first `## v` heading outside ``` fences and <!-- --> comments, as rule 18 reads it.
top=$(awk '
  { sub(/\r$/, "") }
  /^```/ { fence = !fence; next }
  fence { next }
  incom { if (index($0, "-->")) incom = 0; next }
  /^[ \t]*<!--/ { if (!index($0, "-->")) incom = 1; next }
  $1 == "##" && $2 ~ /^v[0-9]/ { print; exit }' CHANGELOG.md)
[ -n "$top" ] || { echo "template-stamp: no '## vX.Y.Z' heading in CHANGELOG.md" >&2; exit 2; }
topv=$(printf '%s\n' "$top" | awk '{ print $2 }')

bad=0; ran=""
case "$top" in
  *candidate*|*unreleased*) want="" ;;
  *) want="$topv"; ran="dated block $topv" ;;
esac

tag=$(git tag --merged HEAD --list 'v[0-9]*' 2>/dev/null | grep -v -- - | sort -V | tail -1)

if [ -z "$want" ] && [ -n "$tag" ]; then
  want="$tag"; ran="highest reachable tag $tag"
fi

if [ -n "$want" ]; then
  for f in $files; do
    s=$(stamp_of < "$f")
    [ "$s" = "$want" ] || { echo "$f: stamped $s, but the $ran says $want (templates/release.md Step 5)"; bad=1; }
  done
fi

if [ -n "$tag" ]; then
  for f in $files; do
    s=$(git show "$tag:$f" 2>/dev/null | stamp_of) || continue
    [ -z "$s" ] || [ "$s" = "$tag" ] || { echo "$f: the $tag tag ships it stamped $s — the bump missed the tagged commit (#171)"; bad=1; }
  done
  ran="${ran:+$ran; }$tag tag's own templates"
fi

if [ -z "$ran" ]; then
  echo "template-stamp: SKIPPED — top block is a candidate and there are no release tags here, so NOTHING was checked" >&2; exit 3
fi
echo "template-stamp: $nf stamped template(s) checked against the $ran" >&2
exit $bad
