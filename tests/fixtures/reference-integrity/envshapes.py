#!/usr/bin/env python3
"""The `.env` extraction contract as a table (#70).

`env` is filename-shaped, not extension-shaped, so `PATH_RE` alone captures
`process.env`. `_is_identifier_not_path` narrows that back down. The two rules
are easy to reason about separately and easy to get wrong together, and the
cost of getting them wrong is asymmetric: over-capture is a phantom finding
somebody will eventually chase, under-capture is silence nobody investigates.

Two things this table is guarding that a reading of the code will not show:

- The leading-dot arm is effectively unreachable. `.env.example` — the example
  given for it in both the code comment and the template — has extension
  `example`, so it never reaches the predicate at all; it is kept by the
  `ext not in IDENTIFIER_EXT` early return. The only shape that actually
  exercises the arm is `.something.env`. Anyone reading the comment will
  reasonably conclude the arm is what preserves `.env.example` and may simplify
  it away, taking `config/live.env` with it.
- A bare `.env` is not extracted, and never was: `PATH_RE` needs a dot with
  something before it. The template's wording implies otherwise. The row below
  is the one that will contradict the prose if the prose gets "fixed" to match
  what it says.

Run from the fixture directory: `python3 envshapes.py`.
"""

import sys

import refcheck as R

# token, extracted by PATH_RE, dropped by the identifier rule
TABLE = [
    # the phantom the fix exists to kill
    ('process.env',         True,  True),
    # the false negative the fix knowingly buys, stated in the changelog
    ('settings.env',        True,  True),
    ('FOO.env',             True,  True),
    ('my-app.env',          True,  True),
    ('a.b.c.env',           True,  True),
    # the path form, which must keep its coverage — this is what T17 protects
    ('config/live.env',     True,  False),
    ('src/app.env',         True,  False),
    ('x/.env',              True,  False),
    ('deploy/.env.example', True,  False),
    # extension is `example`, not `env`: never reaches the predicate
    ('.env.example',        True,  False),
    # the only shape that actually exercises the leading-dot arm
    ('.config.env',         True,  False),
    # never extracted, with or without the fix. The template says otherwise.
    ('.env',                False, False),
    # PATH_RE's extension alternation is case-sensitive
    ('a.ENV',               False, False),
    # KNOWN CORNER, documented rather than fixed: a self-announcing placeholder
    # ending in .env is dropped outright instead of reaching the counted skip
    # section. Never-extracted and skipped are the distinction this whole step
    # is built on, so if this row is ever made to pass it should move to the
    # fixture as a real case, not be silently flipped here.
    ('<slug>.env',          True,  True),
]

fails = []
for token, want_extracted, want_dropped in TABLE:
    got_extracted = bool(R.PATH_RE.fullmatch('`' + token + '`'))
    got_dropped = got_extracted and R._is_identifier_not_path(token)
    if (got_extracted, got_dropped) != (want_extracted, want_dropped):
        fails.append(f'  {token:22s} want extracted={want_extracted} dropped={want_dropped}'
                     f' — got extracted={got_extracted} dropped={got_dropped}')

if fails:
    print('envshapes: the .env contract changed:', file=sys.stderr)
    print('\n'.join(fails), file=sys.stderr)
    sys.exit(1)
sys.exit(0)
