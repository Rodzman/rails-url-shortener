# rails-url-shortener

A small, production-shaped URL shortener built as a Rails 8.1 API-only app.

```sh
# create
curl -s -X POST localhost:3000/api/v1/links -H 'Content-Type: application/json' \
  -d '{"url":"https://rubyonrails.org/doctrine","slug":"doctrine"}'
# → {"slug":"doctrine","short_url":"http://localhost:3000/doctrine","original_url":"...","clicks_count":0,...}

# follow (302) — every visit is recorded
curl -i localhost:3000/doctrine

# stats
curl -s localhost:3000/api/v1/links/doctrine/stats
# → {"total_clicks":1,"unique_visitors_today":1,"last_7_days":[...],"top_referrers":[...]}
```

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/api/v1/links` | Create a link. Body: `url` (required), `slug` (optional, 3-32 chars `[A-Za-z0-9_-]`), `expires_at` (optional ISO 8601). Returns `201` or `422` with field errors. Rate limited to 30/min per IP (`429`). |
| `GET` | `/api/v1/links/:slug` | Link metadata and click count. |
| `GET` | `/api/v1/links/:slug/stats` | Total clicks, unique visitors today, clicks per day for the last 7 days, top 5 referrers. |
| `GET` | `/:slug` | `302` redirect to the original URL. `404` for unknown slugs, `410 Gone` after expiry. |
| `GET` | `/up` | Health check. |

## Design decisions

- **API-only Rails** (`ActionController::API`), SQLite by default. Swapping
  the adapter is a one-line change in `config/database.yml`; nothing here is
  SQLite-specific (stats grouping is done in Ruby on purpose).
- **Slugs**: 7 random alphanumeric characters (about 3.5 trillion combinations)
  with collision retry, or a user-chosen slug validated against a format and a
  reserved list (`api`, `up`, ...). Uniqueness is case-insensitive at the
  application layer and enforced by a unique index.
- **URL validation**: only `http`/`https` with a host. `javascript:` and
  `data:` URLs are rejected, so the redirect can never become an XSS vector.
- **Redirects are 302, not 301**: a permanent redirect lets browsers skip the
  server on repeat visits, which would make click counts meaningless.
- **Click tracking** stores referrer and user agent plus a `visitor_hash`:
  SHA-256 of a daily-rotating salt, the IP and the user agent. That allows a
  "unique visitors today" count without storing IP addresses. `clicks_count`
  is a counter cache, so the hot path (`GET /:slug`) does one insert and one
  update.
- **Rate limiting** uses Rails' built-in `rate_limit` with a dedicated memory
  store so it also works in the test environment (where the app cache is the
  null store). For several processes, point it at a shared store.
- **Errors are JSON** everywhere (`{"error": ...}` or `{"errors": {field: [...]}}`),
  including `RecordNotFound`.

## Running

Requires Ruby 3.3 (see `.ruby-version`).

```sh
bin/setup --skip-server   # bundle install, db:prepare
bin/rails server          # http://localhost:3000
```

```sh
bin/rails test            # Minitest: model + integration tests
bin/rubocop               # rubocop-rails-omakase
bin/brakeman --no-pager   # static security analysis
bin/ci                    # all of the above plus bundler-audit (Rails 8.1 CI runner)
```

### Docker

The generated production `Dockerfile` is kept as-is. It expects a
`RAILS_MASTER_KEY` and persists the SQLite database under `/rails/storage`:

```sh
docker build -t rails-url-shortener .
docker run -p 3000:3000 -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -v $(pwd)/storage:/rails/storage rails-url-shortener
```

`config/master.key` is ignored by git; generate your own with
`bin/rails credentials:edit` if you cloned this without one.

## Layout

```
app/models/link.rb                     validation, slug generation, expiry, record_click!
app/models/click.rb                    counter cache + privacy-preserving visitor hash
app/controllers/api/v1/links_controller.rb   create / show / stats, rate limited
app/controllers/redirects_controller.rb      GET /:slug
app/serializers/link_serializer.rb     public JSON shape of a link
app/queries/link_stats.rb              per-day and per-referrer aggregation
test/                                  Minitest model and integration tests
```

## License

MIT
