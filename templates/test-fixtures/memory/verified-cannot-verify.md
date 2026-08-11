# Backup Appliance

Nightly snapshots are running on the offsite backup appliance.
<!-- verify: if test -e /nonexistent/agent-ready-fixture-target; then cat /nonexistent/agent-ready-fixture-target; else echo "CANNOT VERIFY: backup appliance not reachable from this host"; fi -->

<!--
Fixture intent: a guarded verify command whose target is unreachable.

The guard exists so an unreachable target yields CANNOT VERIFY rather than a
false PASS or a misleading FAIL. This is the disposition that distinguishes
"the check ran and the claim is false" from "the check never ran at all".

The guard here is a filesystem test rather than the `ping` form shown in
curate Step 0 sub-step 5, so the fixture is deterministic and needs no
network. The shape being tested is identical: guard, then real check, then a
CANNOT VERIFY line naming the cause.

Written as an explicit `if`, not as `guard && check || echo ...`: in that form
the fallback also runs when the *check* fails, so a reachable appliance whose
snapshot is genuinely missing would report as un-checkable. curate Step 0
sub-step 5 forbids the shape for that reason, and a fixture may not model what
the step forbids.
-->
