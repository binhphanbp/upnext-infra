#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-prod}"

case "$ENVIRONMENT" in
  prod|production)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"
    ;;
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
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

echo "Starting ${ENVIRONMENT} stack with ${COMPOSE_FILE}"
docker compose -f "$COMPOSE_FILE" pull
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
docker compose -f "$COMPOSE_FILE" ps
