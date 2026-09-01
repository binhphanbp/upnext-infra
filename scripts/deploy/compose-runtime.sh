#!/usr/bin/env bash
# Shared Docker Compose runtime for the live UpNext VPS.
#
# The current production and staging containers share the `upnext` project
# namespace. Do not rely on a Compose file's top-level `name`: it can create a
# second network/volume namespace and make scripts operate on an empty stack.

set -euo pipefail

: "${ROOT_DIR:?ROOT_DIR must be set before sourcing compose-runtime.sh}"
: "${COMPOSE_FILE:?COMPOSE_FILE must be set before sourcing compose-runtime.sh}"

UPNEXT_COMPOSE_ENV_FILE="${UPNEXT_COMPOSE_ENV_FILE:-${ROOT_DIR}/.env}"
UPNEXT_COMPOSE_PROJECT_NAME="${UPNEXT_COMPOSE_PROJECT_NAME:-upnext}"

if [[ ! -r "$UPNEXT_COMPOSE_ENV_FILE" ]]; then
  echo "Compose runtime file is missing or unreadable: ${UPNEXT_COMPOSE_ENV_FILE}" >&2
  echo "Create it from env/compose.env.example before deploying." >&2
  exit 1
fi

upnext_compose() {
  docker compose \
    --project-name "$UPNEXT_COMPOSE_PROJECT_NAME" \
    --env-file "$UPNEXT_COMPOSE_ENV_FILE" \
    -f "$COMPOSE_FILE" \
    "$@"
}
