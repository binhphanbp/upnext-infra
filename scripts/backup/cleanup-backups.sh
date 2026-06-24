#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/opt/upnext/backups/postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Backup directory does not exist: ${BACKUP_DIR}"
  exit 0
fi

echo "Deleting PostgreSQL backups older than ${RETENTION_DAYS} days from ${BACKUP_DIR}"
find "$BACKUP_DIR" -type f -name "*.dump.gz" -mtime "+${RETENTION_DAYS}" -print -delete
