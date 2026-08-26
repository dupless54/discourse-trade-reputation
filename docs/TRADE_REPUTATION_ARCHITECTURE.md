# Trade Reputation Architecture

## Ownership boundary

Trade Reputation owns:
- feedback records
- reputation/rating data derived from its own feedback
- feedback eligibility orchestration on its side

Marketplace owns:
- listings
- transactions
- transaction lifecycle truth
- `Marketplace::TradeContract`

## What Trade Reputation may consume

- `Marketplace::TradeContract::VERSION`
- `Marketplace::TradeContract.completed_transaction_info(transaction_id)`
- optionally `:marketplace_transaction_completed`, in a later phase

## What Trade Reputation must never do

- reference `Marketplace::Transaction`
- reference `Marketplace::Listing`
- query `marketplace_*` tables
- add AR associations to Marketplace models
- call Marketplace private services
- derive transaction authorization from event payloads

## Event semantics

- `:marketplace_transaction_completed` is best-effort only, never authorization truth.
- A missed event must never make a completed transaction permanently unreviewable.
- Every real authorization decision must re-check `TradeContract`, not cached event state.
- Marketplace must never depend on Trade Reputation.

## Data model constraints (future phases)

- `marketplace_transaction_id` is stored as an external scalar identifier, with no DB foreign key to Marketplace tables.
- Uniqueness: `UNIQUE (marketplace_transaction_id, reviewer_id)`.
- Self-review protection: `CHECK (reviewer_id <> reviewee_id)`.

## Autoload rule

`TradeReputation::Engine` registers `lib/` as an autoload root via:

```ruby
config.autoload_paths << File.join(config.root, "lib")
```

New `lib/trade_reputation/*.rb` files must follow Zeitwerk naming (file path matches constant path).
