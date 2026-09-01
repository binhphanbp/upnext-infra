#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-prod}"
NEW_TAG="${2:?Usage: $0 <prod|staging> <image-tag>}"
STATE_DIR="${ROOT_DIR}/state"
NOTIFY="${ROOT_DIR}/scripts/notify/telegram.sh"
HEALTHCHECK="${ROOT_DIR}/scripts/deploy/healthcheck.sh"

mkdir -p "$STATE_DIR"

case "$ENVIRONMENT" in
  prod|production)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"
    SERVICE="frontend"
    TAG_VAR="FRONTEND_IMAGE_TAG"
    STATE_FILE="${STATE_DIR}/frontend.prod.tag"
    HEALTH_URL="https://upnext.works/"
    ;;
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
    SERVICE="frontend-staging"
    TAG_VAR="FRONTEND_STAGING_IMAGE_TAG"
    STATE_FILE="${STATE_DIR}/frontend.staging.tag"
    HEALTH_URL="https://staging.upnext.works/"
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

echo "Deploying ${SERVICE} tag ${NEW_TAG}"
export "$TAG_VAR=$NEW_TAG"
upnext_compose pull "$SERVICE"
upnext_compose up -d --no-deps "$SERVICE"

if "$HEALTHCHECK" "$HEALTH_URL" 20 3; then
  echo "$NEW_TAG" > "$STATE_FILE"
  "$NOTIFY" "UpNext ${SERVICE} deployed successfully: ${NEW_TAG}"
  exit 0
fi

echo "Deploy failed for ${SERVICE}" >&2
"$NOTIFY" "UpNext ${SERVICE} deploy failed: ${NEW_TAG}"

if [[ -n "$PREVIOUS_TAG" ]]; then
  echo "Rolling back ${SERVICE} to ${PREVIOUS_TAG}"
  export "$TAG_VAR=$PREVIOUS_TAG"
  upnext_compose pull "$SERVICE"
  upnext_compose up -d --no-deps "$SERVICE"
  "$HEALTHCHECK" "$HEALTH_URL" 20 3
  "$NOTIFY" "UpNext ${SERVICE} rolled back to ${PREVIOUS_TAG}"
else
  echo "No previous tag found; rollback skipped." >&2
fi

exit 1
