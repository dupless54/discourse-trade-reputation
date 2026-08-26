---
name: reputation-review
description: Read-only security and integrity review of Trade Reputation code.
argument-hint: "[feedback/profile area to review]"
disable-model-invocation: true
context: fork
agent: Explore
model: opus
effort: high
background: false
---

Perform a read-only review of:

$ARGUMENTS

Read `docs/MARKETPLACE_CONTRACT.md` if relevant.
Inspect only files needed for the review.
Do not edit files.

Check specifically for:
- fake/nonexistent transaction feedback
- feedback before completion
- IDOR / nonparticipant feedback
- self-rating
- client-controlled reviewed user
- duplicate/replayed feedback
- concurrent duplicate creation
- missing unique constraints/indexes
- mass assignment
- moderation bypass
- inaccurate aggregate statistics
- expensive/N+1 profile history queries
- private data leakage

Report only concrete issues.
For each issue: severity, file/location, failure scenario, minimal fix.
End with counts: CRITICAL / HIGH / MEDIUM / LOW.
Keep it concise.
