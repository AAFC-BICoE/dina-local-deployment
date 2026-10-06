#!/usr/bin/env bash
# Empties Keycloak's database (the keycloak-data folder) so that Keycloak imports
# keycloak/keycloak-dina-starter-realm.json again on its next start. Users added in Keycloak are lost.
#
# start_stop_dina.sh calls it on "up" when RESET_KEYCLOAK=true, passing its docker compose -f options.
# It can also be run on its own (defaults to docker-compose.base.yml), followed by ./start_stop_dina.sh up.
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [ $# -eq 0 ]; then
  set -- -f docker-compose.base.yml
fi

RED_COLOR_CODE="\033[31m"
WHITE_COLOR_CODE="\033[0m"
echo -e "${RED_COLOR_CODE}RESET_KEYCLOAK:${WHITE_COLOR_CODE} deleting Keycloak's database so the starter realm is imported again."

docker compose "$@" rm --stop --force keycloak keycloak-db

# The files belong to the container's postgres user, so delete them from inside the keycloak-db image
# (as root) instead of needing sudo on the host.
docker compose "$@" run --rm --no-deps --entrypoint find keycloak-db /var/lib/postgresql -mindepth 1 -delete
