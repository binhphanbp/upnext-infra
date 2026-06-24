# Nginx and SSL

Nginx runs on the host and proxies to services bound on `127.0.0.1`.

Install and link configs:
```bash
scripts/server-setup/04-install-nginx-certbot.sh
```

Validate:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

Issue certificates after DNS points to the VPS:
```bash
sudo certbot --nginx \
  -d upnext.works -d www.upnext.works \
  -d api.upnext.works \
  -d n8n.upnext.works \
  -d status.upnext.works \
  -d monitor.upnext.works \
  -d staging.upnext.works \
  -d api-staging.upnext.works
```

Renewal check:
```bash
sudo certbot renew --dry-run
```
