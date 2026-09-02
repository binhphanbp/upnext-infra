#!/usr/bin/env bash
# Canonical CI entry point. Deploys exactly one service from the already-built
# GHCR tag configured in /opt/upnext/.env; it never reconciles the other stack.

set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
ENVIRONMENT="${1:-}"
COMPONENT="${2:-}"
HEALTHCHECK="${ROOT_DIR}/scripts/deploy/healthcheck.sh"
BACKUP="${ROOT_DIR}/scripts/backup/backup-postgres.sh"

case "$ENVIRONMENT" in
  staging)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.staging.yml"
    BACKEND_SERVICE="backend-staging"
    FRONTEND_SERVICE="frontend-staging"
    BACKEND_HEALTH_URL="https://api-staging.upnext.works/health"
    FRONTEND_HEALTH_URL="https://staging.upnext.works/vi"
    ;;
  production|prod)
    COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.prod.yml"
    BACKEND_SERVICE="backend"
    FRONTEND_SERVICE="frontend"
    BACKEND_HEALTH_URL="https://api.upnext.works/health"
    FRONTEND_HEALTH_URL="https://upnext.works/vi"
    ;;
  *)
    echo "Usage: $0 <staging|production> <frontend|backend|ai>" >&2
    exit 2
    ;;
esac

case "$COMPONENT" in
  frontend|backend)
    ;;
  ai)
    if [[ "$ENVIRONMENT" != "staging" ]]; then
      echo "The private AI service is only defined for staging." >&2
      exit 2
    fi
    ;;
  *)
    echo "Usage: $0 <staging|production> <frontend|backend|ai>" >&2
    exit 2
    ;;
esac

if [[ -r "${ROOT_DIR}/env/deploy.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/env/deploy.env"
  set +a
fi

if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_TOKEN:-}" ]]; then
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin
fi

if [[ "$COMPONENT" == "ai" && -f "${ROOT_DIR}/env/ai.staging.env" ]]; then
  export AI_STAGING_ENV_FILE="${AI_STAGING_ENV_FILE:-../env/ai.staging.env}"
fi

# compose-runtime consumes the selected stack file.
export COMPOSE_FILE
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/deploy/compose-runtime.sh"

case "$COMPONENT" in
  backend)
    echo "Creating ${ENVIRONMENT} database backup before migrations"
    "$BACKUP" "$ENVIRONMENT"

    echo "Pulling ${BACKEND_SERVICE} image"
    upnext_compose pull "$BACKEND_SERVICE"

    echo "Applying Prisma migrations from the pulled image"
    upnext_compose run --rm --no-deps "$BACKEND_SERVICE" \
      sh -lc 'npx --no-install prisma migrate deploy'

    echo "Recreating ${BACKEND_SERVICE} only"
    upnext_compose up -d --no-deps --force-recreate "$BACKEND_SERVICE"
    "$HEALTHCHECK" "$BACKEND_HEALTH_URL" 20 3
    ;;
  frontend)
    echo "Pulling ${FRONTEND_SERVICE} image"
    upnext_compose pull "$FRONTEND_SERVICE"

    echo "Recreating ${FRONTEND_SERVICE} only"
    upnext_compose up -d --no-deps --force-recreate "$FRONTEND_SERVICE"
    "$HEALTHCHECK" "$FRONTEND_HEALTH_URL" 20 3
    ;;
  ai)
    echo "Pulling private AI staging image"
    upnext_compose --profile ai pull ai-staging

    echo "Recreating ai-staging only"
    upnext_compose --profile ai up -d --no-deps --force-recreate ai-staging
    # Uvicorn starts after Compose reports the container as started. A single immediate request
    # races that startup and used to make a successful AI deployment look failed.
    for attempt in $(seq 1 20); do
      if upnext_compose --profile ai exec -T ai-staging \
        python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/ready', timeout=5)"; then
        break
      fi
      if [[ "$attempt" == "20" ]]; then
        echo "ai-staging did not become ready after 20 attempts" >&2
        exit 1
      fi
      echo "AI readiness attempt ${attempt}/20 failed; retrying in 3s"
      sleep 3
    done
    ;;
esac

echo "Deployment completed: ${ENVIRONMENT}/${COMPONENT}"
