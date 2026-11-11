#!/usr/bin/env python3
"""EXP-009 instrument check: run exp009.py on a toy file and on CLAUDE.md, assert what it must do.

Usage: fixture.py <empty-dir>     exit 0 only if every assertion holds.
Seeded positives: each check is shown failing on an input built to fail it.
"""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exp009 as X  # noqa: E402

fails = []


def check(name, cond):
    print(('PASS ' if cond else 'FAIL ') + name)
    if not cond:
        fails.append(name)


def run(*args):
    return subprocess.run([sys.executable, os.path.join(HERE, 'exp009.py'), *args],
                          capture_output=True, text=True)


TOY = """# Toy

Intro line one about the project.
Intro line two about the project.

## Table

| Key | Value |
|-----|-------|
| alpha | first row |
| beta | second row |

## Code

```bash
# a comment inside a fence
run-thing --flag
```

Prose one that is a little longer than the others are.
Prose two that is a little longer than the others are.
Prose three that is a little longer than the others are.
Prose four that is a little longer than the others are.
Prose five that is a little longer than the others are.
Prose six that is a little longer than the others are.
Prose seven that is a little longer than the others are.
Prose eight that is a little longer than the others are.
"""


def main(work):
    os.makedirs(work, exist_ok=True)
    lines = TOY.splitlines(keepends=True)
    units, group_of, scaffold = X.parse(lines)
    texts = [lines[u].strip() for u in units]
    check('heading is not a unit', '# Toy' not in texts and '## Table' not in texts)
    check('table header and delimiter are scaffolding, body rows are units',
          '| Key | Value |' not in texts and '| alpha | first row |' in texts)
    check('# comment inside a fence is a unit', '# a comment inside a fence' in texts)
    check('fence lines are scaffolding', '```bash' not in texts and '```' not in texts)

    d = X.Doc(lines)
    a = [i for i, l in enumerate(lines) if 'alpha' in l][0]
    b = [i for i, l in enumerate(lines) if 'beta' in l][0]
    check('first body row deletes alone', d.cost(a) == [a])
    d.delete(a)
    check('last body row takes header and delimiter with it', len(d.cost(b)) == 3)
    d.delete(b)
    check('emptied table leaves no pipe line', '|' not in d.text())

    got = [X.random_variant(lines, s) for s in X.RANDOM_SEEDS + X.RESTART_SEEDS[:5]]
    got = [v for v in got if v is not None]
    check('random variants that return (at least 5 of 8) are inside the window',
          len(got) >= 5 and all(X.LO * v.total <= v.size() <= X.HI * v.total for v in got))
    check('random variant is deterministic per seed',
          X.random_variant(lines, 8101).text() == X.random_variant(lines, 8101).text())
    check('overshoot returns None (seeded: one huge unit cannot fit)',
          X.random_variant(['x' * 1000 + '\n', 'y\n'], 1) is None)

    orig = os.path.join(work, 'orig.md')
    with open(orig, 'w') as f:
        f.write(TOY)
    good = os.path.join(work, 'good.md')
    with open(good, 'w') as f:
        f.write(X.random_variant(lines, 8101).text())
    check('check accepts a line-deleted variant in window', run('check', orig, good, os.path.join(work, 'c.md')).returncode == 0)
    bad = os.path.join(work, 'bad.md')
    with open(bad, 'w') as f:
        f.write(X.random_variant(lines, 8101).text().replace('Prose', 'Prosa', 1))
    check('check rejects a rewritten line (seeded)', run('check', orig, bad, os.path.join(work, 'c.md')).returncode == 2)
    swap = os.path.join(work, 'swap.md')
    with open(swap, 'w') as f:
        f.write(''.join(reversed(X.random_variant(lines, 8101).text().splitlines(True))))
    check('check rejects reordered lines (seeded)', run('check', orig, swap, os.path.join(work, 'c.md')).returncode == 2)

    check('exact match ignores case, backticks, ./',
          X.exact_ok('scripts/x.sh', 'Run `./Scripts/X.sh` first'))
    check('exact match rejects a different path (seeded)', not X.exact_ok('scripts/x.sh', 'scripts/y.sh'))
    check('exact match rejects an empty key (seeded)', not X.exact_ok('', 'anything'))
    check('exact match rejects the key inside a longer path (seeded)',
          not X.exact_ok('run.sh', 'tests/fixtures/q/run.sh'))
    check('exact match rejects the key inside a longer number (seeded)', not X.exact_ok('12', 'rule 112'))
    check('exact match allows sentence punctuation', X.exact_ok('run.sh', 'It is run.sh.'))
    check('table without a delimiter row: every line is a unit',
          len(X.parse(['| a |\n', '| b |\n'])[0]) == 2)

    def chk(name, text):
        pth = os.path.join(work, name)
        with open(pth, 'w') as f:
            f.write(text)
        return run('check', orig, pth, pth + '.canon').returncode

    def canon(name):
        with open(os.path.join(work, name + '.canon')) as f:
            return f.read()
    base = X.random_variant(lines, 8101).text()
    check('check rejects a deleted heading (seeded)', chk('nohead.md', base.replace('## Code\n', '', 1)) == 2)
    check('EXP-009: a deleted blank line is accepted and restored',
          chk('noblank.md', base.replace('\n\n', '\n', 1)) == 0 and canon('noblank.md') == base)
    check('EXP-009: an inserted blank line is accepted and dropped',
          chk('extrablank.md', base.replace('\n', '\n\n', 1)) == 0 and canon('extrablank.md') == base)
    check('EXP-009: all blank lines stripped still restores the exact random variant',
          chk('noblanks.md', ''.join(l for l in base.splitlines(True) if l.strip())) == 0
          and canon('noblanks.md') == base)
    Xd = X.Doc(lines)
    for i, l in enumerate(lines):
        if 'alpha' in l or 'beta' in l:
            Xd.removed.add(i)       # rows gone, header and delimiter left dangling
    check('check rejects a dangling table header (seeded)', chk('dangle.md', Xd.text()) == 2)
    ef = os.path.join(work, 'emptyfence.md')
    with open(ef, 'w') as f:
        f.write('# a\n```\n\n```\nx\n')
    check('check accepts an unchanged file with an empty fence',
          subprocess.run([sys.executable, os.path.join(HERE, 'exp009.py'), 'check', ef, ef, ef + '.c'],
                         capture_output=True).returncode in (0, 1))

    check('H2 holds above the max', X.decide_h2(9.0, [5, 6, 8]) == 'holds')
    check('H2 tie at the max is inconclusive', X.decide_h2(8.0, [5, 6, 8]) == 'inconclusive')
    check('H2 fails at the median', X.decide_h2(6.0, [5, 6, 8]) == 'fails')
    check('H1 holds', X.decide_h1([2, 3, 2], [3, 2, 1]) == 'holds')
    check('H1 inconclusive if one seeded run misses (seeded)', X.decide_h1([2, 1, 3], [3, 3, 3]) == 'inconclusive')
    check('H1 inconclusive if full cannot answer them (seeded)', X.decide_h1([3, 3, 3], [1, 3, 0]) == 'inconclusive')

    # seeded selection, on probes built so each rule has something to exclude
    pl = [i + 1 for i in units]          # 1-based unit lines; the toy has 14 units

    def mk(ev):
        return [{'id': f'P{k:02d}', 'question': 'q', 'answer': 'a', 'evidence': e, 'exact': False}
                for k, e in enumerate(ev)]
    # P00-P02 held-out on unique lines; P03/P04 held-out share a line; P05 held-out has two lines;
    # P06-P14 held-out and P15-P29 known all sit on one shared line.
    ev = ([[pl[0]], [pl[1]], [pl[2]], [pl[3]], [pl[3]], [pl[4], pl[5]]] + [[pl[6]]] * 9
          + [[pl[7]]] * 15)
    sp = {'held_out': [f'P{k:02d}' for k in range(15)], 'known': [f'P{k:02d}' for k in range(15, 30)]}
    chosen, nh, nk = X.pick_seeded(mk(ev), sp, units)
    check('seeded picks exactly the 3 unique single-line held-out probes',
          chosen is not None and sorted(chosen) == ['P00', 'P01', 'P02'] and (nh, nk) == (3, 0))
    ev2 = ([[pl[0]]] + [[pl[6]]] * 14 + [[pl[8]], [pl[9]], [pl[10]]] + [[pl[7]]] * 12)
    chosen, nh, nk = X.pick_seeded(mk(ev2), sp, units)
    check('seeded falls back to known probes when held-out has fewer than 3',
          chosen is not None and chosen[0] == 'P00' and set(chosen[1:]) <= {'P15', 'P16', 'P17'}
          and len(set(chosen)) == 3)
    chosen, _, _ = X.pick_seeded(mk([[pl[6]]] * 30), sp, units)
    check('seeded returns None when nothing qualifies (seeded)', chosen is None)

    # restart path: on the toy, seed 8103 overshoots, so random-3 must restart and still land
    tp, ts, tv = (os.path.join(work, n) for n in ('toy-probes.json', 'toy-split.json', 'toy-variants'))
    X.dump(mk(ev), tp)
    X.dump(sp, ts)
    rt = run('variants', orig, tp, ts, tv)
    tm = X.load(os.path.join(tv, 'manifest.json')) if rt.returncode == 0 else {}
    check('overshooting seed restarts and lands in the window',
          len(tm.get('random-3', {}).get('seeds', [])) > 1 and X.LO <= tm['random-3']['pct'] <= X.HI)

    # end to end on the real CLAUDE.md, with synthetic probes on single unit lines
    real = os.path.join(HERE, '..', '..', 'CLAUDE.md')
    rl = X.read_lines(real)
    ru, _, _ = X.parse(rl)
    import re as _re
    tick = [u for u in ru if _re.search(r'`([^`\s]{4,})`', rl[u])]
    plain = [u for u in ru if u not in tick]
    rp = []
    for k in range(30):
        if k < 12:
            u = tick[k * 2]
            key = _re.search(r'`([^`\s]{4,})`', rl[u]).group(1)
            rp.append({'id': f'P{k + 1:02d}', 'question': f'question {k}', 'answer': key,
                       'evidence': [u + 1], 'exact': True})
        else:
            rp.append({'id': f'P{k + 1:02d}', 'question': f'question {k}', 'answer': 'a',
                       'evidence': [plain[k * 2] + 1], 'exact': False})
    pp, sp, vd = (os.path.join(work, n) for n in ('probes.json', 'split.json', 'variants'))
    X.dump(rp, pp)
    r1 = run('split', real, pp, sp)
    check('split runs on 30 valid probes', r1.returncode == 0)
    bad = [dict(q) for q in rp]
    bad[20]['question'] = 'what is ' + rp[0]['answer'] + '?'
    X.dump(bad, os.path.join(work, 'leak.json'))
    lx = os.path.join(work, 'leak-split.json')
    rl_ = run('split', real, os.path.join(work, 'leak.json'), lx)
    check('split records a key leaked into another question (seeded)',
          rl_.returncode == 0 and X.load(lx)['leaked'] == ['P01'])
    lu = X.parse(rl)[0]
    only = {'held_out': ['P01'], 'known': [], 'leaked': []}
    _, n_clean, _ = X.pick_seeded(rp, only, lu)
    _, n_leak, _ = X.pick_seeded(rp, dict(only, leaked=['P01']), lu)
    check('a leaked probe stops qualifying for seeding', (n_clean, n_leak) == (1, 0))
    bad = [dict(q) for q in rp]
    bad[0]['question'] = 'is it ' + rp[0]['answer'] + '?'
    X.dump(bad, os.path.join(work, 'self.json'))
    check('split refuses a question carrying its own exact key (seeded)',
          run('split', real, os.path.join(work, 'self.json'), os.path.join(work, 'x.json')).returncode == 2)
    bad = [dict(q) for q in rp]
    bad[0]['evidence'] = [rp[15]['evidence'][0]]
    X.dump(bad, os.path.join(work, 'offline.json'))
    check('split refuses an exact key not on its evidence line (seeded)',
          run('split', real, os.path.join(work, 'offline.json'), os.path.join(work, 'x.json')).returncode == 2)
    s = X.load(sp)
    ex_held = sum(1 for p in rp if p['exact'] and p['id'] in s['held_out'])
    check('split is stratified (6 of 12 exact held out)', ex_held == 6)
    r2 = run('variants', real, pp, sp, vd)
    check('variants build on CLAUDE.md', r2.returncode == 0)
    m = X.load(os.path.join(vd, 'manifest.json'))
    check('all three random variants in window on CLAUDE.md',
          all(X.LO <= m[f'random-{k}']['pct'] <= X.HI for k in (1, 2, 3)))
    check('seeded variant built with 3 probes', bool(m.get('seeded')) and len(m['seeded']['probes']) == 3)
    for k in (1, 2, 3):
        rv = os.path.join(vd, f'random-{k}.md')
        check(f'random-{k} passes the pruner check unchanged',
              run('check', real, rv, rv + '.c').returncode == 0 and open(rv).read() == open(rv + '.c').read())

    # scoring end to end with synthetic answers: judged-blind answers everything, randoms half
    ad = os.path.join(work, 'answers')
    for v in X.VARIANTS:
        os.makedirs(os.path.join(ad, v), exist_ok=True)
        if not os.path.exists(os.path.join(vd, v + '.md')):
            with open(os.path.join(vd, v + '.md'), 'w') as f:
                f.write('')
        for k in range(1, 4):
            if v in ('full', 'judged-blind-1', 'judged-blind-2', 'judged-known'):
                ans = {p['id']: p['answer'] for p in rp}
            elif v == 'seeded':
                ans = {p['id']: ('UNKNOWN' if p['id'] in m['seeded']['probes'] else p['answer']) for p in rp}
            elif v.startswith('random'):
                ans = {p['id']: (p['answer'] if int(p['id'][1:]) % 2 else 'UNKNOWN') for p in rp}
            else:
                ans = {p['id']: 'UNKNOWN' for p in rp}
            X.dump(ans, os.path.join(ad, v, f'run-{k}.json'))
    pool, pmap, verd, art = (os.path.join(work, n) for n in ('pool.json', 'map.json', 'verdicts.json', 'art.json'))
    check('pool builds', run('pool', pp, vd, ad, pool, pmap).returncode == 0)
    items = X.load(pool)
    check('pool items carry no variant label', all(set(i) == {'item', 'question', 'key', 'answer'} for i in items))
    X.dump({i['item']: i['answer'] != 'UNKNOWN' for i in items}, verd)
    r3 = run('score', pp, sp, vd, ad, pmap, verd, art)
    out = X.load(art) if r3.returncode == 0 else {}
    check('score: H1 holds on a clean seeded run', out.get('H1') == 'holds')
    check('score: H2 holds when judged beats every random', out.get('H2') == 'holds')
    held = set(s['held_out'])
    odd_held = sum(1 for i in held if int(i[1:]) % 2)
    sc = out.get('scores', {})
    check('score: held-out counted on held-out ids, not known',
          sc.get('judged-blind-1', {}).get('held_out') == 15 and sc.get('random-1', {}).get('held_out') == odd_held
          and sc.get('empty', {}).get('known') == 0)
    check('score: bytes recorded for judged variants',
          all('bytes' in sc.get(v, {}) for v in ('judged-blind-1', 'judged-blind-2', 'judged-known')))
    # H2 fails end to end: judged-blind answers like random
    for v in ('judged-blind-1', 'judged-blind-2'):
        for k in range(1, 4):
            X.dump({p['id']: (p['answer'] if int(p['id'][1:]) % 2 else 'UNKNOWN') for p in rp},
                   os.path.join(ad, v, f'run-{k}.json'))
    run('pool', pp, vd, ad, pool, pmap)
    X.dump({i['item']: i['answer'] != 'UNKNOWN' for i in X.load(pool)}, verd)
    r4 = run('score', pp, sp, vd, ad, pmap, verd, art)
    check('score: H2 fails when judged only matches random', r4.returncode == 0 and X.load(art)['H2'] == 'fails')
    run_one = X.load(os.path.join(ad, 'empty', 'run-1.json'))
    run_one.pop('P01')
    X.dump(run_one, os.path.join(ad, 'empty', 'run-1.json'))
    run('score', pp, sp, vd, ad, pmap, verd, art)
    check('score: an unanswered probe is counted', X.load(art).get('unanswered') == 1)
    fo = os.path.join(work, 'fence-orig.md')
    fl = ['# t\n', '\n'] + [f'prose line {i} with some padding text here\n' for i in range(12)] + \
         ['\n', '```\n', 'cmd one\n', '\n', 'cmd two\n', '```\n', '\n', 'tail line\n']
    with open(fo, 'w') as f:
        f.write(''.join(fl))
    fd = X.Doc(fl)
    for i, l in enumerate(fl):
        if l.startswith('cmd') or l.startswith('prose line 1') or l in ('prose line 2 with some padding text here\n',):
            fd.delete(i)
    fp = os.path.join(work, 'fence-pruned.md')
    with open(fp, 'w') as f:
        f.write(''.join(l for l in fd.text().splitlines(True) if l.strip()))
    rf = run('check', fo, fp, fp + '.c')
    check('EXP-009: a deleted fence with a blank inside restores what random would leave',
          rf.returncode in (0, 1) and open(fp + '.c').read() == fd.text())
    os.remove(os.path.join(vd, 'judged-known.md'))
    run('pool', pp, vd, ad, pool, pmap)
    X.dump({i['item']: i['answer'] != 'UNKNOWN' for i in X.load(pool)}, verd)
    r5 = run('score', pp, sp, vd, ad, pmap, verd, art)
    check('EXP-009: a dropped report-only arm is scored around and listed',
          r5.returncode == 0 and X.load(art)['dropped_arms'] == ['judged-known'] and X.load(art)['H2'] == 'fails')
    os.remove(os.path.join(vd, 'judged-blind-2.md'))
    check('EXP-009: a missing decision arm still stops scoring (seeded)',
          run('score', pp, sp, vd, ad, pmap, verd, art).returncode == 2)
    X.dump({}, verd)
    check('score refuses missing verdicts (seeded)', run('score', pp, sp, vd, ad, pmap, verd, art).returncode == 2)

    print(f'\n{len(fails)} failure(s)')
    return 1 if fails else 0


if __name__ == '__main__':
    if len(sys.argv) != 2 or (os.path.exists(sys.argv[1]) and os.listdir(sys.argv[1])):
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
