#!/usr/bin/env bash
# Controlled engine-image rollout for pgvector. Retains PostgreSQL 16 volume,
# takes a backup first, and deliberately does not run application migrations.

set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-}"

if [[ "${CONFIRM_ENABLE_PGVECTOR:-}" != "enable-pgvector" ]]; then
  echo "Refusing to change the database image without CONFIRM_ENABLE_PGVECTOR=enable-pgvector." >&2
  echo "Usage: CONFIRM_ENABLE_PGVECTOR=enable-pgvector $0 <staging|production>" >&2
  exit 2
fi

case "$ENVIRONMENT" in
  staging) COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"; SERVICE="postgres-staging" ;;
  prod|production) COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"; SERVICE="postgres" ;;
  *) echo "Usage: CONFIRM_ENABLE_PGVECTOR=enable-pgvector $0 <staging|production>" >&2; exit 2 ;;
esac

export COMPOSE_FILE
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/deploy/compose-runtime.sh"

echo "Creating a PostgreSQL backup before changing the ${ENVIRONMENT} engine image"
"${ROOT_DIR}/scripts/backup/backup-postgres.sh" "$ENVIRONMENT"

echo "Pulling the pgvector PostgreSQL image"
upnext_compose pull "$SERVICE"

echo "Recreating ${SERVICE} only; its existing PostgreSQL 16 volume is retained"
upnext_compose up -d --no-deps --force-recreate "$SERVICE"

for attempt in $(seq 1 20); do
  if upnext_compose exec -T "$SERVICE" sh -ec 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'; then
    "${ROOT_DIR}/scripts/deploy/verify-pgvector.sh" "$ENVIRONMENT"
    echo "pgvector engine capability rollout completed for ${ENVIRONMENT}."
    echo "Deploy the backend RAG migration next, then verify with --require-installed."
    exit 0
  fi
  echo "PostgreSQL readiness attempt ${attempt}/20 failed; retrying in 3s"
  sleep 3
done

echo "PostgreSQL did not become ready after the pgvector image rollout." >&2
exit 1
