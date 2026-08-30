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
- Discourse profile visibility is enforced server-side for every serialized user.
- Public feedback detail is revalidated against the current Marketplace public contract before rendering.

## Current Experience

### Trade profile

`/u/:username/trade` provides a native Discourse reputation dashboard with:

- all-time positive reputation and rating distribution;
- received positive, neutral, and negative totals;
- feedback-given count kept separate from received reputation;
- 30-day, 6-month, and 1-year comparison cards;
- newest-first paginated feedback history;
- privacy-safe reviewer fallbacks;
- opaque public feedback detail links;
- responsive desktop/mobile layouts with light/dark theme compatibility.

### Feedback submission

Eligible completed Marketplace transactions expose a localized **Leave feedback** action through the Marketplace plugin outlet. The flow:

- validates the transaction id before any request;
- asks the server for advisory eligibility;
- independently revalidates eligibility at submission time;
- accepts only rating and optional plain-text comment from the client;
- derives the reviewee server-side;
- handles duplicate, ineligible, unavailable, success, and retryable-error states;
- changes the Marketplace CTA to a **Reviewed** state once feedback already exists.

### Feedback detail

Public detail pages use opaque feedback identifiers and expose only the approved display shape:

- transaction and listing references;
- buyer/seller display identity when visible to the viewer;
- rating and plain-text comment;
- transaction completion and feedback submission dates.

Before rendering, the server re-checks the completed transaction through `Marketplace::TradeContract` and verifies that the stored feedback participants still match the contract's buyer/seller pair. Hidden or unavailable participant profiles are not serialized.

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
- immutable transaction detail fields: `transaction_id`, `listing_id`, `buyer_id`, `seller_id`, and `completed_at`

The plugin does not use Marketplace ActiveRecord associations, tables, or private Marketplace services for feedback authorization.

See [`docs/MARKETPLACE_CONTRACT.md`](docs/MARKETPLACE_CONTRACT.md) for the local integration reference.

## Discourse Development Compatibility

The frontend uses current Discourse `.gjs`/Glimmer route templates and plugin outlets instead of legacy template patterns. The GitHub workflow delegates to the official reusable **Discourse Plugin** workflow with linting and runtime tests enabled.

Repository development guidance intentionally points agents to the current Discourse developer guides and current core source when extension APIs are version-sensitive.

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

When extending the plugin, preserve protection against IDOR, fake/non-completed transactions, self-rating, replay/duplicates, race conditions, client-controlled identity, hidden-profile leakage, and public exposure of internal database ids.

For repository-specific development rules, see [`AGENTS.md`](AGENTS.md).

## Support

If Trade Reputation is useful to your marketplace community, you can support continued development through the Buy Me a Coffee banner at the top of this README.
