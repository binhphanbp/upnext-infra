# Deployment

Production branch mapping:

- Frontend `main` -> production
- Backend `main` -> production

Staging branch mapping:

- Frontend `develop` -> staging
- Backend `dev` -> staging

Deploy frontend:
```bash
scripts/deploy/deploy-frontend.sh prod <image-tag>
scripts/deploy/deploy-frontend.sh staging <image-tag>
```

Deploy backend:
```bash
scripts/deploy/deploy-backend.sh prod <image-tag>
scripts/deploy/deploy-backend.sh staging <image-tag>
```

Backend flow:
1. Backup PostgreSQL.
2. Pull new backend image.
3. Run `npx prisma migrate deploy`.
4. Replace backend container.
5. Run healthcheck.
6. Roll back app container if healthcheck fails.

Database restore is manual by design.
