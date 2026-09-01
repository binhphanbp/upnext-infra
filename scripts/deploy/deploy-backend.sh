#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-prod}"
NEW_TAG="${2:?Usage: $0 <prod|staging> <image-tag>}"
STATE_DIR="${ROOT_DIR}/state"
NOTIFY="${ROOT_DIR}/scripts/notify/telegram.sh"
HEALTHCHECK="${ROOT_DIR}/scripts/deploy/healthcheck.sh"
BACKUP="${ROOT_DIR}/scripts/backup/backup-postgres.sh"
MIGRATE="${ROOT_DIR}/scripts/deploy/migrate-backend.sh"

mkdir -p "$STATE_DIR"

case "$ENVIRONMENT" in
  prod|production)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"
    SERVICE="backend"
    TAG_VAR="BACKEND_IMAGE_TAG"
    STATE_FILE="${STATE_DIR}/backend.prod.tag"
    HEALTH_URL="https://api.upnext.works/health"
    ;;
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
    SERVICE="backend-staging"
    TAG_VAR="BACKEND_STAGING_IMAGE_TAG"
    STATE_FILE="${STATE_DIR}/backend.staging.tag"
    HEALTH_URL="https://api-staging.upnext.works/health"
    ;;
  *)
    echo "Usage: $0 <prod|staging> <image-tag>" >&2
    exit 2
    ;;
esac

if [[ -f "${ROOT_DIR}/env/deploy.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/env/deploy.env"
  set +a
fi

# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/deploy/compose-runtime.sh"

if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_TOKEN:-}" ]]; then
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin
fi

PREVIOUS_TAG=""
if [[ -f "$STATE_FILE" ]]; then
  PREVIOUS_TAG="$(cat "$STATE_FILE")"
fi

echo "Backing up PostgreSQL before backend deploy"
"$BACKUP" "$ENVIRONMENT"

echo "Deploying ${SERVICE} tag ${NEW_TAG}"
export "$TAG_VAR=$NEW_TAG"
upnext_compose pull "$SERVICE"

echo "Running migrations before replacing the running backend"
"$MIGRATE" "$ENVIRONMENT"

upnext_compose up -d --no-deps "$SERVICE"

if "$HEALTHCHECK" "$HEALTH_URL" 20 3; then
  echo "$NEW_TAG" > "$STATE_FILE"
  "$NOTIFY" "UpNext ${SERVICE} deployed successfully: ${NEW_TAG}"
  exit 0
fi

echo "Deploy failed for ${SERVICE}" >&2
"$NOTIFY" "UpNext ${SERVICE} deploy failed after migration: ${NEW_TAG}. Database was not restored automatically."

if [[ -n "$PREVIOUS_TAG" ]]; then
  echo "Rolling back app container ${SERVICE} to ${PREVIOUS_TAG}; database restore is intentionally manual."
  export "$TAG_VAR=$PREVIOUS_TAG"
  upnext_compose pull "$SERVICE"
  upnext_compose up -d --no-deps "$SERVICE"
  "$HEALTHCHECK" "$HEALTH_URL" 20 3
  "$NOTIFY" "UpNext ${SERVICE} app rolled back to ${PREVIOUS_TAG}. Review migrations manually."
else
  echo "No previous tag found; app rollback skipped." >&2
fi

exit 1
