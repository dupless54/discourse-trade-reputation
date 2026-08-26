---
name: reputation-plan
description: Plan one Trade Reputation architecture change without implementing it.
argument-hint: "[feature or architecture question]"
disable-model-invocation: true
context: fork
agent: Plan
model: opus
effort: high
background: false
---

Plan this Trade Reputation task:

$ARGUMENTS

Read:
- `docs/PROJECT_BRIEF.md`
- `docs/MARKETPLACE_CONTRACT.md` if it exists
- only repository files necessary for this task
- relevant sections of `docs/TRADE_REPUTATION_ARCHITECTURE.md` if it exists

Do not edit files.

Return a concise plan covering:
- affected files/components
- schema/indexes
- Marketplace contract usage
- authorization/integrity
- aggregate/profile query design
- frontend impact
- moderation implications
- tests

Prefer the smallest maintainable design.
