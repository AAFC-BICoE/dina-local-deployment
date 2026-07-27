# Migrating an Existing Docker Compose-Based DINA Deployment from PostgreSQL 13 to PostgreSQL 18

**Purpose:** This guide explains how to migrate a docker compose-based DINA deployment that uses PostgreSQL 12 and PostGIS 3.1 to use PostgreSQL 18 and PostGIS 3.6. It is assumed that downtime of the deployment is acceptable.

**Notes:**

- This guide assumes you are migrating the `dina-db` service from the `postgis/postgis:12-3.1-alpine` image to the `postgis/postgis:18-3.6-alpine` image, and the `keycloak-db` service from the `postgres:12 image` to the `postgres:18` image.
- This guide assumes the name of the existing docker compose project is `dina-loca-deployment` (as it is by default). If you're migrating a deployment with a different project name, you may have to account for name changes when following instructions and copying commands.
- This guide assumes Keycloak will use the `keycloak` schema going forward (set via `KEYCLOAK_DB_SCHEMA` in your `.env` file, which defaults to `keycloak`). The `keycloak_migration.sql` step below moves Keycloak's existing tables from the `public` schema to `KEYCLOAK_DB_SCHEMA` schema in the `keycloak-db` container before it is dumped, so that the dumped data already lives in the `keycloak` schema. If you have changed `KEYCLOAK_DB_SCHEMA` in your `.env`, update the `target_schema` value in `keycloak_migration.sql` to match before running it.

## Instructions

1. Within this current directory, run the `scale.sh` script to stop all containers from the DINA deployment, except for the 2 `dina-db` and `keycloak-db` database containers.

```bash
./scale.sh stop
```

2. Run the `keycloak_migration.sql` script against the running `keycloak-db` container to move all of Keycloak's tables from the `public` schema to the `keycloak` schema (the value of `KEYCLOAK_DB_SCHEMA` in your `.env`). This is done before dumping so the dumped Keycloak data already resides in the `keycloak` schema.

```bash
docker exec -i dina-local-deployment-keycloak-db-1 psql -U keycloak_user -d keycloak_db --single-transaction -v ON_ERROR_STOP=1 -f - < keycloak_migration.sql
```

3. Run the `dump.sh` script to dump the contents of the `dina-db` database cluster into a directory named `backups/dina-local-deployment-dina-db-1`. **Note: the `dump.sh` script dumps the contents of the `dina-db` PostgreSQL v12 cluster as tar gzipped files into a `backups/dina-local-deployment-dina-db-1` directory created within your local directory. Ensure this script is being executed in a directory with enough storage space to hold the dumped contents of the PostgreSQL cluster being migrated.**

```bash
./dump.sh
```

4. Run the `dump.sh` script, passing the `keycloak-db` container name, the `keycloak-db` superuser name, and the default `keycloak-db` database name as positional arguments. This creates a dump of the entire `keycloak-db` database cluster in the `backups/dina-local-deployment-keycloak-db-1` directory.

```
./dump.sh dina-local-deployment-keycloak-db-1 keycloak_user keycloak_db
```

5. From the root of this repository, run the `start_stop_dina.sh` script to stop the current deployment remove its resources.

```bash
./start_stop_dina.sh down
```

6. Move the existing `keycloak-data` directory to a temporary location. This prevents conflicts when the new PostgreSQL containers initialize, as they require an empty data directory.

```
mkdir tmp && mv keycloak-data/ tmp
```

7. Run the `start_stop_dina.sh` script with the `up` command to start the new DINA deployment.

```bash
./start_stop_dina.sh up -d
```

8. After all containers have started and finished initializing, run the `scale.sh` script from this directory to stop all DINA containers except the `dina-db` and `keycloak-db` database containers. This prevents database transactions while the dumped database contents are being restored.

```bash
./scale.sh stop
```

9. Run the `restore.sh` script to restore the database dump into the running `dina-db` container.

```bash
./restore.sh
```

10. Run the `restore.sh` script, passing the `keycloak-db` container name, the `keycloak-db` superuser name, and the default `keycloak-db` database name as positional arguments. This restores the database dump from `backups/dina-local-deployment-keycloak-db-1` the directory into the running `keycloak-db` container.

```bash
./restore.sh dina-local-deployment-keycloak-db-1 keycloak_user keycloak_db
```

11. Stop all running DINA containers, then restart the deployment by starting all stopped containers.

```bash
./start_stop_dina.sh stop
./start_stop_dina.sh start
```
