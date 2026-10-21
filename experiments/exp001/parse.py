#!/usr/bin/env python3
"""EXP-001 runner: count cross-session repeat searches in Claude Code transcripts.

Implements experiments/backlog.md § EXP-001 as frozen. Every rule below cites the
backlog phrase it implements; a rule the backlog does not state is marked CHOICE.

Usage:
  parse.py --projects <dir> --cutoff <ISO> --artifact <out.json> --raw <out.jsonl>

The artifact holds aggregates only (repos anonymized); --raw holds per-event rows
with repo paths and terms and must stay in the lab, never in the repo.
"""
import argparse, glob, json, os, re, shlex, subprocess, sys
from collections import defaultdict
from datetime import datetime

SEARCH_WORD = re.compile(r'(?<![\w-])(grep|rg|find)(?![\w-])')
SEPARATORS = {'&&', '||', ';', '|', '|&', '&', ';;'}
# Backlog: "flags dropped together with their values"
GREP_VALUE_FLAGS = {'-A', '-B', '-C', '-m', '-e', '-f', '-g', '-t', '-T', '--glob', '--type',
                    '--type-not', '--max-count', '--context', '--after-context',
                    '--before-context', '--regexp', '--file', '--include', '--exclude',
                    '--exclude-dir'}
FIND_TERM_PREDICATES = {'-name', '-iname', '-path', '-ipath'}
FIND_NOARG = {'-print', '-print0', '-delete', '-ls', '-quit', '-empty', '-prune', '-o', '-or',
              '-a', '-and', '-not', '!', '(', ')', '-depth', '-follow', '-xdev', '-mount',
              '-true', '-false', '-readable', '-writable', '-executable'}
# CHOICE: shell words that can lead a segment without being the command.
LEAD_SKIP = {'do', 'then', 'else', 'elif', 'if', 'while', 'until', 'time', 'sudo', 'command',
             'nohup', '!', '{', '(', 'env', 'exec'}
REDIRECTS = {'>', '>>', '<', '>&', '&>', '<<<', '2>', '2>>', '>|'}


def strip_heredocs(cmd):
    """CHOICE: drop heredoc bodies so code inside `python3 - <<EOF` is not parsed as shell."""
    out, delim = [], None
    for line in cmd.split('\n'):
        if delim is not None:
            if line.strip() == delim:
                delim = None
            continue
        m = re.search(r"<<-?\s*['\"]?(\w+)['\"]?", line)
        if m:
            delim = m.group(1)
            line = line[:m.start()]
        out.append(line)
    return ' ; '.join(out)


def extract_subs(cmd):
    """EXP-002: pull $( ), <( ), >( ) and backtick bodies out as separate commands.

    Returns (outer, inners): outer has each body replaced by a placeholder word.
    Nothing is extracted inside single quotes.
    """
    out, inners, i, q = [], [], 0, None
    while i < len(cmd):
        ch = cmd[i]
        if q:
            out.append(ch)
            if ch == q:
                q = None
            i += 1
            continue
        if ch == "'":
            q = ch; out.append(ch); i += 1
            continue
        if ch in '$<>' and cmd[i + 1:i + 2] == '(' and cmd[i + 2:i + 3] != '(':
            depth, j, sq = 1, i + 2, False
            while j < len(cmd) and depth:
                c = cmd[j]
                if c == "'":
                    sq = not sq
                elif not sq and c == '(':
                    depth += 1
                elif not sq and c == ')':
                    depth -= 1
                j += 1
            inners.append(cmd[i + 2:j - 1]); out.append(' __SUB__ '); i = j
            continue
        if ch == '`':
            j = cmd.find('`', i + 1)
            if j > i:
                inners.append(cmd[i + 1:j]); out.append(' __SUB__ '); i = j + 1
                continue
        out.append(ch); i += 1
    return ''.join(out), inners


def tokenize(cmd):
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=';&|<>()')
    lex.whitespace_split = True
    return list(lex)


def segments(tokens):
    """Split on && ; || | (backlog). Yields (tokens, fed_by_pipe)."""
    cur, fed = [], False
    for t in tokens:
        if t in SEPARATORS:
            if cur:
                yield cur, fed
            fed, cur = (t in ('|', '|&')), []
            continue
        cur.append(t)
    if cur:
        yield cur, fed


def drop_redirects(seg):
    out, skip = [], False
    for t in seg:
        if skip:
            skip = False
            continue
        if t in REDIRECTS or re.fullmatch(r'\d?[<>]{1,2}&?', t):
            if out and out[-1].isdigit():
                out.pop()
            skip = True
            continue
        out.append(t)
    return out


def parse_grep_args(args):
    """Return (term, paths). Backlog: first positional after dropping flags+values is the term."""
    pos, skip, end_of_flags = [], False, False
    for a in args:
        if skip:
            skip = False
            continue
        if not end_of_flags and a == '--':
            end_of_flags = True
            continue
        if not end_of_flags and a.startswith('-') and len(a) > 1:
            if '=' in a:
                continue
            if a in GREP_VALUE_FLAGS:
                skip = True
            continue
        pos.append(a)
    if not pos:
        return None, []
    return pos[0], pos[1:]


def parse_find_args(args):
    paths, term, i = [], None, 0
    while i < len(args) and not args[i].startswith('-') and args[i] not in ('(', '!'):
        paths.append(args[i]); i += 1
    while i < len(args):
        a = args[i]
        if a in FIND_TERM_PREDICATES and i + 1 < len(args):
            if term is None:
                term = args[i + 1]
            i += 2
        elif a in FIND_NOARG or not a.startswith('-'):
            i += 1
        elif a == '-exec' or a == '-execdir':
            while i < len(args) and args[i] not in (';', '+', '\\;'):
                i += 1
            i += 1
        else:
            i += 2  # every other predicate takes one value
    return term, paths or ['.']


SEARCH_CMDS = {'grep', 'egrep', 'fgrep', 'rg', 'find'}


def is_candidate(cmd, depth=0):
    """EXP-002: a call is a candidate when a search command is an unquoted shell word."""
    outer, inners = extract_subs(strip_heredocs(cmd) if depth == 0 else cmd)
    try:
        toks = tokenize(outer)
    except ValueError:
        return SEARCH_WORD.search(outer) is not None  # cannot tell; count it
    if any(os.path.basename(t) in SEARCH_CMDS for t in toks):
        return True
    for t_i, t in enumerate(toks):  # bash -c '<cmd>' carries its command as one word
        if t == '-c' and t_i and os.path.basename(toks[t_i - 1]) in ('bash', 'sh', 'zsh') \
                and t_i + 1 < len(toks) and is_candidate(toks[t_i + 1], depth + 1):
            return True
    return any(is_candidate(x, depth + 1) for x in inners)


def bash_events(cmd, cwd, depth=0):
    """Return (events, parse_ok). An event is (term or None, abs_path)."""
    outer, inners = extract_subs(strip_heredocs(cmd) if depth == 0 else cmd)
    try:
        toks = tokenize(outer)
    except ValueError:
        return [], False
    events, here, ok = [], cwd, True
    for inner in inners:  # EXP-002: substitutions are searched from the call's directory
        e, o = bash_events(inner, cwd, depth + 1)
        events += e; ok = ok and o
    for seg, fed in segments(toks):
        seg = drop_redirects(seg)
        seg = skip_lead(seg)
        if not seg:
            continue
        if os.path.basename(seg[0]) in ('bash', 'sh', 'zsh') and '-c' in seg:  # EXP-002
            i = seg.index('-c')
            if i + 1 < len(seg):
                e, o = bash_events(seg[i + 1], here, depth + 1)
                events += e; ok = ok and o
            continue
        if seg[0] == 'cd':  # backlog: skip a leading `cd <dir>`; CHOICE: it moves later segments
            here = os.path.normpath(os.path.join(here, seg[1])) if len(seg) > 1 else here
            continue
        if seg[0] == 'xargs':
            i = 1
            while i < len(seg) and seg[i].startswith('-'):
                i += 2 if seg[i] in ('-I', '-n', '-P', '-d', '-L', '-a') else 1
            seg, fed = skip_lead(seg[i:]), True
            if not seg:
                continue
        base, args = os.path.basename(seg[0]), seg[1:]
        if base == 'git':
            gdir = here
            while args and args[0].startswith('-'):
                if args[0] == '-C' and len(args) > 1:
                    gdir = os.path.normpath(os.path.join(here, args[1])); args = args[2:]
                elif args[0] in ('-c',) and len(args) > 1:
                    args = args[2:]
                else:
                    args = args[1:]
            if not args or args[0] != 'grep':
                continue
            term, paths = parse_grep_args(args[1:])
            events += [(term, os.path.normpath(os.path.join(gdir, p))) for p in (paths or ['.'])]
        elif base in ('grep', 'egrep', 'fgrep', 'rg'):
            term, paths = parse_grep_args(args)
            if not paths:
                paths = ['<stdin>'] if fed else ['.']  # CHOICE: grep/rg after a pipe read stdin
            events += [(term, p if p == '<stdin>' else os.path.normpath(os.path.join(here, p)))
                       for p in paths]
        elif base == 'find':
            term, paths = parse_find_args(args)
            events += [(term, os.path.normpath(os.path.join(here, p))) for p in paths]
    return events, ok


def skip_lead(seg):
    """Drop words that lead a segment without being its command (EXP-002 adds timeout, watch)."""
    while seg:
        if seg[0] in LEAD_SKIP or re.fullmatch(r'\w+=\S*', seg[0]):
            seg = seg[1:]
        elif seg[0] in ('timeout', 'watch'):
            seg = seg[1:]
            while seg and (seg[0].startswith('-') or re.fullmatch(r'[\d.]+[smhd]?', seg[0])):
                seg = seg[2:] if seg[0] in ('-n', '-s', '-k', '--signal') else seg[1:]
        else:
            break
    return seg


_root_cache = {}


def repo_root(cwd):
    """Backlog: git toplevel of the call's cwd, worktrees mapped to their main repo."""
    if cwd in _root_cache:
        return _root_cache[cwd]
    root = None
    if cwd and os.path.isdir(cwd):
        r = subprocess.run(['git', '-C', cwd, 'rev-parse', '--path-format=absolute',
                            '--git-common-dir'], capture_output=True, text=True)
        if r.returncode == 0:
            common = r.stdout.strip()
            root = os.path.dirname(common) if os.path.basename(common) == '.git' else None
            if root is None:  # bare or unusual layout: fall back to toplevel
                t = subprocess.run(['git', '-C', cwd, 'rev-parse', '--show-toplevel'],
                                   capture_output=True, text=True)
                root = t.stdout.strip() or None
    _root_cache[cwd] = root
    return root


def norm_key(term, path, root):
    """Backlog: lowercased, quotes stripped, path relative to the repo root."""
    t = term.strip('\'"').lower()
    # EXP-002: resolve symlinks on both sides, or a symlinked cwd yields ../../ keys
    p = path if path == '<stdin>' else os.path.relpath(os.path.realpath(path), os.path.realpath(root))
    return t, p


def has_term(term):
    """Backlog: a bare `find .` or a Glob with only a wildcard has no term."""
    return term is not None and re.search(r'[A-Za-z0-9]', term) is not None


def load(projects, cutoff_ts):
    calls, results, seen = {}, {}, set()
    files = [(f, False) for f in glob.glob(os.path.join(projects, '*', '*.jsonl'))]
    files += [(f, True) for f in glob.glob(os.path.join(projects, '*', '*', 'subagents', '*.jsonl'))]
    nfiles = 0
    for f, sub in sorted(files):
        if os.path.getmtime(f) >= cutoff_ts:
            continue
        nfiles += 1
        for line in open(f, errors='replace'):
            try:
                o = json.loads(line)
            except ValueError:
                continue
            content = (o.get('message') or {}).get('content')
            if not isinstance(content, list):
                continue
            for b in content:
                if not isinstance(b, dict):
                    continue
                if b.get('type') == 'tool_use' and b.get('id') not in calls:
                    # backlog: deduplicated on tool_use_id
                    calls[b['id']] = dict(name=b.get('name'), input=b.get('input') or {},
                                          session=o.get('sessionId'), cwd=o.get('cwd'),
                                          ts=o.get('timestamp'), sub=sub)
                elif b.get('type') == 'tool_result' and b.get('tool_use_id') not in results:
                    results[b['tool_use_id']] = len(json.dumps(b.get('content'), ensure_ascii=False))
    return calls, results, nfiles


def events_from(calls, results):
    ev, stats = [], defaultdict(int)
    for cid, c in calls.items():
        name, inp, cwd = c['name'], c['input'], c['cwd']
        root = repo_root(cwd)
        if name == 'Bash':
            cmd = inp.get('command') or ''
            if not is_candidate(cmd):
                continue
            raw, ok = bash_events(cmd, cwd or '/')
            if not raw:
                stats['unparsed_main' if not c['sub'] else 'unparsed_sub'] += 1
            stats['bash_candidates_main' if not c['sub'] else 'bash_candidates_sub'] += 1
        elif name == 'Grep':
            raw = [(inp.get('pattern'), os.path.normpath(os.path.join(cwd or '/', inp.get('path') or '.')))]
        elif name == 'Glob':
            raw = [(inp.get('pattern'), os.path.normpath(os.path.join(cwd or '/', inp.get('path') or '.')))]
        else:
            continue
        if root is None:
            stats['dropped_no_repo'] += len(raw)
            continue
        share = results.get(cid, 0) / max(len(raw), 1)  # CHOICE: a call's bytes split over its events
        for term, path in raw:
            if not has_term(term):
                stats['excluded_no_term_main' if not c['sub'] else 'excluded_no_term_sub'] += 1
                continue
            ev.append(dict(repo=root, session=c['session'], ts=c['ts'], sub=c['sub'],
                           key=norm_key(term, path, root), bytes=share, id=cid))
    return ev, stats


def mark_repeats(ev):
    """Backlog: a repeat is an occurrence in a session after the first session that used the key."""
    first = {}
    for e in sorted(ev, key=lambda e: e['ts'] or ''):
        k = (e['repo'], e['key'])
        if k not in first:
            first[k] = e['session']
            e['repeat'] = False
            e['within'] = False
        else:
            e['repeat'] = e['session'] != first[k]
            e['within'] = e['session'] == first[k]
    return ev


def git_text_before(repo_dir, paths_glob, ts):
    """Text of tracked files at the last commit before ts, or None if no such commit."""
    r = subprocess.run(['git', '-C', repo_dir, 'log', '-1', '--format=%H', f'--before={ts}'],
                       capture_output=True, text=True)
    h = r.stdout.strip()
    if r.returncode != 0 or not h:
        return None
    ls = subprocess.run(['git', '-C', repo_dir, 'ls-tree', '-r', '--name-only', h],
                        capture_output=True, text=True).stdout.split('\n')
    want = [p for p in ls if any(re.fullmatch(g, p) for g in paths_glob)]
    if not want:
        return None
    return '\n'.join(subprocess.run(['git', '-C', repo_dir, 'show', f'{h}:{p}'],
                                    capture_output=True, text=True).stdout for p in want)


_cov_cache = {}


def memory_before(repo, session_start):
    """Backlog: project file and any memory/ with its own git history, at the last commit before."""
    k = (repo, session_start)
    if k not in _cov_cache:
        parts = [git_text_before(repo, [r'CLAUDE\.md', r'AGENTS\.md'], session_start)]
        mem = os.path.join(repo, 'memory')
        if os.path.isdir(os.path.join(mem, '.git')):
            parts.append(git_text_before(mem, [r'[^/]+\.md'], session_start))
        parts = [p for p in parts if p is not None]
        _cov_cache[k] = '\n'.join(parts) if parts else None
    return _cov_cache[k]


def coverable(term):
    """Backlog: at least 5 characters, not a bare path or glob."""
    return (len(term) >= 5 and not re.search(r'[/*?\[\]]', term)
            and not re.fullmatch(r'[\w.-]+\.[A-Za-z0-9]{1,5}', term))


def covered(term, text):
    """Backlog: the term appears as a whole token."""
    return re.search(r'(?<![A-Za-z0-9_])' + re.escape(term) + r'(?![A-Za-z0-9_])', text,
                     re.IGNORECASE) is not None


def analyse(ev, stats):
    sessions = defaultdict(set)
    starts = {}
    for e in ev:
        sessions[e['repo']].add(e['session'])
        s = starts.get(e['session'])
        if e['ts'] and (s is None or e['ts'] < s):
            starts[e['session']] = e['ts']
    # backlog: repos with fewer than 5 sessions are dropped (CHOICE: sessions with a search event)
    keep = {r for r, s in sessions.items() if len(s) >= 5}
    total = sum(len(sessions[r]) for r in keep)
    big = [r for r in keep if len(sessions[r]) * 2 > total]
    names = {r: f'R{i + 1}' for i, r in enumerate(sorted(keep, key=lambda r: -len(sessions[r])))}

    def figures(rows):
        main = [e for e in rows if not e['sub']]
        sub = [e for e in rows if e['sub']]
        rep = [e for e in main if e['repeat']]
        cov_n = cov_y = 0
        hist_repos = set()
        for e in rep:
            term = e['key'][0]
            if not coverable(term):
                e['coverage'] = 'uncoverable'
                continue
            text = memory_before(e['repo'], starts.get(e['session']))
            if text is None:
                e['coverage'] = 'no_history'
                continue
            hist_repos.add(e['repo'])
            cov_n += 1
            e['coverage'] = 'covered' if covered(term, text) else 'uncovered'
            cov_y += e['coverage'] == 'covered'
        all_b = sum(e['bytes'] for e in main)
        return dict(
            sessions=len({e['session'] for e in main}),
            events=len(main), repeats=len(rep),
            within_session_repeats=sum(e['within'] for e in main if e.get('within')),
            coverable_repeats=cov_n, covered_repeats=cov_y,
            uncoverable_repeats=sum(e.get('coverage') == 'uncoverable' for e in rep),
            repos_with_history=len(hist_repos),
            M1=round(len(rep) / len(main), 4) if main else None,
            M2=round(cov_y / cov_n, 4) if cov_n else None,
            M3=round(sum(e['bytes'] for e in rep) / all_b, 4) if all_b else None,
            subagent_events=len(sub), subagent_repeats=sum(e['repeat'] for e in sub))

    pooled = [e for e in ev if e['repo'] in keep and e['repo'] not in big]
    out = dict(pooled=figures(pooled),
               separate={names[r]: figures([e for e in ev if e['repo'] == r]) for r in big},
               per_repo={names[r]: figures([e for e in ev if e['repo'] == r])
                         for r in sorted(keep, key=lambda r: names[r])},
               repos_kept=len(keep), repos_dropped_under_5_sessions=len(sessions) - len(keep))
    cand = stats.get('bash_candidates_main', 0)
    out['unparsed_share_main'] = round(stats.get('unparsed_main', 0) / cand, 4) if cand else None
    out['counts'] = dict(stats)
    return out, names


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--projects', default=os.path.expanduser('~/.claude/projects'))
    ap.add_argument('--cutoff', required=True)
    ap.add_argument('--artifact', required=True)
    ap.add_argument('--raw', required=True)
    a = ap.parse_args()
    cutoff = datetime.fromisoformat(a.cutoff).timestamp()
    calls, results, nfiles = load(a.projects, cutoff)
    ev, stats = events_from(calls, results)
    ev = mark_repeats(ev)
    out, names = analyse(ev, stats)
    out = dict(experiment='EXP-001', cutoff=a.cutoff, transcript_files=nfiles,
               tool_calls=len(calls), **out)
    with open(a.artifact, 'w') as f:
        json.dump(out, f, indent=2)
    with open(a.raw, 'w') as f:
        for e in ev:
            f.write(json.dumps(dict(e, repo_name=names.get(e['repo']))) + '\n')
    json.dump(out, sys.stdout, indent=2)


if __name__ == '__main__':
    main()
