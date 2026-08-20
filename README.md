# UpNext Infrastructure

Production/staging infrastructure for `upnext.works` on Ubuntu 24.04 LTS using Docker Compose, host Nginx, Let's Encrypt, GHCR images, PostgreSQL, n8n, Uptime Kuma, Beszel, backups, rollback scripts, and Telegram notifications.

This repo contains infrastructure only. It must not contain FE/BE source code, real `.env` files, passwords, tokens, private keys, JWT secrets, database dumps, or logs.

## Quick Start

1. Point DNS records on Name.com to `<VPS_PUBLIC_IP>`:
   `upnext.works`, `www`, `api`, `n8n`, `status`, `monitor`, `staging`, `api-staging`.
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
   cp env/beszel.env.example env/beszel.env
   cp env/telegram.env.example env/telegram.env
   cp env/deploy.env.example env/deploy.env
   ```
5. Fill deploy variables in `env/deploy.env` before starting compose:
   ```bash
   nano env/deploy.env
   ```
6. Start stacks:
   ```bash
   scripts/deploy/deploy-stack.sh prod
   scripts/deploy/deploy-stack.sh staging
   ```
7. Issue SSL certificates after DNS resolves:
   ```bash
   sudo certbot --nginx \
     -d upnext.works -d www.upnext.works \
     -d api.upnext.works \
     -d n8n.upnext.works \
     -d status.upnext.works \
     -d monitor.upnext.works \
     -d staging.upnext.works \
     -d api-staging.upnext.works
   ```

## Deploy

Frontend:
```bash
scripts/deploy/deploy-frontend.sh prod <image-tag>
scripts/deploy/deploy-frontend.sh staging <image-tag>
```

Backend:
```bash
scripts/deploy/deploy-backend.sh prod <image-tag>
scripts/deploy/deploy-backend.sh staging <image-tag>
```

Backend deploy backs up PostgreSQL, pulls the image, runs `npx prisma migrate deploy`, replaces the app container, checks health, and rolls back the app tag on failure. It does not restore the database automatically.

## Required Variables

Real env files on the VPS:
- `env/frontend.prod.env`, `env/frontend.staging.env`
- `env/backend.prod.env`, `env/backend.staging.env`
- `env/ai.staging.env` only when the private `ai` Compose profile is enabled
- `env/postgres.prod.env`, `env/postgres.staging.env`
- `env/n8n.env`, `env/beszel.env`, `env/telegram.env`
- `env/deploy.env`

Deploy shell variables:
- `GITHUB_OWNER`
- `FRONTEND_IMAGE_TAG`, `BACKEND_IMAGE_TAG`
- `FRONTEND_STAGING_IMAGE_TAG`, `BACKEND_STAGING_IMAGE_TAG`
- `GHCR_USERNAME`, `GHCR_TOKEN` if GHCR images are private
- `BESZEL_AGENT_KEY`

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
- n8n uses basic auth in `env/n8n.env`; Uptime Kuma and Beszel require setting admin accounts in their first-run UI.

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
