# Trade Reputation tests

- Prove behavior with real Trade Reputation objects and public Marketplace contract behavior where integration matters.
- Mock only explicit external seams.
- Cross-plugin integration fixtures/fabricators must match the schema/runtime actually loaded in CI; do not rely on stale sibling-plugin fields.
- Assert privacy/non-enumeration for HTTP paths and exact row cardinality for duplicate rules.
- A green static check is not a passing runtime spec; report exact commands/outcomes.
