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
    siblings = sorted(set(siblings), key=lambda p: p.name)
    # If no sibling repo is reachable, rung 4 cannot run. Findings are then
    # annotated to say so, rather than presented as confirmed breaks.
    rung4_runnable = bool(siblings)

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
                        if '*' not in m.group(1) and not URLISH.match(m.group(1))]
            for pm in PLACEHOLDER_RE.finditer(_mask_spans(line)):
                before = [m for m in eligible if m.end() <= pm.start()]
                if before:
                    placeheld_frags.add(before[-1].group(1))
                else:
                    findings.append((src, '(line %d)' % (i + 1),
                                     'PLACEHOLDER MARKER COVERS NO PATH — it is span-scoped and '
                                     'takes the nearest backticked path before it. Either none is '
                                     'there, or the token is not extractable: a directory, a glob, '
                                     'a URL, or an extension outside the whitelist (that last one '
                                     'is a whitelist gap, not a marker problem)'))

            para = ' '.join(lines[max(0, i - 1):i + 2])

            for frag in PATH_RE.findall(line):
                if '*' in frag or URLISH.match(frag):
                    continue  # a hostname is not a path
                if frag in covered:
                    skipped.append((src, frag, 'asserted-absent'))
                    continue

                is_placeheld = frag in placeheld_frags or ANGLE_SEG_RE.search(frag)
                if is_placeheld:
                    # A marker on a path that DOES resolve is the failure this
                    # skip newly permits: mislabelling is how a real break gets
                    # hidden. Report it instead of skipping it.
                    if (root / frag).exists() or _suffix_matches(rel, frag):
                        findings.append((src, frag, 'STALE PLACEHOLDER MARKER (the path resolves)'))
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
                named = _marked_siblings(para, siblings)
                claim = None
                for s in named:
                    cands = [frag]
                    head, _, tail = frag.partition('/')
                    if tail and head.lower() == s.name.lower():
                        cands.append(tail)
                    srel = [str(p.relative_to(s)) for p in _tree(s)]
                    hits = [h for c in cands for h in _suffix_matches(srel, c)]
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
    if len(argv) < 2:
        sys.exit('usage: refcheck.py [--legacy] <repo-root> <doc> [<doc> ...]\n'
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

    findings, weak, skipped, placeheld, unknown, missing, n_siblings = check(root, sources)

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
