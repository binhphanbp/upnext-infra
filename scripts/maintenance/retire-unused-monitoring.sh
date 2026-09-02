#!/usr/bin/env bash
set -euo pipefail

# One-time retirement for the legacy monitoring services removed from Compose.
# These resources are intentionally not removed by routine deployments because
# deploy.sh never uses --remove-orphans.
if [[ "${CONFIRM_RETIRE_MONITORING:-}" != "retire-unused-monitoring" ]]; then
  echo "Refusing to remove legacy monitoring resources." >&2
  echo "Run with CONFIRM_RETIRE_MONITORING=retire-unused-monitoring after verifying they are unused." >&2
  exit 1
fi

containers=(upnext-uptime-kuma upnext-beszel upnext-beszel-agent)
volumes=(upnext_uptime-kuma-data upnext_beszel-data upnext_beszel-agent-data)
nginx_configs=(
  /etc/nginx/conf.d/status.upnext.works.conf
  /etc/nginx/conf.d/monitor.upnext.works.conf
)

for container in "${containers[@]}"; do
  if docker container inspect "$container" >/dev/null 2>&1; then
    echo "Removing legacy container: $container"
    docker container rm -f "$container"
  fi
done

for volume in "${volumes[@]}"; do
  if docker volume inspect "$volume" >/dev/null 2>&1; then
    echo "Removing unused monitoring volume: $volume"
    docker volume rm "$volume"
  fi
done

for config in "${nginx_configs[@]}"; do
  if [[ -e "$config" || -L "$config" ]]; then
    echo "Removing legacy Nginx config: $config"
    sudo rm -f "$config"
  fi
done

sudo nginx -t
sudo systemctl reload nginx
echo "Legacy Uptime Kuma and Beszel resources have been retired."
