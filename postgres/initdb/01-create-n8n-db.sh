#!/usr/bin/env bash
set -euo pipefail

N8N_DB="${N8N_POSTGRES_DB:-upnext_n8n}"

if psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname='${N8N_DB}'" | grep -q 1; then
  echo "Database ${N8N_DB} already exists."
else
  echo "Creating database ${N8N_DB}"
  createdb -U "$POSTGRES_USER" "$N8N_DB"
fi
