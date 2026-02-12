# powo_ruby

`powo_ruby` is a small, defensive, **unofficial** Ruby client for the Plants of the World Online (POWO) API.

## Disclaimer

- This gem is **not** an official Kew product.
- POWO's API is **undocumented and may change or break** at any time.
- The API is publicly accessible and does not require authentication, but you should use it responsibly.

**Attribution**: Data and service provided by the Royal Botanic Gardens, Kew (POWO: Plants of the World Online).

## Installation

Add to your Gemfile:

```ruby
gem "powo_ruby"
```

Then:

```bash
bundle install
```

Or install directly:

```bash
gem install powo_ruby
```

## Usage

### Convenience clients (recommended)

This gem exposes two convenience client constructors:

- `PowoRuby.powo` (POWO allow-list + POWO group keys)
- `PowoRuby.ipni` (IPNI allow-list + IPNI group keys)

Both return a configured `PowoRuby::Client` instance (memoized per-thread unless you pass overrides).

#### Basic search (POWO)

```ruby
require "powo_ruby"

response = PowoRuby.powo.search.query(
  query: "Apocynaceae",
  filters: {
    family: "Apocynaceae",
    accepted: true
  }
)

response.total_count #=> Integer or nil
response.results     #=> Array of result hashes
```

#### Lookup by POWO/IPNI identifier

```ruby
taxon = PowoRuby.powo.taxa.lookup("urn:lsid:ipni.org:names:30000618-2")
taxon.raw #=> Hash (schema may change)
```

#### Advanced search (structured)

`advanced_search` only accepts parameters defined in `docs/POWO_SEARCH_TERMS.md`.

Flat form:

```ruby
response = PowoRuby.powo.search.advanced(
  family: "Fabaceae",
  accepted: true,
  limit: 24
)
```

Grouped form:

```ruby
response = PowoRuby.powo.search.advanced(
  name: { family: "Fabaceae", genus: "Acacia" },
  geography: { country: "Brazil" },
  accepted: true
)
```

#### Pagination (Enumerator-based)

POWO uses a cursor for paging. For most use-cases, prefer the `*_each` enumerators.

```ruby
PowoRuby.powo.search.each(query: "Acacia", filters: { accepted: true }).take(50)
```

Or for advanced search:

```ruby
enum = PowoRuby.powo.search.advanced_each(name: { family: "Fabaceae" }, accepted: true)
enum.each do |row|
  puts row["name"]
end
```

## IPNI mode

IPNI is exposed at the same level as POWO, and validates parameters against the **IPNI term list** found in `docs/POWO_SEARCH_TERMS.md`:

```ruby
response = PowoRuby.ipni.search.query(query: "Poa annua", filters: { family: "Poaceae" })
```

Note: POWO's API does not expose a clearly documented `/ipni/...` endpoint under `/api/2`. This gem therefore uses the same `/search` and `/taxon/<id>` endpoints but validates parameters against the IPNI allow-list.

## Configuration

```ruby
PowoRuby.configure do |c|
  c.base_url = "https://powo.science.kew.org/api/2"
  c.timeout = 10
  c.open_timeout = 5
  c.retries = true
end
```

### Logger support

Pass any logger responding to `warn`:

```ruby
require "logger"

PowoRuby.configure do |c|
  c.logger = Logger.new($stdout)
end
```

### Caching support (optional adapter)

Provide an object that responds to `fetch(key, options = nil) { ... }`:

```ruby
cache = {}
adapter = Object.new
def adapter.fetch(key)
  @store ||= {}
  return @store[key] if @store.key?(key)
  @store[key] = yield
end

PowoRuby.configure do |c|
  c.cache = adapter
end
```

You can also pass cache options (e.g. TTL) and a namespace for cache keys:

```ruby
PowoRuby.configure do |c|
  c.cache = Rails.cache
  c.cache_options = { expires_in: 60 } # seconds
  c.cache_namespace = "my_app"
end
```

## CLI (optional)

After installation:

```bash
powo_ruby search "Acacia" --filter accepted=true --filter family=Fabaceae
powo_ruby lookup "urn:lsid:ipni.org:names:30000618-2"
powo_ruby ipni-search "Poa annua" --filter family=Poaceae
```

## Development

```bash
bin/setup
bundle exec rspec
bundle exec rubocop
```

## Example app

A tiny Sinatra app (with basic views for search + taxon lookup) lives at `examples/basic_app`.

```bash
cd examples/basic_app
bundle install
bundle exec rackup
```

## License

MIT. See `LICENSE.txt`.
