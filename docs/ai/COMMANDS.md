# Validation commands

Run from a Discourse checkout with this repository installed under `plugins/discourse-trade-reputation`.

## Targeted first
- One Ruby spec: `LOAD_PLUGINS=1 bin/rspec plugins/discourse-trade-reputation/spec/path/to/example_spec.rb`
- Plugin Ruby specs: `bundle exec rake "plugin:spec[discourse-trade-reputation]"`
- Plugin QUnit, only when frontend tests are relevant: `CI=1 bundle exec rake "plugin:qunit[discourse-trade-reputation]"`
- After plugin migration changes: `LOAD_PLUGINS=1 bundle exec rake db:migrate`

## CI source
`.github/workflows/discourse-plugin.yml` runs on pull requests and `main` pushes and delegates to `discourse/.github/.github/workflows/discourse-plugin.yml@v1` with linting skipped. Treat only the workflow result for the latest exact head SHA as CI evidence.

## Discipline
Use the narrowest relevant check first. Never claim a command or CI run passed unless it actually ran.
