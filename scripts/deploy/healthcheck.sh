#!/usr/bin/env bash
set -euo pipefail

URL="${1:?Usage: $0 <url> [attempts] [sleep_seconds]}"
ATTEMPTS="${2:-20}"
SLEEP_SECONDS="${3:-3}"

echo "Checking health endpoint: ${URL}"

for attempt in $(seq 1 "$ATTEMPTS"); do
  if curl -fsS --max-time 5 "$URL" >/dev/null; then
    echo "Healthcheck passed on attempt ${attempt}/${ATTEMPTS}"
    exit 0
  fi
  echo "Healthcheck attempt ${attempt}/${ATTEMPTS} failed; retrying in ${SLEEP_SECONDS}s"
  sleep "$SLEEP_SECONDS"
done

echo "Healthcheck failed: ${URL}" >&2
exit 1
