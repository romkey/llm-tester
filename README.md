# LLM Inference Server Tester

A Rails 8 skeleton for testing LLM inference servers locally. Built with Ruby, SQLite, Bootstrap, Sidekiq, and Redis, running under Docker.

## Stack

- Ruby 3.4.3
- Rails 8.1.3
- SQLite 3
- Bootstrap 5 (cssbundling-rails)
- Sidekiq 8 + Redis 7
- Docker Compose for development, tests, and lint

## Features

- **Servers dashboard** — view all servers and models with health status
- **Test runs** — paginated history of every test execution with pass/fail details
- **Settings** — manage servers (Ollama/OpenAI), models, and test definitions
- **Scheduled testing** — Sidekiq runs due tests every minute based on per-test frequency
- **Model sync** — autopopulate models from server APIs when creating/syncing servers

## Quick start

```bash
docker compose up --build
```

Open [http://localhost:3000](http://localhost:3000). Sidekiq dashboard: [http://localhost:3000/sidekiq](http://localhost:3000/sidekiq).

Redis is exposed on port **6380** (mapped from container port 6379) to avoid collisions with other local Redis instances.

## Docker Compose projects

| Project | Command | Purpose |
|---------|---------|---------|
| Development | `docker compose up --build` | Web app + Sidekiq + Redis |
| Tests | `docker compose -f docker-compose.test.yml up --build --abort-on-container-exit` | Run test suite |
| Lint | `docker compose -f docker-compose.lint.yml up --build --abort-on-container-exit` | Run RuboCop |

All compose projects mount application code from the working tree. Only dependencies are baked into the dev base image (`docker/Dockerfile.dev`).

## Qualified service names

Container and volume names are prefixed with `llm-tester-` to avoid collisions with other projects:

- `llm-tester-web`, `llm-tester-sidekiq`, `llm-tester-redis`
- `llm-tester-test`, `llm-tester-test-redis`, `llm-tester-lint`

If PostgreSQL is added later, use names like `llm-tester-postgres` (see commented example in `docker-compose.yml`).

## Local development (without Docker)

Requires Ruby 3.4.3, Node.js, Yarn, and a local Redis instance.

```bash
bundle install
yarn install
yarn build:css
REDIS_URL=redis://localhost:6379/0 bin/rails db:prepare
bin/dev
```

## Tests and lint

```bash
bin/rails test
bin/rubocop
```

Or via Docker Compose (see table above).

## Production image

The root `Dockerfile` builds a production image. GitHub Actions publishes to GHCR on pushes to `main` with the `latest` tag.

```bash
docker build -t llm-tester .
```

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection for Sidekiq |
| `SIDEKIQ_CONCURRENCY` | `5` | Sidekiq worker concurrency |

No authentication is configured. This app is intended for friendly local environments only.
