# Delegated context: evidence (moved from the live file 2026-11-25, verbatim)

## Evidence so far (2026-11-03)

Last 25 sessions each in the three largest private adopter repos, read from Claude Code transcripts (names in maintainer memory):
- Peak context per session, median 190k–270k tokens (max 538k–650k). Context at the first turn is 41k–50k, mostly the system prompt and tool definitions. The framework's always-loaded files are 28–49 KB, under 10% of the peak.
- Shell output is roughly a third to a half of the peak (bytes/4 as tokens): about 4,000–7,000 calls per 25 sessions, averaging about 1.6 KB each (about 250–460 KB per session). Calls over 10 KB carry only 13–22% of the bytes. The cause is accumulated exploration (`cat`/`sed`/`grep`), not a few runaway dumps. The rest of the peak is mostly assistant turns and file reads (not broken down).
- One repo's outlier: one session read 3.9 MB of screenshots.
- So splitting repos into modules would likely not cut the peak much (reasoning, not measured). Moving exploration out of the session the user talks to would.
- The user rarely reads session output, so a session that reports only decisions and results costs them nothing.
