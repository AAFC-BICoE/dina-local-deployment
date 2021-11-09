# postgresql major updates

1. Dump current database:
```shell
docker exec -t dina-local-deployment_dina-db_1 pg_dumpall -c -U pguser > dump.sql
```
2. Delete old data directory
3. Turn on dina-db, then turn on init-db
4. Restore Database
```shell
cat dump.sql | docker exec -i dina-local-deployment_dina-db_1 psql -U pguser -d dina
```
4. Start Everything Else
