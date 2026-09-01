# Deployment

Production branch mapping:

- Frontend `main` -> production
- Backend `main` -> production

Staging branch mapping:

- Frontend `develop` -> staging
- Backend `dev` -> staging

Deploy frontend:
```bash
scripts/deploy/deploy.sh staging frontend
```

Deploy backend:
```bash
scripts/deploy/deploy.sh staging backend
```

Deploy private AI staging only after `env/ai.staging.env` is provisioned:
```bash
scripts/deploy/deploy.sh staging ai
```

The canonical script reads tags and the current Compose project identity from
`/opt/upnext/.env`, deploys only the selected service, and never uses
`--remove-orphans`. GitHub Actions in the frontend/backend repos call this
script directly.

Backend flow:
1. Create and verify a PostgreSQL backup.
2. Pull the configured backend image.
3. Run `npx --no-install prisma migrate deploy` from that image.
4. Replace only the backend container.
5. Run the public healthcheck.

Database restore is manual by design. `deploy-stack.sh` is only for initial
provisioning or an explicit full-stack reconcile, never for a routine release.
