# Migrating an Existing `dina-helm` Release from PostgreSQL 13 to PostgreSQL 18

**Purpose:** This guide explains how to migrate a `dina-helm` release that uses PostgreSQL 13 and PostGIS 3.2 to use PostgreSQL 18 and PostGIS 3.6. It is assumed that downtime of the release is acceptable.

**Notes:**

- This guide assumes the user is migrating from a release using the `postgis/postgis:13-3.2` image for the dina-helm-dina-db statefulset to a `postgis/postgis:18-3.6` image.
- This guide assumes the user is migrating from a release using Keycloak 25. If you are migrating from a release that uses a newer Keycloak version, you may have to update the `table_list` in `keycloak_migration.sql`.
- This guide assumes the name of the existing release is `dina-helm`. If you're migrating a release with a different release name, you may have to account for name changes when following instructions and copying commands.

## Instructions

1.  Scale down all deployments and all stateful sets, except for the `dina-helm-dina-db`, to 0 replicas.

```bash
./scale.sh
```

2. Copy the `keycloak_migration.sql` file onto a pod in the `dina-helm-dina-db` stateful set.

```bash
kubectl cp keycloak_migration.sql dina-helm-dina-db-0:/
```

3. Access the terminal of the `dina-helm-dina-db` stateful set (e.g. `kubectl exec -it statefulset.apps/dina-helm-dina-db -- bash`). On a `dina-helm-dina-db` pod, run the `keycloak_migration.sql` file in a single transaction using `psql`.

```bash
psql --single-transaction -v ON_ERROR_STOP=1 -U pguser -d dina -f keycloak_migration.sql
```

Exit the bash terminal.

4.  Use `kubectl` to apply the `pg18.yaml` file, bringing up a migration pod running PostgreSQL v18.

```bash
kubectl apply -f pg18.yaml
```

5. Once the migration pod from the previous step is ready, inspect the configuration section at the top of the `dump.sh` script to confirm the defined variables are correct for your specific migration scenario. Once confirmed, export the `DB_PASSWORD` variable with contents equal to the `password` field within the `dina-db-secret` secret. Once complete, run the `dump.sh` script to dump the contents of the database cluster to the current directory. **Note: the `dump.sh` script dumps the contents of the PostgreSQL v13 cluster as tar gzipped files into your local directory. Execute this script in a directory (ideally an empty one) with enough storage space to hold the dumped contents of the PostgreSQL cluster being migrated.**

```bash
export DB_PASSWORD="$(kubectl get secrets/dina-db-secret --template={{.data.password}} | base64 -d)"
./dump.sh
```

6. Update the helm chart's code such that it supports PostgreSQL v18.

```bash
git pull
```

7.  Upgrade the release of the helm chart.

```
helm upgrade dina-helm .
```

8. Once the release has been installed and all pods are ready, scale down all deployments and all stateful sets, except for the `dina-helm-dina-db`, to 0 replicas.

```bash
./scale.sh
```

9. Once all relevant pods have been scaled down, inspect the configuration section at the top of the `dump.sh` script to confirm the defined variables are correct for your specific migration scenario. Once confirmed, run the `restore.sh` script to restore the contents of the database dump from the current directory. **Note: the `restore.sh` scripts expects that the dumped database files (as created by `dump.sh`) exist within the current directory.**

```bash
./restore.sh
```

The migration process is complete.

## Cleanup

Ensure to cleanup the migration pod and reset replicas of all deployments and all stateful sets (except for `dina-helm-dina-db`).

```bash
kubectl delete -f pg18.yaml
./scale.sh 1
```
