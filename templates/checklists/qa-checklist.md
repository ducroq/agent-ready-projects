# QA Checklist

<!-- Definition-of-done for quality assurance review.
     Use before approving a merge or declaring work complete. -->

## Git Reality Check

- [ ] Run `git diff --stat` and compare against claimed changes
- [ ] Flag files changed but not mentioned (forgotten documentation or accidental edits)
- [ ] Flag files mentioned but not changed (incomplete work)
- [ ] Verify each acceptance criterion has corresponding code changes

## Minimum Findings Requirement

- [ ] Review surfaced at least 3 observations (issues, risks, or improvement notes)
- [ ] If fewer than 3: explicitly documented what was verified and why no issues exist
- [ ] Each finding classified: CRITICAL (blocks merge) / HIGH (should fix) / MEDIUM (consider) / LOW (optional)
- [ ] No "looks good" without listing specific checks performed

## Code Quality

- [ ] No security regressions (injection, auth bypass, exposed secrets)
- [ ] No performance regressions (new N+1 queries, unbounded loops, missing pagination)
- [ ] Error handling is present at system boundaries
- [ ] No dead code, unused imports, or debugging artifacts

## Documentation

- [ ] RUNBOOK.md updated if operational procedures changed
- [ ] Gotcha log entry added if a non-obvious problem was encountered
- [ ] ADR created if a significant design choice was made
- [ ] Project file updated if constraints, architecture, or key paths changed

## Deployment Readiness

- [ ] Changes tested in the actual execution context (systemd, Docker, CI), not just manually
- [ ] Database migrations tested (if applicable)
- [ ] Rollback plan exists (or risk is accepted and documented)
