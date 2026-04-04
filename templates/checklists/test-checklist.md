# Test Checklist

<!-- Definition-of-done for test coverage.
     Use before claiming "tests pass" or "tests are complete." -->

## Coverage

- [ ] Happy path tested — the main use case works
- [ ] Edge cases identified and tested (empty input, boundary values, null/missing)
- [ ] Error paths tested — what happens when things go wrong
- [ ] Regression test added for any bug being fixed

## Quality

- [ ] Tests are independent — no test depends on another test's side effects
- [ ] Tests are deterministic — no flaky timing, random data, or network dependencies
- [ ] Test names describe the scenario, not the implementation ("rejects expired tokens" not "test_validate_3")
- [ ] Assertions are specific — not just "no error thrown" but "returns expected value"

## Execution

- [ ] All tests actually run (not skipped, not commented out)
- [ ] Tests run in the project's standard test command (not a custom one-off)
- [ ] Test output is clean — no unexpected warnings or deprecation notices

## Completeness

- [ ] Every acceptance criterion from the design has at least one test
- [ ] No untested code paths added (check coverage diff if available)
- [ ] Tests would catch a regression if someone reverted the change
