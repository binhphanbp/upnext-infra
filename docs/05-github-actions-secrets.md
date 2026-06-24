# GitHub Actions Secrets

Infra repo CI validates compose, shell scripts, and Nginx config. Build workflows for frontend/backend belong in their own repos.

Create these secrets in FE/BE repositories:

- `VPS_HOST`
- `VPS_PORT`
- `VPS_USER`
- `VPS_SSH_KEY`
- `GHCR_USERNAME`
- `GHCR_TOKEN`
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

Example remote deploy step from an app repo:
```yaml
- name: Deploy frontend
  uses: appleboy/ssh-action@v1.0.3
  with:
    host: ${{ secrets.VPS_HOST }}
    port: ${{ secrets.VPS_PORT }}
    username: ${{ secrets.VPS_USER }}
    key: ${{ secrets.VPS_SSH_KEY }}
    script: |
      cd /opt/upnext
      GHCR_USERNAME='${{ secrets.GHCR_USERNAME }}' \
      GHCR_TOKEN='${{ secrets.GHCR_TOKEN }}' \
      scripts/deploy/deploy-frontend.sh prod '${{ github.sha }}'
```
