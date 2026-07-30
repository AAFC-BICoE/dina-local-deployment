#!/usr/bin/env bash

set -e

# DINA Modules to activate
DINA_MODULES=()
DINA_MODULES+=('user_api')
#DINA_MODULES+=('collection_api')
#DINA_MODULES+=('object_store_api')
#DINA_MODULES+=('agent_api')
#DINA_MODULES+=('search_api')
#DINA_MODULES+=('seqdb_api')
#DINA_MODULES+=('export_api')
#DINA_MODULES+=('loan_transaction_api')

#DINA_MODULES+=('wiremock')
#DINA_MODULES+=('kibana')
#DINA_MODULES+=('prometheus')

# DINA Configurations
DINA_CONFIGS=()
DINA_CONFIGS+=('docker-compose.base.yml')
DINA_CONFIGS+=('docker-compose.local.yml')
#DINA_CONFIGS+=('docker-compose.dev.yml')
#DINA_CONFIGS+=('docker-compose.debug.yml')
#DINA_CONFIGS+=('message-producing-override/docker-compose.override.messageProducer.yml')
#DINA_CONFIGS+=('persistence-override/docker-compose.override.persistence.yml')
#DINA_CONFIGS+=('keycloak/docker-compose.enable-dev-user.yml')

# Convert arrays to comma-separated strings
printf -v module_arr '%s,' "${DINA_MODULES[@]}"
printf -v config_arr '%s,' "${DINA_CONFIGS[@]}"

# Remove trailing comma and export the variables for docker-compose
export COMPOSE_PROFILES=$(echo ${module_arr%,})

# Remove training commas to display the compose configs to be applied.
COMPOSE_CONFIGS=$(echo ${config_arr%,})

# Print the ascii-art, profiles and configs being used.
GREEN_COLOR_CODE="\033[32m"
YELLOW_COLOR_CODE="\033[33m"
WHITE_COLOR_CODE="\033[0m"
echo -e "${GREEN_COLOR_CODE}"
echo "*%%%%%%%%%=    .%%%.  #%%%#    :%%%       %%%%%      "
echo "*%%%..-*%%%%.  .%%%.  #%%%%%:  :%%%      +%%%%%#     "
echo "*%%%     *%%%  .%%%.  #%%%%%%# :%%%     +%%%.%%%+    "
echo "*%%%     -%%%  .%%%.  #%%# #%%%#%%%    -%%%.  %%%+   "
echo "*%%%    =%%%#  .%%%.  #%%#  -%%%%%%   .%%%%%%%%%%%-  "
echo "*%%%%%%%%%%-   .%%%.  #%%#    *%%%%   %%%*.....*%%%. "
echo "=######+.       ###.  +##+     .###  *##*       +### "
echo -e "${WHITE_COLOR_CODE}"
echo -e "${YELLOW_COLOR_CODE}Using the following profile(s):${WHITE_COLOR_CODE} $COMPOSE_PROFILES"
echo -e "${YELLOW_COLOR_CODE}Using the following config(s):${WHITE_COLOR_CODE} $COMPOSE_CONFIGS"

# Minio has been removed: the object-store-api now runs in filesystem (FS) mode and
# stores objects on a Docker named volume instead of Minio. If the leftover Minio
# data folder still contains objects, they are NOT migrated automatically and will
# no longer be reachable. Warn the user so they can back them up / migrate manually.
# (The folder is typically root-owned, so detection is best-effort: permission
# errors are suppressed and simply result in no files being found.)
RED_COLOR_CODE="\033[31m"
MINIO_DATA_DIR="./minio-data"
if [ -d "${MINIO_DATA_DIR}" ]; then
  # Count real bucket objects, skipping Minio's internal .minio.sys metadata dir.
  MINIO_FILE_COUNT=$(find "${MINIO_DATA_DIR}" -path '*/.minio.sys' -prune -o -type f -print 2>/dev/null | wc -l)
  if [ "${MINIO_FILE_COUNT}" -gt 0 ]; then
    echo -e "${RED_COLOR_CODE}WARNING:${WHITE_COLOR_CODE} ${MINIO_FILE_COUNT} object(s) found in ${MINIO_DATA_DIR}."
    echo -e "${RED_COLOR_CODE}Minio is no longer used${WHITE_COLOR_CODE} — the object-store-api now runs in filesystem mode and these objects were NOT migrated."
    echo "To keep them, back up or migrate the contents manually before relying on the object-store-api."
  fi
fi

# Append -f to each config for use in docker-compose
for i in "${!DINA_CONFIGS[@]}"; do
  DINA_CONFIGS[$i]="-f ${DINA_CONFIGS[$i]}"
done

./update_env.sh .env.example

# Run docker-compose with the profiles and configs
docker compose ${DINA_CONFIGS[@]} $@
