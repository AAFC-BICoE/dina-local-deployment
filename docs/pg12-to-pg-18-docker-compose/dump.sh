#!/usr/bin/env bash

set -e

# CONFIGURATION (positional arguments with fallbacks to defaults)
# The name of the container running PostgreSQL v18 (e.g. as defined in pg18.yaml)
export DB_CONTAINER="${1:-dina-local-deployment-dina-db-1}"
# The Docker network where DB_CONTAINER lives
export DOCKER_NETWORK="dina-local-deployment_dina"
# Dump tool image (using PostGIS image so spatial definitions in postgis/postgis:18 don't cause issues)
export MIGRATION_IMAGE="postgis/postgis:18-3.6-alpine"
# The name of the user to use when connecting to the database cluster being migrated
export DB_USER="${2:-pguser}"
# The name of a database that exists on the database cluster being migrated (note: this script will dump the contents of all databases, not just the one listed below)
export DB_NAME="${3:-dina}"

# Directory where output archives will be stored to keep containers separate
OUTPUT_DIR="./backups/${DB_CONTAINER}"
mkdir -p "$OUTPUT_DIR"

# Fetch POSTGRES_PASSWORD (or KEYCLOAK_DATABASE_PW) directly from the target container
DB_PASSWORD=$(docker exec "$DB_CONTAINER" sh -c 'echo "${POSTGRES_PASSWORD:-$KEYCLOAK_DATABASE_PW}"')

if [ -n "$DB_PASSWORD" ]; then
    PG_ENV="-e PGPASSWORD=$DB_PASSWORD"
else
    PG_ENV=""
fi

# Fetch list of databases from the specified container
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -Atc "SELECT datname FROM pg_database WHERE NOT datistemplate AND datname != 'postgres'" > "${OUTPUT_DIR}/dbs.txt"

while read -r db; do
    # Skip empty lines if any
    [ -z "$db" ] && continue
    echo "-------------------------------------"
    echo "Processing database: $db on container: $DB_CONTAINER..."

    # Create a local temporary directory to hold the raw dump
    rm -rf "/tmp/${db}_dir"
    mkdir -p "/tmp/${db}_dir"

    # Run pg_dump from the dump image, mounted directly to local /tmp
    if docker run --rm $PG_ENV \
        --network "$DOCKER_NETWORK" \
        -v "/tmp/${db}_dir:/dump" \
        "$MIGRATION_IMAGE" \
        pg_dump -U "$DB_USER" -h "$DB_CONTAINER" -Fd -j 4 -f /dump "$db"; then

        # Archive the output directly into the target container's dedicated folder
        tar -czf "${OUTPUT_DIR}/${db}_dir.tar.gz" -C /tmp "${db}_dir"

        # Clean up local temporary raw folder
        rm -rf "/tmp/${db}_dir"

        echo "SUCCESS: $db backup saved to ${OUTPUT_DIR}/${db}_dir.tar.gz"
    else
        echo "ERROR: pg_dump failed for $db, skipping archive step."
        rm -rf "/tmp/${db}_dir"
    fi
done < "${OUTPUT_DIR}/dbs.txt"
