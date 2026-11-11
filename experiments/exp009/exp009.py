#!/usr/bin/env python3
"""EXP-009 runner: build file variants, split probes, grade answers, apply the decision rule.

Implements experiments/backlog.md § EXP-009 (and EXP-008 where it defers) as frozen. A rule the backlog does not state is
marked CHOICE. The agent steps (probe writer, pruners, readers, grader) are not here; their
prompts are in prompts.md, and this script checks and scores what they return.

Usage (run dir = lab/experiments/<date>-exp009/):
  exp009.py number   <original.md>                       # numbered text for the probe writer
  exp009.py split    <original.md> <probes.json> <split.json>
  exp009.py variants <original.md> <probes.json> <split.json> <variants-dir>
  exp009.py check    <original.md> <pruner-out.md> <variant.md>   # validate, restore layout, window
  exp009.py pool     <probes.json> <variants-dir> <answers-dir> <pool.json> <pool-map.json>
  exp009.py score    <probes.json> <split.json> <variants-dir> <answers-dir> \\
                     <pool-map.json> <verdicts.json> <artifact.json>

Formats:
  probes.json   [{"id","question","answer","evidence":[1-based line numbers],"exact":bool}]
  answers-dir   <variant>/run-<k>.json, each {"<probe id>": "<answer text>"}
  verdicts.json {"<pool item id>": true|false}, written by the grader agent
"""
import hashlib, json, os, random, re, sys

SPLIT_SEED = 8008
RANDOM_SEEDS = [8101, 8102, 8103]                 # random-1..3
RESTART_SEEDS = list(range(8201, 8221))           # consumed in order on overshoot
SEEDED_SEED = 8301
POOL_SEED = 8401
LO, HI = 0.57, 0.60
READER_RUNS = 3
VARIANTS = ['full', 'empty', 'random-1', 'random-2', 'random-3',
            'judged-blind-1', 'judged-blind-2', 'judged-known', 'seeded']
HEADING = re.compile(r'^#{1,6}\s')
FENCE = re.compile(r'^\s*(```|~~~)')
TABLE_DELIM = re.compile(r'^\s*\|?[\s:|-]+\|?\s*$')


def die(msg):
    print(f'exp009: {msg}', file=sys.stderr)
    sys.exit(2)


def load(p):
    with open(p, encoding='utf-8') as f:
        return json.load(f)


def dump(obj, p):
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(obj, f, indent=1, ensure_ascii=False)
        f.write('\n')


def read_lines(p):
    with open(p, encoding='utf-8') as f:
        lines = f.read().splitlines(keepends=True)
    if lines and not lines[-1].endswith('\n'):
        lines[-1] += '\n'   # CHOICE: a missing final newline is added, so every line costs its newline
    return lines


def nbytes(line):
    return len(line.encode('utf-8'))


def parse(lines):
    """Return (units, scaffold): units are deletable line indexes; scaffold maps a group id to
    the scaffolding line indexes deleted with that group's last unit, and group_of maps unit->gid.
    Backlog: a unit is a non-blank line that is not a markdown heading; lines inside a code fence
    are units, # comments included; a table's header and delimiter go with its last body row.
    CHOICE: a fence's opening and closing lines are scaffolding, like a table's header, and go
    with the fence's last content line."""
    units, group_of, scaffold = [], {}, {}
    i, n, gid = 0, len(lines), 0
    while i < n:
        s = lines[i].rstrip('\n')
        if FENCE.match(s):
            j = i + 1
            while j < n and not FENCE.match(lines[j].rstrip('\n')):
                j += 1
            close = j if j < n else None
            gid += 1
            scaffold[gid] = [i] + ([close] if close is not None else [])
            for k in range(i + 1, j):
                if lines[k].strip():
                    units.append(k)
                    group_of[k] = gid
            i = j + 1
            continue
        if s.lstrip().startswith('|'):
            j = i
            while j < n and lines[j].lstrip().startswith('|'):
                j += 1
            # CHOICE: without a delimiter row it is not a table header; every line is a unit
            body_start = i + 2 if i + 1 < j and TABLE_DELIM.match(lines[i + 1].rstrip('\n')) else i
            gid += 1
            scaffold[gid] = list(range(i, body_start))
            for k in range(body_start, j):
                units.append(k)
                group_of[k] = gid
            if body_start >= j:          # a table with no body: its header is an ordinary unit
                units.extend(scaffold.pop(gid))
            i = j
            continue
        if s.strip() and not HEADING.match(s):
            units.append(i)
        i += 1
    return sorted(units), group_of, scaffold


class Doc:
    def __init__(self, lines):
        self.lines = lines
        self.units, self.group_of, self.scaffold = parse(lines)
        self.total = sum(nbytes(l) for l in lines)
        self.removed = set()

    def size(self):
        return self.total - sum(nbytes(self.lines[i]) for i in self.removed)

    def cost(self, u):
        """Lines that go if unit u is deleted: u, plus its group's scaffolding if u is the last."""
        out = [u]
        g = self.group_of.get(u)
        if g is not None:
            left = [k for k, gg in self.group_of.items() if gg == g and k not in self.removed]
            if left == [u]:
                out += self.scaffold[g]
        return out

    def delete(self, u):
        self.removed.update(self.cost(u))

    def text(self):
        return ''.join(l for i, l in enumerate(self.lines) if i not in self.removed)


def random_variant(lines, seed):
    d = Doc(lines)
    lo, hi = LO * d.total, HI * d.total
    order = list(d.units)
    random.Random(seed).shuffle(order)
    for u in order:
        if u in d.removed:
            continue
        drop = sum(nbytes(lines[i]) for i in d.cost(u))
        if d.size() - drop < lo:      # backlog: skip a unit whose deletion would go below 57%
            continue
        d.delete(u)
        if d.size() <= hi:
            return d
    return None                        # ended above 60%: caller restarts with the next seed


def cmd_number(orig_p):
    for n, line in enumerate(read_lines(orig_p), 1):
        sys.stdout.write(f'{n}: {line}')


def cmd_split(orig_p, probes_p, out_p):
    probes = load(probes_p)
    lines = read_lines(orig_p)
    for p in probes:
        if not all(k in p for k in ('id', 'question', 'answer', 'evidence', 'exact')):
            die(f'probe {p.get("id", "?")} lacks one of id, question, answer, evidence, exact')
        ev = p.get('evidence') or []
        if not ev or not all(isinstance(n, int) and 1 <= n <= len(lines) for n in ev):
            die(f'{p.get("id")}: evidence {ev} is not a list of line numbers 1..{len(lines)}')
        if p['exact'] and not any(exact_ok(p['answer'], lines[n - 1]) for n in ev):
            die(f'{p["id"]}: exact key {p["answer"]!r} is not on its evidence line(s)')
    leaked = set()                       # backlog: a key in another probe's question is recorded,
    for p in probes:                     # and that probe cannot be seeded; in its own question, refused
        for q in probes:
            if q['exact'] and exact_ok(q['answer'], p['question']):
                if p is q:
                    die(f'{p["id"]}\'s question contains its own exact key {q["answer"]!r}')
                leaked.add(q['id'])
    ids = [p['id'] for p in probes]
    if len(ids) != 30 or len(set(ids)) != 30:
        die(f'need 30 probes with unique ids, got {len(ids)} ({len(set(ids))} unique)')
    if sum(p['exact'] for p in probes) < 10:
        die('fewer than 10 exact-identifier probes')
    rng = random.Random(SPLIT_SEED)
    known, held = [], []
    for flag in (True, False):         # backlog: stratified on the exact-identifier flag
        grp = sorted(p['id'] for p in probes if p['exact'] == flag)
        rng.shuffle(grp)
        # CHOICE: an odd stratum gives its extra probe to whichever half is shorter so far,
        # held-out first on a tie, so the halves come out 15/15.
        half = len(grp) // 2
        extra = grp[2 * half:]
        known += grp[:half]
        held += grp[half:2 * half]
        for e in extra:
            (held if len(held) <= len(known) else known).append(e)
    if len(known) != 15 or len(held) != 15:
        die(f'split came out {len(known)}/{len(held)}')
    dump({'seed': SPLIT_SEED, 'known': sorted(known), 'held_out': sorted(held),
          'leaked': sorted(leaked)}, out_p)
    print(f'split: 15 known, 15 held-out, seed {SPLIT_SEED}; {len(leaked)} key(s) leaked into other questions')


def pick_seeded(probes, split, units):
    """Backlog: held-out probes whose evidence line backs no other probe; 3 drawn with the fixed
    seed; known probes join the pool if fewer than 3 qualify. CHOICE: only probes resting on
    exactly one line qualify, and that line must be a unit, so deleting it removes the evidence."""
    backers = {}
    for p in probes:
        for ln in p['evidence']:
            backers.setdefault(ln, set()).add(p['id'])
    unit_lines = {u + 1 for u in units}

    leaked = set(split.get('leaked', []))

    def ok(p):
        return (p['id'] not in leaked and len(p['evidence']) == 1 and p['evidence'][0] in unit_lines
                and backers[p['evidence'][0]] == {p['id']})
    held = sorted(p['id'] for p in probes if p['id'] in split['held_out'] and ok(p))
    known = sorted(p['id'] for p in probes if p['id'] in split['known'] and ok(p))
    rng = random.Random(SEEDED_SEED)
    if len(held) >= 3:
        return rng.sample(held, 3), len(held), len(known)
    if len(held) + len(known) >= 3:
        return held + rng.sample(known, 3 - len(held)), len(held), len(known)
    return None, len(held), len(known)


def cmd_variants(orig_p, probes_p, split_p, out_dir):
    lines = read_lines(orig_p)
    probes, split = load(probes_p), load(split_p)
    os.makedirs(out_dir, exist_ok=True)
    manifest = {'original_bytes': sum(nbytes(l) for l in lines), 'window': [LO, HI]}

    def write(name, text):
        with open(os.path.join(out_dir, name + '.md'), 'w', encoding='utf-8') as f:
            f.write(text)
        manifest[name] = {'bytes': len(text.encode('utf-8')),
                          'pct': round(len(text.encode('utf-8')) / manifest['original_bytes'], 4)}
    write('full', ''.join(lines))
    write('empty', '')
    restarts = iter(RESTART_SEEDS)
    for k, seed in enumerate(RANDOM_SEEDS, 1):
        used, d = [seed], random_variant(lines, seed)
        while d is None:
            s = next(restarts, None)
            if s is None:
                die(f'random-{k}: restart seeds exhausted')
            used.append(s)
            d = random_variant(lines, s)
        write(f'random-{k}', d.text())
        manifest[f'random-{k}']['seeds'] = used
    d = Doc(lines)
    chosen, nh, nk = pick_seeded(probes, split, d.units)
    manifest['seeded_pool'] = {'held_out_qualifying': nh, 'known_qualifying': nk}
    if chosen is None:
        manifest['seeded'] = None
        print('seeded: fewer than 3 probes qualify; H1 will be inconclusive', file=sys.stderr)
    else:
        by_id = {p['id']: p for p in probes}
        for pid in chosen:
            d.delete(by_id[pid]['evidence'][0] - 1)
        write('seeded', d.text())
        manifest['seeded']['probes'] = chosen
    dump(manifest, os.path.join(out_dir, 'manifest.json'))
    print(json.dumps({k: v for k, v in manifest.items() if k != 'seeded_pool'}, indent=1))


def cmd_check(orig_p, out_p, var_p):
    """EXP-009: a pruner's output must be the original with units deleted, in order: headings
    kept, and a table's or fence's scaffolding deleted exactly when all its units are. Blank lines
    are layout: they are ignored when aligning, and the variant written to var_p is the original
    with exactly the deleted lines removed, so every original blank line is restored, as random
    keeps them. The window is measured on that variant. Exit 0 in window, 1 outside, 2 rejected.
    CHOICE: non-blank lines are aligned by keeping each original line that matches the next
    output line; a rare duplicate line that defeats this fails loudly rather than passing."""
    orig = read_lines(orig_p)
    out = [l for l in read_lines(out_p) if l.strip()]
    units, group_of, scaffold = parse(orig)
    unit_set = set(units)
    removed, j = set(), 0
    for i, line in enumerate(orig):
        if not line.strip():
            continue
        if j < len(out) and out[j] == line:
            j += 1
        else:
            removed.add(i)
    if j != len(out):
        die(f'{out_p}: non-blank line {j + 1} is not an original line in order '
            f'(rewritten, added or reordered)')
    members = {g: [k for k, gg in group_of.items() if gg == g] for g in scaffold}
    gone_groups = {g for g in scaffold if members[g] and all(k in removed for k in members[g])}
    allowed = unit_set | {i for g in gone_groups for i in scaffold[g]}
    bad = sorted(removed - allowed)
    if bad:
        die(f'{out_p}: deleted line {bad[0] + 1}, which is a heading or scaffolding '
            f'of a block that still has lines ({len(bad)} such)')
    dangling = sorted(i for g in gone_groups for i in scaffold[g] if i not in removed)
    if dangling:
        die(f'{out_p}: kept line {dangling[0] + 1}, scaffolding of a block whose lines are all deleted')
    # blank lines inside a fully deleted fence stay, exactly as random_variant leaves them
    text = ''.join(l for i, l in enumerate(orig) if i not in removed)
    with open(var_p, 'w', encoding='utf-8') as f:
        f.write(text)
    total = sum(nbytes(l) for l in orig)
    size = len(text.encode('utf-8'))
    pct = size / total
    inside = LO <= pct <= HI
    print(f'{var_p}: {size} bytes, {pct:.2%} of {total}; {"IN" if inside else "OUTSIDE"} window; '
          f'{len(removed)} lines deleted')
    sys.exit(0 if inside else 1)


def norm(s):
    s = s.lower()
    for ch in '`"\'“”‘’':
        s = s.replace(ch, '')
    return re.sub(r'(^|\s)\./', r'\1', s).strip()


def exact_ok(key, answer):
    """Backlog: case-insensitive, after stripping backticks, quotes and a leading ./; correct if
    the key appears in the answer as a whole token: not inside a longer path, name or number."""
    k = norm(key)
    if not k:
        return False
    pat = r'(?<![\w./-])' + re.escape(k) + r'(?![\w/-])(?!\.\w)'
    return re.search(pat, norm(answer)) is not None


def answers_for(answers_dir, variant):
    out = []
    for k in range(1, READER_RUNS + 1):
        p = os.path.join(answers_dir, variant, f'run-{k}.json')
        if not os.path.exists(p):
            die(f'missing {p}')
        out.append(load(p))
    return out


def present_variants(variants_dir):
    vs = [v for v in VARIANTS if os.path.exists(os.path.join(variants_dir, v + '.md'))]
    # EXP-009: a report-only arm that failed check twice is dropped, not a stop
    missing = [v for v in VARIANTS if v not in vs and v not in ('seeded', 'judged-known')]
    if missing:
        die(f'variants missing: {missing}')
    return vs


def cmd_pool(probes_p, variants_dir, answers_dir, pool_p, map_p):
    """Non-exact answers from all variants, pooled, shuffled and unlabelled for the grader."""
    probes = load(probes_p)
    items, mapping = [], {}
    for v in present_variants(variants_dir):
        for k, run in enumerate(answers_for(answers_dir, v), 1):
            for p in probes:
                if p['exact']:
                    continue
                ans = str(run.get(p['id'], '')).strip()
                iid = hashlib.sha256(f'{v}|{k}|{p["id"]}'.encode()).hexdigest()[:12]
                mapping[iid] = {'variant': v, 'run': k, 'probe': p['id']}
                items.append({'item': iid, 'question': p['question'], 'key': p['answer'],
                              'answer': ans})
    random.Random(POOL_SEED).shuffle(items)
    dump(items, pool_p)
    dump(mapping, map_p)
    print(f'pool: {len(items)} items for the grader')


def decide_h1(seeded_fail_counts, full_pass_counts):
    """Backlog: in each seeded run at least 2 of the 3 seeded probes fail, and in at least 2 of
    the 3 full runs at least 2 of them pass."""
    if seeded_fail_counts is None:
        return 'inconclusive'
    ok_seeded = all(c >= 2 for c in seeded_fail_counts)
    ok_full = sum(c >= 2 for c in full_pass_counts) >= 2
    return 'holds' if ok_seeded and ok_full else 'inconclusive'


def decide_h2(judged, randoms):
    """Backlog: holds if above the highest random score; fails if at or below their median;
    inconclusive between. Compared as computed; a tie counts as the lower outcome."""
    r = sorted(randoms)
    if judged <= r[1]:
        return 'fails'
    if judged > r[2]:
        return 'holds'
    return 'inconclusive'


def cmd_score(probes_p, split_p, variants_dir, answers_dir, map_p, verdicts_p, art_p):
    probes, split = load(probes_p), load(split_p)
    mapping, verdicts = load(map_p), load(verdicts_p)
    unjudged = [i for i in mapping if i not in verdicts]
    if unjudged:
        die(f'{len(unjudged)} pool items have no grader verdict')
    verdict_of = {(m['variant'], m['run'], m['probe']): bool(verdicts[i]) for i, m in mapping.items()}
    manifest = load(os.path.join(variants_dir, 'manifest.json'))
    held, known = set(split['held_out']), set(split['known'])
    correct, scores, missing = {}, {}, 0
    for v in present_variants(variants_dir):
        per_run = []
        for k, run in enumerate(answers_for(answers_dir, v), 1):
            got = {}
            for p in probes:
                if p['id'] not in run:
                    missing += 1           # CHOICE: an unanswered probe is wrong, and counted
                got[p['id']] = (exact_ok(p['answer'], str(run.get(p['id'], ''))) if p['exact']
                                else verdict_of[(v, k, p['id'])])
            per_run.append(got)
        correct[v] = per_run
        h = [sum(g[i] for i in held) for g in per_run]
        kn = [sum(g[i] for i in known) for g in per_run]
        scores[v] = {'held_out_runs': h, 'known_runs': kn,
                     'held_out': sum(h) / len(h), 'known': sum(kn) / len(kn)}
        b = os.path.getsize(os.path.join(variants_dir, v + '.md'))
        scores[v]['bytes'] = b
        scores[v]['held_out_per_1000_bytes'] = round(1000 * scores[v]['held_out'] / b, 4) if b else None
    seeded = manifest.get('seeded')
    if seeded and 'seeded' in correct:
        sp = seeded['probes']
        h1 = decide_h1([sum(not g[i] for i in sp) for g in correct['seeded']],
                       [sum(g[i] for i in sp) for g in correct['full']])
    else:
        h1 = decide_h1(None, None)
    judged = (scores['judged-blind-1']['held_out'] + scores['judged-blind-2']['held_out']) / 2
    randoms = [scores[f'random-{k}']['held_out'] for k in (1, 2, 3)]
    h2 = decide_h2(judged, randoms) if h1 == 'holds' else 'not read (H1 inconclusive)'
    art = {'experiment': 'EXP-009', 'probes': probes, 'split': split, 'scores': scores,
           'dropped_arms': [v for v in VARIANTS if v not in scores],
           'judged_blind_mean_held_out': judged, 'random_held_out': randoms,
           'seeded': seeded, 'unanswered': missing, 'H1': h1, 'H2': h2}
    dump(art, art_p)
    print(f'H1 {h1}; H2 {h2}; judged-blind {judged:.2f} vs random {sorted(randoms)}; '
          f'unanswered {missing}')


CMDS = {'number': (cmd_number, 1), 'split': (cmd_split, 3), 'variants': (cmd_variants, 4), 'check': (cmd_check, 3),
        'pool': (cmd_pool, 5), 'score': (cmd_score, 7)}

if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in CMDS or len(sys.argv) - 2 != CMDS[sys.argv[1]][1]:
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    CMDS[sys.argv[1]][0](*sys.argv[2:])
