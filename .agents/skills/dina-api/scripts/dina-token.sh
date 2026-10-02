#!/usr/bin/env bash
# Prints a valid Keycloak access token for the local DINA deployment (https://dina.local).
# Tokens are cached and refreshed automatically; a new password-grant login happens only
# when the refresh token has also expired.
#
#   dina-token.sh          print access token
#   dina-token.sh --force  ignore the cache and log in again
#   dina-token.sh --clear  delete the cached token
#
# Credentials default to the local dev account cnc-su; override with DINA_USERNAME / DINA_PASSWORD.
set -euo pipefail

TOKEN_URL="https://dina.local/auth/realms/dina/protocol/openid-connect/token"
CLIENT_ID="dina-public"
USERNAME="${DINA_USERNAME:-cnc-su}"
PASSWORD="${DINA_PASSWORD:-cnc-su}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dina-api"
CACHE_FILE="$CACHE_DIR/token-$USERNAME.json"

case "${1:-}" in
  --clear) rm -f "$CACHE_FILE"; exit 0 ;;
  --force) rm -f "$CACHE_FILE" ;;
esac

# json_get FILE KEY -> prints value (empty if missing)
json_get() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get(sys.argv[2], ""))' "$1" "$2"
}

# save_token RESPONSE_JSON -> writes cache, fails if response has no access_token
save_token() {
  mkdir -p "$CACHE_DIR" && chmod 700 "$CACHE_DIR"
  (umask 077; TOKEN_RESPONSE="$1" python3 - "$CACHE_FILE" <<'PY'
import json, os, sys, time
try:
    r = json.loads(os.environ["TOKEN_RESPONSE"])
except ValueError:
    sys.exit(1)
if "access_token" not in r:
    sys.exit(1)
now = int(time.time())
json.dump({
    "access_token": r["access_token"],
    "refresh_token": r.get("refresh_token", ""),
    "expires_at": now + int(r.get("expires_in", 0)) - 30,
    "refresh_expires_at": now + int(r.get("refresh_expires_in", 0)) - 30,
}, open(sys.argv[1], "w"))
PY
  )
}

now=$(date +%s)

if [[ -f "$CACHE_FILE" ]]; then
  if (( $(json_get "$CACHE_FILE" expires_at) > now )); then
    json_get "$CACHE_FILE" access_token; exit 0
  fi
  if (( $(json_get "$CACHE_FILE" refresh_expires_at) > now )); then
    resp=$(curl -sS -X POST "$TOKEN_URL" \
      -d grant_type=refresh_token -d client_id="$CLIENT_ID" \
      --data-urlencode refresh_token="$(json_get "$CACHE_FILE" refresh_token)")
    if save_token "$resp"; then json_get "$CACHE_FILE" access_token; exit 0; fi
  fi
fi

resp=$(curl -sS -X POST "$TOKEN_URL" \
  -d grant_type=password -d client_id="$CLIENT_ID" -d scope=openid \
  --data-urlencode username="$USERNAME" --data-urlencode password="$PASSWORD")
if ! save_token "$resp"; then
  echo "dina-token: login failed for '$USERNAME': $resp" >&2
  exit 1
fi
json_get "$CACHE_FILE" access_token
