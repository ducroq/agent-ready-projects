#!/usr/bin/env python3
"""Reference implementation of audit-context Step 4 (reference integrity).

This exists so that a change to Step 4 can be *tested* rather than asserted.
Run tests/fixtures/reference-integrity/run.sh to exercise it against a fixture
that seeds the failures Step 4 must catch.

The skill text is normative; this is one faithful reading of it. If they
disagree, the skill is right and this file is the bug.
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
    '|vue|svelte|rst|log|tag|svg|png'
)
PATH_RE = re.compile(r'`([A-Za-z0-9_.][A-Za-z0-9_./*-]*\.(?:' + EXT + r'))`')

STATE_DIRS = ('data/', 'state/', 'cache/', 'logs/', 'run/', 'var/', 'artifacts/')
STATE_SHAPE = re.compile(r'(_state\.json|_health\.json|\.pid|\.sock)$')
BARE_STATE = re.compile(r'^[a-z0-9_.-]+\.(json|jsonl)$')
PRUNE = {'.git', 'venv', '.venv', 'node_modules', '__pycache__', 'target', 'dist'}

# Span-scoped, NOT line-scoped. A line may retire one path and name its live
# replacement in the same sentence; skipping the line loses the replacement.
STRIKE_RE = re.compile(r'~~(.+?)~~')
DELETED_RE = re.compile(r'\*\*Deleted\*\*:?\s*(`[^`]+`)')
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
        for line in (root / src).read_text().split('\n'):
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

    rel = [str(p.relative_to(root)) for p in _tree(root)]
    findings, resolved_weak, skipped = [], [], []

    for src in sources:
        text = (root / src).read_text()
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

            para = ' '.join(lines[max(0, i - 1):i + 2])

            for frag in PATH_RE.findall(line):
                if '*' in frag or URLISH.match(frag):
                    continue  # a hostname is not a path
                if frag in covered:
                    skipped.append((src, frag, 'asserted-absent'))
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

                # rung 4 BEFORE rung 3 — a file this repo's own runtime writes is
                # explained here; letting a sibling claim it first produces a
                # provenance that is simply false.
                if frag.startswith(STATE_DIRS) or STATE_SHAPE.search(frag) \
                        or BARE_STATE.match(frag):
                    resolved_weak.append((src, frag, 'runtime state'))
                    continue

                # rung 3 — marked cross-repo, suffix-matched inside the sibling,
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

                findings.append((src, frag, 'UNRESOLVED'))

    tree_ext = {p.suffix.lstrip('.').lower() for p in _tree(root) if p.suffix}
    known = set(EXT.split('|'))
    unknown = sorted(e for e in tree_ext - known if e and len(e) <= 12)
    return findings, resolved_weak, skipped, unknown


def main():
    argv = sys.argv[1:]
    legacy = '--legacy' in argv
    if legacy:
        argv.remove('--legacy')
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

    findings, weak, skipped, unknown = check(root, sources)

    print("== FINDINGS (broken or ambiguous) ==")
    for s, p, v in findings:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(findings)}")

    print("\n== RESOLVED BELOW RUNG 1 (enumerated, not defects) ==")
    for s, p, v in weak:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(weak)}")

    print("\n== SKIPPED as asserted-absent ==")
    for s, p, v in skipped:
        print(f"  {s:24s} {p:44s} {v}")
    print(f"  total: {len(skipped)}")

    print(f"\n== EXTENSIONS IN TREE NOT EXTRACTED: {', '.join(unknown) if unknown else '(none)'} ==")
    return 1 if findings else 0


if __name__ == '__main__':
    sys.exit(main())
