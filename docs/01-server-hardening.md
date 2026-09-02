# Server Hardening

Target: Ubuntu 24.04 LTS VPS.

## Checklist

- Create a non-root deploy user:
  ```bash
  DEPLOY_SSH_PUBLIC_KEY='<YOUR_PUBLIC_KEY>' scripts/server-setup/01-create-deploy-user.sh
  ```
- Install Docker:
  ```bash
  scripts/server-setup/03-install-docker.sh
  ```
- Configure Docker log rotation:
  ```bash
  scripts/server-setup/05-configure-docker-daemon.sh
  ```
- Enable UFW and Fail2Ban:
  ```bash
  scripts/server-setup/02-harden-ssh-ufw-fail2ban.sh
  ```
- After SSH key login is verified, disable password login:
  ```bash
  DISABLE_PASSWORD_LOGIN=true scripts/server-setup/02-harden-ssh-ufw-fail2ban.sh
  ```

## Firewall

Only these inbound ports should be open:

- `22/tcp` or your chosen SSH port
- `80/tcp`
- `443/tcp`

PostgreSQL, app ports, and n8n must not be public.
