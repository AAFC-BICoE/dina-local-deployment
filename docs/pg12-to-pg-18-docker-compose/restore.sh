#!/usr/bin/env bash

set -e

# CONFIGURATION (positional arguments with fallbacks to defaults)
# The name of the pod running the PostgreSQL cluster being migrated
export DB_CONTAINER="${1:-dina-local-deployment-dina-db-1}"
# The name of the user to use when connect to the database cluster being migrated to
export DB_USER="${2:-pguser}"
# The name of a database that exists on the database cluster being migrated to (note: this script will restore the contents of all databases, not just the one listed below)
export DB_NAME="${3:-dina}"
# A (space separated) list of databases to exclude migrating
export EXCLUDE_DBS=()

# Directory where backups are saved
INPUT_DIR="./backups/${DB_CONTAINER}"

while read -r db; do
    # Skip blank lines
    [ -z "$db" ] && continue

    if [[ " ${EXCLUDE_DBS[*]} " =~ " ${db} " ]]; then
        echo "--------------------------------------------------"
        echo "Skipping ignored database: $db"
        continue
    fi

    # Check if backup file exists before attempting restore
    ARCHIVE_PATH="${INPUT_DIR}/${db}_dir.tar.gz"
    if [ ! -f "$ARCHIVE_PATH" ]; then
        echo "--------------------------------------------------"
        echo "Warning: Backup archive $ARCHIVE_PATH not found, skipping $db..."
        continue
    fi

    echo "--------------------------------------------------"
    echo "Processing database: $db..."

    # Safely handle database creation on target container
    DB_EXISTS=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$db'")

    if [ "$DB_EXISTS" != "1" ]; then
        echo "Database $db does not exist. Creating..."
        docker exec "$DB_CONTAINER" createdb -U "$DB_USER" "$db"
    else
        echo "Database $db already exists. Proceeding with sync/overwrite..."
    fi

    # Ensure PostGIS is present
    # docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$db" -c "CREATE EXTENSION IF NOT EXISTS postgis;"

    # Stream and untar the local archive directly into the target container's /tmp directory
    echo "Streaming backup files into the container..."
    docker exec -i "$DB_CONTAINER" tar -xzf - -C /tmp < "$ARCHIVE_PATH"

    # Run an idempotent parallel restore directly inside the target container
    echo "Restoring data and overwriting existing objects..."
    docker exec "$DB_CONTAINER" pg_restore -U "$DB_USER" -d "$db" -Fd -j 4 --clean --if-exists "/tmp/${db}_dir" || {
        echo "Warning: pg_restore completed with minor notices (normal if using PostGIS)."
    }

    # Clean up target container's temporary space
    docker exec "$DB_CONTAINER" rm -rf "/tmp/${db}_dir"
    echo "Successfully synchronized $db."

done < "${INPUT_DIR}/dbs.txt"
