#!/usr/bin/env bash

set -e

# CONFIGURATION
# The name of the pod running PostgreSQL v18 (e.g. as defined in pg18.yaml)
export MIGRATION_POD_NAME="pod/pg-migration-pod"
# The name of the user to use when connect to the database cluster being migrated
export DB_USER="pguser"
# The name of a database that exists on the database cluster being migrated (note: this script will dump the contents of all databases, not just the one listed below)
export DB_NAME="dina"
# The name of the kubernetes service providing access to the database cluster being migrated 
export DB_HOST="dina-db-service"

if [ -n "${DB_PASSWORD:-}" ]; then
    PG_ENV="PGPASSWORD='$DB_PASSWORD'"
else
    PG_ENV=""
fi

kubectl exec "$MIGRATION_POD_NAME" -- sh -c "$PG_ENV psql -U '$DB_USER' -h '$DB_HOST' -d '$DB_NAME' -Atc \"SELECT datname FROM pg_database WHERE NOT datistemplate AND datname != 'postgres'\"" > dbs.txt

while read -r db; do
    # Skip empty lines if any
    [ -z "$db" ] && continue
    echo "-------------------------------------"
    echo "Processing database: $db..."

    # Run parallel dump inside the pod using explicit sh -c execution
    kubectl exec "$MIGRATION_POD_NAME" -- sh -c "$PG_ENV pg_dump -U '$DB_USER' -h '$DB_HOST' -Fd -j 4 -f /tmp/${db}_dir '$db'"

    # Check if pg_dump actually succeeded before trying to tar it
    if [ ${PIPESTATUS[0]} -eq 0 ] || [ $? -eq 0 ]; then
        # Tar the folder and stream it directly to your local machine
        kubectl exec "$MIGRATION_POD_NAME" -- sh -c "tar -czf - -C /tmp ${db}_dir" > "${db}_dir.tar.gz"

        # Clean up the temporary folder inside the pod to save space
        kubectl exec "$MIGRATION_POD_NAME" -- sh -c "rm -rf /tmp/${db}_dir"

        echo "SUCCESS: $db backup saved locally as ${db}_dir.tar.gz"
    else
        echo "ERROR: pg_dump failed for $db, skipping archive step."
    fi
done < dbs.txt
