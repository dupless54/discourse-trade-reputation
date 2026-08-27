# Trade Reputation schema

Read `.agents/skills/project-schema-review/SKILL.md` before schema/index changes.

- Preserve feedback uniqueness and profile/history query performance.
- Review existing rows, null/default/backfill, constraints, index cost, deploy ordering, rollback/recovery, and audit retention.
- No Marketplace FKs or cross-plugin table ownership.
- Never perform destructive production DB work during ordinary development.
