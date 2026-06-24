#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-prod}"
BACKUP_DIR="${BACKUP_DIR:-/opt/upnext/backups/postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

case "$ENVIRONMENT" in
  prod|production)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"
    SERVICE="postgres"
    PREFIX="upnext-prod"
    ;;
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
    SERVICE="postgres-staging"
    PREFIX="upnext-staging"
    ;;
  *)
    echo "Usage: $0 <prod|staging>" >&2
    exit 2
    ;;
esac

mkdir -p "$BACKUP_DIR"
OUT_FILE="${BACKUP_DIR}/${PREFIX}-${TIMESTAMP}.dump.gz"

echo "Creating PostgreSQL backup: ${OUT_FILE}"
docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE" sh -c \
  'pg_dump -Fc -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip -9 > "$OUT_FILE"

chmod 600 "$OUT_FILE"
echo "Backup created: ${OUT_FILE}"

find "$BACKUP_DIR" -type f -name "${PREFIX}-*.dump.gz" -mtime "+${RETENTION_DAYS}" -print -delete
