# Durable decisions

Load only when an architecture or integration choice is relevant.

- Marketplace owns transaction truth; Trade Reputation owns feedback, summaries, history, and moderation state.
- Marketplace authorization/integration goes through the documented `Marketplace::TradeContract`; no direct Marketplace model/table/private-service coupling.
- Feedback eligibility is revalidated server-side at submission time; completion events are notification-only.
- Reviewee identity is derived from the verified transaction, never accepted from the client.
- Duplicate protection is persistence-backed: at most one feedback per reviewer per transaction.
- Received history, given totals, profile privacy, and public identifiers remain distinct concerns; expose only approved public data.

Do not record temporary PR/CI state here; use `CURRENT_STATE.md` for volatile facts.
