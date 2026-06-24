#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${UPNEXT_ROOT:-/opt/upnext}"

echo "Installing Nginx and Certbot"
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx

sudo install -d -m 755 /etc/nginx/snippets

echo "Linking UpNext Nginx configs"
for file in "${ROOT_DIR}"/nginx/snippets/*.conf; do
  sudo ln -sfn "$file" "/etc/nginx/snippets/$(basename "$file")"
done

for file in "${ROOT_DIR}"/nginx/conf.d/*.conf; do
  sudo ln -sfn "$file" "/etc/nginx/conf.d/$(basename "$file")"
done

sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx

echo "Nginx installed. Run Certbot after DNS points to this VPS."
