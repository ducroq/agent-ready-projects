# Webhook Relay

The webhook relay is deployed on the edge server and forwarding events to the queue.
<!-- verify: webhook-relay-status -->

<!--
Fixture intent: the verify command names a tool that no longer exists, so the
check cannot speak to the claim either way. Exit 127 and, more generally, any
command that prints nothing on stdout is ERROR — "the verify command may be
stale" — and not FAIL, which asserts the claim itself is now false.
-->
