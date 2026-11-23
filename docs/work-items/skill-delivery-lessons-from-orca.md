# Skill delivery: two lessons from Orca's skills

## What & Why

Orca (github.com/stablyai/orca, MIT) ships agent skills that are built in two ways ours are not. Both bear on goals this repo already holds: adopter token cost, and safe upgrades of installed skills.

1. **Stub plus on-demand guide.** The installed `skills/orchestration/SKILL.md` is ~4 KB. It mostly tells the agent to run `orca skills get orchestration`, which prints the guide matched to the installed binary. Reference sections load only when a step names them (`--reference references/<file>.md`). Our skill templates are read whole on every run: 7–20 KB each (`wc -c templates/{release,curate,audit-context,review-changes,savepoint,update-drift}.md`, 2026-11-23).
2. **Add-only ledger of released digests.** `resources/skills/released-digests.json` keeps the sha256 of every version of every skill ever shipped. An upgrade can then tell an untouched old install (safe to replace) from one the user edited (leave alone). The generator's comment: "Digest ledger is add-only or older untouched SKILL.md installs become unrecognizable." Our `scripts/install-global-skills.sh` copies over the destination without looking (`cp "$src" "$DEST/$s/SKILL.md"`, line 262). For adopters, `grep -niE 'local(ly)? edit|customi|modified|overwrit|diverg' templates/update-drift.md adopt.md` returned nothing on 2026-11-23, so neither file appears to address an edited install. That grep is a lead, not a measurement: the first task below checks it.

Source read 2026-11-23: `skills/orchestration/SKILL.md`, `resources/skills/*.json`, `config/scripts/skills/bundle-generation/generate-skill-bundle-manifest.mjs`.

## Current Status

Opened 2026-11-23. Nothing built. The engineer said "yes" to opening a work item for either lesson.

**No pointer in `memory/MEMORY.md` yet** (engineer's call, 2026-11-23): lint rule 15 blocks growth of the session-start set, and parked work should not cost every session. Add the pointer when work starts.

- [ ] Decide which lesson to take first (digests are smaller and more concrete).
- [ ] Digests: measure what an adopter's update path does today with a locally edited skill, then design the ledger (where it lives, which hash, when a release appends to it).
- [ ] Stub: Orca's stub works because a binary serves the guide. We ship plain files. Work out what plays that role here, if anything (a reference file the skill reads only at a named step?). Check against #46, closed, on curate's read surface.

## Decisions

- [2026-11-23] One work item for both lessons: both are about how a skill reaches an adopter and stays correct there.

## Open Questions

- Does a digest ledger belong in `templates/` (adopter-facing, MINOR bump) or only in the maintainer installer?
- Text-normalised hashes (Orca keeps exact, CRLF-normalised and identity hashes) — do we need more than one, given Windows adopters (#198)?
- Does splitting a skill into stub plus reference files hurt tools that load a skill as one file? `templates/README.md` is the naming map to check.

## Outcome

**Status**:
**Date**:

**What happened**:

**What remains**:

**Related**: Orca repo above; #46; #198.
