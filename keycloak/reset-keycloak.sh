#!/usr/bin/env bash
# Empties Keycloak's database (the keycloak-data folder) so that Keycloak imports
# keycloak/keycloak-dina-starter-realm.json again on its next start.
# Everything stored in Keycloak is lost, and the users are recreated with new IDs.
#
# Run it manually, then start the stack with ./start_stop_dina.sh up.
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

RED_COLOR_CODE="\033[31m"
WHITE_COLOR_CODE="\033[0m"
echo -e "${RED_COLOR_CODE}Keycloak reset:${WHITE_COLOR_CODE} deleting Keycloak's database so the starter realm is imported again."

docker compose -f docker-compose.base.yml rm --stop --force keycloak keycloak-db

# The files belong to the container's postgres user, so delete them from inside the keycloak-db image
# (as root) instead of needing sudo on the host.
# Only docker-compose.base.yml is loaded, so don't report the other DINA containers as orphans.
COMPOSE_IGNORE_ORPHANS=true docker compose -f docker-compose.base.yml run --rm --no-deps --entrypoint find keycloak-db /var/lib/postgresql -mindepth 1 -delete

echo "Keycloak's database is empty. Keycloak imports keycloak/keycloak-dina-starter-realm.json on its next start (./start_stop_dina.sh up)."
