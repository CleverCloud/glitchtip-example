#!/bin/bash
set -e

# Clever Cloud routes HTTP traffic to CC_DOCKER_EXPOSED_HTTP_PORT (8080).
# GlitchTip 6 defaults to port 8000, so make it listen on 8080 unless told otherwise.
export PORT="${PORT:-8080}"

if [ "${START_TARGET}" = "worker" ]; then
  # The worker serves no HTTP traffic: a dummy server answers Clever Cloud health checks.
  mkdir -p /tmp/sandboxed
  cd /tmp/sandboxed && nohup python -m http.server "${PORT}" &
  cd /code
  exec ./bin/run-worker.sh
else
  # Apply migrations, create the cache table and maintain Postgres partitions on each start.
  if [ "${SKIP_INIT}" != "true" ]; then
    ./bin/run-migrate.sh
  fi
  exec ./bin/start.sh
fi
