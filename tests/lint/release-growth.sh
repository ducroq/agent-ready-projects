#!/usr/bin/env bash
# Lint rule 19 — H-022. A release that grows the adopter-facing surface must say so.
#
# Rule 8's budget can always be raised, so it never limited growth (43 raises by
# 2026-09-25). This rule moves the pressure to the one point where it is read:
# when the top CHANGELOG.md block is dated (a release, not a candidate), the size
# of templates/**/*.md is compared with the previous release tag. If it grew, the
# block must carry a line "Adopter-facing size: +N bytes" with N the real growth.
#
# Size is taken at the block's tag if it exists, else from the working tree (the
# release commit, before tagging). A candidate top block is not checked.
#
# Exit 0 clean, 1 finding, 2 cannot run, 3 SKIPPED — no earlier release tag here
# (a CI checkout fetches none), so nothing was compared.
set -u
root="${1:?usage: release-growth.sh <repo-root>}"
cd "$root" || exit 2
[ -f CHANGELOG.md ] || { echo "release-growth: no CHANGELOG.md in $root" >&2; exit 2; }

head=$(awk '{ sub(/\r$/, "") } /^```/ { f = !f; next } f { next }
            /^## v[0-9]+\.[0-9]+\.[0-9]+/ { print; exit }' CHANGELOG.md)
[ -n "$head" ] || { echo "release-growth: no '## vX.Y.Z' block in CHANGELOG.md" >&2; exit 2; }
v=$(printf '%s\n' "$head" | awk '{ print $2 }')
case "$head" in *candidate*|*unreleased*)
  echo "release-growth: top block $v is a candidate — nothing to check until it is dated" >&2; exit 0 ;;
esac

base=$(git tag --merged HEAD --list 'v[0-9]*' 2>/dev/null | sed '/-/d' | grep -vxF "$v" | sort -V | tail -1)
[ -n "$base" ] || { echo "release-growth: SKIPPED — no release tag before $v here, so NOTHING was compared" >&2; exit 3; }

size_at() { git ls-tree -r -l "$1" -- templates 2>/dev/null |
            awk -F'\t' '$2 ~ /\.md$/ { split($1, a, " "); s += a[4] } END { print s + 0 }'; }
old=$(size_at "$base")
if git rev-parse --verify --quiet "refs/tags/$v" >/dev/null; then new=$(size_at "$v"); where="tag $v"
else new=$(find templates -name '*.md' -type f -print0 | xargs -0 cat | wc -c | tr -d ' '); where="working tree"
fi
[ "$old" -gt 0 ] && [ "$new" -gt 0 ] || { echo "release-growth: could not measure templates/ ($base=$old, $where=$new)" >&2; exit 2; }

echo "release-growth: $v ($where) $new bytes against $base $old bytes" >&2
grow=$((new - old))
[ "$grow" -gt 0 ] || exit 0

block=$(awk -v h="$head" '$0 == h { f = 1; next } f && /^## v[0-9]/ { exit } f' CHANGELOG.md)
said=$(printf '%s\n' "$block" | grep -oE 'Adopter-facing size[^0-9+-]*\+[0-9,]+ bytes' | head -1 | grep -oE '\+[0-9,]+' | tr -d '+,')
if [ -z "$said" ]; then
  echo "CHANGELOG.md: $v grows templates/ by +$grow bytes since $base and its block does not say so — add 'Adopter-facing size: +$grow bytes' and why"
  exit 1
elif [ "$said" != "$grow" ]; then
  echo "CHANGELOG.md: $v says 'Adopter-facing size: +$said bytes' but templates/ grew +$grow bytes since $base"
  exit 1
fi
exit 0
