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
    SERVICE="frontend"
    TAG_VAR="FRONTEND_IMAGE_TAG"
    STATE_FILE="${ROOT_DIR}/state/frontend.prod.tag"
    HEALTH_URL="https://upnext.works/"
    ;;
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
    SERVICE="frontend-staging"
    TAG_VAR="FRONTEND_STAGING_IMAGE_TAG"
    STATE_FILE="${ROOT_DIR}/state/frontend.staging.tag"
    HEALTH_URL="https://staging.upnext.works/"
    ;;
  *)
    echo "Usage: $0 <prod|staging> [target-tag]" >&2
    exit 2
    ;;
esac

if [[ -z "$TARGET_TAG" ]]; then
  if [[ ! -s "$STATE_FILE" ]]; then
    echo "No saved frontend tag exists for ${ENVIRONMENT}; pass an explicit target tag." >&2
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

echo "Rolling back ${SERVICE} to ${TARGET_TAG}"
export "$TAG_VAR=$TARGET_TAG"
upnext_compose pull "$SERVICE"
upnext_compose up -d --no-deps "$SERVICE"
"$HEALTHCHECK" "$HEALTH_URL" 20 3
echo "$TARGET_TAG" > "$STATE_FILE"
"$NOTIFY" "UpNext ${SERVICE} rolled back to ${TARGET_TAG}"
