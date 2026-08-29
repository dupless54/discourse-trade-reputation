<p align="center">
  <a href="https://buymeacoffee.com/erespawn">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" width="217" height="60">
  </a>
</p>

# Discourse Trade Reputation

A Discourse feedback and reputation plugin for verified [`discourse-marketplace`](https://github.com/dupless54/discourse-marketplace) transactions.

Trade Reputation owns feedback, profile reputation summaries, history, feedback detail, and moderation. Marketplace remains the source of truth for listings and transaction completion.

## Core Rules

- Feedback requires a verified completed Marketplace transaction.
- The reviewer must be an authenticated transaction participant.
- The reviewee is derived server-side as the other participant.
- A reviewer can leave at most one feedback entry per transaction.
- Ratings are **positive**, **neutral**, or **negative**.
- Profile history is paginated and reputation aggregates do not load full histories into memory.
- Received reputation and given-feedback totals remain separate concepts.
- Discourse profile visibility is respected.

## Current Features

- Trade reputation summary and feedback history on `/u/:username/trade`.
- Feedback form for eligible completed transactions.
- Detailed feedback pages using opaque public identifiers instead of exposing database IDs.
- Transaction display reference, listing context, buyer/seller context, completion date, rating, and comment presentation.
- Profile privacy enforcement on feedback detail/history surfaces.
- Deleted-participant fallback behavior.
- Responsive light/dark-compatible Discourse UI.
- English and Turkish localization.

## Moderation and Auditability

Feedback is retained rather than silently deleted when moderated:

- feedback has active/invalidated moderation state;
- invalidation records the moderator, time, and reason;
- invalidated feedback is excluded from public history and reputation aggregates;
- invalidated feedback still counts for one-feedback-per-transaction eligibility so moderation cannot be used to submit duplicates;
- staff moderation uses the public feedback identifier in the current UI;
- repeated invalidation is idempotent and preserves the original audit record.

## Marketplace Integration

Trade Reputation integrates through the public Marketplace contract only:

- `Marketplace::TradeContract::VERSION == 1`
- `Marketplace::TradeContract.completed_transaction_info(transaction_id)`

The plugin does not need direct Marketplace ActiveRecord associations or private Marketplace services for feedback authorization.

The Marketplace transaction UI exposes a generic plugin outlet. Trade Reputation uses that outlet to show a localized **Leave feedback** CTA for eligible completed transactions.

Recent improvements also make the CTA show an **already reviewed** state after feedback has been submitted instead of continuing to offer a duplicate action.

## Recent Development Highlights

The current `main` branch includes:

- V1 feedback moderation with durable audit state.
- Opaque public feedback IDs and full feedback-detail experience.
- Complete responsive V1 profile/history/detail/form UI.
- English/Turkish locale parity.
- Direct profile-route refresh support for `/u/:username/trade`.
- Marketplace transaction feedback CTA integration.
- Already-reviewed CTA state based on the existing server-authoritative eligibility endpoint.
- CI-first and token-efficient repository development guidance.

## Installation

Install Marketplace first, then Trade Reputation:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/dupless54/discourse-marketplace.git
          - git clone https://github.com/dupless54/discourse-trade-reputation.git
```

Rebuild Discourse:

```bash
cd /var/discourse
./launcher rebuild app
```

Enable `trade_reputation_enabled` after both plugins are available.

## Security Notes

Authorization is server-side. The client never decides transaction completion, participant identity, reviewee identity, or duplicate-feedback eligibility.

When extending the plugin, preserve protection against IDOR, fake/non-completed transactions, self-rating, replay/duplicates, race conditions, client-controlled identity, and private-data leakage.

For repository-specific development rules, see [`AGENTS.md`](AGENTS.md).

## Support

If Trade Reputation is useful to your marketplace community, you can support continued development through the Buy Me a Coffee banner at the top of this README.
