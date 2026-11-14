"""Seeded cases for render.py. Run: python3 -I fixture.py  (exit 0 = all behaved)."""
import json, os, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render

E = [
 {"type": "user", "message": {"content": "please fix the build <system-reminder>noise</system-reminder>"}},
 {"type": "user", "isMeta": True, "message": {"content": [{"type": "text", "text": "SKILL BODY expanded"}]}},
 {"type": "user", "message": {"content": "<task-notification>agent done</task-notification>"}},
 {"type": "user", "message": {"content": "<command-name>/curate</command-name>"}},
 {"type": "user", "isSidechain": True, "message": {"content": "subagent prompt"}},
 {"type": "user", "message": {"content": "<pasted_content id=x>log text</pasted_content> see this"}},
 {"type": "assistant", "message": {"content": [{"type": "thinking", "thinking": "SECRET THOUGHT"},
   {"type": "text", "text": "On it."}, {"type": "tool_use", "name": "Bash", "input": {"command": "make"}}]}},
 {"type": "user", "message": {"content": [{"type": "tool_result", "content": "x" * 5000}]}},
 {"type": "api-request-blob", "message": {"content": [{"type": "text", "text": "DUPLICATE"}]}},
 {"type": "user", "message": {"content": "key sk-abcdefghijklmnopqrstuvwxyz123 and me@example.org"}},
 {"type": "system", "subtype": "compact_boundary"},
]
fd, p = tempfile.mkstemp(suffix=".jsonl"); os.close(fd)
open(p, "w").write("\n".join(json.dumps(e) for e in E))
body, info = render.render(p); os.remove(p)
users = [l for l in body.split("\n\n") if " USER: " in l]
checks = {
 "human text kept, reminder stripped": any("please fix the build" in u and "noise" not in u for u in users),
 "isMeta skill body is not USER": not any("SKILL BODY" in u for u in users),
 "task-notification is not USER": not any("agent done" in u for u in users),
 "command tag is not USER": not any("/curate" in u for u in users),
 "sidechain dropped": "subagent prompt" not in body,
 "pasted content is USER": any("log text" in u for u in users),
 "thinking dropped": "SECRET THOUGHT" not in body,
 "assistant text kept": "ASSISTANT: On it." in body,
 "tool call rendered": "call Bash" in body,
 "tool result capped": "chars cut]" in body and "x" * 2001 not in body,
 "api-request-blob ignored": "DUPLICATE" not in body,
 "secrets redacted": "sk-abc" not in body and "example.org" not in body and info["redactions"] == 2,
 "compaction flagged": info["compacted"] is True,
 "user count": info["user_messages"] == 3,
}
bad = [k for k, ok in checks.items() if not ok]
for k in checks: print(("FAIL " if k in bad else "ok   ") + k)
sys.exit(1 if bad else 0)
