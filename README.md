# LLM Inference Server Tester

A Rails 8 skeleton for testing LLM inference servers locally. Built with Ruby, SQLite, Bootstrap, Sidekiq, and Redis, running under Docker.

## Stack

- Ruby 3.4.3
- Rails 8.1.3
- Node.js 24 LTS
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
| Production | `docker compose -f docker-compose.production.yml up -d` | Published GHCR image + persistent SQLite |
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

The root `Dockerfile` builds a production image. GitHub Actions publishes to GHCR **only when you push a version tag** (e.g. `v1.0.0`).

```bash
git tag v1.0.0
git push origin v1.0.0
```

Update the `VERSION` file in the same commit as each release tag (e.g. `v1.0.0`). The footer reads it at runtime; Docker images include it automatically.

That triggers the **Docker Publish** workflow, which builds the image tagged with the version, semver aliases, and `latest`.

```bash
docker build -t llm-tester .
```

The app footer shows the version from the `VERSION` file and a GitHub link from `config/github_repository`.

## Production deployment

Use `docker-compose.production.yml` to run the published image from GHCR with persistent SQLite storage.

```bash
cp .env.production.example .env.production
# Generate a secret once: bin/rails secret
# Paste into .env or .env.production as SECRET_KEY_BASE=...

docker login ghcr.io
docker compose -f docker-compose.production.yml pull
docker compose -f docker-compose.production.yml up -d
```

Open [http://localhost:8080](http://localhost:8080) (or the port set in `LLM_TESTER_PORT`).

SQLite databases and uploaded files are stored in the **`llm-tester-prod-storage`** Docker volume mounted at `/rails/storage`, so data survives container rebuilds and image upgrades. The running version is shown in the app footer (from the `VERSION` file baked into the image).

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY_BASE` | — (required in production) | Rails secret for production Docker deploys |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection for Sidekiq |
| `SIDEKIQ_CONCURRENCY` | `5` | Sidekiq worker concurrency |

Version and GitHub repository metadata come from `VERSION` and `config/github_repository` in the repo (with git fallbacks in local development). No environment variables needed.

No authentication is configured. This app is intended for friendly local environments only.
