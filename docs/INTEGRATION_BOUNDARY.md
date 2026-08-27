# Marketplace ↔ Trade Reputation Integration Boundary

This document describes, from the Trade Reputation (consumer) side, the
existing integration boundary with the Marketplace plugin. It does not
introduce a new API, event, or runtime dependency — it records what the
current implementation already does and relies on.

## Ownership

- Marketplace owns listings, transactions, and transaction truth.
- Trade Reputation owns feedback and reputation data (summaries and history).
- Marketplace must never read or write Trade Reputation tables.
- Trade Reputation must never query Marketplace database tables or reference
  `Marketplace::Transaction` / `Marketplace::Listing` directly.

## Supported lookup surface

The only supported way for Trade Reputation to consult Marketplace is:

```ruby
Marketplace::TradeContract::VERSION # => 1

Marketplace::TradeContract.completed_transaction_info(transaction_id)
# => Marketplace::TradeContract::TransactionInfo | nil
```

`TransactionInfo` is an immutable value object (`Data.define`) exposing only:

- `transaction_id`
- `buyer_id`
- `seller_id`
- `completed_at`

No Marketplace internals, associations, or ActiveRecord models are exposed
through it.

## Eligibility semantics

`completed_transaction_info` returns a populated value only for a completed
transaction. Invalid, unknown, pending, and cancelled transactions all
collapse to `nil` — there is no separate lookup that would let a caller
re-derive eligibility incorrectly. A `nil` result means the transaction is
not feedback-eligible.

`TradeReputation::Feedbacks::Create` and `TradeReputation::FeedbacksController`
both revalidate transaction truth by calling `completed_transaction_info`
directly at request time; neither caches or trusts a prior eligibility
decision. Reviewer participation (buyer/seller) and reviewee identity are
derived only from this contract response, never from client-supplied input.

## Fail-closed behavior

Both call sites first verify the contract is present and at the expected
version:

```ruby
defined?(::Marketplace::TradeContract) &&
  ::Marketplace::TradeContract.respond_to?(:completed_transaction_info) &&
  ::Marketplace::TradeContract.const_defined?(:VERSION, false) &&
  ::Marketplace::TradeContract::VERSION == 1
```

If `Marketplace::TradeContract` is missing, does not respond to
`completed_transaction_info`, or reports an unsupported `VERSION`, feedback
submission fails closed rather than falling back to any other lookup.

## Optional event

Marketplace may also emit a `:marketplace_transaction_completed` event
carrying only a `transaction_id` scalar. This event is best-effort and
delivery is not guaranteed. It is a notification only: it must never be
treated as authorization truth, and a missed event must never permanently
block feedback on a transaction that later re-checks as completed via the
contract. Any handling of this event must still re-validate eligibility
through `completed_transaction_info` before making an authorization
decision.

## Scope of this document

This document describes the consumer-side boundary as currently implemented
in `TradeReputation::Feedbacks::Create` and
`TradeReputation::FeedbacksController`. It does not define a new contract,
change existing behavior, or add a runtime dependency between the plugins.
