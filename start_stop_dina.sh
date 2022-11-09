DINA_MODULES=()
DINA_MODULES+=('object_store_api')
#DINA_MODULES+=('search_api')
#DINA_MODULES+=('seqdb_api')
#DINA_MODULES+=('report_label_api')

#DINA_MODULES+=('kibana')
#DINA_MODULES+=('prometheus')

printf -v module_arr '%s,' "${DINA_MODULES[@]}"

# remove last comma and export the variable for docker compose
export COMPOSE_PROFILES=$(echo ${module_arr%,})

echo "Using the following profile(s): $COMPOSE_PROFILES"

# pass all the arguments to docker compose
docker compose -f docker-compose.base.yml -f docker-compose.local.yml $@

