# Backup and Restore

Backup uses `pg_dump -Fc`, compresses with gzip, and stores files in `/opt/upnext/backups/postgres`.

Run backup:
```bash
scripts/backup/backup-postgres.sh prod
scripts/backup/backup-postgres.sh staging
```

Default retention is 14 days:
```bash
RETENTION_DAYS=14 scripts/backup/cleanup-backups.sh
```

Restore is destructive and requires explicit confirmation:
```bash
CONFIRM_RESTORE=restore-prod scripts/backup/restore-postgres.sh prod /opt/upnext/backups/postgres/<backup>.dump.gz
```

Before production restore:
- Confirm the backup file and timestamp.
- Stop write traffic if possible.
- Take a fresh backup.
- Notify stakeholders.
