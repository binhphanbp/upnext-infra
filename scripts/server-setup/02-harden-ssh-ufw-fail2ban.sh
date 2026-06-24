#!/usr/bin/env bash
set -euo pipefail

SSH_PORT="${SSH_PORT:-22}"
DISABLE_PASSWORD_LOGIN="${DISABLE_PASSWORD_LOGIN:-false}"
PASSWORD_AUTHENTICATION="yes"

if [[ "$DISABLE_PASSWORD_LOGIN" == "true" ]]; then
  PASSWORD_AUTHENTICATION="no"
fi

echo "Installing UFW and Fail2Ban"
sudo apt-get update
sudo apt-get install -y ufw fail2ban

echo "Configuring UFW: allow ${SSH_PORT}/tcp, 80/tcp, 443/tcp"
sudo ufw allow "${SSH_PORT}/tcp"
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
sudo ufw status verbose

SSHD_CONFIG="/etc/ssh/sshd_config.d/99-upnext-hardening.conf"
echo "Writing ${SSHD_CONFIG}"
sudo tee "$SSHD_CONFIG" >/dev/null <<EOF
Port ${SSH_PORT}
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication ${PASSWORD_AUTHENTICATION}
KbdInteractiveAuthentication no
X11Forwarding no
EOF

if [[ "$DISABLE_PASSWORD_LOGIN" != "true" ]]; then
  echo "Password login is still enabled."
  echo "Set DISABLE_PASSWORD_LOGIN=true only after SSH key login has been tested."
fi

sudo systemctl restart ssh
sudo systemctl enable --now fail2ban
echo "SSH, UFW, and Fail2Ban hardening completed."
