# Trade Reputation query/integration layer

- Profile summary/history reads Trade Reputation tables only unless an approved detail contract explicitly requires a revalidation lookup.
- Paginate history; preload reviewer; deterministic newest-first ordering with id tiebreaker.
- Aggregates stay in SQL/bounded query paths, not full-table Ruby loads.
- Zero-feedback percentage is no-data (`nil`), not an invented score.
- When Marketplace contract data is needed, use only its documented immutable public value object.
