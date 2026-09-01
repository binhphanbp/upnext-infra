# Docker Compose

Production:
```bash
docker compose --project-name upnext --env-file .env -f compose/docker-compose.prod.yml config
docker compose --project-name upnext --env-file .env -f compose/docker-compose.prod.yml up -d
```

Staging:
```bash
docker compose --project-name upnext --env-file .env -f compose/docker-compose.staging.yml config
docker compose --project-name upnext --env-file .env -f compose/docker-compose.staging.yml up -d
```

Create `.env` from `env/compose.env.example`. On the current VPS it must retain
`COMPOSE_PROJECT_NAME=upnext`; changing it would create a second namespace
instead of managing the running containers. Do not pass `--remove-orphans` when
production and staging share that project namespace.

Required variables in `env/deploy.env`:
- `GITHUB_OWNER`
- `FRONTEND_IMAGE_TAG`
- `BACKEND_IMAGE_TAG`
- `FRONTEND_STAGING_IMAGE_TAG`
- `BACKEND_STAGING_IMAGE_TAG`
- `BESZEL_AGENT_KEY`

Internal ports are bound to `127.0.0.1`; PostgreSQL has no host port mapping.
