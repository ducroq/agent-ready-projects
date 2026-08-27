#!/usr/bin/env python3
"""Reference implementation of audit-context Step 4 (reference integrity).

    python3 refcheck.py [--legacy] <repo-root> <doc> [<doc> ...]

This exists so that a change to Step 4 can be *tested* rather than asserted.
Run run.sh in this directory to exercise it against a fixture that seeds the
failures Step 4 must catch.

The skill text is normative; this is one faithful reading of it. If they
disagree, the skill is right and this file is the bug.

Promoting this file to the *runtime* for Step 4 was attempted and shelved
(see docs/work-items/model-fit.md). Two blockers, both unresolved: the installer
ships only SKILL.md, so the script never reaches an adopter repo; and the manual
fallback written for that case omitted the report-shape split, so it silently
reproduced the v1.15.0 defect it was meant to replace. The idea is sound; the
packaging is not. Do not re-attempt without solving distribution first.

Output sections: FINDINGS (broken or ambiguous — the defects), RESOLVED BELOW
RUNG 1 (enumerated, not defects), SKIPPED as asserted-absent, UNCONFIRMED (what
this run could not decide), extensions in the tree the extractor misses, and —
only when they apply — DOCUMENTS NOT READ and
a RUNG 4 COVERAGE line. On the default path a VERDICT line closes the report and
names the exit status, so the two cannot drift apart unnoticed; `--legacy` is a
re-derivation of the v1.15.0 numbers and prints no verdict; it returns 0 on any
run that reaches it, which a usage error does not.

Exit (default path): 0 clean; 1 something was ruled on — a finding a rung
actually decided, or a document that could not be read; 2 nothing was ruled on
but something was left undecided, because rung 4 had no neighbouring repo to run
against (#93). **2 is still non-zero** — a gate written as `refcheck.py ... && ...`
behaves exactly as it did before, and only a caller that opts in
(`|| [ $? -eq 2 ]`) accepts an undecided run. A usage error exits **64**
(`EX_USAGE`), so a typo'd flag cannot be read as either verdict.

**Backticked paths and markdown-link URLs are extracted; a bare prose path is
not.** A link's *label* is a display name and is masked before extraction, while
its URL is checked in the label's place (#55); a URL the whitelist declines is
listed under LINK URLs NOT CHECKED rather than dropped. An all-empty report is
still not by itself proof of a clean document — check the document's style, and
check that DOCUMENTS NOT READ is absent, before reading empty as passing.
"""

import re
import sys
import pathlib

# The verdict a reference gets when every rung that could run has run and none
# of them could rule on it, because rung 4 needs a neighbouring repo on disk and
# none was reachable. It is deliberately a distinct string from a plain
# `UNRESOLVED`: the two look identical to a reader and exited identically to a
# gate, which made the exit status a property of WHERE the audit ran rather than
# of what it audited (#93). A correct repo whose neighbours are simply not
# checked out — CI, a fresh clone, a container — failed on its environment.
UNCONFIRMED = 'UNRESOLVED (unconfirmed: rung 4 did not run)'

# Extensions the extractor recognises. NOT a closed world: `unknown_extensions`
# below reports what the tree contains that this list misses, so a repo whose
# primary sources are .tf/.ipynb/.kt cannot be silently un-audited.
EXT = (
    'py|md|yaml|yml|json|jsonl|sh|bash|zsh|ini|cfg|conf|toml|txt|csv|tsv|sql|db'
    '|xml|html|css|js|ts|tsx|jsx|rs|go|java|rb|php|c|h|cpp|hpp|cs|kt|swift|r'
    '|lock|env|example|service|timer|socket|gitignore|dockerfile|tf|ipynb|proto'
    '|vue|svelte|rst|log|tag|svg|png|qmd'
)
# `<` and `>` are in the class so that `docs/work-items/<slug>.md` is EXTRACTED.
# Leaving them out looked like the skip working — the path simply never
# reached the checker, so it could be neither reported nor counted, which is
# the silent-skip failure this file exists to prevent (#45).
PATH_RE = re.compile(r'`([A-Za-z0-9_.<][A-Za-z0-9_./*<>-]*\.(?:' + EXT + r'))`')
URLPATH_RE = re.compile(r'^[A-Za-z0-9_.<][A-Za-z0-9_./*<>-]*\.(?:' + EXT + r')$')

# Some EXT entries are FILENAME-shaped, not extension-shaped, and the rule
# matches the tail of any dotted token — so `env` captures `process.env`, a
# ubiquitous code identifier and a guaranteed phantom: no such file exists and
# none was ever meant to. That is the failure the whitelist exists to prevent,
# arriving through it rather than around it (#70).
#
# Keep such a token only when it still looks like a path: it contains a `/`, or
# it starts with a `.` — `.config.env`, NOT `.env.example`, whose extension is
# `example` and which therefore never reaches this test. A bare `.env` never
# matched anyway —
# PATH_RE needs a dot with something before it.
#
# ⚠️ Measured cost, stated rather than hidden: a bare `settings.env` written
# with no directory is no longer extracted. Both shapes are seeded in the
# fixture (T17 keeps the path form reported, N15 keeps `process.env` silent).
# Only `env` is listed. `example`, `gitignore` and `dockerfile` are the same
# shape and are deliberately NOT included — no collision has been measured for
# them, and tightening on argument rather than evidence is how a check loses
# sensitivity nobody notices.
IDENTIFIER_EXT = ('env',)


def _is_identifier_not_path(frag):
    """True for a dotted code identifier wearing a whitelisted extension."""
    ext = frag.rsplit('.', 1)[-1].lower()
    if ext not in IDENTIFIER_EXT:
        return False
    return '/' not in frag and not frag.startswith('.')

STATE_DIRS = ('data/', 'state/', 'cache/', 'logs/', 'run/', 'var/', 'artifacts/')
STATE_SHAPE = re.compile(r'(_state\.json|_health\.json|\.pid|\.sock)$')
# NB: there is deliberately no 'bare lowercase .json' rule. One existed and was
# removed — it classified package.json, tsconfig.json and package-lock.json as
# runtime state, i.e. as correctly-absent. A committed lockfile is not runtime
# state. The documented test is a state DIRECTORY or a state-file SHAPE; keep it
# that way, and see docs/reference-integrity.md before widening either.
PRUNE = {'.git', 'venv', '.venv', 'node_modules', '__pycache__', 'target', 'dist'}

# Span-scoped, NOT line-scoped. A line may retire one path and name its live
# replacement in the same sentence; skipping the line loses the replacement.
STRIKE_RE = re.compile(r'~~(.+?)~~')
# The retired path may be written as a backticked span or as a markdown link;
# before #55 only the first form existed here, and masking the link label made
# the second form stop being covered at all — a deliberate deletion reported as
# a break. Seeded as N27.
DELETED_RE = re.compile(r'\*\*Deleted\*\*:?\s*(\[[^\]\[]*\]\([^()\s]+\)|`[^`]+`)')
# `<!-- placeholder -->` mirrors the file's existing `<!-- verify: -->` idiom:
# invisible when rendered, greppable, machine-readable.
PLACEHOLDER_RE = re.compile(r'<!--\s*placeholder\s*-->')
SPAN_RE = re.compile(r'`[^`]*`')
# A markdown link's TEXT is a display label, not a reference (#55). The house
# style this framework recommends is exactly ``[`writing-guide.md`](templates/writing-guide.md)``
# — a backticked filename as the label with the real path in the URL — so the
# better a document follows the convention, the more phantom collisions the
# label generates, and the pressure is to stop backticking link text, which
# makes the docs worse. Mask the label, then extract the URL, which is the
# reference. Masking ALONE would be a loosening with no compensating check: the
# label used to give a broken URL accidental coverage, since a label matching
# its own target reported UNRESOLVED when the target was missing.
LINK_RE = re.compile(r'\[([^\]\[]*)\]\(([^()\s]+)(?:\s+"[^"]*")?\)')


def _mask_link_labels(line):
    """Blank the TEXT of every markdown link, preserving offsets, so the label
    is not extracted as a path. The URL is left in place; it is extracted
    separately by _link_urls()."""
    def sub(m):
        whole = m.group(0)
        label = m.group(1)
        i = whole.index('[')
        return whole[:i + 1] + ' ' * len(label) + whole[i + 1 + len(label):]
    return LINK_RE.sub(sub, line)


def _link_urls(line):
    """Markdown-link URLs on this line, as (start, end, url, why).

    `why` is None when the URL is a checkable path. Otherwise it names the
    reason it is not, and the caller must REPORT that rather than drop it: the
    label used to give these accidental coverage, so silently declining them
    would trade a phantom for a silent skip — the class this whole file exists
    to prevent (#45). Measured on five broken-link shapes where the label was
    the only coverage, dropping them silently took the findings from 5 to 1."""
    out = []
    for m in LINK_RE.finditer(line):
        raw = m.group(2)
        st, en = m.start(2), m.end(2)
        url = raw.split('#', 1)[0].strip()
        if not url:
            out.append((st, en, raw, 'an in-page anchor, no file named'))
        elif URLISH.match(url) or ':' in url.split('/', 1)[0]:
            out.append((st, en, url, 'an external URL, not a path in this tree'))
        # Root-relative BEFORE the whitelist test, or the reason printed is
        # simply wrong: `/docs/GUIDE.md` failed URLPATH_RE on its leading slash
        # and was reported as "extension outside the whitelist: .md" — and `.md`
        # is whitelisted. Root-relative is the standard GitHub link form, so it
        # is a message an adopter meets early and is misled by. Declined rather
        # than resolved because "root" is ambiguous here: a docs site's root and
        # the repo root are frequently not the same directory.
        elif url.startswith('/'):
            out.append((st, en, url,
                        'root-relative; this checker resolves from the repo root '
                        'and cannot tell that apart from a docs-site root'))
        elif URLPATH_RE.match(url):
            out.append((st, en, url, None))
        elif url.endswith('/'):
            out.append((st, en, url, 'a directory, not a file'))
        else:
            ext = url.rsplit('.', 1)[-1] if '.' in url.rsplit('/', 1)[-1] else ''
            out.append((st, en, url,
                        'extension outside the whitelist: .%s' % ext if ext
                        else 'no extension, so no whitelist entry can match it'))
    return out


# A link-shaped construct LINK_RE cannot parse: nested brackets, a `]` inside the
# label, parentheses inside the URL, an angle-bracket URL, a reference-style
# `[text][ref]`. Each one drops BOTH the label and the URL, so the reference
# vanishes entirely — no finding, no enumeration. Counting them is what keeps
# "never dropped" from being a false absolute.
LINKISH_RE = re.compile(r'\]\s*[\(\[]')


def _unparsed_links(raw_line):
    """How many link-shaped constructs LINK_RE failed to parse on this line."""
    return max(0, len(LINKISH_RE.findall(raw_line)) - len(LINK_RE.findall(raw_line)))


def _candidates(raw_line):
    """Every path-shaped candidate on the line, as (start, end, frag), in source
    order: backticked spans with markdown-link LABELS masked out, plus the URL
    of each markdown link that is a checkable path.

    One extractor for all three consumers — the strikethrough/`**Deleted**`
    skip collectors, the span-scoped placeholder arithmetic, and the rung
    ladder — because they must agree on what a candidate IS. They did not on
    the first draft of #55: masking the label removed the only backticked token
    from a struck span, so `~~[`old.py`](src/old.py)~~ was removed` stopped
    being suppressed and a deliberate retirement was reported as a break, while
    a placeholder on a link reported COVERS NO PATH *and* excused the path in
    the same run. Measured against HEAD, both directions."""
    masked = _mask_link_labels(raw_line)
    out = [(m.start(1), m.end(1), m.group(1)) for m in PATH_RE.finditer(masked)]
    out += [(st, en, u) for st, en, u, why in _link_urls(raw_line) if why is None]
    out.sort()
    return out


def _mask_spans(line):
    """Blank code spans, preserving offsets, so a marker that is *mentioned*
    inside backticks (any doc explaining the convention, including this file)
    is not read as a marker in use."""
    return SPAN_RE.sub(lambda m: ' ' * len(m.group(0)), line)
# A `<...>` segment announces itself; `docs/work-items/<slug>.md` needs no marker.
ANGLE_SEG_RE = re.compile(r'<[^<>/]+>')
NEGATED_RE = re.compile(r'!\s*test\s+-f\s+`?([A-Za-z0-9_./-]+)`?')


def _tree(root):
    return [p for p in root.rglob('*') if p.is_file() and not PRUNE & set(p.parts)]


def _suffix_matches(rel_paths, frag):
    return [r for r in rel_paths if r == frag or r.endswith('/' + frag)]


URLISH = re.compile(r'^(www\.|[a-z0-9-]+\.(com|org|net|nl|io|gov|edu|xyz|ai|mg)(/|$))')


def _marked_siblings(paragraph, siblings):
    """Sibling repos named in `paragraph` as a whole token or path component.

    Two rules, both load-bearing:

    - **Whole token, not substring.** A substring test lets "infrastructure"
      mark a repo called `infra`.
    - **The reference may not mark itself.** Backticked paths are stripped from
      the prose before the search, or `docs/DEPLOY.md` marks a sibling repo
      named `docs` and any broken `docs/X.md` silently resolves next door.
    """
    prose = re.sub(r'`[^`]*`', ' ', paragraph)
    out = []
    for s in siblings:
        if re.search(r'(?<![A-Za-z0-9])' + re.escape(s.name) + r'(?![A-Za-z0-9])',
                     prose, re.IGNORECASE):
            out.append(s)
    return out


def _sibling_hit(frag, siblings, listing, named):
    """Rung 4 for a MARKED path. Returns (kind, text) or None.

    A marker asserts the path is not meant to resolve here, and the population
    most likely to be marked is the cross-repo one — so requiring the sibling to
    be named in prose, as the normal rung 4 does, can never fire on the
    references that need it most (#73). This arm therefore widens the search,
    but only where widening cannot invent a provenance:

    - **Every candidate sibling must be NAMED IN PROSE**, qualified path or bare
      basename alike. Exempting qualified paths was tried, on the argument that
      a path containing `/` carries its own evidence. Measured false on a real
      30-repo estate: 544 qualified relative paths occur in more than one
      neighbour, headed by `memory/gotcha-log.md` (21) and `docs/RUNBOOK.md`
      (8) — the files this framework tells every adopter to create. Marking one
      before writing it produced a permanent finding per audit. Seeded as N22.
    - A qualified path does get a wider CANDIDATE SET: its leading component may
      be stripped when it repeats the sibling's name. That strip is gated on
      naming too, redundantly now, because it was independently load-bearing
      when the sibling gate was looser and re-loosening without noticing would
      restore the self-marking failure.
      Measured by a reviewer on a real tree: of the bare basenames extractable
      and absent locally, 207 occurred in more than one sibling repo, and the
      unrestricted form told `ovr.news` to qualify its own `principes.md`
      against a house-renovation repo that happened to sort first. A confident
      wrong answer is worse than a miss, and it is what makes a reader stop
      trusting the step.
    - **More than one sibling matching** yields no single provenance, so the
      finding says so rather than picking one. The finding text names a repo and
      a file and tells the author to qualify against them; that sentence has to
      be true.
    """
    hits = []
    for s in siblings:
        if s not in named:
            # EVERY candidate must be named in prose, qualified path or bare
            # basename alike. An earlier draft exempted qualified paths on the
            # argument that a path with a `/` "carries its own evidence". That
            # argument is false, and was measured false on the estate this
            # framework lives in: 544 qualified relative paths occur in more
            # than one neighbouring repo across 30 repos, headed by
            # `memory/gotcha-log.md` (21) and `docs/RUNBOOK.md` (8) — the files
            # this framework instructs every adopter to create. Marking one, as
            # an adopter does before the file exists, produced a permanent
            # finding per audit: exactly the re-triage cost the placeholder skip
            # was added to remove, on the framework's own canonical paths.
            continue
        cands = [frag]
        head, _, tail = frag.partition('/')
        # The head-strip is gated on naming too — now implied by the loop gate
        # above, kept explicit because it was independently load-bearing when
        # the sibling gate was looser, and re-loosening the sibling gate without
        # noticing this would restore the self-marking failure.
        if tail and head.lower() == s.name.lower():
            cands.append(tail)
        for c in cands:
            for h in _suffix_matches(listing(s), c):
                # Keyed on the sibling PATH, not its name: two distinct repos
                # can share a basename, and collapsing them here rebuilds the
                # very defect the listing cache was re-keyed to remove — one
                # function lower, and deterministically, so a hash-seed sweep
                # cannot see it.
                if (s, h) not in hits:
                    hits.append((s, h))
    if not hits:
        return None
    uniq = sorted(set(hits), key=lambda x: (str(x[0]), x[1]))
    if len(uniq) > 1:
        # If two siblings share a basename, naming them both `shared` prints the
        # same string twice and reads like a duplicate rather than two repos.
        dupe = len({s.name for s, _ in uniq}) < len({s for s, _ in uniq})
        shown = ', '.join('%s -> %s' % (str(s) if dupe else s.name, h)
                          for s, h in uniq[:3])
        more = '' if len(uniq) <= 3 else ', and %d more' % (len(uniq) - 3)
        return ('AMBIGUOUS',
                'resolves in %d places (%s%s) — no single provenance, so it cannot be '
                'qualified against one' % (len(uniq), shown, more))
    return ('RESOLVED', 'sibling %s -> %s' % (uniq[0][0].name, uniq[0][1]))


def _read(root, src):
    """Return file text, or None if it cannot be read. Callers must report None
    loudly — a document that was never read is not a document that is clean."""
    try:
        return (pathlib.Path(root) / src).read_text()
    except (OSError, UnicodeDecodeError):
        return None


def check_legacy(root, sources):
    """v1.15.0's Step 4, faithfully: permissive extraction, exact-join rung 3
    with substring markers, single-depth siblings, no prose-deletion skip, and
    every rung-2 resolution reported as "written stale".

    Kept so the "before" number in the changelog is reproducible from the same
    instrument as the "after" number. A before/after that only one of them can
    re-derive is the failure this fixture exists to prevent.
    """
    root = pathlib.Path(root).resolve()
    siblings = [p for p in root.parent.glob('*')
                if p.is_dir() and (p / '.git').exists() and p.resolve() != root]
    names = {p.name.lower() for p in siblings}
    rel = [str(p.relative_to(root)) for p in _tree(root)]
    loose = re.compile(r'`([A-Za-z0-9_.][A-Za-z0-9_./*-]*\.[A-Za-z0-9]{1,6})`')
    reports, stale = [], []
    for src in sources:
        text = _read(root, src)
        if text is None:
            continue          # unreadable doc; the non-legacy path reports these
        for line in text.split('\n'):
            if '! test -f' in line:
                continue
            for frag in loose.findall(line):
                if '*' in frag:
                    continue
                if (root / frag).exists():
                    continue
                hits = _suffix_matches(rel, frag)
                if len(hits) > 1:
                    reports.append((src, frag, 'COLLISION'))
                elif len(hits) == 1:
                    stale.append((src, frag, 'reported written-stale'))
                elif any(n in line.lower() for n in names) and \
                        any((s / frag).exists() for s in siblings):
                    continue
                elif frag.startswith(STATE_DIRS) or STATE_SHAPE.search(frag):
                    continue
                else:
                    reports.append((src, frag, 'UNRESOLVED'))
    return reports, stale


def check(root, sources, sibling_roots=None):
    root = pathlib.Path(root).resolve()
    siblings = []
    for cand in (sibling_roots or [root.parent, root.parent.parent]):
        cand = pathlib.Path(cand)
        for pat in ('*', '*/*'):
            siblings += [p for p in cand.glob(pat)
                         if p.is_dir() and (p / '.git').exists()
                         and p.resolve() != root]
    # Sort on the full path, not the basename: `sorted` is stable, so same-named
    # siblings would otherwise keep set-iteration (hash) order, and the unmarked
    # rung-4 loop below breaks on the FIRST hit. Re-keying the listing cache fixed
    # which listing a name maps to; it did not fix the order they are tried in.
    siblings = sorted(set(siblings), key=lambda p: (p.name, str(p)))
    # If no sibling repo is reachable, rung 4 cannot run, and an unresolved
    # reference carries that on its own verdict rather than only in the run's
    # coverage header — see UNCONFIRMED above. (This flag was assigned and never
    # read until #93, while the comment above it claimed the annotation existed.)
    rung4_runnable = bool(siblings)
    # Walked once per sibling, not once per reference, and LAZILY: a repo with
    # no rung-4 traffic pays nothing. Measured by a reviewer on real trees —
    # NexusMind 19.7s -> 7.8s, ovr.news >4min (killed) -> 5.8s — because the
    # pre-existing rung 4 re-walked every sibling for every reference.
    #
    # Keyed on the PATH, not on `s.name`. A name-keyed dict silently drops one
    # of any two siblings sharing a basename, and `sorted(set(...))` leaves the
    # tie in set-iteration order — which is hash order, which is randomized per
    # process. The checker's own findings then varied between two runs of the
    # same command. An oracle that is not reproducible is worse than the gap it
    # closes. No collision exists on this machine today; it is one `git init`
    # away, and it fails silently in both directions.
    _listing_cache = {}

    def listing(s):
        if s not in _listing_cache:
            _listing_cache[s] = [str(q.relative_to(s)) for q in _tree(s)]
        return _listing_cache[s]

    rel = [str(p.relative_to(root)) for p in _tree(root)]
    findings, resolved_weak, skipped, placeheld = [], [], [], []
    # Marked references the rung-4 stale test could not run against (R1). Counted,
    # not reported as defects: nothing here is known to be wrong, only unchecked.
    undecided_markers = []
    unchecked = []   # link URLs declined with a stated reason (#55)

    missing = []
    for src in sources:
        text = _read(root, src)
        if text is None:
            missing.append(src)   # e.g. an optional Layer-4 gotcha log
            continue
        lines = text.split('\n')
        for i, raw_line in enumerate(lines):
            # #55: the label of a markdown link is masked out before ANY
            # extraction on this line — offsets are preserved, so the
            # span-scoped placeholder arithmetic further down is unaffected —
            # and the link's URL becomes a candidate in its place. It is done
            # here rather than lower so the strikethrough and deleted-span
            # collectors below see the same masked line.
            line = _mask_link_labels(raw_line)
            cands = _candidates(raw_line)
            # A link URL this checker declines to resolve is REPORTED rather
            # than dropped — every URL `LINK_RE` matches, plus a count of the
            # link-shaped constructs it could not parse at all. Before #55 the label gave these accidental coverage;
            # masking the label without saying so would trade a phantom finding
            # for a silent skip, and a silent skip is the failure class this
            # file exists to prevent. Measured: five broken-link shapes where
            # the label was the only coverage went from 5 findings to 1 when
            # they were dropped quietly. `.pdf` is the sharp one — an extension
            # outside the whitelist on a file that does NOT exist appears in
            # neither the findings nor the "extensions in tree" trailer, which
            # only names extensions the tree actually holds.
            for _st, _en, _u, _why in _link_urls(raw_line):
                if _why is not None:
                    unchecked.append((src, _u, 'LINK URL NOT CHECKED (%s)' % _why))
            _n = _unparsed_links(raw_line)
            if _n:
                unchecked.append((src, '(line %d)' % (i + 1),
                                  'LINK-SHAPED CONSTRUCT NOT PARSED x%d — nested brackets, a '
                                  '`]` in the label, parens in the URL, an angle-bracket URL '
                                  'or a reference-style link. Both label and URL are dropped, '
                                  'so the reference is invisible to every rung' % _n))

            # Span-scoped skips: collect only the paths the markers cover. These
            # run over _candidates() rather than PATH_RE so a struck or deleted
            # markdown LINK is suppressed like a struck backticked path — see
            # the _candidates docstring for the regression that forced it.
            covered = set()
            for m in STRIKE_RE.finditer(raw_line):
                covered |= {c[2] for c in _candidates(m.group(1))}
            for m in DELETED_RE.finditer(raw_line):
                covered |= {c[2] for c in _candidates(m.group(1))}
            for m in NEGATED_RE.finditer(line):
                covered.add(m.group(1))

            # #45 — paths that were never meant to resolve. Two markers: an
            # explicit `<!-- placeholder -->`, and an angle-bracket segment,
            # which is self-announcing and costs the author nothing.
            #
            # The marker is SPAN-scoped, not line-scoped: it covers the nearest
            # eligible path before it, the way STRIKE_RE and DELETED_RE are
            # scoped. Line-scoping was the first draft and it relabelled a
            # co-located genuine break as intentional — the defect this step
            # already measured once for strikethrough.
            placeheld_frags = set()
            eligible = [c for c in cands
                        if '*' not in c[2] and not URLISH.match(c[2])
                        and not _is_identifier_not_path(c[2])]
            for pm in PLACEHOLDER_RE.finditer(_mask_spans(line)):
                before = [c for c in eligible if c[1] <= pm.start()]
                if before:
                    placeheld_frags.add(before[-1][2])
                else:
                    findings.append((src, '(line %d)' % (i + 1),
                                     'PLACEHOLDER MARKER COVERS NO PATH — it is span-scoped and '
                                     'takes the nearest backticked path before it. Either none is '
                                     'there, or the token is not extractable: a directory, a glob, '
                                     'a URL, an extension outside the whitelist (a whitelist gap, '
                                     'not a marker problem), or a dotted code identifier wearing a '
                                     'whitelisted extension (#70) — not a path, so there is nothing '
                                     'here to suppress and the marker can simply go. NB: no literal '
                                     'identifier is named in this string on purpose; embedding one '
                                     'made it collide with a fixture needle and silently disarm '
                                     'that case. The example lives in the template prose instead)'))

            para = ' '.join(lines[max(0, i - 1):i + 2])
            # Computed at most once per line and only when something actually
            # needs it. Hoisting it unconditionally cost one `re.sub` plus a
            # regex search PER SIBLING for every line including those with no
            # backticks: measured 5.69s against 0.11s on 60k lines with 38
            # siblings and zero references, in the change whose headline is a
            # speed-up. `None` is the not-yet-computed sentinel; `[]` is a real
            # empty answer.
            named_cache = [None]

            def named_siblings():
                if named_cache[0] is None:
                    named_cache[0] = _marked_siblings(para, siblings)
                return named_cache[0]

            for frag in [c[2] for c in cands]:
                if '*' in frag or URLISH.match(frag):
                    continue  # a hostname is not a path
                if _is_identifier_not_path(frag):
                    continue  # `process.env` is not a file (#70)
                if frag in covered:
                    skipped.append((src, frag, 'asserted-absent'))
                    continue

                is_placeheld = frag in placeheld_frags or ANGLE_SEG_RE.search(frag)
                if is_placeheld:
                    # A marker on a path that DOES resolve is the failure this
                    # skip newly permits: mislabelling is how a real break gets
                    # hidden. Report it instead of skipping it.
                    #
                    # RUNG 1 ONLY, and the suffix arm is deliberately not here
                    # (#56). A marker whose path resolves *as written* is
                    # unambiguously mislabelled. A marker whose path merely
                    # shares a SUFFIX with some file elsewhere is not evidence of
                    # mislabelling at all — it is the bare-basename ambiguity
                    # #54 is about, and the suffix rung was built to RESOLVE
                    # references, not to ADJUDICATE INTENT. With the suffix arm
                    # in, any repo that ships a template *and* instances of it
                    # left the author no correct move: marked reported STALE,
                    # unmarked reported COLLISION, and both are findings on a
                    # reference that is doing exactly what it should. Measured on
                    # an adopter that ships `templates/CLAUDE.md` beside
                    # `papers/*/CLAUDE.md`; three references were left knowingly
                    # unfixed there because neither move was correct.
                    # Which of the two forms excused it decides the WORD, and
                    # round 6 found the marker wording being printed for a path
                    # that carries no marker: `<slug>.md` with a literal
                    # `docs/<slug>.md` on disk was reported as a STALE
                    # PLACEHOLDER MARKER, prescribing the removal of something
                    # not in the document. Both adjudicating arms use this.
                    stale = ('STALE PLACEHOLDER MARKER' if frag in placeheld_frags
                             else 'PLACEHOLDER SHAPE THAT RESOLVES')
                    if (root / frag).exists():
                        findings.append((src, frag,
                                         f'{stale} (resolves at rung 1, as written)'))
                        continue
                    # rung 1b and rung 2 — LOCAL, and they run here for
                    # DECIDABILITY, which this arm had conflated with
                    # ADJUDICATION. Two different questions:
                    #
                    #   is the reference decidable?  -> any rung that RAN and
                    #                                   resolved it answers yes
                    #   is the marker mislabelled?   -> rung 1 only (#56)
                    #
                    # Until round 5 this arm ran 1, 3, 4 and skipped 1b and 2.
                    # That was harmless while the fall-through was `placeheld`
                    # (exit 0). v1.29.0 made the fall-through `undecided_markers`
                    # (exit 2), which turned the gap into #93's own defect a
                    # third time: MARKING a reference the local tree answers made
                    # the run undecided, so the same reference went exit 2 with no
                    # neighbour on disk and exit 0 with one, while UNMARKED it was
                    # `fragment -> src/helpers.py` at exit 0 in both. Measured on
                    # v1.28.0: exit 0 in both, so this is a v1.29.0 regression.
                    #
                    # 1b ADJUDICATES, like rung 1: markdown link semantics ARE
                    # doc-relative (see the rung list in the step), so a marked
                    # path that resolves next to its own document resolves AS
                    # WRITTEN — the marker is wrong in exactly the sense rung 1
                    # means. 2 does NOT adjudicate: sharing a suffix with a file
                    # elsewhere is not evidence of intent, which is #56, and that
                    # rule is unchanged. It only decides.
                    # Distinct names from the unmarked arm's `docrel`/`hits`
                    # ON PURPOSE: `ablate` refuses a mutation site that occurs
                    # more than once, so a shared name would make both arms
                    # unablatable and the guard would read as a passing suite.
                    mdocrel = (root / src).parent / frag
                    if mdocrel.exists() and mdocrel.is_file():
                        try:
                            shown = mdocrel.resolve().relative_to(root.resolve())
                        except ValueError:
                            shown = mdocrel
                        findings.append((src, frag,
                                         f'{stale} (resolves at rung 1b, '
                                         f'doc-relative: {shown})'))
                        continue
                    # Collisions are excused here rather than reported, and that is
                    # #56 restated: a repo shipping a template AND instances of it
                    # gave the author no correct move when marked reported STALE and
                    # unmarked reported COLLISION. Any hit at all decides it.
                    mhits = _suffix_matches(rel, frag)
                    if mhits:
                        placeheld.append((src, frag,
                                          ('declared-placeholder' if frag in placeheld_frags
                                           else 'angle-bracket segment')
                                          + f' — decided at rung 2 ({len(mhits)} local match'
                                          + ('es' if len(mhits) > 1 else '') + ')'))
                        continue
                    # rung 3 (runtime state) BEFORE rung 4, for the same reason the
                    # unmarked path does it in that order two hundred lines below: a
                    # file this repo's own runtime writes is explained here, and
                    # letting a sibling claim it first produces a provenance that is
                    # simply false. The first draft of this arm ran rung 4 straight
                    # after the local test, so MARKING a runtime-state path flipped
                    # its provenance to a sibling repo — and the remedy the finding
                    # prescribes would have written that falsehood into the document.
                    if frag.startswith(STATE_DIRS) or STATE_SHAPE.search(frag):
                        placeheld.append((src, frag,
                                          'declared-placeholder'
                                          if frag in placeheld_frags else 'angle-bracket segment'))
                        continue
                    # Both arms above are LOCAL. A marker on a path that lives in a
                    # SIBLING repo resolved nowhere, was excused, and left the checked
                    # set permanently — so a later move or deletion there is reported
                    # by nothing. That is the population most likely to be marked in
                    # the first place (#73). Naming the rung matters: the author's
                    # remedy is to qualify the reference, and a qualified reference is
                    # checked forever where a marker is never checked again.
                    sib = _sibling_hit(frag, siblings, listing, named_siblings())
                    if sib and sib[0] == 'RESOLVED':
                        findings.append((src, frag,
                                         'STALE PLACEHOLDER MARKER (resolves at rung 4: '
                                         f'{sib[1]}) — qualify it instead'))
                    elif sib:
                        findings.append((src, frag,
                                         f'STALE PLACEHOLDER MARKER ({sib[1]})'))
                    elif rung4_runnable:
                        placeheld.append((src, frag,
                                          'declared-placeholder'
                                          if frag in placeheld_frags else 'angle-bracket segment'))
                    elif ANGLE_SEG_RE.search(frag):
                        # An angle-bracket segment is decided by a regex over the
                        # fragment, consulting nothing on disk — rung 4 declines it
                        # with every neighbour reachable (measured) — so its verdict
                        # cannot depend on whether one is. This arm is tested FIRST,
                        # and adding a redundant `<!-- placeholder -->` marker to such
                        # a path must not change that: round 3 tested the marker first
                        # and a both-forms reference went exit 0 -> exit 2 on where it
                        # ran, which is the defect this whole change is about.
                        # #98: labelled by the reason that ACTUALLY excused it.
                        # This arm exists because of the angle bracket, so a path
                        # carrying a redundant marker too was printing
                        # `declared-placeholder` — pointing its reader at the
                        # rung-4 coverage sentence, which is false for a row
                        # decided by shape and not by any rung.
                        placeheld.append((src, frag, 'angle-bracket segment'))
                    else:
                        # A `<!-- placeholder -->` marker is rung-4 traffic, and
                        # without a neighbour this arm cannot tell a legitimate
                        # placeholder (N17) from a stale marker whose path lives next
                        # door (T19). Excusing it silently exits 0 on a repo that a
                        # reachable neighbour would have reported.
                        #
                        # An ANGLE-BRACKET segment is NOT in this class, and putting
                        # it here reproduced #93 one bucket over: `<name>` is decided
                        # by a regex over the fragment, consulting nothing on disk, and
                        # rung 4 declines it with every neighbour reachable (measured).
                        # A repo whose only references are angle-bracket placeholders
                        # — this one — went from exit 0 to exit 2 in a fresh clone.
                        undecided_markers.append(
                            (src, frag, 'declared-placeholder — NOT rung-4 tested '
                                        '(no neighbouring repo reachable)'))
                    continue

                # rung 1 — as written
                if (root / frag).exists():
                    continue

                # rung 1b — DOC-RELATIVE, which is not a courtesy rung: markdown
                # link semantics ARE doc-relative, so a bare `backlog.md` in
                # `papers/one/CLAUDE.md` means the file next to it, and that is
                # how the rendered link resolves. Without this rung such a
                # reference either misses rung 1 outright or gets downgraded to a
                # COLLISION against a same-named file elsewhere in the tree — and
                # a collision is reported as a defect requiring a decision when
                # there is nothing to decide. Measured on one adopter: 42 of 102
                # findings, 41%, were correct doc-relative references (#54).
                # It must sit ABOVE rung 2, or the collision fires first.
                # Enumerated rather than silent: it is not a defect, but a reader
                # comparing two repos should be able to see how much of the tree
                # resolves this way.
                docrel = (root / src).parent / frag
                if docrel.exists() and docrel.is_file():
                    try:
                        shown = docrel.resolve().relative_to(root.resolve())
                    except ValueError:
                        shown = docrel
                    resolved_weak.append((src, frag, f'doc-relative -> {shown}'))
                    continue

                # rung 2 — suffix in the working tree; collisions are findings
                hits = _suffix_matches(rel, frag)
                if len(hits) > 1:
                    findings.append((src, frag, f'COLLISION ({len(hits)} local matches)'))
                    continue
                if len(hits) == 1:
                    resolved_weak.append((src, frag, f'fragment -> {hits[0]}'))
                    continue

                # rung 3 (runtime state) BEFORE rung 4 (sibling) — a file this
                # repo's own runtime writes is explained here; letting a sibling
                # claim it first produces a provenance that is simply false.
                if frag.startswith(STATE_DIRS) or STATE_SHAPE.search(frag):
                    resolved_weak.append((src, frag, 'runtime state'))
                    continue

                # rung 4 — marked cross-repo, suffix-matched inside the sibling,
                # carrying rung 2's collision rule with it.
                claim = None
                for s in named_siblings():
                    cands = [frag]
                    head, _, tail = frag.partition('/')
                    if tail and head.lower() == s.name.lower():
                        cands.append(tail)
                    # Dedup: with `cands = ['foo/bar.py', 'bar.py']` against a
                    # sibling `foo` nesting `foo/`, both candidates suffix-match
                    # the SAME file and the undeduped list reported
                    # "COLLISION (2 matches)" for one file. A count inside a
                    # finding message is a measurement; it has to be true.
                    hits = []
                    for c in cands:
                        for h in _suffix_matches(listing(s), c):
                            if h not in hits:
                                hits.append(h)
                    if len(hits) > 1:
                        claim = (f'COLLISION ({len(hits)} matches in {s.name})', True)
                        break
                    if hits:
                        claim = (f'sibling {s.name} -> {hits[0]}', False)
                        break
                if claim:
                    (findings if claim[1] else resolved_weak).append((src, frag, claim[0]))
                    continue

                # "A rung you cannot run is not a pass." Do not guess which
                # references rung 4 might have rescued — a bare filename is rung-4
                # traffic too (see fixture T9), and an unmarked path never was. Report
                # every unresolved reference, and when rung 4 could not run say so on
                # each one, so no finding is presented as a confirmed break on the
                # strength of a check that never executed.
                findings.append((src, frag,
                                 'UNRESOLVED' if rung4_runnable else UNCONFIRMED))

    tree_ext = {p.suffix.lstrip('.').lower() for p in _tree(root) if p.suffix}
    known = set(EXT.split('|'))
    unknown = sorted(e for e in tree_ext - known if e and len(e) <= 12)
    return (findings, resolved_weak, skipped, placeheld, unknown, missing,
            len(siblings), unchecked, undecided_markers)


def _usage(msg):
    # 64 is EX_USAGE. It matters here because #93 gave exit 1 a meaning — "a rung
    # ruled on something" — and a mistyped flag is not that. Returned rather than
    # printed-and-exited so `sys.exit` keeps one exit path.
    print(msg, file=sys.stderr)
    return 64


def main():
    argv = sys.argv[1:]
    legacy = '--legacy' in argv
    if legacy:
        argv.remove('--legacy')
    # `check()` has always accepted explicit sibling roots; nothing could pass
    # them. Without that, the search is root.parent and root.parent.parent, so a
    # fixture built under the system temp dir adopts every git repo sitting in
    # /tmp — including one left behind by an interrupted run of this very
    # harness. Measured: a leftover fixture supplied a second repo named `docs`
    # and a newly-added negative passed for that reason alone.
    sibling_roots = None
    while '--sibling-root' in argv:
        i = argv.index('--sibling-root')
        if i + 1 >= len(argv):
            # A traceback is not a usage error. This harness pins the search
            # with this flag, so a typo that drops its value must say so rather
            # than crash into an IndexError a caller has to decode.
            sys.exit(_usage('--sibling-root needs a directory'))
        sibling_roots = (sibling_roots or []) + [argv[i + 1]]
        del argv[i:i + 2]
    # #96: an UNRECOGNISED `--` argument used to be consumed as <repo-root>, the
    # real root became a source document, and the run returned `DEFECTS (exit 1)`
    # — exit 1 being the status #93 gave the meaning "a rung ruled on something".
    # Measured: `--sibling-roots /tmp . CLAUDE.md` (note the s) returned rc=1.
    # This is what the module docstring's "a mistyped flag cannot be read as
    # either verdict" claims, and it was false until this arm existed.
    for a in argv:
        if a.startswith('--'):
            sys.exit(_usage('unrecognised option: %s' % a))
    if len(argv) < 2:
        sys.exit(_usage(
            'usage: refcheck.py [--legacy] [--sibling-root DIR] <repo-root> <doc> [<doc> ...]\n'
            '  e.g. refcheck.py . CLAUDE.md memory/MEMORY.md'))
    root, sources = argv[0], argv[1:]

    if legacy:
        reports, stale = check_legacy(root, sources)
        print("== v1.15.0 BEHAVIOUR ==")
        for s, p, v in reports:
            print(f"  {s:24s} {p:44s} {v}")
        print(f"  reports: {len(reports)}")
        print(f"  additionally reported 'written stale': {len(stale)}")
        print(f"  TOTAL ITEMS PUT TO A HUMAN: {len(reports) + len(stale)}")
        return 0

    (findings, weak, skipped, placeheld, unknown, missing, n_siblings, unchecked,
     undecided_markers) = check(root, sources, sibling_roots)

    # State rung 4's coverage as a fact rather than inferring a verdict per
    # reference. We cannot tell which unresolved paths a sibling would have
    # rescued without knowing the repo names, so disclose the scope instead:
    # a reader seeing "0 sibling repositories" knows no finding here is confirmed.
    print(f"== RUNG 4 COVERAGE: scanned {n_siblings} sibling repositor"
          f"{'y' if n_siblings == 1 else 'ies'} ==")
    if n_siblings == 0:
        print("   No sibling repo was reachable, so rung 4 did not run. A reference\n"
              "   that lives in another repo cannot be distinguished from a broken one\n"
              "   here, so every finding marked UNCONFIRMED below is undecided rather\n"
              "   than broken, and so is every `<!-- placeholder -->` reference the\n"
              "   rung-4 stale test could not be run against. An angle-bracket segment\n"
              "   is decided by its shape and is excused here as anywhere. Findings a LOCAL rung ruled on — a\n"
              "   collision, a marker on a path that resolves as written — stand\n"
              "   regardless, and this line does not excuse them.")
    print()

    if missing:
        # A document that was never read cannot be audited. Say so loudly:
        # silence here would read as "these docs are clean".
        print("== DOCUMENTS NOT READ (not audited) ==")
        for m in missing:
            print(f"  {m}")
        print(f"  total: {len(missing)}\n")

    confirmed_findings = [f for f in findings if f[2] != UNCONFIRMED]
    print("== FINDINGS (broken or ambiguous) ==")
    for s, p, v in confirmed_findings:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(confirmed_findings)}")

    print("\n== RESOLVED BELOW RUNG 1 (enumerated, not defects) ==")
    for s, p, v in weak:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(weak)}")

    print("\n== SKIPPED as declared-placeholder ==")
    for s, p, v in placeheld:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(placeheld)}")

    print("\n== LINK URLs NOT CHECKED (every URL LINK_RE matched, plus a count of those it could not) ==")
    for s, p, v in unchecked:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(unchecked)}")

    print("\n== SKIPPED as asserted-absent ==")
    for s, p, v in skipped:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(skipped)}")

    print("\n== UNCONFIRMED (this run could not decide these) ==")
    for s_, p_, v_ in ([f for f in findings if f[2] == UNCONFIRMED] + undecided_markers):
        print(f"  {s_:24s} {p_:44s} {v_}")
    print(f"  total: {len([f for f in findings if f[2] == UNCONFIRMED]) + len(undecided_markers)}")

    print(f"\n== EXTENSIONS IN TREE NOT EXTRACTED: {', '.join(unknown) if unknown else '(none)'} ==")

    # Three outcomes, not two (#93). `curate` Step 0 sub-step 5 is the precedent
    # for the DISPOSITION — a thing that is neither a pass nor a failure gets its
    # own state and its own status — and NOT for the trigger: curate exits 2 only
    # when *nothing* produced a verdict, while this exits 2 on a single undecided
    # reference in an otherwise fully decided run. Measured, so the citation is
    # scoped rather than borrowed whole.
    #
    # ⚠️ This does NOT make the status a function of the repo alone, and nothing
    # can. Rung 4 gates on a repo name in prose, and a name is only recognisable
    # as a repo name when that repo is on disk, so per-reference decidability is
    # not computable. `bool(siblings)` is a coarse proxy for it in both
    # directions: one unrelated clone next door is enough to make this call rung 4
    # "runnable" for a reference naming a repo that is absent, and that reference
    # is then reported as a defect. What the third state buys is narrower and
    # still worth having — an undecided run now SAYS it is undecided instead of
    # picking one of the two verdicts it has not earned.
    unconfirmed = [f for f in findings if f[2] == UNCONFIRMED] + undecided_markers
    confirmed = [f for f in findings if f[2] != UNCONFIRMED]
    if confirmed or missing:
        parts = []
        if confirmed:
            parts.append('%d finding(s)' % len(confirmed))
        if missing:
            # No rung ran on a document that could not be read, so this count may
            # not sit under a "ruled out by a rung" label. The file's own rule: a
            # count inside a finding message is a measurement, and it has to be true.
            parts.append('%d unreadable document(s)' % len(missing))
        if unconfirmed:
            parts.append('%d left undecided' % len(unconfirmed))
        rc, verdict = 1, 'DEFECTS — ' + ', '.join(parts)
    elif unconfirmed:
        rc, verdict = 2, ('COVERAGE INCOMPLETE — rung 4 did not run (no neighbouring '
                          'repo reachable) and %d reference(s) needed it; none of them '
                          'is ruled on either way' % len(unconfirmed))
    else:
        rc, verdict = 0, 'CLEAN — no findings'
    print(f"\n== VERDICT: {verdict} (exit {rc}) ==")
    return rc


if __name__ == '__main__':
    sys.exit(main())
