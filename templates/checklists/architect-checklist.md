# Architect Checklist

<!-- Definition-of-done for the architecture/design phase.
     Use before moving to implementation. 10-15 items, not enterprise gates. -->

## Context & Requirements

- [ ] Problem statement is written down (not just discussed)
- [ ] Constraints identified — what can't change, what's non-negotiable
- [ ] Existing patterns reviewed — does the codebase already solve something similar?
- [ ] Scope is bounded — "what we're NOT doing" is explicit

## Design Decisions

- [ ] ADR created for any non-obvious choice between alternatives
- [ ] Trade-offs documented — what you're giving up and why that's acceptable
- [ ] Key interfaces defined — how components talk to each other
- [ ] Dependencies identified — external services, libraries, APIs

## Documentation

- [ ] Architecture sketch updated (if it changed)
- [ ] "Before You Start" table updated (if new trigger/read pairs emerged)
- [ ] Key paths table updated (if new files or directories will be created)

## Handoff

- [ ] Implementation can start from this design without a follow-up conversation
- [ ] Test strategy is clear — what to test, at what level (unit, integration, e2e)
- [ ] No open questions marked "TBD" — resolve or explicitly defer with a reason
