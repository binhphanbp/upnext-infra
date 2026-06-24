# Rollback

Frontend rollback:
```bash
scripts/deploy/rollback-frontend.sh prod <previous-tag>
scripts/deploy/rollback-frontend.sh staging <previous-tag>
```

Backend rollback:
```bash
scripts/deploy/rollback-backend.sh prod <previous-tag>
scripts/deploy/rollback-backend.sh staging <previous-tag>
```

Backend rollback only reverts the app image. It does not automatically restore PostgreSQL because migrations may be irreversible or partially compatible. If a migration must be reversed, decide between:

- forward fix migration,
- explicit down migration if available and reviewed,
- full restore from backup after stakeholder approval.
