#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-prod}"

case "$ENVIRONMENT" in
  prod|production)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"
    SERVICE="backend"
    ;;
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
    SERVICE="backend-staging"
    ;;
  *)
    echo "Usage: $0 <prod|staging>" >&2
    exit 2
    ;;
esac

if [[ -f "${ROOT_DIR}/env/deploy.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/env/deploy.env"
  set +a
fi

echo "Running Prisma migrations for ${SERVICE}"
docker compose -f "$COMPOSE_FILE" run --rm "$SERVICE" npx prisma migrate deploy
