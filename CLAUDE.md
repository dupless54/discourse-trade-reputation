# Discourse Trade Reputation — Project Instructions

This repository is a production Discourse plugin for trade feedback/reputation.

## Context discipline
- Read only files required for the current task.
- Search before opening many files.
- Do not scan unrelated directories or sibling repositories.
- Prefer targeted tests over the full suite.
- Keep final summaries under 8 lines unless asked otherwise.
- Load Marketplace integration details from `docs/MARKETPLACE_CONTRACT.md`, not from the whole Marketplace repository, unless explicitly doing integration testing.

## Implementation
- Follow current Discourse plugin APIs and this repository's existing conventions.
- Prefer supported plugin APIs over monkey patches.
- Make the smallest maintainable change.
- Do not refactor unrelated working code.
- Keep authorization server-side.
- Avoid N+1 queries.
- Add indexes for profile/history/aggregate queries.
- Preserve backward compatibility unless explicitly changing an API.

## Core feedback rules
Feedback is allowed only when:
- the referenced Marketplace transaction exists
- the transaction is completed
- reviewer is a participant
- reviewed user is the other participant
- reviewer and reviewed user are different users
- that reviewer has not already reviewed this transaction

Supported ratings:
- positive
- neutral
- negative

Enforce critical integrity rules at database level where appropriate.

## Reputation behavior
- Buyer may review seller after completion.
- Seller may review buyer after completion.
- One feedback per reviewer per transaction.
- Feedback includes a comment and creation timestamp.
- Profile history is paginated.
- Aggregate statistics must not require loading all feedback rows into memory.
- Moderation must preserve an audit trail.

## Security
Protect against:
- fake/nonexistent transactions
- pre-completion feedback
- IDOR
- self-rating
- duplicate/replayed feedback
- race conditions
- client-controlled reviewed_user_id
- mass assignment
- private data leakage

## Tests
Test the smallest relevant scope:
- valid buyer -> seller feedback
- valid seller -> buyer feedback
- unauthorized/nonparticipant
- self-rating
- incomplete/cancelled/disputed transaction
- duplicate/replayed feedback
- aggregation/profile history behavior

Before finishing, inspect the diff.

## Git / deployment
- Never commit, push, merge, rebase, reset, force-push, or deploy unless explicitly requested.
- Never overwrite unrelated uncommitted changes.
- Never expose secrets or production credentials.

## Documentation
- `docs/PROJECT_BRIEF.md` contains V1 reputation requirements.
- `docs/MARKETPLACE_CONTRACT.md` is the only Marketplace integration contract this plugin should normally need.
- `docs/TRADE_REPUTATION_ARCHITECTURE.md` should contain the approved architecture once created.
