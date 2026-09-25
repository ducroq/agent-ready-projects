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
git rev-parse --git-dir >/dev/null 2>&1 || { echo "release-growth: $root is not a git repository" >&2; exit 2; }
[ -f CHANGELOG.md ] || { echo "release-growth: no CHANGELOG.md in $root" >&2; exit 2; }

# Headings inside fences (``` or ~~~) and HTML comments are skipped, as in rule 18.
headings() { awk '
  { sub(/\r$/, "") }
  /^(```|~~~)/ { fence = !fence; next }
  fence { next }
  incom { if (index($0, "-->")) incom = 0; next }
  /^[ \t]*<!--/ { if (!index($0, "-->")) incom = 1; next }
  { print NR "\t" $0 }' CHANGELOG.md; }
top=$(headings | awk -F'\t' '$2 ~ /^## v[0-9]+\.[0-9]+\.[0-9]+/ { print; exit }')
[ -n "$top" ] || { echo "release-growth: no '## vX.Y.Z' block in CHANGELOG.md" >&2; exit 2; }
line=${top%%	*}; head=${top#*	}
v=$(printf '%s\n' "$head" | grep -oE '^## v[0-9]+\.[0-9]+\.[0-9]+' | cut -c4-)
case "$head" in *candidate*|*unreleased*)
  echo "release-growth: top block $v is a candidate — nothing to check until it is dated" >&2; exit 0 ;;
esac

# The previous release: the highest non-prerelease tag reachable from HEAD that sorts below v.
tags=$(git tag --merged HEAD --list 'v[0-9]*') || { echo "release-growth: git tag failed" >&2; exit 2; }
base=$(printf '%s\n%s\n' "$tags" "$v" | sed '/-/d; /^$/d' | sort -t. -k1.2,1n -k2,2n -k3,3n -u |
       awk -v v="$v" '$0 == v { print p; exit } { p = $0 }')
[ -n "$base" ] || { echo "release-growth: SKIPPED — no release tag before $v here, so NOTHING was compared" >&2; exit 3; }

# Tracked templates/**/*.md only, on both sides, so ignored scratch files never count.
size_at() { git -c core.quotePath=false ls-tree -r -l -z "$1" -- templates 2>/dev/null |
            awk -v RS='\0' -F'\t' '$2 ~ /\.md$/ { split($1, a, " "); if (a[4] ~ /^[0-9]+$/) s += a[4] } END { print s + 0 }'; }
if git rev-parse --verify --quiet "refs/tags/$v" >/dev/null; then new=$(size_at "$v"); where="tag $v"
else new=$(git ls-files -z -- 'templates/*.md' | xargs -0 cat 2>/dev/null | wc -c | tr -d ' '); where="working tree, tracked files"
fi
old=$(size_at "$base")
[ "$old" -gt 0 ] && [ "$new" -gt 0 ] || { echo "release-growth: could not measure templates/ ($base=$old, $where=$new)" >&2; exit 2; }

echo "release-growth: $v ($where) $new bytes against $base $old bytes" >&2
grow=$((new - old))
[ "$grow" -gt 0 ] || exit 0

block=$(awk -v start="$line" '{ sub(/\r$/, "") } NR > start && /^## v[0-9]/ { exit } NR > start' CHANGELOG.md)
said=$(printf '%s\n' "$block" | grep -oE 'Adopter-facing size[^0-9+-]*\+[0-9,]+ bytes' | head -1 | grep -oE '\+[0-9,]+' | tr -d '+,')
if [ -z "$said" ]; then
  echo "CHANGELOG.md: $v grows templates/ by +$grow bytes since $base and its block does not say so — add 'Adopter-facing size: +$grow bytes' and why"
  exit 1
elif [ "$((10#$said))" -ne "$grow" ]; then
  echo "CHANGELOG.md: $v says 'Adopter-facing size: +$said bytes' but templates/ grew +$grow bytes since $base"
  exit 1
fi
exit 0
