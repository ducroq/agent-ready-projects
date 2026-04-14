# Anti-Hallucination Checklist: It Starts With Markdown

**Last Updated:** 2026-04-12

Run for every citation. Step 0 catches fabrications in seconds. Full checklist ~2 min per source.

---

## Source Verification Status

| # | Source | Step 0 | Step 1 | Step 2 | Step 3 | Step 4 | Step 5 | Step 6 | Status |
|---|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| 1 | Gloaguen et al. 2026, arXiv:2602.11988 | [x] | [x] | [x] | [x] | [x] | [~] | [~] | Verified (caveat: exact % from secondary sources) |
| 2 | OWASP Agentic Top 10 2026 | [x] | [x] | [x] | [x] | [x] | [x] | [x] | Verified |
| 3 | Microsoft Agent Governance Toolkit | [x] | [x] | [x] | [x] | [x] | [x] | [x] | Verified |
| 4 | VS Magazine "All About the Markdown" | [x] | [x] | [x] | [x] | [x] | [x] | [x] | Verified |
| 5 | agentskills.io specification | [x] | [x] | [x] | [x] | [x] | [x] | [x] | Verified |
| 6 | agents.md / AAIF | [x] | [x] | [x] | [x] | [x] | [x] | [x] | Verified |
| 7 | modelcontextprotocol.io | [x] | [x] | [x] | [x] | [x] | [x] | [x] | Verified (S1-5 revised in article) |
| 8 | Cooperative AI multi-agent risks report | [x] | [x] | [x] | [x] | [x] | [x] | [x] | Verified |

---

## Steps

### Step 0: Quick Web Verification
1. Search Google Scholar for `[Author Year Title]`
2. Check if DOI resolves at `https://doi.org/[DOI]`
3. Both confirm → proceed. Neither confirms → HIGH RISK.

### Step 1: Confirm canonical citation
Record exact DOI, canonical title, publication year.

### Step 2: Is the author real?
Check institutional affiliation, Google Scholar profile, or ORCID.

### Step 3: Is the venue real?
Check publisher website. Cross-reference Web of Science / Scopus.

### Step 4: Does the claim match the paper's scope?
Read abstract. Could this paper contain the cited claim?

### Step 5: Is the exact location cited?
Page, table, figure, or section number.

### Step 6: Have I read the relevant section?
Not just the abstract — the actual section with the claim.

---

## Notes

- Sources 2-3, 5-8 are web resources / standards, not academic papers. Steps 2-3 (author/venue) simplify to "does the organization exist and publish this?"
- Source 1 (Gloaguen et al.) is the only academic citation — full 6-step treatment required.
- Source 4 (VS Magazine) is trade press — verify article exists, date, and specific claims about VS2026 features.
- RenkumSpot evidence is OWN WORK — verify against repo artifacts (PR #5, constitution-robert.md, ADR-015), not external sources.
