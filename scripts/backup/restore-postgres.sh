#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-}"
BACKUP_FILE="${2:-}"

if [[ -z "$ENVIRONMENT" || -z "$BACKUP_FILE" ]]; then
  echo "Usage: CONFIRM_RESTORE=restore-$ENVIRONMENT $0 <prod|staging> <backup-file.dump.gz>" >&2
  exit 2
fi

case "$ENVIRONMENT" in
  prod|production)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"
    SERVICE="postgres"
    CONFIRM_VALUE="restore-prod"
    ;;
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
    SERVICE="postgres-staging"
    CONFIRM_VALUE="restore-staging"
    ;;
  *)
    echo "Usage: CONFIRM_RESTORE=restore-$ENVIRONMENT $0 <prod|staging> <backup-file.dump.gz>" >&2
    exit 2
    ;;
esac

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Backup file not found: ${BACKUP_FILE}" >&2
  exit 1
fi

if [[ "${CONFIRM_RESTORE:-}" != "$CONFIRM_VALUE" ]]; then
  echo "Refusing destructive restore." >&2
  echo "This will drop and recreate objects in the target database." >&2
  echo "Run with CONFIRM_RESTORE=${CONFIRM_VALUE} after verifying the backup and target." >&2
  exit 1
fi

if [[ -f "${ROOT_DIR}/env/deploy.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/env/deploy.env"
  set +a
fi

echo "Restoring ${BACKUP_FILE} into ${ENVIRONMENT} PostgreSQL"
gzip -dc "$BACKUP_FILE" | docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE" sh -c \
  'pg_restore --clean --if-exists --no-owner --no-privileges -U "$POSTGRES_USER" -d "$POSTGRES_DB"'

echo "Restore completed."
