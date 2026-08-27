# Trade Reputation HTTP

- Keep controllers thin and use normal Discourse auth/plugin guards.
- Eligibility is advisory only; create revalidates independently.
- Preserve intentional status/error semantics; avoid state/identity leakage.
- Never accept client reviewer/reviewee/transaction state as authority.
- Profile/detail endpoints must enforce Discourse visibility server-side; frontend checks are UX only.
- Public JSON should expose the minimum approved shape.
