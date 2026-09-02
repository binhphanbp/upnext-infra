# UpNext Infrastructure

Production/staging infrastructure for `upnext.works` on Ubuntu 24.04 LTS using Docker Compose, host Nginx, Let's Encrypt, GHCR images, PostgreSQL, n8n, backups, rollback scripts, health checks, and optional Telegram deploy notifications.

This repo contains infrastructure only. It must not contain FE/BE source code, real `.env` files, passwords, tokens, private keys, JWT secrets, database dumps, or logs.

## Quick Start

1. Point DNS records on Name.com to `<VPS_PUBLIC_IP>`:
   `upnext.works`, `www`, `api`, `n8n`, `staging`, `api-staging`.
2. Clone this repo on the VPS:
   ```bash
   sudo mkdir -p /opt/upnext
   sudo git clone <INFRA_REPO_URL> /opt/upnext
   ```
3. Run server setup scripts as a sudo-capable user:
   ```bash
   cd /opt/upnext
   DEPLOY_SSH_PUBLIC_KEY='<YOUR_PUBLIC_KEY>' scripts/server-setup/01-create-deploy-user.sh
   scripts/server-setup/03-install-docker.sh
   scripts/server-setup/05-configure-docker-daemon.sh
   scripts/server-setup/06-create-directories.sh
   scripts/server-setup/04-install-nginx-certbot.sh
   ```
4. Create real env files from examples:
   ```bash
   cp env/frontend.prod.env.example env/frontend.prod.env
   cp env/frontend.staging.env.example env/frontend.staging.env
   cp env/backend.prod.env.example env/backend.prod.env
   cp env/backend.staging.env.example env/backend.staging.env
   # Create this only when preparing the private AI staging rollout.
   cp env/ai.staging.env.example env/ai.staging.env
   cp env/postgres.prod.env.example env/postgres.prod.env
   cp env/postgres.staging.env.example env/postgres.staging.env
   cp env/n8n.env.example env/n8n.env
   cp env/telegram.env.example env/telegram.env
   cp env/deploy.env.example env/deploy.env
   ```
5. Fill deploy variables in `env/deploy.env` before starting compose:
   ```bash
   nano env/deploy.env
   ```
6. Create the Compose runtime file and preserve the current live project namespace:
   ```bash
   cp env/compose.env.example .env
   nano .env
   ```
7. Bootstrap stacks only when provisioning or reconciling an environment:
   ```bash
   scripts/deploy/deploy-stack.sh prod
   scripts/deploy/deploy-stack.sh staging
   ```
8. Issue SSL certificates after DNS resolves:
   ```bash
   sudo certbot --nginx \
     -d upnext.works -d www.upnext.works \
     -d api.upnext.works \
     -d n8n.upnext.works \
     -d staging.upnext.works \
     -d api-staging.upnext.works
   ```

## Deploy

Routine release (the CI entry point) deploys exactly one service:
```bash
scripts/deploy/deploy.sh staging backend
scripts/deploy/deploy.sh staging frontend
scripts/deploy/deploy.sh staging ai
```

The corresponding GHCR image tag is read from `.env`. The backend path takes a
database backup, runs Prisma migrations from the pulled image, recreates only
the backend service, and checks the public health endpoint. Do not use
`deploy-stack.sh` for routine releases.

## Retire legacy monitoring

Uptime Kuma and Beszel are no longer operated. After this change is deployed,
remove their stopped/running containers, data volumes, and Nginx routes once:

```bash
CONFIRM_RETIRE_MONITORING=retire-unused-monitoring \
  scripts/maintenance/retire-unused-monitoring.sh
```

The command has an explicit confirmation because it permanently removes only
the legacy monitoring data. DNS records and old TLS certificates can be left to
expire or removed separately after confirming nothing uses them.

Tag-specific deploy and rollback commands remain available for controlled
manual operations:
```bash
scripts/deploy/deploy-backend.sh prod <image-tag>
scripts/deploy/deploy-backend.sh staging <image-tag>
scripts/deploy/deploy-frontend.sh prod <image-tag>
scripts/deploy/deploy-frontend.sh staging <image-tag>
```

## Required Variables

Real env files on the VPS:
- `env/frontend.prod.env`, `env/frontend.staging.env`
- `env/backend.prod.env`, `env/backend.staging.env`
- `env/ai.staging.env` only when the private `ai` Compose profile is enabled
- `env/postgres.prod.env`, `env/postgres.staging.env`
- `env/n8n.env`, `env/telegram.env`
- `env/deploy.env`
- `.env`, created from `env/compose.env.example`; it holds Compose image tags
  and the live `COMPOSE_PROJECT_NAME`

Deploy shell variables:
- `GITHUB_OWNER`
- `FRONTEND_IMAGE_TAG`, `BACKEND_IMAGE_TAG`
- `FRONTEND_STAGING_IMAGE_TAG`, `BACKEND_STAGING_IMAGE_TAG`
- `GHCR_USERNAME`, `GHCR_TOKEN` if GHCR images are private

GitHub Actions secrets for FE/BE repos:
- `VPS_HOST`
- `VPS_PORT`
- `VPS_USER`
- `VPS_SSH_KEY`
- `GHCR_USERNAME`
- `GHCR_TOKEN`
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

## Operations

Validate compose:
```bash
make validate
```

Backup:
```bash
scripts/backup/backup-postgres.sh prod
```

Restore:
```bash
CONFIRM_RESTORE=restore-prod scripts/backup/restore-postgres.sh prod /opt/upnext/backups/postgres/<backup>.dump.gz
```

Rollback app image:
```bash
scripts/deploy/rollback-frontend.sh prod <previous-tag>
scripts/deploy/rollback-backend.sh prod <previous-tag>
```

## Security Baseline

- UFW should only allow SSH, HTTP, and HTTPS.
- Disable SSH password login only after SSH key login is tested.
- Use the `deploy` user, not root, for deployments.
- PostgreSQL is not published to the public internet.
- App/admin services bind to `127.0.0.1` and are exposed through Nginx only.
- n8n uses basic auth in `env/n8n.env`. Application availability is checked by the deployment health checks and the operational commands in `docs/09-monitoring-alerting.md`.

## Agent Tooling

This repo declares the [Superpowers](https://github.com/obra/superpowers) Claude
Code plugin in `.claude/settings.json`, but that file only records intent —
Claude Code does not auto-install a plugin just because a repo declares it. After
cloning, run once per machine:

```bash
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace --scope project
```

Skip this and `claude plugin list` will show the plugin as `failed to load` inside
this repo. Not using Claude Code, or don't want the plugin? Nothing to do — it has
no effect on the build or runtime.
