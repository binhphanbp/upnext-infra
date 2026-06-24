# Incident Runbook

## App Down

1. Check Uptime Kuma alert details.
2. Check Nginx:
   ```bash
   sudo nginx -t
   sudo journalctl -u nginx -n 100 --no-pager
   ```
3. Check containers:
   ```bash
   docker compose -f compose/docker-compose.prod.yml ps
   docker compose -f compose/docker-compose.prod.yml logs --tail=200 frontend backend
   ```
4. Roll back the affected app if the last deploy caused it.

## Backend Migration Fail

1. Do not restore DB automatically.
2. Check migration logs.
3. Confirm whether the migration changed schema/data.
4. Prefer a forward fix migration. Restore only with explicit approval.

## Database Full Disk

1. Check disk:
   ```bash
   df -h
   docker system df
   ```
2. Remove old backups beyond retention.
3. Prune unused Docker objects after review:
   ```bash
   docker system prune
   ```
4. Increase VPS disk if pressure remains.

## SSL Expired

1. Check Certbot timer:
   ```bash
   systemctl list-timers | grep certbot
   sudo certbot renew --dry-run
   ```
2. Verify DNS still points to this VPS.
3. Check Nginx config and reload.

## Container Restart Loop

1. Inspect logs:
   ```bash
   docker logs <container> --tail=200
   ```
2. Check env files and image tag.
3. Check healthcheck failures.
4. Roll back to previous image if caused by deploy.

## High CPU or RAM

1. Check Beszel dashboard.
2. Check Docker stats:
   ```bash
   docker stats
   ```
3. Identify noisy service.
4. Scale VPS resources or reduce workload if sustained.
