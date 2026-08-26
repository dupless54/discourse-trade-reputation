---
name: reputation-implement
description: Implement one narrowly scoped Trade Reputation task with minimal context.
argument-hint: "[single implementation task]"
disable-model-invocation: true
context: fork
agent: general-purpose
model: sonnet
effort: medium
background: false
---

Implement exactly this task:

$ARGUMENTS

Before editing:
1. Check git status.
2. Read `CLAUDE.md`.
3. Read only relevant sections of `docs/PROJECT_BRIEF.md`.
4. Use `docs/MARKETPLACE_CONTRACT.md` for Marketplace integration.
5. Read `docs/TRADE_REPUTATION_ARCHITECTURE.md` only if this task needs it.
6. Locate only directly relevant source files.

Rules:
- Make the smallest maintainable change.
- Do not scan or refactor unrelated code.
- Enforce feedback authorization server-side.
- Derive the other participant from the verified transaction.
- Prevent self-rating and duplicates.
- Add DB constraints/indexes where appropriate.
- Avoid N+1 queries.
- Preserve unrelated uncommitted changes.
- Do not commit, push, merge, deploy, or use destructive git commands.

Testing:
- Add/update relevant tests only.
- Run the smallest relevant test set.
- Inspect final git diff.

Final response only:
1. Files changed
2. What changed
3. Tests
4. Remaining issue, if any

Maximum 8 lines.
