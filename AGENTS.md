# Discourse Trade Reputation — Project Instructions

This repository is a production Discourse plugin for trade feedback and reputation.

## Context discipline

- Read only files required for the current task.
- Search before opening many files.
- Do not scan unrelated directories or sibling repositories.
- Prefer targeted tests over the full suite.
- Keep final summaries concise unless asked otherwise.
- Load Marketplace integration details from `docs/MARKETPLACE_CONTRACT.md`.
- Do not inspect the Marketplace repository unless the task explicitly requires integration verification.
- Fresh-read relevant current Discourse source when framework behavior matters.

## Implementation

- Follow current Discourse plugin APIs and this repository's existing conventions.
- Prefer supported plugin APIs over monkey patches.
- Make the smallest maintainable change.
- Do not refactor unrelated working code.
- Keep authorization and trust decisions server-side.
- Avoid N+1 queries.
- Add indexes for profile, history, and aggregate queries where justified.
- Preserve backward compatibility unless explicitly changing an API.

## Marketplace boundary

Marketplace owns:
- Listings
- Transactions
- Transaction truth

Trade Reputation owns:
- Feedback
- Reputation summaries
- Reputation history

Trade Reputation may consume Marketplace only through its stable documented public contract.

Supported Marketplace boundary:

- `Marketplace::TradeContract::VERSION == 1`
- `Marketplace::TradeContract.completed_transaction_info(transaction_id)`

Never reference or query:
- `Marketplace::Transaction`
- `Marketplace::Listing`
- Marketplace database tables
- private Marketplace services or context
- cross-plugin ActiveRecord associations

Do not depend on Marketplace implementation details.

Marketplace events, when consumed, are notifications only and must never replace authoritative contract validation.

Marketplace must never depend on Trade Reputation.

## Core feedback rules

Feedback is allowed only when:

- the referenced Marketplace transaction exists
- the transaction is completed
- reviewer is a transaction participant
- reviewed user is the other participant
- reviewer and reviewed user are different users
- that reviewer has not already reviewed that transaction

Supported ratings:
- positive
- neutral
- negative

Enforce critical integrity rules at database level where appropriate.

## Reputation behavior

- Buyer may review seller after completion.
- Seller may review buyer after completion.
- One feedback per reviewer per transaction.
- Feedback includes an optional comment and creation timestamp.
- Profile history is paginated.
- Aggregate statistics must not load all feedback rows into memory.
- Received feedback history and given-feedback totals must remain distinct concepts.
- Do not invent reputation scores that are not part of the approved product contract.
- Moderation behavior must preserve an audit trail when implemented.

## Profile privacy

- Respect current Discourse profile visibility rules.
- Backend authorization remains authoritative.
- Frontend visibility checks are UX only and must not replace server-side protection.
- Do not expose transaction, listing, buyer, seller, reviewer, reviewee, feedback, or other private database identifiers unless explicitly part of an approved public API.

## Security

Protect against:
- fake or nonexistent transactions
- pre-completion feedback
- IDOR
- self-rating
- duplicate/replayed feedback
- race conditions
- client-controlled reviewed user identity
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
- profile visibility when relevant

Before finishing:
- inspect the final diff
- run `git diff --check`
- verify task scope
- scan for forbidden Marketplace dependencies
- do not claim tests passed unless they actually ran

If Ruby/Bundler is unavailable locally:
- perform source/static verification
- report runtime specs as NOT RUN

## Git / deployment

Never perform without explicit human approval:
- commit
- push
- merge
- rebase
- reset
- clean
- force-push
- deployment
- production changes

Never use:
- `git add .`
- `git add -A`

Stage only explicitly approved files.

Never overwrite unrelated uncommitted changes.

Never stage or commit `.claude/settings.local.json`.

## Documentation

- `docs/PROJECT_BRIEF.md` contains V1 reputation requirements.
- `docs/MARKETPLACE_CONTRACT.md` is the normal Marketplace integration boundary for this plugin.
- `docs/TRADE_REPUTATION_ARCHITECTURE.md` contains or should contain the approved architecture.
