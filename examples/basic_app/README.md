# Example app: `powo_ruby` + Sinatra

This folder is a tiny Sinatra app that exercises the gem with a couple basic views:

- Search (query + a few optional filters)
- Taxon lookup by identifier

Its dependencies are **not** gem runtime dependencies and are **excluded from the packaged gem**.

## Run it

From the repo root:

```bash
cd examples/basic_app
bundle install
bundle exec rackup
```

Then open `http://localhost:9292`.

## Optional configuration

You can override a few settings via env vars:

```bash
POWO_BASE_URL="https://powo.science.kew.org/api/2" \
POWO_TIMEOUT=10 \
POWO_OPEN_TIMEOUT=5 \
POWO_RETRIES=true \
bundle exec rackup
```

## Notes

- POWO's API is undocumented and may change. The views intentionally display raw JSON to make schema drift obvious.

