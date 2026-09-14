#!/usr/bin/env python3
"""Extract review-changes Step 1.5's awk program from the template.

Usage: extract-step15.py <templates/review-changes.md> <out.awk>

THE AUTHORITY for this extraction. Two callers need the shipped program — the
seeded fixture (tests/fixtures/step15-tables/run.sh) and the corpus rule
(tests/lint/step15-corpus.sh) — and a second copy of the anchors would drift
from this one silently, which is the class rule 6 exists for one level up.

EXTRACTED, NEVER COPIED: a copy of the program itself would pass while the
template rotted, and `memory/gotcha-log.md` records a session hand-slicing this
block by line range on a branch where the lines differed — awk failed to parse
eight times and the wrapper printed what a clean run prints.

Loud rather than silent: an extraction yielding a program without the constructs
under test is the same failure the callers exist to catch, so a missing needle
exits non-zero rather than writing a program that finds nothing.
"""
import sys
import pathlib

if len(sys.argv) != 3:
    sys.exit("usage: extract-step15.py <template> <out.awk>")

src = pathlib.Path(sys.argv[1])
if not src.is_file():
    sys.exit("EXTRACTION FAILED — %s is not a file" % src)

s = src.read_text()
open_anchor = '  awk -v F="$f" \''
try:
    i = s.index(open_anchor)
    j = s.index("' \"$f\"", i)
except ValueError:
    sys.exit("EXTRACTION FAILED — the anchors moved in %s" % src)

prog = s[i + len(open_anchor):j]

# The three constructs the callers assert on. A program missing one of them
# still runs and still prints nothing, which is indistinguishable from a clean
# corpus — the silence this guard ends.
for needle in ("isdelim", "sub(/\\r$/", "infm"):
    if needle not in prog:
        sys.exit("EXTRACTION FAILED — extracted program is missing %r" % needle)

pathlib.Path(sys.argv[2]).write_text(prog)
