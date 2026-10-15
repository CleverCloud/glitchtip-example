![Clever Cloud logo](./github-assets/clever-cloud-logo.png)

# Deploy GlitchTip on Clever Cloud

[![GlitchTip – Sentry-compatible Error Tracking](https://img.shields.io/badge/GlitchTip-Sentry%20compatible%20error%20tracking-blue)](https://glitchtip.com)
[![Clever Cloud - PaaS](https://img.shields.io/badge/Clever%20Cloud-PaaS-orange)](https://clever-cloud.com)

This repository deploys [GlitchTip](https://glitchtip.com/), an open-source, Sentry API compatible error tracking platform, on [Clever Cloud](https://clever-cloud.com).

GlitchTip lets you capture and manage application errors with a modern UI and Sentry-compatible SDKs. This example runs the official `glitchtip/glitchtip` image (currently **6.2.6**) on the [Docker runtime](https://www.clever.cloud/developers/doc/applications/docker/), as two applications (web and worker) sharing a [PostgreSQL add-on](https://www.clever.cloud/developers/doc/addons/postgresql/) and a [Redis add-on](https://www.clever.cloud/developers/doc/addons/redis/). Both applications listen on port 8080.

## How it works

- The `Dockerfile` starts from the official GlitchTip image and replaces its entrypoint with `docker-entrypoint.sh`.
- The entrypoint reads `START_TARGET`:
  - `web` (default): runs the upstream `bin/run-migrate.sh` (Django migrations, cache table, Postgres partition maintenance), then starts the Granian web server through `bin/start.sh`. Set `SKIP_INIT=true` to skip the migration step.
  - `worker`: starts a tiny HTTP server on port 8080 so Clever Cloud health checks pass, then runs the GlitchTip background worker and scheduler (`bin/run-worker.sh`).
- GlitchTip 6 listens on port 8000 by default; the entrypoint sets `PORT=8080` (unless already set) to match `CC_DOCKER_EXPOSED_HTTP_PORT`.
- GlitchTip reads the `REDIS_HOST`, `REDIS_PORT` and `REDIS_PASSWORD` variables exposed by the linked Redis add-on and uses Redis as both cache and task queue.

## Project structure

```
.
├── Dockerfile             # FROM glitchtip/glitchtip:<version>, custom entrypoint
├── docker-entrypoint.sh   # web (migrate + serve) or worker, chosen by START_TARGET
├── github-assets/         # README assets
├── CHANGELOG.md
└── LICENSE
```

## Deployment steps

### Before you begin

In the commands below, replace:

- `<ORGANISATION>` with the organisation where GlitchTip will be deployed
- `<GLITCHTIP_DOMAIN>` with the public URL of your instance (e.g. `https://glitchtip.example.com`; without a custom domain, use the `cleverapps.io` domain shown by `clever domain -a glitchtip-web`)
- `<SECRET_KEY>` with a long random secret (e.g. `openssl rand -hex 32`)
- `<EMAIL_URL>` with your mail server URL (e.g. `smtp://user:password@smtp.example.com:587`, or `consolemail://` to only log emails)

### Versions

This example deploys GlitchTip **6.2.6**. To deploy another version, change the `FROM glitchtip/glitchtip:<version>` line in the `Dockerfile`. Since GlitchTip 6, image tags no longer carry a `v` prefix (`6.2.6`, not `v6.2.6`).

### Configuration

Both applications (web and worker) need the same configuration. To avoid duplication, you can use the [Config Provider](https://www.clever.cloud/developers/doc/addons/config-provider/) add-on, populated in the Web Console and linked to both apps. For a fully automated, CLI-only setup, the steps below set environment variables directly on both apps with Clever Tools.

### Deploy with Clever Tools

```bash
# 1. Create the Docker applications
clever create --type docker glitchtip-web --org <ORGANISATION>
clever create --type docker glitchtip-worker --org <ORGANISATION>

# 2. Create and link the PostgreSQL add-on
clever addon create postgresql-addon --plan xxs_sml --addon-version 18 glitchtip-postgres --org <ORGANISATION>
clever service link-addon glitchtip-postgres -a glitchtip-web
clever service link-addon glitchtip-postgres -a glitchtip-worker

# 3. Create and link the Redis add-on (exposes REDIS_HOST, REDIS_PORT and REDIS_PASSWORD)
clever addon create redis-addon --plan s_mono glitchtip-redis --org <ORGANISATION>
clever service link-addon glitchtip-redis -a glitchtip-web
clever service link-addon glitchtip-redis -a glitchtip-worker

# 4. Configure environment variables
eval "$(clever env -F shell -a glitchtip-web)"
clever domain add <YOUR_DOMAIN_NAME> -a glitchtip-web   # optional, custom domain

for app in glitchtip-web glitchtip-worker; do
  clever env set CC_DOCKER_EXPOSED_HTTP_PORT 8080 -a $app
  clever env set DATABASE_URL "$POSTGRESQL_ADDON_URI" -a $app
  clever env set EMAIL_URL "<EMAIL_URL>" -a $app
  clever env set SECRET_KEY "<SECRET_KEY>" -a $app
  clever env set GLITCHTIP_DOMAIN "<GLITCHTIP_DOMAIN>" -a $app
done

clever env set START_TARGET web -a glitchtip-web
clever env set START_TARGET worker -a glitchtip-worker

# 5. Deploy (web first: it applies the database migrations)
clever deploy -a glitchtip-web
clever deploy -a glitchtip-worker
```

### Create an administrator

Open an SSH session on the web application:

```bash
clever ssh -a glitchtip-web
```

and run:

```bash
cd /code && ./manage.py createsuperuser
```

## Running locally

Build and run the image against a local PostgreSQL and Redis:

```bash
docker build -t glitchtip-clever .
docker run --rm -p 8080:8080 \
  -e DATABASE_URL=postgres://postgres:postgres@host.docker.internal:5432/postgres \
  -e REDIS_HOST=host.docker.internal \
  -e SECRET_KEY=change-me-to-something-random \
  -e GLITCHTIP_DOMAIN=http://localhost:8080 \
  -e START_TARGET=web \
  glitchtip-clever
```

Run a second container with `START_TARGET=worker` for background processing.

## Troubleshooting

- Check the logs: `clever logs -a glitchtip-web` and `clever logs -a glitchtip-worker`.
- Check the configuration: `clever env -a glitchtip-web`.
- The web app must listen on `0.0.0.0:8080`; the entrypoint sets `PORT=8080` and `CC_DOCKER_EXPOSED_HTTP_PORT` must be `8080`.
- A `RuntimeWarning` about `ALLOWED_HOSTS` is expected; set `ALLOWED_HOSTS` to your domain(s) to silence it in production.
- If the worker starts before the web app has applied migrations, restart it: `clever restart -a glitchtip-worker`.

## Contributing

Contributions to improve this example are welcome! Please open issues or submit pull requests.

## License

This example is provided under the terms of the MIT license.
