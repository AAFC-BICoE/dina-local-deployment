#!/usr/bin/env bash

set -e

# CONFIGURATION
# Action to perform: "stop" or "start" (defaults to "stop")
ACTION="${1:-stop}"
# Project name used for docker deployment
PROJECT_NAME="dina-local-deployment"

# Space-separated array of container names to skip
export EXCLUDE_CONTAINERS=(
    "dina-local-deployment-keycloak-db-1"
    "dina-local-deployment-dina-db-1"
    "dina-local-deployment-init-db-1"
    "dina-local-deployment-elastic-configurator-1"
)

# Validate action parameter
if [[ "$ACTION" != "stop" && "$ACTION" != "start" ]]; then
    echo "Error: Invalid action '$ACTION'. Use 'stop' or 'start'."
    exit 1
fi

echo "Action: Performing docker $ACTION..."

# Find containers belonging to the project
# For 'stop', filter running containers (-f status=running)
# For 'start', filter stopped containers (-f status=exited)
FILTER_STATUS=$([ "$ACTION" == "stop" ] && echo "status=running" || echo "status=exited")

# Get list of container names matching the project label filter
ALL_TARGET_CONTAINERS=$(docker ps -a --filter "label=com.docker.compose.project=$PROJECT_NAME" --filter "$FILTER_STATUS" --format "{{.Names}}")

TARGETS=()

# Filter out excluded containers
for container in $ALL_TARGET_CONTAINERS; do
    if [[ " ${EXCLUDE_CONTAINERS[*]} " =~ " ${container} " ]]; then
        echo "Excluding container: $container"
    else
        TARGETS+=("$container")
    fi
done

# Execute action if matching containers exist
if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "No containers found to $ACTION."
else
    echo "--------------------------------------------------"
    echo "Executing docker $ACTION on:"
    printf ' - %s\n' "${TARGETS[@]}"
    echo "--------------------------------------------------"
    docker "$ACTION" "${TARGETS[@]}"
fi
