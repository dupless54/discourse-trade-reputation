# Repository map

Use this to choose paths before searching. Source code remains authoritative if the map becomes stale.

- `plugin.rb` — plugin entrypoint/registration.
- `app/models/trade_reputation/` — feedback persistence/invariants; read local `AGENTS.md`.
- `app/services/trade_reputation/` — feedback creation/eligibility; read local `AGENTS.md`.
- `app/controllers/trade_reputation/` — JSON endpoints/auth surface; read local `AGENTS.md`.
- `lib/trade_reputation/` — profile queries and Marketplace-contract integration; read local `AGENTS.md`.
- `assets/javascripts/discourse/` — frontend profile/detail UI; read local `AGENTS.md`.
- `db/` — migrations/schema; read `db/AGENTS.md`.
- `spec/` — Ruby/integration specs; read `spec/AGENTS.md`.
- `test/` — frontend/test support when the task references it.
- `docs/` — Marketplace contract, current state, workflow; do not preload wholesale.

Fast read order: root `AGENTS.md` -> task packet -> nearest local `AGENTS.md` -> exact symbol/source -> exact test. Open `DECISIONS.md`, `COMMANDS.md`, or `CURRENT_STATE.md` only when needed.
