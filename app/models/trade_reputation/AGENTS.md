# Trade Reputation persistence

`TradeReputation::Feedback` owns reputation persistence.

- Preserve one-feedback-per `(marketplace_transaction_id, reviewer_id)` at DB/model level.
- Reviewer/reviewee are Discourse users and must differ.
- Rating enum is negative/neutral/positive.
- Keep profile/history access indexed and bounded.
- Do not add Marketplace foreign keys or AR associations.
- Moderation/audit schema changes require explicit migration review and must retain enough history to explain staff actions.
