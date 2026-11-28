#!/usr/bin/env bash
# Empties Keycloak's database (the keycloak-data folder) so that Keycloak imports
# keycloak/keycloak-dina-starter-realm.json again on its next start.
# Everything stored in Keycloak is lost, and the users are recreated with new IDs.
# Other DINA data (dina-db, object-store-data, elasticsearch) is not touched.
#
# Usage: ./keycloak/reset-keycloak.sh [-y|--yes]
#   -y, --yes  skip the confirmation prompt
#
# Run it manually, then start the stack with ./start_stop_dina.sh up -d.
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

RED_COLOR_CODE="\033[31m"
WHITE_COLOR_CODE="\033[0m"

ASSUME_YES=false
case "$1" in
  -y|--yes) ASSUME_YES=true ;;
  "") ;;
  *) echo "Usage: $0 [-y|--yes]" >&2; exit 2 ;;
esac

# Docker Compose reads the dina network's subnet from .env. Without it, Compose would recreate
# the network with different settings, so stop before anything is deleted.
if [ ! -f .env ]; then
  echo -e "${RED_COLOR_CODE}Keycloak reset:${WHITE_COLOR_CODE} .env not found. Start the stack once with ./start_stop_dina.sh up -d, then run this again." >&2
  exit 1
fi

echo -e "${RED_COLOR_CODE}Keycloak reset:${WHITE_COLOR_CODE} this deletes everything stored in Keycloak, including users, passwords, groups and roles."
if [ "${ASSUME_YES}" != true ]; then
  read -r -p "Continue? [y/N] " answer || true
  case "${answer}" in
    [yY] | [yY][eE][sS]) ;;
    *) echo "Cancelled. Nothing was deleted."; exit 1 ;;
  esac
fi

docker compose -f docker-compose.base.yml rm --stop --force keycloak keycloak-db

# The files belong to the container's postgres user, so delete them from inside the keycloak-db image
# (as root) instead of needing sudo on the host.
# Only docker-compose.base.yml is loaded, so don't report the other DINA containers as orphans.
COMPOSE_IGNORE_ORPHANS=true docker compose -f docker-compose.base.yml run --rm --no-deps --entrypoint find keycloak-db /var/lib/postgresql -mindepth 1 -delete

echo "Keycloak's database is empty. Keycloak imports keycloak/keycloak-dina-starter-realm.json on its next start."
echo "Start the stack with: ./start_stop_dina.sh up -d"
