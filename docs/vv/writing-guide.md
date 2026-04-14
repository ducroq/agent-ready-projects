# Writing Guide: It Starts With Markdown

**Last Updated:** 2026-04-12

---

## Section-to-Registry Mapping

### Section 1: The New Stack Nobody Planned For
**Registry entries:** S1-1 through S1-7
**Dominant type:** CLAIM (industry facts)
**Confidence range:** SUPPORTED to ESTABLISHED
**Language:** Assertive for standards convergence (AGENTS.md under LF = ESTABLISHED). Cautious for "20+ platforms" (SUPPORTED — verify exact number).

### Section 2: What a Project File Actually Does
**Registry entries:** S2-1 through S2-4
**Dominant type:** CLAIM (research findings)
**Confidence range:** ESTABLISHED (ETH Zurich data)
**Language:** Report exact numbers, cite precisely. "Reduced success rates by 3%" not "reduced success rates."
**Watch for:** Oversimplifying the ETH Zurich findings — the study is nuanced (LLM-generated vs human-written have different effects).

### Section 3: Beyond the Project File — Layered Memory
**Registry entries:** S3-1, S3-2
**Dominant type:** CLAIM (tool properties) + PROPOSITION (layered model itself)
**Note:** The layered model is OWN WORK — it's a framework contribution, not a cited fact. Language should reflect this: "we use" / "the solution is" rather than "research shows."

### Section 4: Where MCP Fits
**Registry entries:** S4-1
**Dominant type:** CLAIM (protocol specification)
**Language:** Technical precision. "JSON-RPC protocol" not "JSON-based protocol."

### Section 5: The Problem Nobody's Talking About
**Registry entries:** S5-1 through S5-10
**Dominant type:** Mixed — CLAIMs (facts about frameworks), ARGUMENTs (landscape gap), CLAIMs (RenkumSpot events)
**Language:**
- Framework gap claims: Use "as of April 2026" qualifier (S5-1, S5-2)
- RenkumSpot case: Factual, specific, ESTABLISHED
- Landscape arguments: SUPPORTED — qualify with "surveyed" or "major"
**Watch for:** Overclaiming the gap. "No framework" is strong. "No surveyed framework" is defensible.

### Section 6: Where This Comes From
**Registry entries:** S6-1 through S6-3
**Dominant type:** CLAIM (provenance) + ARGUMENT (gap confirmation)
**Language:** "28+ active projects" is OWN WORK — defensible but verify against ADR-001.

### Section 7: Honest Limitations
**No registry entries.** This section is authorial hedging — scope boundaries and caveats. No verification needed.

---

## Language Calibration

| Confidence Tier | Language |
|-----------------|----------|
| ESTABLISHED | "demonstrates", "shows", "confirms", "established" |
| SUPPORTED | "indicates", "supports", "evidence suggests" |
| EMERGING | "may", "preliminary evidence", "initial findings suggest" |
| SPECULATIVE | "warrants investigation", "remains unclear", "we hypothesize" |

### Key Calibration Decisions

| Entry | Current Language | Tier | Correct? |
|-------|-----------------|------|----------|
| S2-3 | "reduced success rates by 3%" | ESTABLISHED | Yes — direct report of peer-reviewed data |
| S5-1 | "None solve multi-user-multi-agent coordination" | SUPPORTED | Check — should be "As of April 2026, no surveyed framework..." |
| S5-2 | "No open-source system supports shared team memory" | SUPPORTED | Check — add "surveyed" qualifier |
| S1-6 | "Markdown is how LLMs were trained to understand structure" | SUPPORTED | Check — oversimplification? LLMs were trained on many formats |

---

## Framework Component Language

The layered model (Layers 1-5) and self-learning loop are OWN WORK contributions. They should be written in **EMERGING** language:
- "We propose" / "We use" / "The solution is" — not "research demonstrates"
- The exception is where OWN WORK evidence supports them: "tested across 28+ projects" moves specific claims to SUPPORTED

The coordination layer (Layer 5) is newer, designed from one case study. Language should be **EMERGING**:
- "Designed from observed friction" — not "proven to work"
- "The fix is" / "We propose" — authorial recommendation, clearly labeled
