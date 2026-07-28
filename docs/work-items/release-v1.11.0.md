# Release v1.11.0 — commit and tag

<!-- Created from templates/work-item.md. Testing the work-item pattern
     on a real (small) task: commit and tag the v1.11.0 release. -->

## What & Why

Ship the v1.11.0 release: commit all changed files and tag `v1.11.0`. New `templates/work-item.md`, GUIDE.md additions (work items subsection, memory-as-residue, index-wins), wiring in CLAUDE.md and MEMORY.md, `docs/work-items/` directory.

## Current Status

**State:** in progress

- [x] Create `templates/work-item.md`
- [x] Update `templates/README.md` (naming map + description)
- [x] Update `templates/memory-index.md` (Current State comment)
- [x] Update `docs/GUIDE.md` (work items subsection + memory-as-residue + index-wins + feature branches update + version badge)
- [x] Update `CHANGELOG.md` (v1.11.0 entry)
- [x] Update `CLAUDE.md` (version pin + Before You Start wiring)
- [x] Update `memory/MEMORY.md` (current release + active work items)
- [x] Create `docs/work-items/README.md` (lint requirement)
- [x] Lint passes
- [ ] Commit all changes
- [ ] Tag v1.11.0
- [ ] Push commit + tag
- [ ] Fill Outcome section below
- [ ] Update MEMORY.md pointer to [done]

## Decisions

- 2026-07-28 Chose `work-item.md` over `feature-context.md` — more general, honest about what it replaces (the ad-hoc todo file). GUIDE.md uses "Work items (feature-level context)" as the section heading to bridge both terms.
- 2026-07-28 Chose single-file template over directory-per-work-item — lighter weight, consistent with existing template philosophy.
- 2026-07-28 Chose no YAML frontmatter on the template — follows gotcha-log/hypothesis-log convention; status is an inline field.
- 2026-07-28 Chose to dogfood the pattern on this release task — tests the full lifecycle before tagging.

## Open Questions

*(none — this is a straightforward release)*

## Outcome

*(fill after commit and tag)*
