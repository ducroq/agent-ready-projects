#!/usr/bin/env bash
# Rule 24 — a fetched framework script is checked before it is used (#268).
#
# Usage: fetch-validates.sh <repo-root>
# Violations to stdout; coverage line to stderr. Exit 0 clean, 1 violations, 2 could not run.
#
# An HTTP 200 with an empty or cut-off body runs as a short script and exits 0: a
# taken tag read as free, a broken table as clean. So a line that names a raw
# scripts/ URL must, on that line and in this order:
#   curl ... <url> -o F && tail -n 1 F | grep -q... '<text>' && VAR=F
# and <text> must match the last line of scripts/<name>.sh in THIS repo, and no
# earlier line (a copy cut off there would pass). A text
# that matches nothing makes every adopter's fetch fail; editing a script's last
# line has the same effect, so this rule reads the script too.
# A $ in <text> before its end must be escaped unless -qF: ugrep, which Claude Code
# runs as grep, reads it as an anchor, GNU grep as a literal (#378).
#
# Not seen: a ugrep difference other than $, since matches run GNU grep; another host, a URL built from variables or split across lines, or a
# later line that runs F. A raw URL in prose is reported: link the blob page instead.
set -u
root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: fetch-validates.sh <repo-root>" >&2; exit 2; }
cd "$root" || exit 2
command -v python3 >/dev/null || { echo "rule 24: python3 absent — nothing was checked" >&2; exit 2; }
python3 -I - <<'PY'
import glob, os, re, subprocess, sys
URL = re.compile(r'https://raw\.githubusercontent\.com/[^\s/]+/agent-ready-projects/[^\s/]+/(scripts/[\w./-]+\.sh)')
TOK = r'"?(\$?[\w./~{}-]+)"?'
FORM = re.compile(r'curl\b[^|;&]*\s-o\s+' + TOK + r'\s+&&\s+tail -n 1\s+' + TOK +
                  r"\s+\|\s+grep (-q[FE]?)\s+'([^']+)'\s+&&\s+\w+=" + TOK)
# Anything after the assignment but a closing `; }` or a comment can use F unchecked.
TAIL = re.compile(r'\s*(;\s*\}\s*)?(#.*)?$')
files = sorted(set(glob.glob('templates/**/*.md', recursive=True) + glob.glob('.claude/skills/*/SKILL.md')
                   + [f for f in ('adopt.md', 'README.md', 'docs/GUIDE.md') if os.path.isfile(f)]))
n = bad = 0
def flag(where, msg):
    global bad
    bad += 1
    print(f'{where}: {msg}')
for f in files:
    try:
        lines = open(f, encoding='utf-8').read().splitlines()
    except (OSError, UnicodeDecodeError) as e:
        flag(f, f'could not be read ({e}); not checked'); continue
    for i, line in enumerate(lines, 1):
        urls = URL.findall(line)
        if not urls:
            continue
        n += len(urls); where = f'{f}:{i}'
        if len(urls) > 1:
            flag(where, 'two script fetches on one line; put each on its own line'); continue
        m = FORM.search(line)
        if not m or not URL.search(m.group(0)):
            flag(where, f'fetches {urls[0]} and uses it unchecked; add `tail -n 1 F | grep -q` before the path is assigned'); continue
        if not TAIL.fullmatch(line[m.end():]):
            flag(where, f'more shell follows the assignment of {urls[0]}; it can run the file when the check refused it'); continue
        out, tailed, opt, text, used = m.groups()
        if not (out == tailed == used):
            flag(where, f'saves {out}, checks {tailed}, uses {used}; all three must be the same file'); continue
        if opt != '-qF' and re.search(r'(?<!\\)(?:\\\\)*\$.', text):
            flag(where, 'unescaped $ before the end of the check text; ugrep reads it as an anchor and refuses every fetch (#378). Write \\$ or use -qF'); continue
        if not os.path.isfile(urls[0]):
            flag(where, f'{urls[0]} is not in this repo'); continue
        src = open(urls[0], encoding='utf-8').read().splitlines()
        last = (src[-1] if src else '') + '\n'
        if subprocess.run(['grep', opt, '-e', text], input=last.encode()).returncode:
            flag(where, f'the check text does not match the last line of {urls[0]}, so every fetch would be refused')
        elif subprocess.run(['grep', opt, '-e', text], input=b'\n').returncode == 0:
            flag(where, 'the check text matches an empty line, so it checks nothing')
        else:
            early = [k for k, l in enumerate(src[:-1], 1)
                     if subprocess.run(['grep', opt, '-e', text], input=(l + '\n').encode()).returncode == 0]
            if early:
                flag(where, f'the check text also matches line {early[0]} of {urls[0]}, so a copy cut off there passes')
print(f'  {n} script fetch(es) in {len(files)} file(s)', file=sys.stderr)
if n == 0:
    print('rule 24: no script fetch found — nothing was checked', file=sys.stderr); sys.exit(2)
sys.exit(1 if bad else 0)
PY
