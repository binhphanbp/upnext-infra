ROOT_DIR ?= /opt/upnext
ENV ?= prod

.PHONY: validate up down ps logs backup cleanup nginx-test

validate:
	test -r .env
	docker compose --project-name upnext --env-file .env -f compose/docker-compose.prod.yml config >/dev/null
	docker compose --project-name upnext --env-file .env -f compose/docker-compose.staging.yml config >/dev/null

up:
	./scripts/deploy/deploy-stack.sh $(ENV)

down:
	docker compose -f compose/docker-compose.$(ENV).yml down

ps:
	docker compose -f compose/docker-compose.$(ENV).yml ps

logs:
	docker compose -f compose/docker-compose.$(ENV).yml logs -f --tail=200

backup:
	./scripts/backup/backup-postgres.sh $(ENV)

cleanup:
	./scripts/backup/cleanup-backups.sh

nginx-test:
	nginx -t
