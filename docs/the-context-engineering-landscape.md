---
title: "The Context Engineering Landscape"
subtitle: "Who's building what for AI coding agents — and what nobody's building yet"
author: Jeroen Veen
date: 2026-09-12
supersedes: 2026-04-14 draft
status: verified
---

# The Context Engineering Landscape

> **Second edition, 2026-09-12.** The April draft was five months stale and, more
> importantly, **wrong in ways a reader could not have detected.** Everything below was
> re-verified before publication. What the verification found, including four errors in the
> previous edition, is in *Corrections* — first, rather than in a footnote, because the class
> of error matters more than any individual number.

## How this edition was verified

Stated up front so a reader can judge the claims, and so the next edition knows what to re-run.

| Claim type | Instrument | Date |
|---|---|---|
| Repo popularity and liveness | `gh api repos/<owner>/<name>` — stars, `pushed_at`, license, commit count | 2026-09-12 |
| Repo existence | same call; a `404` is recorded as **dead link**, not silently dropped | 2026-09-12 |
| Paper identity | fetched `arxiv.org/abs/<id>`; title, author list and submission date read off the abstract page | 2026-09-12 |
| Standards governance | `agents.md` and the Linux Foundation press release | 2026-09-12 |

⚠️ **One instrument failed and nearly produced a false result, which is worth recording.** The
first pass queried `export.arxiv.org/api/query`, which returned **empty for every paper**,
including ones certain to exist. Read at face value that says *"five of the cited papers do not
exist."* A control — arXiv 1706.03762, *Attention Is All You Need* — returned empty too, which
is what exposed the instrument rather than the papers. `arxiv.org` itself answered HTTP 200
throughout; only the API host was unreachable. **A negative from a broken instrument is
indistinguishable from a real absence**, and the only thing that separated them here was running
a case whose answer was known in advance.

⚠️ **Not verified, and named so it is not read as verified**: the *content* of the memory-system
benchmark scores below (LoCoMo, LongMemEval). Those are each project's self-reported numbers on
their own README. No independent replication was attempted, and benchmark scores self-reported by
the system being benchmarked are the weakest evidence class on this page.

## Corrections to the April 2026 edition

**1. Three of the four research citations named the wrong author.** The arXiv identifiers were
correct and the paper contents were roughly right; the surnames were not.

| April edition said | Actual first author |
|---|---|
| "Rombaut et al. — Impact of AGENTS.md" | **Jai Lal Lulla** et al. |
| "Li et al. — Externalization in LLM Agents" | **Chenyu Zhou** et al. |
| "Zhang et al. — Memory for Autonomous LLM Agents" | **Pengfei Du** et al. |
| "Gloaguen et al. — Evaluating AGENTS.md" | Thibaud Gloaguen — ✅ correct |

This is the characteristic shape of a fabricated attribution: a real paper, a correct identifier,
a plausible-sounding surname, and a summary close enough that nothing reads as wrong. **A citation
that resolves is not a citation that was checked.**

**2. Every popularity figure was stale by a factor of 2–3**, and the April draft gave no measurement
date for any of them, so a reader had no way to know how much to discount. Figures in this edition
carry the date at the top of the table.

**3. Four cited projects return 404** and were presented as live tooling: `AgentEval/AgentEval`,
`Jinjos/vibe-cli`, `Rule-Porter/Rule-Porter`, `cso1z/OMEGA`. Whether they were renamed, made
private, or never existed at the given paths is not determinable now — which is the argument for
recording the check date beside the link.

**4. 🔴 The central empirical claim was overstated, and its numbers are not in the paper.** April
said the ETH Zurich study found LLM-generated context files *"reduced task success by 3%"* and
human-written ones *"improved success by 4% but increased inference costs by 19%."*

Both abstracts were pulled verbatim and checked (`curl` on `arxiv.org/abs/2602.11988` and `…v1`,
2026-09-12):

| | v1 — 12 Feb 2026 | v2 — 23 Jun 2026 |
|---|---|---|
| success | context files *"tend to **reduce** task success rates compared to providing no repository context"* | *"does **not generally improve** task success rates"* |
| cost | *"increasing inference cost by over **20%**"* | *"increasing inference cost by over **20%** on average"* |
| abstract contains "4%" / "19%" | **no** / **no** | **no** / **no** |
| **body** contains them | **YES** — *"an increase of 4% on average"*, *"a decrease of 3% on average"*, *"at most 19%"* | **superseded** — *"improve agent performance by 2.4% on average (p = 21%)"*, cost *"20% and 23%"* at *"p-value < 0.001%"* |

⚠️ **This section was wrong twice before it was right, and both drafts are recorded because the
pattern is the lesson.** Draft 1 said the favourable finding *"did not survive revision"* — asserted
without reading v1. Draft 2 then over-corrected: it said the 4% and 19% figures *"appear in neither
abstract"* and that the full text *"was not checked"*, implying they might be invented. **Both drafts
argued about numbers nobody had looked up.** The full text of both versions was then retrieved
(`curl https://arxiv.org/html/2602.11988v1` and `…v2`) and settles it:

**The April figures were real, exact, and correctly located in the v1 body.** The April edition did
not invent them — unlike the three author names beside them. **But v2 supersedes all three, and the
supersession is the finding**: the developer-provided improvement drops from *"an increase of 4% on
average"* to *"2.4% on average (p = 21%)"* — **not statistically significant** — while the cost
increase holds at 20–23% with *"p-value < 0.001%"*. v2 also renames the second benchmark AGENTbench
→ CTXbench. So draft 1's instinct was right (the favourable half did not survive) and its reasoning
was not: the number survived and its **significance** did not.

**The finding that actually stands is still the hardest available result for the premise of this
document**: across both versions, context files cost over 20% more and do not improve task success.
Restated under *The research* below.

## The frameworks

Stars and last-push measured **2026-09-12**. Star counts are a popularity proxy and nothing more —
they are included because the April edition led with them, and dropping them silently would hide
how badly they moved.

| Project | Stars | Last push | What it prescribes |
|---|---|---|---|
| [Superpowers](https://github.com/obra/superpowers) | 285,516 | 2026-09-12 | Workflow discipline: brainstorming, worktree isolation, plan decomposition, two-stage review, mandatory TDD. *How the agent works* — not what it knows between sessions |
| [OpenCode](https://github.com/anomalyco/opencode) | 206,817 | 2026-09-12 | Go terminal agent, dynamic rule injection via `.md`/`.mdc` |
| [spec-kit](https://github.com/github/spec-kit) | 135,869 | 2026-09-12 | Spec-Driven Development. Covers pre-implementation; stops before session context and memory |
| [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | 52,930 | 2026-09-12 | Maximalist: a full AI-driven agile methodology |
| [Context Hub](https://github.com/andrewyng/context-hub) | 13,970 | **2026-05-31** | API docs with agent annotations. ⚠️ No push in 3½ months |

⚠️ **The April claim that none of these carries cross-session memory is WRONG for spec-kit, and this
edition nearly repeated it unchecked.** spec-kit ships `.specify/memory/constitution.md`: a
*ratified, semver-versioned* project-principles document whose header carries a **SYNC IMPACT
REPORT** naming every template reviewed for alignment when the constitution changed, plus
`docs/concepts/spec-persistence.md`, which addresses what happens to artifacts as requirements move.
That is durable project context with a drift-propagation mechanism attached — independently arrived
at, and closer to this framework's project-file-plus-ADR design than anything else on this page.

What spec-kit does **not** carry is *session* memory: no journal, no gotcha capture, no
cross-session state, no learning loop. That is the distinction the April edition blurred by calling
the whole category memoryless.

⚠️ **Superpowers: hedged, because the instrument is weak.** A recursive path-name scan of its tree
for `memor|persist|context` returns **0 matches** — but a skill could implement session memory
without those words in a filename, so this is evidence of absence only at the level of naming. Read
as *"no memory subsystem is advertised in its file layout"*, not as *"it has none."* BMAD returns
1 such path, unexamined.

## The closest relatives

New section, and the one worth the most attention: the April edition had no comparison against
work in the same shape as this framework, only against much larger projects doing different things.

### The Memory Bank family

The real relative is not a repository, it is a **pattern**: [Cline's Memory
Bank](https://docs.cline.bot/prompting/cline-memory-bank) (Cline itself: 67,863 stars, pushed
2026-09-12). A structured set of markdown files that an agent reads at session start and updates at
session end, driven by instructions in `.clinerules` or `AGENTS.md`. Cline's own documentation is
explicit that it is *a methodology using custom instructions and docs, not a fixed feature* — which
makes it the same category of thing as this framework, and the one with by far the widest reach.

Typical Memory Bank layout: a product/purpose file, an active-context file, a system-architecture
file, a progress journal. **That is this framework's Layer 1 and Layer 3, and nothing else.**

### [agent-markdown-memory-bank-protocol](https://github.com/rtoma/agent-markdown-memory-bank-protocol)

A one-person port of the Memory Bank pattern onto `AGENTS.md`. Measured 2026-09-12:

| | |
|---|---|
| Stars / forks | **6** / 1 |
| Commits | **2** (2026-03-27, 2026-03-29) |
| Last push | **2026-03-29** — dormant 5½ months |
| Total size | **~4.3 KB** across 6 files |
| License | **none** |

It is a weekend sketch, and reading it is still worth the ten minutes. The whole protocol is a
1.6 KB `AGENTS.md` prescribing: read three files before a task, update the architecture file during,
append a timestamped entry and refresh next-steps after, and confirm to the user. It ends with a
*"Mandatory Completion Checklist"* — which is `/curate`, in three bullet points.

⚠️ **One detail in it is a genuine convergent invention.** It instructs the agent to run
`date '+%Y-%m-%d %H:%M'` *"instead of guessing"* the timestamp. That is the same instinct as this
framework's verification-command embedding — don't let the model assert a fact it can cheaply
check — arrived at independently, in one line, for the one fact this protocol records.

### Head-to-head

| | Memory Bank / rtoma protocol | agent-ready-projects |
|---|---|---|
| Instruction file (Layer 1) | ✅ | ✅ |
| Structured memory directory (Layer 3) | ✅ | ✅ |
| Task-triggered reads ("before X, read Y") | ✅ | ✅ |
| End-of-session update discipline | ✅ (a checklist) | ✅ (`/curate`, a 70 KB skill) |
| Timestamp verified rather than guessed | ✅ (one line) | ✅ (generalised to arbitrary claims) |
| **Verification commands embedded in memory** | ❌ | ✅ |
| **Gotcha log → pattern promotion loop** | ❌ | ✅ |
| **Review finding → mechanical check promotion** | ❌ | ✅ (v1.41.0) |
| **Size budgets on the loaded surface** | ❌ | ✅ (lint rule 8) |
| **Structural self-tests / seeded-defect fixtures** | ❌ | ✅ (13 rules, 16 fixtures) |
| **Framework-drift triage for adopters** | ❌ | ✅ (`/update-drift`) |
| Adopter-facing bytes | **~4.3 KB** | **238 KB** templates + 347 KB docs |
| Maintained | ❌ dormant since March | ✅ |

⚠️ **This table compares against the Memory Bank family only, not against the landscape.** Several
rows would look different against spec-kit, which has versioned project principles and a
sync-impact mechanism of its own. Read it as "what the extra bytes buy over a Memory Bank", which
is the comparison a reader choosing between the two actually faces.

**The ratio is ~55×, and that is the finding, not a boast.** Everything in the bottom half of that
table is what the extra 234 KB buys. Whether it is worth it is exactly the question issue #126 is
open on, and exactly what the ETH Zurich result below puts pressure on. A reader deciding between
the two should note that the top half — the part both have — is the part with published evidence
behind it.

## The standards

**[AGENTS.md](https://agents.md/)** is stewarded by the **Agentic AI Foundation under the Linux
Foundation**, alongside Anthropic's MCP and Block's goose (AAIF formed December 2025). Verified on
`agents.md` 2026-09-12: **"used by over 60k open-source projects."** The AAIF now reports **146
members** and 8 platinum sponsors — AWS, Anthropic, Block, Bloomberg, Cloudflare, Google, Microsoft,
OpenAI. Supported by Codex, Jules, Gemini CLI, Cursor, VS Code, Zed, Aider, goose, Devin, Copilot's
coding agent, JetBrains Junie, Windsurf, RooCode and others.

The standard says *where* to put instructions. It still does not say *what* to put in them.

**[Agent Skills](https://agentskills.io/)** standardizes portable skills: YAML frontmatter plus
markdown body. The format for skills, not a guide for composing them.

## The memory systems

⚠️ **Scores below are self-reported by each project.** Not independently replicated; treat as
positioning, not measurement. Stars measured 2026-09-12.

| System | Stars | Last push | Claim |
|---|---|---|---|
| [Mem0](https://github.com/mem0ai/mem0) | 65,156 | 2026-09-11 | Drop-in memory infrastructure |
| [Graphiti](https://github.com/getzep/graphiti) | 30,825 | 2026-09-11 | Real-time knowledge graphs |
| [Letta](https://github.com/letta-ai/letta) | 24,704 | 2026-09-10 | Stateful agents, MemGPT lineage |
| [Memori](https://github.com/MemoriLabs/Memori) | 16,642 | 2026-09-03 | SQL-native, LLM-agnostic |
| [MemOS](https://github.com/MemTensor/MemOS) | 11,292 | 2026-09-09 | "Skill memory" — crystallizes successful executions |
| [SimpleMem](https://github.com/aiming-lab/SimpleMem) | 3,754 | 2026-07-24 | Simpler architecture, better recall |
| [MemMachine](https://github.com/MemMachine/MemMachine) | 3,219 | 2026-09-11 | Graph + SQL + working memory |

**OMEGA is dropped from this edition**: `cso1z/OMEGA` returns 404 as of 2026-09-12.

**The April gap claim survives verification and is the important one.** All of these optimize
**recall** — can the system retrieve what it stored? None verify **truth** — is what was stored
still accurate? LoCoMo and LongMemEval measure retrieval accuracy, not factual accuracy, so a system
that perfectly retrieves a memory saying "deployed to production" months after a rollback scores as
well as one that retrieves a current fact. MemOS's skill-memory remains the nearest thing to a
learning loop.

## The context tooling

| Tool | Stars | Last push | Note |
|---|---|---|---|
| [ctxlint](https://github.com/YawLabs/ctxlint) | **10** | 2026-09-12 | Checks context files against the codebase; catches stale references |
| [cclint](https://github.com/carlrannaberg/cclint) | 22 | **2025-09-10** | ⚠️ No push in 12 months |
| [rulesync](https://github.com/dyoshikawa/rulesync) | 1,417 | 2026-09-12 | Syncs `.rulesync/*.md` across Claude Code, Cursor, Gemini CLI, Copilot |
| [context-mode](https://github.com/mksglu/context-mode) | 22,251 | 2026-09-11 | Context reduction via MCP sandboxing |

**Dead as of 2026-09-12** — all four were presented as live in April: `AgentEval/AgentEval`,
`Jinjos/vibe-cli`, `Rule-Porter/Rule-Porter` (404), plus AgentLinter, which was only ever cited as a
website.

⚠️ **A practitioner recommendation is withdrawn.** April advised that *"ctxlint catching stale
references automatically is worth more than a quarterly manual audit."* ctxlint has **10 stars**.
That may still be the right call on the merits — the *idea* is right, and it is the idea this
framework implements itself in `audit-context` Step 4 — but recommending a 10-star single-maintainer
dependency without saying so was not a fair presentation of the risk.

**The category's positioning is unchanged**: linters, sync tools and optimizers all assume the
context files exist, and handle format, validation and distribution. None addresses what should be
in them.

## The research

**🔴 [Gloaguen et al., "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding
Agents?"](https://arxiv.org/abs/2602.11988)** (Gloaguen, Mündler, Müller, Raychev, Vechev — ETH
Zurich; v1 2026-02-12, v2 2026-06-23). The v2 abstract, quoted verbatim from the arXiv page:
*"Surprisingly, we find that providing context files does not generally improve task success rates,
while increasing inference cost by over 20% on average."* ⚠️ **v1 put it more strongly** — *"context
files tend to reduce task success rates compared to providing no repository context"* — so the
20% cost figure is stable across both versions and the success finding was **softened** on revision,
not hardened.
Agents do follow the instructions; repository overviews, despite being universally recommended,
do not improve performance. The authors conclude context files may be useful for documenting
**non-standard practices**, and that any claimed improvement should be rigorously tested before
deployment.

**Read plainly, that is a negative result for context engineering as a category, and it is the most
important sentence on this page.** It does not refute the practice, and it is worth saying exactly
what it does and does not cover: it measures *task success on benchmark tasks*, not defect rate, not
rework, not whether a human later finds the work correct — and the framework in this repo targets
the latter. But the burden has moved. "Context files help" is no longer the default a practitioner
may assume; it is a claim that now runs against the best available evidence, and anyone shipping a
context framework — this one included — owes a measurement rather than a rationale.

The authors' own surviving recommendation — *document the non-standard* — is close to what this
framework calls "only write what the agent cannot infer from the code," which is one of the few
places where the paper and the practice agree.

**[Lulla et al., "On the Impact of AGENTS.md Files on the Efficiency of AI Coding
Agents"](https://arxiv.org/abs/2601.20404)** (v1 2026-01-28, v2 2026-03-30). 10 repositories,
124 pull requests, Codex and Claude Code: AGENTS.md is associated with **lower median runtime
(Δ 28.64%)** and **reduced output token consumption (Δ 16.58%)**, with comparable task completion.
⚠️ **Note what this does and does not say.** It measures *efficiency*, not *success* — and "comparable
task completion behaviour" is consistent with Gloaguen's "does not generally improve task success."
The April edition framed these two papers as complementary halves of a positive story. **They are
better read as agreeing: context files change cost, not outcome.** The disagreement is only over the
sign of the cost, and the two measure different cost units (inference cost vs output tokens).

**[Zhou et al., "Externalization in LLM Agents: A Unified Review of Memory, Skills, Protocols and
Harness Engineering"](https://arxiv.org/abs/2604.08224)** (21 authors, 2026-04-09). Argues agent
capability is migrating from model weights to externalized memory, skills and protocols. The
theoretical case for the practice. ⚠️ The April edition's "SJTU/CMU" affiliation could not be
confirmed from the abstract page and is dropped rather than repeated.

**[Du et al., "Memory for Autonomous LLM Agents: Mechanisms, Evaluation, and Emerging
Frontiers"](https://arxiv.org/abs/2603.07670)** (2026-03-08). The survey of memory systems 2022
through early 2026. Good entry point.

Aggregators: [Awesome Agent Memory](https://github.com/TeleAI-UAGI/Awesome-Agent-Memory) (632
stars), [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) (53,914).

## The gaps

Re-assessed rather than copied forward.

**Content guidance — still open, and now with a harder edge.** Nobody addresses what belongs in the
files. Gloaguen makes this sharper than April did: bad content does not merely fail to help, it
costs 20%+ in inference and can make outcomes worse.

**Memory verification — still open, and still the clearest differentiator.** Every memory system
optimizes recall; none verifies truth. Checked again across all seven systems above: no benchmark in
use tests whether a retrieved memory is *still true*. This is the gap this framework's
verification-command embedding addresses, and five months on nobody else has moved into it.

**Review-cost accounting — new, and unclaimed by anyone.** No framework on this page prices its own
loop. This one measures it (`memory/review-ledger.tsv`: **224k tokens for a two-lens round, 485k for the
largest four-lens round**, re-derived from the ledger 2026-09-12 — ⚠️ issue #127's widely-quoted
557,442 figure appears nowhere in it and did not reconcile) and has an open issue saying the price
is not yet justified (#126). That nobody else even measures it is not
a point in anyone's favour, including ours.

**Multi-user coordination — still open.** Multi-agent orchestration solves one person driving many
agents. Many people, each with an agent, in one codebase remains unaddressed.

**Session strategy — still open.** When to start fresh, why reviewing in the building session is a
bad idea, how to use cross-model validation.

## Should we cooperate with anyone?

Asked directly, so answered directly. The candidates are ranked by what cooperation would actually
change, not by how close the subject matter looks.

**1. `agent-markdown-memory-bank-protocol` — no.** It is 6 stars, 2 commits, dormant 5½ months, and
carries **no license**, which means its text cannot legally be reused or adapted even if we wanted
to. There is no audience to reach through it and no maintainer activity to join. ⚠️ The one thing
worth doing costs ten minutes: **open a single issue** noting the `date` instinct is the same one
this framework generalises, and linking
`docs/seeded-defects-and-ablations.md`. If it is read, one person learns something; if not, nothing
was spent. Do not propose a merge, a rewrite, or joint maintenance.

**2. ctxlint — yes, and this is the best near-term target.** 10 stars, pushed today, and it does
*mechanically* what `audit-context` Step 4 does: check context files against the actual codebase and
catch stale references. This framework's `refcheck` is substantially further along — four resolution
rungs, a 40-case seeded fixture, an exit-status table, and a documented cross-repo rung — and it is
buried in a methodology repo where no linter author would find it. **The overlap is real, the
direction of value is clear, and the project is small enough that a well-formed contribution
lands.** ⚠️ But note what we would be giving: `refcheck.py` is explicitly an *oracle*, not normative,
and porting it means porting its false-positive classes too.

**3. AGENTS.md / the Agentic AI Foundation — the highest leverage and the slowest.** The standard's
own gap, restated on `agents.md` and unchanged since December 2025, is that it says *where* to put
instructions and not *what* to put in them. That is precisely this framework's subject. With 146
members and eight platinum sponsors it is a real governance body, not a mailing list. ⚠️ **The
blocker is ours, not theirs** — see below.

**4. Cline's Memory Bank documentation — a contribution, not a cooperation.** Widest reach on this
page by a distance. What is missing there is the verification idea: a Memory Bank entry saying
"deployed" is trusted forever. A short, concrete addition to their prompting docs would reach more
practitioners than everything else on this list combined.

**5. The memory-system vendors (Mem0, Letta, Graphiti, MemOS) — not yet.** The truth-vs-recall gap is
genuinely complementary to what they build, and there is a real paper in it. But they are funded
infrastructure companies competing on benchmark scores, and "your benchmark measures the wrong
thing" is a hard opening from an unfunded methodology repo with no published evaluation.

### ⚠️ The precondition, and it applies to all five

**This framework has not measured its own effect.** Gloaguen's v2 says context files do not generally
improve task success and cost 20%+ more; this repo's own `memory/review-ledger.tsv` prices a review
round at 121k–485k tokens; and issue #126 — *"review cost is unpriced… otherwise the framework does
not earn its keep"* — is open, filed by the maintainer. **Approaching a standards body or a vendor
with a method whose benefit is argued rather than measured is the exact move this framework forbids
its own authors** (*"an absolute in a description is a measurement, and it needs one"*).

So the sequencing is: **(2) and (4) now** — both are concrete artifacts, useful on their own terms,
and neither requires claiming an effect size. **(1) as a courtesy.** **(3) after there is a
measurement to bring**, because the AAIF is the one audience that will and should ask for one.

## What it means for practitioners

1. **Start with a Memory Bank, not with this framework.** Four markdown files and a
   read-before/update-after instruction is ~4 KB, takes an afternoon, and is the part of the design
   with the broadest independent adoption. If it is not paying off at that size, more structure will
   not fix it.
2. **Pick AGENTS.md as the format.** Linux Foundation stewardship, 60k+ projects, read natively by
   most tools. The format is settled; the content is not.
3. **Be surgical.** Gloaguen is the finding to internalise: context files cost 20%+ and do not
   generally improve success. Write what the agent cannot infer from the code — the paper's own
   surviving recommendation.
4. **Don't trust memory.** High recall scores say nothing about accuracy. State claims go stale.
   Attach a command that can check them.
5. **Price your own loop.** If you add review, auditing or multi-agent validation on top of context
   files, measure what it costs before deciding it earns its keep. Nobody in this landscape does
   this, which means nobody's published cost claims — including this framework's — have been
   independently checked.
6. **Re-verify anything on this page before citing it.** The April edition of this document had
   three wrong author attributions, four dead links and a materially overstated headline result, and
   every one of them would have survived any amount of re-reading. Only re-running the check found
   them.
