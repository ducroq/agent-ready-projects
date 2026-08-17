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
RUNG 1 (enumerated, not defects), SKIPPED as asserted-absent, extensions in the
tree the extractor misses, and — only when they apply — DOCUMENTS NOT READ and
a RUNG 4 COVERAGE line.

**Only backticked paths are extracted.** A markdown link or a bare prose path is
invisible here, so an all-empty report is not by itself proof of a clean
document — check the document's style, and check that DOCUMENTS NOT READ is
absent, before reading empty as passing.
"""

import re
import sys
import pathlib

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
DELETED_RE = re.compile(r'\*\*Deleted\*\*:?\s*(`[^`]+`)')
# `<!-- placeholder -->` mirrors the file's existing `<!-- verify: -->` idiom:
# invisible when rendered, greppable, machine-readable.
PLACEHOLDER_RE = re.compile(r'<!--\s*placeholder\s*-->')
SPAN_RE = re.compile(r'`[^`]*`')


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
      basename alike. A qualified path gets a wider candidate set (its own head
      may be stripped when it repeats the sibling's name); it does not get an
      unnamed sibling. Exempting qualified paths from the gate was tried and
      reintroduced the self-marking failure it was meant to avoid.
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
    qualified = '/' in frag
    for s in siblings:
        is_named = s in named
        if not qualified and not is_named:
            continue
        cands = [frag]
        head, _, tail = frag.partition('/')
        # THE HEAD-STRIP IS GATED ON NAMING, NOT THE SIBLING. Stripping a
        # leading segment that repeats the sibling's own name is precisely the
        # self-marking mechanism `_marked_siblings` exists to prevent: allow it
        # unnamed and `docs/ARCHITECTURE.md` matches `runbooks/ARCHITECTURE.md`
        # inside a neighbour called `docs`, after which every broken `docs/X.md`
        # resolves next door — rung 4's own rule, which the unmarked path has
        # always honoured. Two drafts got this wrong in opposite directions:
        # exempting qualified paths from the gate entirely reintroduced that
        # failure, and then gating the whole sibling on naming killed #73's
        # actual case, since a marked cross-repo path typically does NOT name
        # its repo. An unnamed sibling is searched with the WHOLE fragment only,
        # which carries its own evidence.
        if tail and is_named and head.lower() == s.name.lower():
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
    # If no sibling repo is reachable, rung 4 cannot run. Findings are then
    # annotated to say so, rather than presented as confirmed breaks.
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

    missing = []
    for src in sources:
        text = _read(root, src)
        if text is None:
            missing.append(src)   # e.g. an optional Layer-4 gotcha log
            continue
        lines = text.split('\n')
        for i, line in enumerate(lines):
            # Span-scoped skips: collect only the paths the markers cover.
            covered = set()
            for m in STRIKE_RE.finditer(line):
                covered |= set(PATH_RE.findall(m.group(1)))
            for m in DELETED_RE.finditer(line):
                covered |= set(PATH_RE.findall(m.group(1)))
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
            eligible = [m for m in PATH_RE.finditer(line)
                        if '*' not in m.group(1) and not URLISH.match(m.group(1))
                        and not _is_identifier_not_path(m.group(1))]
            for pm in PLACEHOLDER_RE.finditer(_mask_spans(line)):
                before = [m for m in eligible if m.end() <= pm.start()]
                if before:
                    placeheld_frags.add(before[-1].group(1))
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

            for frag in PATH_RE.findall(line):
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
                    if (root / frag).exists() or _suffix_matches(rel, frag):
                        findings.append((src, frag,
                                         'STALE PLACEHOLDER MARKER (resolves at rung 1-2, locally)'))
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
                    else:
                        placeheld.append((src, frag,
                                          'declared-placeholder'
                                          if frag in placeheld_frags else 'angle-bracket segment'))
                    continue

                # rung 1 — as written
                if (root / frag).exists():
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
                findings.append((src, frag, 'UNRESOLVED'))

    tree_ext = {p.suffix.lstrip('.').lower() for p in _tree(root) if p.suffix}
    known = set(EXT.split('|'))
    unknown = sorted(e for e in tree_ext - known if e and len(e) <= 12)
    return findings, resolved_weak, skipped, placeheld, unknown, missing, len(siblings)


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
            sys.exit('--sibling-root needs a directory')
        sibling_roots = (sibling_roots or []) + [argv[i + 1]]
        del argv[i:i + 2]
    if len(argv) < 2:
        sys.exit('usage: refcheck.py [--legacy] [--sibling-root DIR] <repo-root> <doc> [<doc> ...]\n'
                 '  e.g. refcheck.py . CLAUDE.md memory/MEMORY.md')
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

    findings, weak, skipped, placeheld, unknown, missing, n_siblings = check(
        root, sources, sibling_roots)

    # State rung 4's coverage as a fact rather than inferring a verdict per
    # reference. We cannot tell which unresolved paths a sibling would have
    # rescued without knowing the repo names, so disclose the scope instead:
    # a reader seeing "0 sibling repositories" knows no finding here is confirmed.
    print(f"== RUNG 4 COVERAGE: scanned {n_siblings} sibling repositor"
          f"{'y' if n_siblings == 1 else 'ies'} ==")
    if n_siblings == 0:
        print("   No sibling repo was reachable, so rung 4 did not run. A reference\n"
              "   that lives in another repo cannot be distinguished from a broken one\n"
              "   here — treat every finding below as unconfirmed.")
    print()

    if missing:
        # A document that was never read cannot be audited. Say so loudly:
        # silence here would read as "these docs are clean".
        print("== DOCUMENTS NOT READ (not audited) ==")
        for m in missing:
            print(f"  {m}")
        print(f"  total: {len(missing)}\n")

    print("== FINDINGS (broken or ambiguous) ==")
    for s, p, v in findings:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(findings)}")

    print("\n== RESOLVED BELOW RUNG 1 (enumerated, not defects) ==")
    for s, p, v in weak:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(weak)}")

    print("\n== SKIPPED as declared-placeholder ==")
    for s, p, v in placeheld:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(placeheld)}")

    print("\n== SKIPPED as asserted-absent ==")
    for s, p, v in skipped:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(skipped)}")

    print(f"\n== EXTENSIONS IN TREE NOT EXTRACTED: {', '.join(unknown) if unknown else '(none)'} ==")
    # Unread documents are a failure of the run, not a clean result.
    return 1 if (findings or missing) else 0


if __name__ == '__main__':
    sys.exit(main())
