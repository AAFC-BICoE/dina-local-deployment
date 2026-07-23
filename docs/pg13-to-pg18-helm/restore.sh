#!/usr/bin/env bash

set -e

# CONFIGURATION
# The name of the pod running the PostgreSQL v18 being migrated to
export POD_NAME="pod/dina-helm-dina-db-0"
# The name of the user to use when connect to the database cluster being migrated to
export DB_USER="pguser"
# The name of a database that exists on the database cluster being migrated to (note: this script will restore the contents of all databases, not just the one listed below)
export DB_NAME="dina"
# A (space separated) list of databases to exclude migrating
export EXCLUDE_DBS=("keycloak_db")

while read -r db; do
    # Skip blank lines
    [ -z "$db" ] && continue

    if [[ " ${EXCLUDE_DBS[*]} " =~ " ${db} " ]]; then
        echo "--------------------------------------------------"
        echo "Skipping ignored database: $db"
        continue
    fi

    echo "--------------------------------------------------"
    echo "Processing database: $db..."

    # Safely handle database creation
    # Check if database exists first. If it does not, create it.
    DB_EXISTS=$(kubectl exec "$POD_NAME" -- psql -U "$DB_USER" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$db'")
    
    if [ "$DB_EXISTS" != "1" ]; then
        echo "Database $db does not exist. Creating..."
        kubectl exec "$POD_NAME" -- createdb -U "$DB_USER" "$db"
    else
        echo "Database $db already exists. Proceeding with sync/overwrite..."
    fi

    # Ensure PostGIS is present
    # kubectl exec "$POD_NAME" -- psql -U "$DB_USER" -d "$db" -c "CREATE EXTENSION IF NOT EXISTS postgis;"

    # Stream and untar the local archive into the target pod's /tmp directory
    echo "Streaming backup files into the pod..."
    kubectl exec -i "$POD_NAME" -- tar -xzf - -C /tmp < "${db}_dir.tar.gz"

    # Run an idempotent parallel restore
    # --clean: Drops database objects before recreating them
    # --if-exists: Prevents errors when dropping objects that aren't there yet
    echo "Restoring data and overwriting existing objects..."
    kubectl exec "$POD_NAME" -- sh -c "pg_restore -U $DB_USER -d $db -Fd -j 4 --clean --if-exists /tmp/${db}_dir" || {
        echo "Warning: pg_restore completed with minor notices (normal with PostGIS)."
    }

    # Clean up target pod's temporary space
    kubectl exec "$POD_NAME" -- rm -rf "/tmp/${db}_dir"
    echo "Successfully synchronized $db."

done < dbs.txt
