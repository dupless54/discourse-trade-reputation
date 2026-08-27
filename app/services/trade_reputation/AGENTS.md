# Feedback creation service

`TradeReputation::Feedbacks::Create` is the authoritative creation path.

- Accept transaction id, rating, optional comment; derive reviewer from `guardian.user`.
- Derive reviewee only from verified TradeContract participant data.
- Fail closed if Marketplace contract is absent/incompatible.
- Re-read completed transaction truth at submission time.
- Duplicate protection is persistence-backed and race-safe.
- Never consume Marketplace models/tables/private services.
