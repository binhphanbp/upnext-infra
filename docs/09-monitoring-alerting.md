# Monitoring and Alerting

Uptime Kuma:
- URL: `https://status.upnext.works`
- Create admin user on first login.
- Add monitors for frontend, backend, staging, n8n, Beszel, and SSL expiry.
- Configure Telegram notification inside Uptime Kuma.

Beszel:
- URL: `https://monitor.upnext.works`
- Create admin user on first login.
- Add local system using the Beszel agent key.
- Monitor CPU, RAM, disk, Docker containers, and network.

Telegram deploy notifications:
- Copy `env/telegram.env.example` to `env/telegram.env`.
- Fill `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.
- Test:
  ```bash
  scripts/notify/telegram.sh "UpNext test notification"
  ```
