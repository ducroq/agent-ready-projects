#!/usr/bin/env bash
# Lint rule 18 — #197. A release tag whose CHANGELOG.md block still reads
# "(candidate, unreleased)" — or that has no block at all — is a release adopters
# cannot see: CHANGELOG.md is what they read to decide whether to upgrade. v1.45.1
# shipped that way and three checks agreed it was released, because each read the
# TAG and none read the heading.
#
# Population: `git tag --list 'v[0-9]*'` less prereleases (a hyphen). Exit 0 clean,
# 1 findings, 2 cannot run, 3 SKIPPED — no release tags here (a CI checkout
# fetches none), so nothing was checked.
#
# ⚠️ What it cannot see: it reads the WORKING TREE, not what each tag held — a tag
# cut before its heading was dated reads green here forever. And it reads the
# heading only: a dated but empty or wrongly dated block passes.
set -u
root="${1:?usage: released-heading.sh <repo-root>}"
cd "$root" || exit 2
[ -f CHANGELOG.md ] || { echo "released-heading: no CHANGELOG.md in $root" >&2; exit 2; }
n=0; bad=0
while IFS= read -r t; do
  case "$t" in ''|*-*) continue ;; esac
  n=$((n + 1))
  # CR stripped (a CRLF file put `\r` on the tag when it was the last field), and
  # headings inside ``` fences or <!-- --> comments skipped: this CHANGELOG
  # quotes bad headings as examples, and the first match wins (#197 review).
  h=$(awk -v t="$t" '
    { sub(/\r$/, "") }
    /^```/ { fence = !fence; next }
    fence { next }
    incom { if (index($0, "-->")) incom = 0; next }
    /^[ \t]*<!--/ { if (!index($0, "-->")) incom = 1; next }
    $1 == "##" && $2 == t { print; exit }' CHANGELOG.md)
  if [ -z "$h" ]; then
    echo "CHANGELOG.md: $t is tagged but has no '## $t' block"; bad=1
  else
    case "$h" in *candidate*|*unreleased*)
      echo "CHANGELOG.md: $t is tagged but its block still reads '$h' — promote it (templates/release.md Step 4)"; bad=1 ;;
    esac
  fi
done < <(git tag --list 'v[0-9]*' 2>/dev/null)
if [ "$n" -eq 0 ]; then
  echo "released-heading: SKIPPED — no release tags here, so NOTHING was checked" >&2; exit 3
fi
echo "released-heading: $n release tag(s) checked against CHANGELOG.md headings" >&2
exit $bad
