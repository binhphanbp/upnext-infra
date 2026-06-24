#!/usr/bin/env bash
set -euo pipefail

echo "Configuring Docker daemon log rotation"
sudo install -d -m 755 /etc/docker

if [[ -f /etc/docker/daemon.json ]]; then
  sudo cp /etc/docker/daemon.json "/etc/docker/daemon.json.$(date -u +%Y%m%dT%H%M%SZ).bak"
fi

sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true
}
EOF

sudo systemctl restart docker
docker info --format '{{.LoggingDriver}}'
