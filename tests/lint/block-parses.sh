#!/usr/bin/env bash
# Lint rule 11 — a fenced bash block on an adopter-facing surface must parse.
#
# #105: `templates/review-changes.md`'s Step 1.5 block carried an ASCII
# apostrophe inside a single-quoted awk program ("Step 1.5's property"). That
# apostrophe closed the program, and the backticked regex a few lines below was
# then read by bash as command substitution:
#
#     syntax error near unexpected token `rest,'
#
# It shipped for eight releases. Nothing here could see it: rule 6 compares two
# copies carrying the same apostrophe, so they agree perfectly; the size ratchet
# measures bytes; and every internal run of Step 1.5 transcribed the awk into a
# fresh heredoc rather than copying the fenced block, which is why it worked for
# the maintainer and for no adopter. The magnitude gate in that very file says
# "any change to a shell script or an executable" is always full depth — a
# fenced block in a template is neither, and nothing parsed it.
#
# SCOPE, and it is deliberately narrow: this reports a block that does not
# parse. It does not run anything, and `bash -n` cannot see a command that is
# well-formed and wrong.
#
# THE EXEMPTION IS EXPLICIT, NOT HEURISTIC. Some blocks are templates an author
# fills in — `git add CHANGELOG.md <each file updated in Step 5>` — and cannot
# parse by design. A first draft skipped any block containing an angle-bracket
# placeholder and that was wrong on three of the four it exempted: `<slug>` in
# curate's block sits inside the embedded PYTHON program, and that block is the
# highest-traffic executable in the framework. Measured: 26 blocks, 8 skipped by
# the heuristic, only 1 (in two copies) genuinely unrunnable. A block that
# cannot parse must say so on its first line, which is reviewable where a
# heuristic is not.
usage() { echo "usage: block-parses.sh <repo-root>" >&2; exit 2; }
[ $# -eq 1 ] || usage
cd "$1" 2>/dev/null || { echo "block-parses: cannot enter $1" >&2; exit 2; }

MARKER='# lint-skip: not-executable'
found=0 total=0 skipped=0

# The surfaces an adopter consumes or executes. `.claude/skills/**` is here for
# the same reason rule 6 has it: a defect there ships to every derived install.
files=$(ls templates/*.md .claude/skills/*/SKILL.md adopt.md docs/GUIDE.md README.md 2>/dev/null)
[ -n "$files" ] || { echo "block-parses: no adopter-facing files found under $1" >&2; exit 2; }

work=$(mktemp -d) || exit 2
trap 'rm -rf "$work"' EXIT

fileno=0
for f in $files; do
  fileno=$((fileno + 1))
  # Split into fenced bash/sh blocks. Opening fence must be exactly ```bash or
  # ```sh; the closing fence exactly ```. A tilde fence is not used by any
  # shipped block (measured) and is out of scope rather than silently handled.
  # ⚠️ The output name carries the FILE ordinal as well as the block ordinal.
  # awk's `n` restarts at 1 for every invocation, so a name keyed on `n` alone
  # made each file's blocks overwrite the previous file's: the rule reported
  # "26 blocks parsed, 0 failures" while actually parsing the last file's
  # content 26 times, and the one block known to fail came back clean. Caught by
  # checking the count against a known-failing block rather than by reading it.
  awk -v OUT="$work" -v F="$f" -v FN="$fileno" '
    !inb && /^```(bash|sh)[ \t]*$/ { inb=1; n++; start=NR; buf=""; next }
    inb && /^```[ \t]*$/ {
      inb=0
      path = OUT "/" FN "-" n ".sh"
      printf "%s", buf > path
      close(path)
      printf "%s %d %s\n", F, start, path
      next
    }
    inb { buf = buf $0 "\n" }
    END { if (inb) printf "%s %d UNCLOSED\n", F, start }
  ' "$f"
done > "$work/index"

while read -r file line blk; do
  total=$((total + 1))
  if [ "$blk" = "UNCLOSED" ]; then
    printf '%s:%s: unclosed ```bash fence — the block cannot be extracted, so it was never parsed\n' "$file" "$line"
    found=1; continue
  fi
  if head -1 "$blk" | grep -qF -- "$MARKER"; then
    skipped=$((skipped + 1)); continue
  fi
  if ! err=$(bash -n "$blk" 2>&1); then
    printf '%s:%s: fenced bash block does not parse — an adopter copying it gets a shell error, not a check\n' "$file" "$line"
    printf '    %s\n' "$(printf '%s' "$err" | head -1 | sed "s|$blk|<block>|g")"
    found=1
  fi
done < "$work/index"

# The coverage line is not decoration: run.sh fails the rule when it is missing,
# because "no output" from a checker that scanned nothing reads identically to a
# clean run. Same reason rules 6-10 each print one.
printf 'block-parses: %d fenced bash block(s) parsed across adopter-facing surfaces; %d skipped as declared not-executable\n' "$total" "$skipped" >&2
exit "$found"
