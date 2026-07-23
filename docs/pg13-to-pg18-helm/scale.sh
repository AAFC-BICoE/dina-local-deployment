#!/usr/bin/env bash

set -e

RELEASE_NAME="dina-helm"
REPLICAS="${1:-0}"

echo "Scaling to $REPLICAS replicas"

kubectl scale deployment "${RELEASE_NAME}-agent-api" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-collection-api" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-dina-export-api" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-dina-user-api" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-keycloak" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-loan-transaction-api" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-objectstore-api" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-seqdb-api" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-dina-ui" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-rabbitmq-dina" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-search-cli" --replicas="$REPLICAS"
kubectl scale deployment "${RELEASE_NAME}-search-ws" --replicas="$REPLICAS"
kubectl scale statefulset "${RELEASE_NAME}-elasticsearch-dina" --replicas="$REPLICAS"
