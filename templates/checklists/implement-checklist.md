# Implement Checklist

<!-- Definition-of-done for implementation work.
     Use before claiming a feature or fix is complete. -->

## Code Completeness

- [ ] All acceptance criteria from the design are implemented
- [ ] No TODO/FIXME/HACK comments added without a linked issue or explicit deferral
- [ ] No commented-out code left behind
- [ ] No untracked files that should be committed (check `git status`)

## Architecture Compliance

- [ ] Implementation follows the patterns established in the codebase
- [ ] No new dependencies added without justification
- [ ] File placement matches the project's directory conventions
- [ ] No architectural shortcuts that contradict the design

## Testing

- [ ] Tests pass — actually ran them, not just claiming they pass
- [ ] New code has tests (see test-checklist for depth)
- [ ] Existing tests still pass — no regressions introduced

## Operational

- [ ] No secrets, credentials, or tokens in code or config files
- [ ] Error handling exists at system boundaries (user input, external APIs)
- [ ] Logging/observability added where debugging would otherwise be blind
- [ ] Configuration changes documented in RUNBOOK.md (if applicable)

## Cleanup

- [ ] Git diff matches what you'd describe in a PR — no unrelated changes
- [ ] Commit message explains why, not just what
