# Marketplace Integration Contract

This is the only Marketplace integration surface Trade Reputation should normally need.
Do not couple to Marketplace internals beyond what is documented here.

Status: synchronized with `dupless54/discourse-marketplace` `main` and
`Marketplace::TradeContract::VERSION == 1`.

## Contract

```ruby
Marketplace::TradeContract::VERSION # => 1

Marketplace::TradeContract.completed_transaction_info(transaction_id)
# => Marketplace::TradeContract::TransactionInfo | nil
```

`TransactionInfo` is an immutable value object with these public fields:
- `transaction_id`
- `listing_id`
- `buyer_id`
- `seller_id`
- `completed_at`

`listing_id` is display/detail context only. It does not authorize feedback.

## Semantics

- Accepts only an actual positive `Integer`. Invalid input returns `nil`.
- Returns a populated `TransactionInfo` only for a completed transaction. Unknown or non-completed transactions return `nil`.
- The return value is an immutable value object, not an ActiveRecord model. No Marketplace internals are exposed through it.
- Every feedback authorization decision must call this method directly; it is the only source of transaction authorization truth.
- Detail views may use `listing_id` only after revalidating the completed transaction through this contract.
- Stored feedback participant ids must continue to match the freshly verified buyer/seller pair before public detail is rendered.

## Hard boundary

Trade Reputation must not:
- reference `Marketplace::Transaction` or `Marketplace::Listing`;
- query `marketplace_*` tables;
- add associations to Marketplace models;
- call Marketplace private services;
- derive authorization from client state or event payloads.

## Optional event

```
:marketplace_transaction_completed
```

- Payload: the `transaction_id` scalar only.
- Best-effort notification only, never authorization truth.
- Delivery is not guaranteed.
- A missed event must never make a historically completed transaction permanently unreviewable.
- Authorization must always re-check `completed_transaction_info`, never cached event state.
