# Changelog

## [2026-10-15]

### Changed
- GlitchTip image: `v5.1.0` → `6.2.6` (MAJOR; upstream switched from Celery to django-vtasks, from uWSGI to Granian, and dropped the `v` tag prefix)
- PostgreSQL add-on in the deployment steps: 15 → 18
- `docker-entrypoint.sh`: worker now runs `bin/run-worker.sh` (the former `run-celery-with-beat.sh` is deprecated), web runs `bin/run-migrate.sh` before starting (replaces the `CC_RUN_SUCCEEDED_HOOK` migration hook), and `PORT` defaults to 8080 since GlitchTip 6 listens on 8000 by default
- README normalized to the Clever Cloud example format (how it works, project structure, running locally, troubleshooting); removed redundant Redis variable copies, since the linked add-on already exposes them

### Notes
- The Python runtime (3.14) is baked into the upstream GlitchTip image and is not controlled by this repository
