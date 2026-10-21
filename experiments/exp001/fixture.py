#!/usr/bin/env python3
"""EXP-001 instrument check: build the 10-case fixture, run parse.py on it, assert the counts.

Usage: fixture.py <empty-dir>     exit 0 only if every expected count in
                                  experiments/backlog.md § Instrument check holds.
"""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))


def git(repo, *args, date=None):
    env = dict(os.environ, GIT_AUTHOR_NAME='fx', GIT_AUTHOR_EMAIL='fx@example.invalid',
               GIT_COMMITTER_NAME='fx', GIT_COMMITTER_EMAIL='fx@example.invalid')
    if date:
        env.update(GIT_AUTHOR_DATE=date, GIT_COMMITTER_DATE=date)
    subprocess.run(['git', '-C', repo, *args], check=True, env=env, capture_output=True)


def make_repo(path, commits):
    os.makedirs(os.path.join(path, 'src'), exist_ok=True)
    git(path, 'init', '-q')
    for date, text in commits:
        with open(os.path.join(path, 'CLAUDE.md'), 'w') as f:
            f.write(text)
        git(path, 'add', 'CLAUDE.md')
        git(path, 'commit', '-q', '-m', 'fx', date=date)


class Session:
    n = 0

    def __init__(self, sid, day, cwd):
        self.sid, self.day, self.cwd, self.lines, self.minute = sid, day, cwd, [], 0

    def bash(self, cmd, cwd=None, sub=False):
        Session.n += 1
        self.minute += 1
        tid = f'toolu_{Session.n:04d}'
        ts = f'2026-01-{self.day:02d}T10:{self.minute:02d}:00.000Z'
        base = dict(sessionId=self.sid, cwd=cwd or self.cwd, timestamp=ts, isSidechain=sub)
        self.lines.append(dict(base, type='assistant', uuid=tid + 'a', message=dict(
            role='assistant', content=[dict(type='tool_use', id=tid, name='Bash',
                                            input=dict(command=cmd))])))
        self.lines.append(dict(base, type='user', uuid=tid + 'u', message=dict(
            role='user', content=[dict(type='tool_result', tool_use_id=tid,
                                       content='x' * 100)])))
        return self

    def write(self, path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w') as f:
            for l in self.lines:
                f.write(json.dumps(l) + '\n')


def build(fx):
    A, B = os.path.join(fx, 'repos', 'repoA'), os.path.join(fx, 'repos', 'repoB')
    make_repo(A, [('2026-01-01T09:00:00Z', 'Config is read by parse_config.\n'),
                  ('2026-01-20T09:00:00Z', 'Config is read by parse_config.\nCache: load_cache.\n')])
    make_repo(B, [('2026-01-01T09:00:00Z', 'Run the test suite before committing.\n')])
    pa, pb = os.path.join(fx, 'projects', '-fx-repoA'), os.path.join(fx, 'projects', '-fx-repoB')
    s = {k: Session(f'sid-{k}', d, A) for k, d in zip(['A1', 'A2', 'A3', 'A4', 'A5', 'A6'], range(5, 11))}
    s.update({k: Session(f'sid-{k}', d, B) for k, d in zip(['B1', 'B2', 'B3', 'B4', 'B5', 'B6'], range(5, 11))})
    # 1: planted repeat, different quoting and flags
    s['A1'].bash('grep -rn "FooBar" .'); s['A2'].bash('cd . && rg foobar | head')
    # 2: covered repeat
    s['A1'].bash('grep -rn parse_config .'); s['A3'].bash('grep -rn parse_config .')
    # 3: term added to CLAUDE.md only after the second session
    s['A2'].bash('grep load_cache .'); s['A4'].bash('grep load_cache .')
    # 4: within one session only
    s['A5'].bash('grep onlyonce .').bash('grep onlyonce .')
    # 5: same key in both repos, once each
    s['A6'].bash('grep sharedterm .'); s['B1'].bash('grep sharedterm .')
    # extra control: grep inside a heredoc body is not a search and not unparsed
    s['A6'].bash("python3 - <<'EOF'\n# grep foobar here\nEOF")
    # extra control: a leading `cd` moves the path of later segments (single event, no repeat)
    s['B1'].bash('cd src && grep zzcdterm .')
    # EXP-002 controls: one single event per shape the first parser missed, plus a non-candidate
    for cmd in ['echo $(grep -c zzsubterm .)', 'diff <(grep zzprocsub a.txt) b.txt',
                'echo `grep zzbacktick .`', "bash -c 'grep zzbashc .'", 'timeout 30 grep zzto .',
                'ls | xargs command grep zzxargs', 'for f in a b; do grep zzloop "$f"; done',
                "sed -n '/grep/p' notes.txt"]:
        s['B2'].bash(cmd)
    # 7: a subagent repeat of a main-session key
    s['B2'].bash('grep subterm .'); s['B3'].bash('grep b3only .')
    sub = Session('sid-B3', 8, B); sub.minute = 30; sub.bash('grep subterm .', sub=True)
    # 8: same search from root and from a subdirectory
    s['B4'].bash('grep barbaz src'); s['B5'].bash('grep barbaz .', cwd=os.path.join(B, 'src'))
    # 9: short term that is also in CLAUDE.md
    s['B4'].bash('grep test .'); s['B6'].bash('grep test .')
    # 10: flag values must not become the key; a bare find has no term
    s['B5'].bash('grep -A 3 baz .'); s['B6'].bash('grep -A 3 qux .').bash('find .')
    for k, sess in s.items():
        sess.write(os.path.join(pa if k[0] == 'A' else pb, f'sid-{k}.jsonl'))
    # 6: a resume copies A5's lines, same tool_use_ids, into a second file
    s['A5'].write(os.path.join(pa, 'sid-A5-resumed.jsonl'))
    sub.write(os.path.join(pb, 'sid-B3', 'subagents', 'agent-1.jsonl'))
    return os.path.join(fx, 'projects')


EXPECT = dict(repeats=5, coverable_repeats=4, covered_repeats=1, uncoverable_repeats=1,
              within_session_repeats=1, subagent_repeats=1, sessions=12)


def main():
    fx = os.path.abspath(sys.argv[1])
    if os.listdir(fx) if os.path.isdir(fx) else False:
        sys.exit(f'{fx} is not empty')
    projects = build(fx)
    out = subprocess.run([sys.executable, '-I', os.path.join(HERE, 'parse.py'), '--projects', projects,
                          '--cutoff', '2099-01-01T00:00:00+00:00',
                          '--artifact', os.path.join(fx, 'artifact.json'),
                          '--raw', os.path.join(fx, 'raw.jsonl')], capture_output=True, text=True)
    if out.returncode:
        sys.exit(out.stderr)
    art = json.load(open(os.path.join(fx, 'artifact.json')))
    got = art['pooled']
    fails = [f'{k}: expected {v}, got {got.get(k)}' for k, v in EXPECT.items() if got.get(k) != v]
    c = art['counts']
    for k, v in [('excluded_no_term_main', 1), ('unparsed_main', 0)]:
        if c.get(k, 0) != v:
            fails.append(f'{k}: expected {v}, got {c.get(k, 0)}')
    if art['repos_kept'] != 2 or art['separate']:
        fails.append(f"repos_kept={art['repos_kept']} separate={list(art['separate'])}")
    keys = {tuple(json.loads(l)['key']) for l in open(os.path.join(fx, 'raw.jsonl'))}
    if ('zzcdterm', 'src') not in keys:
        fails.append('cd control: no event keyed (zzcdterm, src)')
    for k in [('zzsubterm', '.'), ('zzprocsub', 'a.txt'), ('zzbacktick', '.'), ('zzbashc', '.'),
              ('zzto', '.'), ('zzxargs', '<stdin>'), ('zzloop', '$f')]:
        if k not in keys:
            fails.append(f'EXP-002 control: no event keyed {k}')
    if c.get('bash_candidates_main') != 27:  # 20 frozen-case calls + 7 shapes; the sed call is not one
        fails.append(f"bash_candidates_main: expected 27, got {c.get('bash_candidates_main')}")
    print('\n'.join(fails) or 'instrument check PASSED: every expected count holds')
    sys.exit(1 if fails else 0)


if __name__ == '__main__':
    main()
