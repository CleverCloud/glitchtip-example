![Clever Cloud logo](/github-assets/clever-cloud-logo.png)

# GlitchTip on Clever Cloud

[![GlitchTip – Sentry-compatible Error Tracking](https://img.shields.io/badge/GlitchTip-Sentry%20compatible%20error%20tracking-blue)](https://glitchtip.com)
[![Clever Cloud - PaaS](https://img.shields.io/badge/Clever%20Cloud-PaaS-orange)](https://clever-cloud.com)

## Overview

This repository provides a starting point for running [GlitchTip](https://glitchtip.com/) — an open-source, Sentry API compatible error tracking platform — on [Clever Cloud](https://clever-cloud.com).

GlitchTip lets you capture and manage application errors with a modern UI and Sentry-compatible SDKs. This example outlines the core components and configuration you’ll need on Clever Cloud. Deployment instructions are intentionally omitted here and can be added later.

## Prerequisites

- A [Clever Cloud](https://www.clever-cloud.com/) account
- (Optional) A custom domain for production use
- Basic familiarity with environment variables and service add-ons (PostgreSQL and Redis)

## Deployment Guide

Glitchtip comes with a Dockerfile, which means we will use a [docker runtime](https://www.clever.cloud/developers/doc/applications/docker/). It also requires a PostgreSQL Database and a Redis cache, which means we will deploy a [PostgreSQL addon](https://www.clever.cloud/developers/doc/addons/postgresql/) and a [Redis addon](https://www.clever.cloud/developers/doc/addons/redis/). 

### Before You Begin

Before starting the deployment process, you'll need to decide on:

- **Application Name**: Choose a unique name for your Kestra application (e.g., `my-kestra-app`)
- **Domain Name**: Optionally, choose a domain name for your application

You'll use these values throughout the deployment process. In the commands below, replace:
- `<ORGANISATION>` with the name of your organisation where the Glitchtip instance will be deployed
- `<APP_NAME>` with your chosen application name
- `<YOUR_DOMAIN_NAME>` with your domain name (if applicable)
- `<SECRET_KEY>` with your chosen secret key for Glitchtip
- `<EMAIL_URL>` with your chosen email server for Glitchtip

### Important Notes

#### Versions

In the example we are setting-up the latest version of Glitchtip, currently the v5.1.0. You can deploy other versions by changing the `FROM glitchtip/glitchtip:<version>` line in the `Dockerfile`. 

#### Configuration

We are deploying two applications (web and worker) and we need to inject the configuration to both of them.

To avoid duplication, you can use the [Config Provider](https://www.clever.cloud/developers/doc/addons/config-provider/) add-on and link it to both apps. If you prefer Config Provider, populate it in the Web Console and link it to both apps.

For a fully automated, CLI-only setup, this example sets environment variables directly on both apps with Clever Tools, because Config Provider cannot currently be populated via the CLI.

### Deployment steps

Using the Clever Cloud CLI:

```bash
# 1. Create the docker applications:
clever create --type docker glitchtip-web --org <ORGANISATION>
clever create --type docker glitchtip-worker --org <ORGANISATION>

# 2. Create and link the PG addon
clever addon create postgresql-addon --plan s_sml --addon-version 15 glitchtip-postgres --org <ORGANISATION>
clever service link-addon glitchtip-postgres -a glitchtip-web
clever service link-addon glitchtip-postgres -a glitchtip-worker

# 3. Create and link the Redis addon
clever addon create redis-addon --plan s_mono glitchtip-redis --org <ORGANISATION>
clever service link-addon glitchtip-redis -a glitchtip-web
clever service link-addon glitchtip-redis -a glitchtip-worker

# 4. Configure environment variables
eval "$(clever env -F shell --alias glitchtip-web)"
clever domain add --alias glitchtip-web <GLITCHTIP_DOMAIN>

clever env set CC_DOCKER_EXPOSED_HTTP_PORT 8080 -a glitchtip-web
clever env set CC_DOCKER_EXPOSED_HTTP_PORT 8080 -a glitchtip-worker

clever env set DATABASE_URL $POSTGRESQL_ADDON_URI -a glitchtip-web
clever env set DATABASE_URL $POSTGRESQL_ADDON_URI -a glitchtip-worker

clever env set REDIS_HOST $REDIS_HOST -a glitchtip-web
clever env set REDIS_HOST $REDIS_HOST -a glitchtip-worker

clever env set REDIS_PASSWORD $REDIS_PASSWORD -a glitchtip-web
clever env set REDIS_PASSWORD $REDIS_PASSWORD -a glitchtip-worker

clever env set REDIS_PORT $REDIS_PORT -a glitchtip-web
clever env set REDIS_PORT $REDIS_PORT -a glitchtip-worker

clever env set EMAIL_URL <EMAIL_URL> -a glitchtip-web
clever env set EMAIL_URL <EMAIL_URL> -a glitchtip-worker

clever env set SECRET_KEY <SECRET_KEY> -a glitchtip-web
clever env set SECRET_KEY <SECRET_KEY> -a glitchtip-worker

clever env set GLITCHTIP_DOMAIN <GLITCHTIP_DOMAIN> -a glitchtip-web
clever env set GLITCHTIP_DOMAIN <GLITCHTIP_DOMAIN> -a glitchtip-worker

#glitchtip-web custom env
clever env set CC_RUN_SUCCEEDED_HOOK "./manage.py migrate" -a glitchtip-web
clever env set START_TARGET "web" -a glitchtip-web
#glitchtip-worker custom env
clever env set START_TARGET "worker" -a glitchtip-worker

# 5. Deploy the application
clever deploy -a glitchtip-web
clever deploy -a glitchtip-worker
```

Your glitchtip is now almost ready to use. One last action is required: you need to create a super user to administrate Glitchtip.

Connect in SSH to your Clever application:

```bash
clever ssh -a glitchtip-web
```

and run

```bash 
./manage.py createsuperuser
```

## Contributing

Contributions to improve this example are welcome! Please open issues or submit pull requests.

## License

This example is provided under the terms of the MIT license.
