# Discourse Trade Reputation Agent Router

Canonical instructions for ChatGPT/Codex, Claude, and Gemini.

## Authority and context

When information conflicts: current source/tests > `docs/ai/CURRENT_STATE.md` or active work `state.md` > nearest scoped `AGENTS.md` > stable docs > history.

Always read this file, then only the nearest local rules for areas actually inspected or changed:
- feedback persistence -> `app/models/trade_reputation/AGENTS.md`
- feedback creation -> `app/services/trade_reputation/AGENTS.md`
- HTTP endpoints -> `app/controllers/trade_reputation/AGENTS.md`
- profile queries/integration helpers -> `lib/trade_reputation/AGENTS.md`
- frontend -> `docs/ai/scopes/frontend/AGENTS.md`
- schema/migrations -> `db/AGENTS.md`
- specs/integration tests -> `spec/AGENTS.md`

For multi-session work, read the active `docs/ai/work/<feature>/state.md` first and only the relevant implementation-plan section. Do not preload completed phases or unrelated docs.

## Fast task path

For non-trivial work, use `.agents/skills/task-packet/SKILL.md` before broad reads. Use `docs/ai/REPO_MAP.md` to locate code, `COMMANDS.md` only when validation is needed, and `DECISIONS.md` only when architecture/integration behavior is relevant. Skip the formal packet for trivial one-file edits.

## Marketplace boundary

Marketplace owns listings/transactions/authoritative transaction state. Trade Reputation owns feedback/summary/history/moderation.

Normally the only permitted Marketplace authorization surface is:
- `Marketplace::TradeContract::VERSION == 1`
- `Marketplace::TradeContract.completed_transaction_info(transaction_id)`

Do not query Marketplace tables or reference `Marketplace::Transaction`, `Marketplace::Listing`, private Marketplace services/context, or cross-plugin AR associations unless an explicitly approved contract change requires it. Marketplace completion events are notification-only; authorization always revalidates through the contract.

## Feedback invariants

- Feedback requires a verified completed transaction.
- Reviewer is the authenticated transaction participant.
- Reviewee is derived server-side as the other participant.
- Reviewer and reviewee differ.
- At most one feedback per reviewer per transaction.
- Ratings are positive, neutral, or negative.
- Profile history is paginated and aggregates must not load full histories into memory.
- Received history and given totals are separate concepts.
- Respect current Discourse profile visibility.
- Never expose internal transaction/listing/user/feedback database identifiers unless an approved public API explicitly requires it.
- Moderation, when present, preserves auditability and must not silently bypass duplicate/eligibility rules.

## Security, implementation, tests

Protect against fake/non-completed transactions, IDOR, self-rating, replay/duplicates, races, client-controlled identity, mass assignment, and private-data leakage. Keep authorization server-side. Use current Discourse APIs verified from source when version-sensitive. Make the smallest maintainable change; no unrelated refactors.

Test the smallest relevant behavior. Never claim tests passed unless they actually ran; unavailable runtime checks are NOT RUN. Before finishing inspect the diff, run `git diff --check` when available, verify scope, and scan for forbidden Marketplace dependencies.

## Safety and delivery

Stop for unresolved architecture, schema/migration, authorization/security, Marketplace-contract, or product ambiguity. Preserve unrelated work. Never stage/commit `.claude/settings.local.json`. Never force-push, reset/clean, delete branches, deploy, or make destructive DB changes. Commit/push/PR/merge only when the current user task explicitly authorizes it.

## Token discipline and skills

Minimum unnecessary tokens, not minimum reasoning. Prefer targeted symbols/ranges/diffs over broad scans or repeated summaries. Reusable procedures live under `.agents/skills/`; read only the matching `SKILL.md`: `task-packet`, `project-plan`, `project-implement`, `project-review`, `project-final-verify`, `project-ci-repair`, `project-schema-review`, `project-security-review`, `project-update-state`.

## Adaptive model / effort routing

Classify execution risk with `docs/ai/EFFORT_ROUTER.md` before broad reads. Start at the lowest sufficient tier: T0 mechanical, T1 routine, T2 high-risk, T3 exceptional. Escalate for risk/ambiguity rather than task size, and de-escalate when the risky phase ends. Use platform-native workers under `.claude/agents/` or `.codex/agents/` when supported; never trade away correctness, security, or validation to save tokens.
