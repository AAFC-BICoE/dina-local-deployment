#!/bin/bash
# Runs on first initialization of the keycloak-db container (empty data directory)
# to create the schema Keycloak will use (configured via KEYCLOAK_DB_SCHEMA, default "keycloak").
# Keycloak does not create the KC_DB_SCHEMA schema itself, so it must pre-exist.
set -e

KC_SCHEMA="${KEYCLOAK_DB_SCHEMA:-keycloak}"

echo "Initializing keycloak schema: $KC_SCHEMA"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE SCHEMA IF NOT EXISTS "$KC_SCHEMA" AUTHORIZATION "$POSTGRES_USER";
EOSQL
