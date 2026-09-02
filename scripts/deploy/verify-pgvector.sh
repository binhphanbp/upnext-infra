#!/usr/bin/env bash
# Verify the database engine can load pgvector before a RAG migration runs.
# Read-only: backend migrations own CREATE EXTENSION and schema history.

set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-}"
REQUIRE_INSTALLED="${2:-}"

case "$ENVIRONMENT" in
  staging) COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"; SERVICE="postgres-staging" ;;
  prod|production) COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"; SERVICE="postgres" ;;
  *) echo "Usage: $0 <staging|production> [--require-installed]" >&2; exit 2 ;;
esac

if [[ "$REQUIRE_INSTALLED" != "" && "$REQUIRE_INSTALLED" != "--require-installed" ]]; then
  echo "Unknown option: $REQUIRE_INSTALLED" >&2
  exit 2
fi

export COMPOSE_FILE
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/deploy/compose-runtime.sh"

if ! upnext_compose exec -T "$SERVICE" sh -ec \
  'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_available_extensions WHERE name = '\''vector'\''"' \
  | grep -qx '1'; then
  echo "pgvector is unavailable in ${ENVIRONMENT}. Refusing RAG migration." >&2
  exit 1
fi

if [[ "$REQUIRE_INSTALLED" == "--require-installed" ]] && ! upnext_compose exec -T "$SERVICE" sh -ec \
  'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_extension WHERE extname = '\''vector'\''"' \
  | grep -qx '1'; then
  echo "pgvector is available but extension vector is not installed in ${ENVIRONMENT}." >&2
  exit 1
fi

echo "pgvector capability verified for ${ENVIRONMENT}${REQUIRE_INSTALLED:+ (installed)}."
