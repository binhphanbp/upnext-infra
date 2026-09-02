# DNS on Name.com

Create A records pointing to `<VPS_PUBLIC_IP>`:

- `@` -> `upnext.works`
- `www`
- `api`
- `n8n`
- `staging`
- `api-staging`

Use low TTL during setup, for example 300 seconds. After DNS is stable, 1800 or 3600 seconds is fine.

Verify:
```bash
dig +short upnext.works
dig +short api.upnext.works
dig +short staging.upnext.works
```
