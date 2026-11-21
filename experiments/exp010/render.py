"""EXP-010 renderer (draft; not pinned). See experiments/backlog.md § EXP-010 "Rendering".

    python3 -I render.py render <transcript.jsonl> <out.txt>   # writes the rendered file, prints a JSON summary
    python3 -I render.py pool <dir>                             # eligibility table for every *.jsonl in <dir>

Reads only `user` and `assistant` entries; every other entry type (api-request-blob duplicates,
attachments, mode, titles ...) is ignored. A USER message is human-typed text only: not isMeta
(expanded skills/commands), not a sidechain, not a tool result, not text that opens with a
harness tag (<task-notification>, <command-...>, <local-command-...>, <system-reminder>);
<system-reminder> blocks inside human text are stripped. <pasted_content> counts as the user's.
Everything else that is not assistant text is rendered as TOOL. Thinking blocks are dropped.
Secrets are redacted in place, and counted.
"""
import json, re, sys, os, glob

TOOL_CAP = 2000
HARNESS = ("<task-notification", "<command-", "<local-command", "<system-reminder")
REMINDER = re.compile(r"<system-reminder>.*?</system-reminder>\s*", re.S)
SECRETS = [
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----", re.S),
    re.compile(r"\b(?:sk|pk|rk)-[A-Za-z0-9_-]{20,}"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bxox[abpr]-[A-Za-z0-9-]{10,}"),
    re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
]

def redact(t, tally):
    for rx in SECRETS:
        t, n = rx.subn("[REDACTED]", t)
        tally[0] += n
    return t

def cap(t):
    return t if len(t) <= TOOL_CAP else t[:TOOL_CAP] + f" [... {len(t) - TOOL_CAP} chars cut]"

def as_text(x):
    if isinstance(x, str):
        return x
    if isinstance(x, list):
        return "\n".join(b.get("text", "") if isinstance(b, dict) and b.get("type") == "text"
                         else (f"[{b.get('type')}]" if isinstance(b, dict) else str(b)) for b in x)
    return json.dumps(x)

def messages(path):
    """Yield (role, text) in transcript order, and flag compaction."""
    out, compacted = [], False
    for line in open(path, errors="replace"):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if d.get("isCompactSummary") or (d.get("type") == "system" and "compact" in str(d.get("subtype", ""))):
            compacted = True
        t = d.get("type")
        if t not in ("user", "assistant") or d.get("isSidechain"):
            continue
        m = d.get("message") or {}
        c = m.get("content")
        if t == "assistant":
            for b in c if isinstance(c, list) else [{"type": "text", "text": c or ""}]:
                if b.get("type") == "text" and b.get("text", "").strip():
                    out.append(("ASSISTANT", b["text"]))
                elif b.get("type") == "tool_use":
                    out.append(("TOOL", cap(f"call {b.get('name')}: " + json.dumps(b.get("input", {}), ensure_ascii=False))))
            continue
        blocks = [{"type": "text", "text": c}] if isinstance(c, str) else (c or [])
        for b in blocks:
            if b.get("type") == "tool_result":
                out.append(("TOOL", cap("result: " + as_text(b.get("content")))))
            elif b.get("type") == "text":
                txt = b.get("text", "")
                human = not d.get("isMeta") and not txt.lstrip().startswith(HARNESS)
                if human:
                    txt = REMINDER.sub("", txt).strip()
                    if txt:
                        out.append(("USER", txt))
                elif txt.strip():
                    out.append(("TOOL", cap(txt)))
    return out, compacted

def render(path):
    msgs, compacted = messages(path)
    tally = [0]
    lines = [f"[{i}] {role}: {redact(text, tally)}" for i, (role, text) in enumerate(msgs, 1)]
    body = "\n\n".join(lines) + "\n"
    return body, {"messages": len(msgs), "user_messages": sum(r == "USER" for r, _ in msgs),
                  "bytes": len(body.encode()), "est_tokens": len(body) // 4,
                  "compacted": compacted, "redactions": tally[0]}

def main(argv):
    if len(argv) == 4 and argv[1] == "render":
        body, info = render(argv[2])
        open(argv[3], "w").write(body)
        print(json.dumps(info))
    elif len(argv) == 3 and argv[1] == "pool":
        rows = []
        for f in sorted(glob.glob(os.path.join(argv[2], "*.jsonl"))):
            _, info = render(f)
            info["eligible"] = (not info["compacted"]) and 40000 <= info["est_tokens"] <= 150000
            rows.append(info)
        print(json.dumps({"transcripts": len(rows), "compacted": sum(r["compacted"] for r in rows),
                          "eligible": sum(r["eligible"] for r in rows),
                          "est_ktokens_sorted": sorted(r["est_tokens"] // 1000 for r in rows)}))
    else:
        sys.exit(__doc__)

if __name__ == "__main__":
    main(sys.argv)
