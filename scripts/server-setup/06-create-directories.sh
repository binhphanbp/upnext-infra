#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"

echo "Creating UpNext directories under ${ROOT_DIR}"
sudo install -d -m 755 "$ROOT_DIR"
sudo install -d -m 750 "${ROOT_DIR}/env" "${ROOT_DIR}/state" "${ROOT_DIR}/backups/postgres"
sudo install -d -m 755 "${ROOT_DIR}/compose" "${ROOT_DIR}/nginx" "${ROOT_DIR}/scripts" "${ROOT_DIR}/docs"

if id "$DEPLOY_USER" >/dev/null 2>&1; then
  sudo chown -R "$DEPLOY_USER:$DEPLOY_USER" "$ROOT_DIR"
fi

echo "Directory setup completed."
