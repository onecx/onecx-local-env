#!/bin/bash
## Set SKIP_CONTAINER_MANAGEMENT to 1 or true to skip starting/stopping containers
## Can be useful if containers are already running and are still needed after the imports are done (e.g. to run additional custom import scripts)
SKIP_CONTAINER_MANAGEMENT=${SKIP_CONTAINER_MANAGEMENT:-0}

if [[ "$SKIP_CONTAINER_MANAGEMENT" == "1" || "$SKIP_CONTAINER_MANAGEMENT" == "true" ]]; then
  echo "SKIP_CONTAINER_MANAGEMENT is set to $SKIP_CONTAINER_MANAGEMENT, skipping container startup..."
else
  ## Start containers using data-import profile
  echo " "
  echo "Starting containers using data-import profile..."
  docker compose -f docker-compose.v2.yaml --profile data-import up -d --wait
fi

## Fetch token from keycloak
echo " "
echo "Fetching token from Keycloak..."
export onecx_token=$(curl -X POST "http://keycloak-app/realms/onecx/protocol/openid-connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=onecx" -d "password=onecx"  -d "grant_type=password" -d "client_id=onecx-shell-ui-client" | jq -r .access_token)

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m' # No Color

## Sleep for 30 seconds to wait for services to be operational
echo " "
echo "Waiting 30 seconds to ensure all services are operational..."
sleep 30

## Import data
echo " "
echo "Importing data..."

cd imports/tenant

echo " "
bash ./import-tenants.sh

cd ../product-store

echo " "
bash ./import-products.sh
echo " "
bash ./import-slots.sh
echo " "
bash ./import-microservices.sh
echo " "
bash ./import-microfrontends.sh

cd ../permissions

echo " "
bash ./import-permissions.sh

cd ../parameters

echo " "
bash ./import-parameters.sh

cd ../assignments

echo " "
bash ./import-assignments.sh

cd ../workspace

echo " "
bash ./import-workspaces.sh

cd ../theme

echo " "
bash ./import-themes.sh

cd ../..


if [[ "$SKIP_CONTAINER_MANAGEMENT" == "1" || "$SKIP_CONTAINER_MANAGEMENT" == "true" ]]; then
  echo "SKIP_CONTAINER_MANAGEMENT is set to $SKIP_CONTAINER_MANAGEMENT, skipping container shutdown..."
  exit 0
else
  ## Stop containers
  echo " "
  echo "Stopping containers used for data import..."
  docker compose -f docker-compose.v2.yaml --profile data-import down
fi