# Migrating an Existing `dina-helm` Release from PostgreSQL 13 to PostgreSQL 18

**Purpose:** This guide explains how to migrate a `dina-helm` release that uses PostgreSQL 13 and PostGIS 3.2 to use PostgreSQL 18 and PostGIS 3.6. It is assumed that downtime of the release is acceptable.

**Notes:**

- This guide assumes the user is migrating from a release using the `postgis/postgis:13-3.2` image for the dina-helm-dina-db statefulset to a `postgis/postgis:18-3.6` image.
- This guide assumes the name of the existing release is `dina-helm`. If you're migrating a release with a different release name, you may have to account for name changes when following instructions and copying commands.

## Instructions

1.  Scale down all deployments and all stateful sets, except for the `dina-helm-dina-db`, to 0 replicas.

```bash
./scale.sh
```

2. Access the terminal of the `dina-helm-dina-db` stateful set (e.g. `kubectl exec -it statefulset.apps/dina-helm-dina-db -- bash`). On a `dina-helm-dina-db` pod, install the required packages.

```bash
apt-get update
apt-get install -y postgresql-common nano
```

3. On the `dina-helm-dina-db` pod from the previous step, execute the `/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh` script, entering `1` if prompted `What do you want to do about modified configuration file createcluster.conf?`.

```bash
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
```

4. On the `dina-helm-dina-db` pod from the previous step, upgrade the required packages:

```bash
apt-get update
apt-get install -y --only-upgrade 'postgresql*'
```

5. On the `dina-helm-dina-db` pod from the previous step, enter a `psql` terminal, accessing the `dina` database as the `pguser` user.

```bash
psql -U pguser -d dina
```

6. On the psql terminal from the previous step, execute the following SQL to upgrade the version of PostGIS being used.

```sql
SELECT postgis_extensions_upgrade();
```

7. On the psql terminal from the previous step, execute the following SQL to begin a transaction.

```sql
BEGIN;
```

8. On the psql terminal from the previous step, execute the following SQL to open an editor.

```sql
\e
```

9. In the editor from the previous step, copy and paste the SQL from `keycloak_migration.sql` into the editor, ensuring only the contents of `keycloak_migration.sql` are in the editor. Once complete, save the contents of the editor (Ctrl+S) and then exit the editor (Ctrl+X).
10. In the psql terminal from the previous steps, ensure that no errors were raised. If no errors occured, commit the transaction.

```sql
COMMIT;
```

Exit the psql terminal and the bash terminal from the previous steps.

11. Use `kubectl` to apply the `pg18.yaml` file, bringing up a migration pod running PostgreSQL v18.

```bash
kubectl apply -f pg18.yaml
```

12. Once the migration pod from the previous step is ready, inspect the configuration section at the top of the `dump.sh` script to confirm the defined variables are correct for your specific migration scenario. Once confirmed, export the `DB_PASSWORD` variable with contents equal to the `password` field within the `dina-db-secret` secret. Once complete, run the `dump.sh` script to dump the contents of the database cluster to the current directory. **Note: the `dump.sh` script dumps the contents of the PostgreSQL v13 cluster as tar gzipped files into your local directory. Execute this script in a directory (ideally an empty one) with enough storage space to hold the dumped contents of the PostgreSQL cluster being migrated.**

```bash
export DB_PASSWORD="$(kubectl get secrets/dina-db-secret --template={{.data.password}} | base64 -d)"
./dump.sh
```

13. Uninstall the existing helm release.

```bash
helm uninstall dina-helm
```

14. Update the helm chart's code such that it supports PostgreSQL v18.

```bash
git pull
git checkout 38618-upgrade-postgresql-image
```

15. Install a release of the helm chart.

```
helm install dina-helm .
```

16. Once the release has been installed and all pods are ready, scale down all deployments and all stateful sets, except for the `dina-helm-dina-db`, to 0 replicas.

```bash
./scale.sh
```

17. Once all relevant pods have been scaled down, inspect the configuration section at the top of the `dump.sh` script to confirm the defined variables are correct for your specific migration scenario. Once confirmed, run the `restore.sh` script to restore the contents of the database dump from the current directory. **Note: the `restore.sh` scripts expects that the dumped database files (as created by `dump.sh`) exist within the current directory.**

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
