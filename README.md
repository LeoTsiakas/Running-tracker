# Running Tracker

A Rails app for logging your runs, importing them from Strava and tracking your progress over time.

## Features

- Sign up with email and password, or with Google
- Log runs by hand (distance, time, date)
- Connect Strava: a scheduled Sidekiq job imports new activities every 5 minutes
- Filter runs by date range (powered by Typesense) and see them on a chart

## Tech stack

Rails 8.1 · Ruby 3.2.2 · SQLite · Hotwire (Turbo, Stimulus) with importmap · Tailwind CSS 4 · Devise + OmniAuth · Sidekiq + sidekiq-scheduler · Typesense · Draper · Sentry · Minitest

## Requirements

- Ruby 3.2.2
- Redis on `localhost:6379` (for Sidekiq)
- Docker (runs Typesense and Mailpit)

## Setup

```bash
git clone git@github.com:LeoTsiakas/Running-tracker.git
cd Running-tracker
bin/setup --skip-server   # installs gems and prepares the database
```

### Credentials

`config/credentials.yml.enc` is encrypted with a key that isn't in the repo. Replace it with your own:

```bash
rm config/credentials.yml.enc
bin/rails credentials:edit
```

```yaml
google:
  client_id: ...
  client_secret: ...
strava:
  client_id: ...
  client_secret: ...
```

- **Google**: create an OAuth client in Google Cloud Console with the redirect URI `http://localhost:3000/auth/google_oauth2/callback`.
- **Strava**: create an API application at <https://www.strava.com/settings/api> with the Authorization Callback Domain `localhost`.

The app runs without these keys, but Google sign-in and the Strava import won't work.

## Running locally

Run each command in its own terminal:

```bash
docker compose up typesense mailpit   # search and local email
bin/dev                               # Rails server and Tailwind watcher on :3000
bundle exec sidekiq                   # background jobs and the Strava sync schedule
```

Open <http://localhost:3000>. Use port 3000: the Strava redirect URI is hardcoded to it.

### Email

In development, emails go to Mailpit instead of real inboxes. Read them at <http://localhost:8025>, or preview them without sending at <http://localhost:3000/rails/mailers>.

The Typesense connection defaults to `localhost:8108` with the API key `devkey`, matching `docker-compose.yml`. Override it with `TYPESENSE_HOST`, `TYPESENSE_PORT`, `TYPESENSE_PROTOCOL` and `TYPESENSE_API_KEY`.

### Troubleshooting

- **`The asset "tailwind.css" is not present in the asset pipeline`**: the CSS hasn't been built. Start the app with `bin/dev`, or build it once with `bin/rails tailwindcss:build`.
- **Runs are in the database but don't show up**: the Typesense index is empty or stale, for example after resetting Docker volumes. Rebuild it with `bin/rails runner 'Metric.reindex'`.

## Tests

```bash
bin/rails test
```

The suite needs neither Typesense nor Redis: search indexing is turned off in tests and Sidekiq runs in fake mode.
