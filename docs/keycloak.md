# Keycloak

## 0. Prerequisites

An entry for Keycloak in your `hosts` file:

`172.19.33.10	keycloak.local`

## 1. Get a Bearer token

You can use the following script:
https://github.com/akoserwal/keycloak-integrations/blob/master/curl-post-request/keycloak-curl.sh[keycloak-curl.sh]

The script has to parse the json response so https://stedolan.github.io/jq/download/[jq] should be installed.

The script usage is `./keycloak-curl.sh hostname realm username clientid`

Usage with the object-store docker-compose:

`./keycloak-curl.sh keycloak.local:8080 dina user objectstore`

You will have a enter a password ('user').
The token will be printed in the console.

NOTE: The scripts assumes https which may not be available on local setup, in that case the script has to be modified to use http.

## 2. Use the Bearer token

`curl -v -H "Authorization: Bearer <TOKEN>" localhost:8081/api/v1`

NOTE: The token expires after 5 minutes

