# DINA Modules to activate
DINA_MODULES=()
DINA_MODULES+=('user_api')
#DINA_MODULES+=('object_store_api')
#DINA_MODULES+=('agent_api')
#DINA_MODULES+=('search_api')
#DINA_MODULES+=('seqdb_api')
#DINA_MODULES+=('export_api')
#DINA_MODULES+=('loan_transaction_api')

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

# Print the profiles and configs being used
YELLOW_COLOR_CODE="\033[33m"
WHITE_COLOR_CODE="\033[0m"
echo -e "${YELLOW_COLOR_CODE}Using the following profile(s):${WHITE_COLOR_CODE} $COMPOSE_PROFILES"
echo -e "${YELLOW_COLOR_CODE}Using the following config(s):${WHITE_COLOR_CODE} $COMPOSE_CONFIGS"

# Append -f to each config for use in docker-compose
for i in "${!DINA_CONFIGS[@]}"; do
  DINA_CONFIGS[$i]="-f ${DINA_CONFIGS[$i]}"
done

# Run docker-compose with the profiles and configs
docker compose ${DINA_CONFIGS[@]} $@
