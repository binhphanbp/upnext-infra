#!/usr/bin/env bash
set -euo pipefail

DEPLOY_USER="${DEPLOY_USER:-deploy}"

if id "$DEPLOY_USER" >/dev/null 2>&1; then
  echo "User ${DEPLOY_USER} already exists."
else
  echo "Creating user ${DEPLOY_USER}"
  sudo adduser --disabled-password --gecos "" "$DEPLOY_USER"
fi

sudo usermod -aG sudo "$DEPLOY_USER"

sudo install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/${DEPLOY_USER}/.ssh"

if [[ -n "${DEPLOY_SSH_PUBLIC_KEY:-}" ]]; then
  AUTH_KEYS="/home/${DEPLOY_USER}/.ssh/authorized_keys"
  sudo touch "$AUTH_KEYS"
  if ! sudo grep -qxF "$DEPLOY_SSH_PUBLIC_KEY" "$AUTH_KEYS"; then
    echo "Adding SSH public key for ${DEPLOY_USER}"
    echo "$DEPLOY_SSH_PUBLIC_KEY" | sudo tee -a "$AUTH_KEYS" >/dev/null
  fi
  sudo chown "$DEPLOY_USER:$DEPLOY_USER" "$AUTH_KEYS"
  sudo chmod 600 "$AUTH_KEYS"
else
  echo "DEPLOY_SSH_PUBLIC_KEY is empty; add the key manually before disabling password login."
fi

echo "Deploy user setup completed."
