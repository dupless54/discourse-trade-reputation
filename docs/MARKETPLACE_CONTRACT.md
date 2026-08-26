# Marketplace Integration Contract

This is the only Marketplace integration surface Trade Reputation should normally need.
Do not couple to Marketplace internals beyond what is documented here.

## Contract

```ruby
Marketplace::TradeContract::VERSION # => 1

Marketplace::TradeContract.completed_transaction_info(transaction_id)
# => Marketplace::TradeContract::TransactionInfo | nil
```

`TransactionInfo` fields:
- `transaction_id`
- `buyer_id`
- `seller_id`
- `completed_at`

## Semantics

- Accepts only an actual positive `Integer`. Invalid input returns `nil`.
- Returns a populated `TransactionInfo` only for a completed transaction. Unknown or non-completed transactions return `nil`.
- The return value is an immutable value object, not an ActiveRecord model. No Marketplace internals are exposed through it.
- Every feedback authorization decision must call this method directly; it is the only source of authorization truth.

## Optional event

```
:marketplace_transaction_completed
```

- Payload: the `transaction_id` scalar only.
- Best-effort notification only, never authorization truth.
- Delivery is not guaranteed.
- A missed event must never make a historically completed transaction permanently unreviewable.
- Authorization must always re-check `completed_transaction_info`, never cached event state.
