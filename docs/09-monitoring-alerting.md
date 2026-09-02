# Operational Checks and Alerts

Uptime Kuma and Beszel are intentionally not part of this stack. They were not
operated and their unhealthy containers created noise without providing an
actionable alerting path.

After merging the removal, run
`scripts/maintenance/retire-unused-monitoring.sh` with its explicit
confirmation value once on the VPS. It removes only the old monitoring
containers, data volumes, and Nginx vhosts; it does not touch application,
database, or n8n resources.

Every routine application deploy runs an authenticated image pull, replaces one
service only, and verifies its public health endpoint. For manual checks:

```bash
curl -fsS https://upnext.works/vi >/dev/null
curl -fsS https://api.upnext.works/health
curl -fsS https://staging.upnext.works/vi >/dev/null
curl -fsS https://api-staging.upnext.works/health
docker compose --project-name upnext --env-file .env -f compose/docker-compose.prod.yml ps
docker stats --no-stream
df -h
```

Optional Telegram deploy notifications:
- Copy `env/telegram.env.example` to `env/telegram.env`.
- Fill `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.
- Test:
  ```bash
  scripts/notify/telegram.sh "UpNext test notification"
  ```
