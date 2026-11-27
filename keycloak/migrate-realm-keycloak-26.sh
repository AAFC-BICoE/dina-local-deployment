#!/usr/bin/env bash
# Keycloak 26 realm migration for EXISTING installs (new installs get this from the realm import).
# See docs/keycloak-26-upgrade.md. Safe to run more than once.
#
# Usage, from dina-local-deployment:
#   docker exec -i <keycloak-container> bash -s -- dina < keycloak/migrate-realm-keycloak-26.sh
#   kubectl exec -i <keycloak-pod> -- bash -s -- dina < keycloak/migrate-realm-keycloak-26.sh
#   oc exec -i <keycloak-pod> -- bash -s -- dina < keycloak/migrate-realm-keycloak-26.sh
set -euo pipefail

# kcadm saves its login under $HOME, which isn't writable when OKD runs the pod as a random user
export HOME=/tmp
trap 'rm -rf /tmp/.keycloak' EXIT  # don't leave the admin login behind

REALM="${1:-dina}"
KCADM=/opt/keycloak/bin/kcadm.sh

echo "Logging in to Keycloak"
$KCADM config credentials --server http://localhost:8080/auth --realm master \
  --user "${KEYCLOAK_ADMIN:-admin}" --password "$KEYCLOAK_ADMIN_PASSWORD"

get_client_id() {
  $KCADM get clients -r "$REALM" -q clientId="$1" --fields id --format csv --noquotes
}

USER_SVC_ID=$(get_client_id user-svc)
DINA_PUBLIC_ID=$(get_client_id dina-public)
REALM_MANAGEMENT_ID=$(get_client_id realm-management)

# The kc-admin-api scope is created by the Keycloak 26.8 upgrade itself
KC_ADMIN_API_SCOPE_ID=$($KCADM get client-scopes -r "$REALM" --fields id,name --format csv --noquotes \
  | grep ',kc-admin-api$' | cut -d, -f1) || { echo "kc-admin-api scope not found in realm $REALM"; exit 1; }

echo "1. Add kc-admin-api as a default client scope of user-svc"
$KCADM update "clients/$USER_SVC_ID/default-client-scopes/$KC_ADMIN_API_SCOPE_ID" -r "$REALM"

echo "2. Map realm roles to dina-public"
DINA_REALM_USER=$($KCADM get roles/dina-realm-user -r "$REALM")
DINA_ADMIN=$($KCADM get roles/dina-admin -r "$REALM")
READ_ONLY_ADMIN=$($KCADM get roles/read-only-admin -r "$REALM")
$KCADM create "clients/$DINA_PUBLIC_ID/scope-mappings/realm" -r "$REALM" \
  -b "[$DINA_REALM_USER, $DINA_ADMIN, $READ_ONLY_ADMIN]"

echo "3. Map realm-management roles to user-svc"
REALM_MANAGEMENT_ROLES="clients/$REALM_MANAGEMENT_ID/roles"
VIEW_USERS=$($KCADM get "$REALM_MANAGEMENT_ROLES/view-users" -r "$REALM")
MANAGE_USERS=$($KCADM get "$REALM_MANAGEMENT_ROLES/manage-users" -r "$REALM")
QUERY_USERS=$($KCADM get "$REALM_MANAGEMENT_ROLES/query-users" -r "$REALM")
QUERY_GROUPS=$($KCADM get "$REALM_MANAGEMENT_ROLES/query-groups" -r "$REALM")
$KCADM create "clients/$USER_SVC_ID/scope-mappings/clients/$REALM_MANAGEMENT_ID" -r "$REALM" \
  -b "[$VIEW_USERS, $MANAGE_USERS, $QUERY_USERS, $QUERY_GROUPS]"

# Done last, so tokens never lose their roles in between
echo "4. Turn off 'Full scope allowed' on user-svc and dina-public"
$KCADM update "clients/$USER_SVC_ID" -r "$REALM" -s fullScopeAllowed=false
$KCADM update "clients/$DINA_PUBLIC_ID" -r "$REALM" -s fullScopeAllowed=false

echo "Done"
