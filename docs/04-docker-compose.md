# Docker Compose

Production:
```bash
set -a; source env/deploy.env; set +a
docker compose -f compose/docker-compose.prod.yml config
docker compose -f compose/docker-compose.prod.yml up -d
```

Staging:
```bash
set -a; source env/deploy.env; set +a
docker compose -f compose/docker-compose.staging.yml config
docker compose -f compose/docker-compose.staging.yml up -d
```

Required variables in `env/deploy.env`:
- `GITHUB_OWNER`
- `FRONTEND_IMAGE_TAG`
- `BACKEND_IMAGE_TAG`
- `FRONTEND_STAGING_IMAGE_TAG`
- `BACKEND_STAGING_IMAGE_TAG`
- `BESZEL_AGENT_KEY`

Internal ports are bound to `127.0.0.1`; PostgreSQL has no host port mapping.
