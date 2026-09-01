#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-prod}"
TARGET_TAG="${2:-}"
NOTIFY="${ROOT_DIR}/scripts/notify/telegram.sh"
HEALTHCHECK="${ROOT_DIR}/scripts/deploy/healthcheck.sh"

case "$ENVIRONMENT" in
  prod|production)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"
    SERVICE="backend"
    TAG_VAR="BACKEND_IMAGE_TAG"
    STATE_FILE="${ROOT_DIR}/state/backend.prod.tag"
    HEALTH_URL="https://api.upnext.works/health"
    ;;
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
    SERVICE="backend-staging"
    TAG_VAR="BACKEND_STAGING_IMAGE_TAG"
    STATE_FILE="${ROOT_DIR}/state/backend.staging.tag"
    HEALTH_URL="https://api-staging.upnext.works/health"
    ;;
  *)
    echo "Usage: $0 <prod|staging> [target-tag]" >&2
    exit 2
    ;;
esac

if [[ -z "$TARGET_TAG" ]]; then
  if [[ ! -s "$STATE_FILE" ]]; then
    echo "No saved backend tag exists for ${ENVIRONMENT}; pass an explicit target tag." >&2
    exit 1
  fi
  TARGET_TAG="$(cat "$STATE_FILE")"
fi

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

echo "Rolling back ${SERVICE} app image to ${TARGET_TAG}; migrations are not run during rollback."
export "$TAG_VAR=$TARGET_TAG"
upnext_compose pull "$SERVICE"
upnext_compose up -d --no-deps "$SERVICE"
"$HEALTHCHECK" "$HEALTH_URL" 20 3
echo "$TARGET_TAG" > "$STATE_FILE"
"$NOTIFY" "UpNext ${SERVICE} app image rolled back to ${TARGET_TAG}. Review database migrations manually."
