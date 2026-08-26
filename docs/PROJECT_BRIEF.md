# Trade Reputation V1 Product Brief

## Goal
Create an R10-style trade reputation experience for Discourse without copying R10 branding, source code, graphics, or exact visual styling.

The reputation plugin works only with verified completed transactions supplied by the separate Marketplace plugin.

## Feedback V1
Each completed Marketplace transaction can permit at most:
- one buyer -> seller feedback
- one seller -> buyer feedback

Feedback fields:
- transaction reference
- reviewer
- reviewed user
- rating: positive / neutral / negative
- comment
- created timestamp
- moderation/audit state if needed

The reviewed user must always be derived from the verified transaction relationship, not blindly accepted from client input.

## Profile Trade Tab
Add a profile tab for trade reputation.

Summary should support:
- total received feedback
- positive count
- neutral count
- negative count
- positive percentage / reputation percentage
- feedback given counts if useful

Time ranges:
- last 30 days
- last 6 months
- last 1 year

History:
- rating indicator
- comment/title
- reviewer
- listing/transaction reference
- date
- pagination

Feedback detail:
- listing reference
- buyer
- seller
- rating
- comment
- transaction/completion date

## UI
Use the supplied R10 screenshots only as a UX/layout reference.
Build a native design matching the forum's own theme.
Requirements:
- desktop and mobile
- dark/light theme compatible
- accessible controls
- no horizontal overflow
- no exact R10 branding or proprietary visual copying

Reference screenshots:
- `docs/reference/r10-trade-list.png`
- `docs/reference/r10-trade-detail.png`

## Marketplace dependency
Normally read only `docs/MARKETPLACE_CONTRACT.md`.
Do not couple directly to Marketplace database internals if the public contract is sufficient.

## Performance
Design for large feedback histories:
- pagination
- indexed profile/history queries
- efficient aggregate queries
- no N+1 requests
- no full-table loading for percentages/statistics

## Moderation
V1 should allow authorized staff to invalidate/hide abusive feedback while retaining enough audit data to understand what happened.

## Out of scope for V1
Unless requested later:
- public leaderboards
- complex fraud scoring
- automated dispute arbitration
- paid reputation features
