#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-prod}"
TARGET_TAG="${2:-}"

case "$ENVIRONMENT" in
  prod|production)
    STATE_FILE="${ROOT_DIR}/state/backend.prod.tag"
    ;;
  staging)
    STATE_FILE="${ROOT_DIR}/state/backend.staging.tag"
    ;;
  *)
    echo "Usage: $0 <prod|staging> [target-tag]" >&2
    exit 2
    ;;
esac

if [[ -z "$TARGET_TAG" ]]; then
  TARGET_TAG="$(cat "$STATE_FILE")"
fi

"${ROOT_DIR}/scripts/deploy/deploy-backend.sh" "$ENVIRONMENT" "$TARGET_TAG"
