# Keycloak 26 upgrade

Realm changes, in `keycloak/keycloak-dina-starter-realm.json` and `helm/config/keycloak/dina-realm.json` (keep identical):

- **`kc-admin-api` client scope on `user-svc`**: Keycloak 26.8 requires it for Admin API calls. Without it, user-api
  `/user` and `/group` return 500. It must be defined in the realm file, or the import ignores the reference.
- **"Full scope allowed" off** on `user-svc` and `dina-public` (deprecated). Tokens then only carry mapped roles:

| Client        | Mapped roles                                                                    |
|---------------|---------------------------------------------------------------------------------|
| `dina-public` | realm: `dina-realm-user`, `dina-admin`, `read-only-admin`                       |
| `user-svc`    | `realm-management`: `view-users`, `manage-users`, `query-users`, `query-groups` |

Any new realm role read from the token must be added to `dina-public`.

## Existing installs

New installs get this from the realm import. Existing realms are not re-imported, so back up the Keycloak database, then run:

```shell
docker exec -i <keycloak-container> bash -s -- dina < keycloak/migrate-realm-keycloak-26.sh
kubectl exec -i <keycloak-pod> -- bash -s -- dina < keycloak/migrate-realm-keycloak-26.sh
oc exec -i <keycloak-pod> -- bash -s -- dina < keycloak/migrate-realm-keycloak-26.sh   # pod name: oc get pods | grep keycloak
```

Or from a terminal in the Keycloak pod (OKD console Terminal tab, or `oc rsh <keycloak-pod>`), paste the script into a file and run it:

```shell
cat > /tmp/migrate.sh <<'EOF'
# paste the contents of keycloak/migrate-realm-keycloak-26.sh here
EOF
bash /tmp/migrate.sh dina
rm /tmp/migrate.sh
```
