#!/usr/bin/env bash
# Authenticated curl against the local DINA API (https://dina.local/api).
#
#   dina-curl.sh METHOD PATH [BODY] [extra curl args...]
#
#   PATH  API path, e.g. '/agent-api/person?page[limit]=5' (a full https://dina.local/... URL also works)
#   BODY  inline JSON, @file.json, or - for stdin; pass "" for no body when adding extra curl args
#
# Prints the response body to stdout and "HTTP <status>" to stderr. Exits non-zero on HTTP >= 400.
# Retries once with a fresh login if the API answers 401.
# Content-Type is application/vnd.api+json (application/json for /search-api); override with DINA_CONTENT_TYPE.
set -euo pipefail

BASE_URL="https://dina.local/api"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if (( $# < 2 )); then
  sed -n '4,11p' "$0" >&2; exit 2
fi

method="${1^^}"; path="$2"; body="${3:-}"
shift $(( $# >= 3 ? 3 : 2 ))

case "$path" in
  https://dina.local/*) url="$path" ;;
  *://*) echo "dina-curl: only https://dina.local is allowed" >&2; exit 2 ;;
  /*) url="$BASE_URL$path" ;;
  *) url="$BASE_URL/$path" ;;
esac

# The search API (Elasticsearch passthrough) wants plain JSON; everything else is JSON:API.
case "$url" in
  */search-api/*) content_type="${DINA_CONTENT_TYPE:-application/json}" ;;
  *) content_type="${DINA_CONTENT_TYPE:-application/vnd.api+json}" ;;
esac

body_args=()
if [[ "$body" == "-" ]]; then
  # Buffer stdin so the body can be resent on a 401 retry.
  body_file=$(mktemp); cat > "$body_file"
  body_args=(--data-binary "@$body_file")
elif [[ -n "$body" ]]; then
  body_args=(--data-binary "$body")
fi

out=$(mktemp)
trap 'rm -f "$out" ${body_file:+"$body_file"}' EXIT

send() {
  curl -sS -g -X "$method" "$url" \
    -H "Authorization: Bearer $1" \
    -H "Content-Type: $content_type" \
    ${body_args[@]+"${body_args[@]}"} "${@:2}" \
    -o "$out" -w '%{http_code}'
}

status=$(send "$("$SCRIPT_DIR/dina-token.sh")" "$@")
if [[ "$status" == 401 ]]; then
  status=$(send "$("$SCRIPT_DIR/dina-token.sh" --force)" "$@")
fi

cat "$out"; [[ -s "$out" ]] && echo
echo "HTTP $status" >&2
(( status < 400 ))
