# Private AI staging service

`ai-staging` is intentionally opt-in. Merging its Compose definition must not affect the
existing frontend or backend deployment paths.

## Before enabling

1. Confirm the `ghcr.io/<owner>/upnext-ai:develop` package can be pulled on the VPS using the
   existing `GHCR_USERNAME` and `GHCR_TOKEN` deployment credentials.
2. Create `/opt/upnext/env/ai.staging.env` from `env/ai.staging.env.example` and set a unique
   `AI_INTERNAL_JWT_SECRET`. Set exactly the same value in
   `/opt/upnext/env/backend.staging.env`; never reuse a public JWT secret.
3. Leave `AI_LLM_PROVIDER=gemini` in the backend environment for this first container deploy.

## Start and verify

```bash
cd /opt/upnext
set -a && source env/deploy.env && set +a
AI_STAGING_ENV_FILE=../env/ai.staging.env COMPOSE_PROFILES=ai docker compose -f compose/docker-compose.staging.yml pull ai-staging
AI_STAGING_ENV_FILE=../env/ai.staging.env COMPOSE_PROFILES=ai docker compose -f compose/docker-compose.staging.yml up -d ai-staging
docker inspect --format '{{.State.Health.Status}}' upnext-ai-staging
```

The service has no public host port and must not be added to Nginx. Only after it is healthy and
the backend remains stable should the backend flag be changed to `AI_LLM_PROVIDER=upnext-ai`.

## Rollback

Set `AI_LLM_PROVIDER=gemini` and restart only the backend. To stop the private service, run:

```bash
AI_STAGING_ENV_FILE=../env/ai.staging.env COMPOSE_PROFILES=ai docker compose -f compose/docker-compose.staging.yml stop ai-staging
```
