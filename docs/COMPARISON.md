# How This Guide Relates to BMAD and spec-kit

Two of the most popular frameworks for AI-driven development — and how they complement (not compete with) this guide.

---

# Part 1: BMAD-METHOD

A side-by-side look at how the [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) framework relates to the layered documentation model in this guide. BMAD is the most comprehensive open-source implementation of AI-driven development — 38K+ stars, 34+ workflows, 12+ agent personas. Understanding how it works illuminates both the strengths of structured agent context and where the complexity trade-offs lie.

This is not a review. It's a mapping: which of these guide's principles does BMAD implement, how, and what does it add on top?

## Where BMAD validates the guide

### The auto-loading cliff — BMAD respects it

BMAD doesn't dump everything into a single auto-loaded file. Agent personas, workflow steps, and task definitions are loaded on demand — only when a user triggers a slash command. The core orchestrator (`workflow.xml`), agent definitions, and step files are all below the cliff until explicitly activated.

This is the guide's progressive disclosure principle in action. An agent working on a brainstorming session doesn't load the architecture workflow. An agent doing sprint planning doesn't load the market research steps.

Where BMAD differs: it doesn't use a single project file (CLAUDE.md / AGENTS.md) as the auto-loaded home base. Instead, it distributes context across agent YAML files, module configs, and manifests. There's no single orientation document — the `/bmad-help` command serves that role dynamically.

### Task-triggered loading — BMAD implements it through menus

Each agent has a menu of triggers:

```yaml
menu:
  - trigger: "BP or fuzzy match on brainstorm-project"
    exec: "{project-root}/_bmad/core/workflows/brainstorming/workflow.md"
    description: "[BP] Brainstorm Project"
```

This is a formalized version of the guide's "Before You Start" table — mapping tasks to files. The difference: BMAD's triggers are machine-executed (the agent loads and runs the workflow), while the guide's pointers are agent-navigated (the agent decides to read the file).

BMAD also supports fuzzy matching on trigger descriptions, which means agents can activate workflows from natural language — closer to the guide's vision of agents self-navigating to the right context.

### Memory and persistence — BMAD uses agent-specific sidecars

Where the guide proposes MEMORY.md + topic files, BMAD implements **agent-specific sidecar directories**:

```
_bmad/_memory/
└── tech-writer-sidecar/
    └── documentation-standards.md
```

Each agent that needs persistent memory gets its own sidecar, loaded automatically when that agent activates. The tech-writer agent remembers your documentation standards across sessions. User customizations are preserved through updates.

This is a more granular version of the guide's topic files — instead of one memory system shared across all agents, each specialist has its own persistent context. The trade-off: better isolation but more files to maintain.

BMAD's session-level persistence is also worth noting: workflows save progress in output file frontmatter (`stepsCompleted: [1,2,3]`), so interrupted workflows can resume. The guide doesn't address this — it's a workflow concern, not a documentation concern.

### Principles embedded where they're used

BMAD embeds principles directly in agent definitions — the analyst agent's YAML contains its analytical frameworks, the architect agent carries its design principles. This is the guide's "right content, right place" idea applied at the agent level.

The workflow orchestrator (`workflow.xml`) embeds its own mandates:

```xml
<mandate>Always read COMPLETE files - NEVER use offset/limit</mandate>
<mandate>Instructions are MANDATORY - execute in exact order</mandate>
<mandate>NEVER skip a step</mandate>
```

These are operational constraints placed exactly where they're needed — not in a separate principles document that might not get loaded. This validates the guide's warning about "principles without a runbook."

## What BMAD adds beyond the guide

### 1. A full agent persona system

The guide doesn't model agent personas. BMAD defines 12+ specialized agents, each with:
- A name and identity ("Mary the Business Analyst", "James the Architect")
- Communication style ("speaks with the excitement of a treasure hunter")
- Domain-specific principles and frameworks
- A menu of available workflows

This is a layer the guide doesn't address — the guide is about *project* context, BMAD adds *role* context. A project manager agent thinks differently about the same codebase than a developer agent.

### 2. Workflow orchestration

The guide describes documentation structure. BMAD describes *process* structure — multi-step workflows with:
- Sequential steps loaded on demand
- Checkpoints where output is saved and reviewed
- Branching paths (user-selected vs. AI-recommended techniques)
- Nested workflow invocation (`<invoke-workflow>`)
- Reusable protocols (`discover_inputs`)

This is a different concern entirely. The guide helps agents understand a project. BMAD tells agents how to run a methodology.

### 3. A module and manifest system

BMAD tracks everything through manifests:

```csv
module,phase,name,code,command,agent,description
bmm,1-analysis,Market Research,MR,bmad-bmm-market-research,analyst,"Market analysis, competitive landscape"
bmm,2-planning,Create PRD,CP,bmad-bmm-create-prd,pm,"Expert led facilitation to produce PRD"
```

This enables discovery — the help system can tell you what's available, what phase you're in, and what comes next. The guide's "Before You Start" table is a manual version of this.

### 4. Multi-agent collaboration (Party Mode)

BMAD supports bringing multiple agent personas into a single session to debate and collaborate. A product manager, architect, and developer can discuss a feature from their respective viewpoints.

The guide doesn't address multi-agent scenarios at all — it's written for a single agent working with a single human.

### 5. An installer and IDE abstraction

BMAD installs via `npx bmad-method install`, configures IDE-specific files (Claude Code skills, Cursor rules), preserves configuration across updates, and manages module dependencies.

The guide's approach is "copy a template and fill it in." BMAD's approach is "run an installer and answer prompts."

## What you probably don't need

This is where it gets opinionated. BMAD is built for teams adopting a comprehensive AI-driven development methodology. Most projects — especially solo or small-team projects — don't need all of it.

### Agent personas — probably not

Named personas with communication styles ("speaks with the excitement of a treasure hunter") add charm but not necessarily capability. For most projects, a single well-informed agent with good project context outperforms a dozen role-playing specialists. The personas solve a *team coordination* problem — when multiple people use different agents, personas ensure consistency. If you're the only user, you don't need Mary the Analyst and James the Architect. You need one agent that understands your project.

Where personas *do* help: forcing the agent to adopt a specific analytical lens. "Think like a QA engineer" produces different output than "think like a developer." But you can achieve this with a prompt, not a framework.

### The full SDLC workflow system — probably not

BMAD's phased workflow (analysis → planning → architecture → implementation) with 34+ formalized workflows assumes you want AI to facilitate your entire development process. Most developers don't work this way — they have a task, they want help with it, they move on.

The workflow orchestrator (`workflow.xml`) with its step sequencing, template outputs, and checkpoint system is genuine engineering. But it's engineering for a problem most projects don't have: ensuring agents follow a prescribed multi-step methodology across sessions.

If you're building a product and using agents to help, you probably want agents that understand your project context (the guide's concern), not agents that run you through a brainstorming-to-deployment pipeline.

### Manifests for discovery — probably not

CSV manifests tracking every installed workflow, agent, and task solve a discovery problem that exists *because* BMAD has so many moving parts. If your project has a CLAUDE.md with a "Before You Start" table and 3-5 on-demand docs, you don't need a manifest system to find things.

### The module/installer system — probably not

The installer and module architecture make sense for a framework that ships to thousands of users. For your own projects, copying a template and spending 10 minutes filling it in is simpler and produces documentation you fully understand.

## What's worth borrowing

### Agent-specific memory isolation

BMAD's sidecar pattern — each specialist gets its own persistent context — is worth considering if your project has distinct subsystems with very different concerns. Instead of one MEMORY.md with everything, you could have topic files that function as "sidecars" for different types of work.

The guide already recommends topic files. BMAD's contribution is making the loading automatic and agent-role-aware.

### Session continuation via output state

Saving workflow progress in output files so interrupted work can resume is practical. The guide's gotcha log is backward-looking (what went wrong). BMAD's session state is forward-looking (where are we in this process). Both are useful.

### Structured help/discovery

The `/bmad-help` command that shows contextual next steps is genuinely useful. A lightweight version — a "What to do next" section in CLAUDE.md that updates as the project evolves — captures the same benefit without the framework.

## The fundamental difference

The guide answers: **"How do I structure my project so any agent can work effectively?"**

BMAD answers: **"How do I restructure my entire development process around specialized AI agents?"**

The guide is a documentation strategy. BMAD is a development methodology. The guide assumes you have a way of working and want agents to fit into it. BMAD proposes a new way of working built around agents.

For most projects, the guide's approach — lightweight, tool-agnostic, focused on project context — is the right starting point. BMAD's ideas about memory isolation and structured discovery are worth borrowing. The full methodology is worth exploring if you're building something large enough that the overhead pays for itself.

---

# Part 2: GitHub's spec-kit

## How spec-kit Complements This Guide

[spec-kit](https://github.com/github/spec-kit) (73K+ stars) is GitHub's Spec-Driven Development methodology — specifications are the primary artifact, code is generated from them. It's a different kind of project than BMAD: where BMAD prescribes your entire workflow, spec-kit prescribes your *pre-implementation* process and then gets out of the way.

This matters because the two tools solve different problems at different times. **They're not competing — they're sequential.** A project can (and arguably should) use both.

### What spec-kit does

Spec-kit enforces a six-step workflow before any code is written:

1. **Constitution** (`constitution.md`) — non-negotiable project principles ("library-first", "test-first", "security-first")
2. **Specification** (`spec.md`) — user stories with acceptance criteria (Given/When/Then), edge cases, success metrics
3. **Clarification** — interactive ambiguity resolution
4. **Planning** (`plan.md`) — technical architecture, tech stack, research decisions
5. **Tasking** (`tasks.md`) — parallel-executable work items with file paths
6. **Analysis** — consistency validation across all artifacts

The output: a set of markdown files committed to Git that define *what* to build and *how* to build it, validated for internal consistency before a single line of code is written.

### What spec-kit doesn't do

Spec-kit stops at the implementation boundary. It explicitly does **not** address:

| Gap | What it means |
|-----|---------------|
| **Session context management** | No mechanism for loading the right spec artifacts into the right agent session |
| **Memory and persistence** | No gotcha logs, no lessons learned, no "we tried X and it failed" |
| **Progressive disclosure** | No model for what to load when — all artifacts are equally available (or equally invisible) |
| **Post-implementation guidance** | Nothing about maintaining, debugging, or extending the codebase after initial build |
| **The auto-loading cliff** | Spec artifacts exist in Git but nothing ensures agents actually read them at the right moment |

### Where spec-kit ends and this guide begins

The handoff point is implementation:

```
SPEC-KIT (pre-implementation)          THIS GUIDE (during implementation)
─────────────────────────────          ──────────────────────────────────
Constitution  ──┐                      CLAUDE.md
Spec          ──┤                      ├── "Before You Start" table
Plan          ──┤── Git commit ──→     │   points agents to spec artifacts
Tasks         ──┤                      ├── Hard constraints
Analysis      ──┘                      ├── Architecture sketch
                                       │
                                       MEMORY.md + topic files
                                       ├── Lessons from implementation
                                       ├── Gotcha log
                                       └── Cross-session knowledge
```

Spec-kit produces the *what* and *how* artifacts. This guide's layered model ensures agents **actually find and use them** during implementation — and captures everything learned along the way.

### Using them together

A project using both would look like this:

**1. Spec phase (spec-kit owns this)**

```bash
# Generate specification artifacts
specify init my-project --agent claude
/speckit.constitution    # → constitution.md
/speckit.specify         # → spec.md
/speckit.plan            # → plan.md
/speckit.tasks           # → tasks.md
/speckit.analyze         # → validates consistency
git commit -m "spec-driven development artifacts"
```

**2. Implementation phase (this guide owns this)**

CLAUDE.md integrates the spec artifacts via task-triggered pointers:

```markdown
## Before You Start

| When | Read |
|------|------|
| Starting a new task | `tasks.md` — claim your task, check dependencies |
| Making architectural decisions | `plan.md` — tech stack and design decisions |
| Unsure about requirements | `spec.md` — user stories and acceptance criteria |
| Questioning a project principle | `constitution.md` — non-negotiable governance |
| Stuck or debugging | `memory/gotcha-log.md` — problem-fix archive |
```

The spec artifacts become **on-demand context** — loaded when the agent needs them, not dumped into every session. The constitution might belong in CLAUDE.md itself (it's short and always-relevant), while spec.md and plan.md live below the cliff, loaded via task triggers.

**3. Memory accumulates (this guide owns this)**

As implementation proceeds, the gotcha log captures what spec-kit couldn't predict:
- "Task T003 blocked because spec assumed PostgreSQL but we're using SQLite"
- "Constitution says library-first but auth needs to be a module (see DR-003)"
- "Plan's API design doesn't account for rate limiting — added in implementation"

These lessons feed back into the spec artifacts when needed, but the *capture mechanism* is the guide's memory layer, not spec-kit.

### What's worth borrowing from spec-kit

**Templates that structurally constrain output.** Spec-kit's templates force agents to mark ambiguities with `[NEEDS CLARIFICATION]` markers instead of guessing, include checklists that act as "unit tests for specifications," and enforce abstraction levels ("focus on WHAT, not HOW"). The templates shape agent behavior through structure rather than instruction.

This is a technique this guide doesn't use enough. The guide's templates are fill-in-the-blank — they show what to include. Spec-kit's templates are *constrained output formats* — they prevent agents from producing low-quality artifacts. A CLAUDE.md template that includes `[NEEDS CLARIFICATION]` markers for unresolved items, or a decision record template with a mandatory "Revisit If" section, would borrow this pattern.

**Pre-implementation consistency checking.** Spec-kit's `/speckit.analyze` validates that spec, plan, and tasks are internally consistent before implementation begins. This guide has no equivalent — it trusts that the human has set up the docs correctly. A lightweight validation step ("does CLAUDE.md reference files that exist? do task triggers match actual file content?") would be valuable.

### The fundamental difference

spec-kit answers: **"What should we build, and is the specification internally consistent?"**

This guide answers: **"How do agents stay effective while building it?"**

spec-kit is a *specification engine*. This guide is an *operational context engine*. You need both: spec-kit so agents build the right thing, this guide so agents know how to work together while building it. A project with great specs but no session context will have agents re-reading plan.md from scratch every session, missing gotchas, and re-debating decisions. A project with great context but no specs will have agents that work smoothly but build the wrong thing.

The two are stronger together than either is alone.

---

*Since this comparison was written, the guide has added: the **self-learning loop** (a named knowledge lifecycle that neither BMAD nor spec-kit provides), a **processor memory hierarchy analogy** (miss cost asymmetry, eviction discipline, locality of reference), **agent-driven adoption** ([adopt.md](../adopt.md)) that scaffolds the framework automatically, and **versioning** ([CHANGELOG.md](../CHANGELOG.md)) so adopted projects can track updates. In v1.1.0, the framework was **generalized to be fully tool-agnostic**, a [worked example](EXAMPLE.md) was added, and **real adoption feedback** (from driven-pendulum) led to end-of-session curation triggers, document size heuristics, and parallel specialized review as a validation technique. These additions widen the gap with spec-kit (which has no knowledge lifecycle) and complement BMAD (whose role-based personas could feed into the loop's capture phase).*
