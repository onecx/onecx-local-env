#!/bin/bash
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

## Set SKIP_CONTAINER_MANAGEMENT to 1 or true to skip starting/stopping containers:
##  export SKIP_CONTAINER_MANAGEMENT=1
## Can be useful if containers are already running and are still needed after the imports are done (e.g. to run additional custom import scripts)
SKIP_CONTAINER_MANAGEMENT=${SKIP_CONTAINER_MANAGEMENT:-0}

if [[ "$SKIP_CONTAINER_MANAGEMENT" == "1" || "$SKIP_CONTAINER_MANAGEMENT" == "true" ]]; then
  echo -e "${CYAN}Skipping container startup/shutdown${NC} (SKIP_CONTAINER_MANAGEMENT is set to $SKIP_CONTAINER_MANAGEMENT)"
else
  echo " "
  echo -e "${CYAN}Starting containers using data-import profile...${NC}"
  docker compose --profile=data-import up -d --wait
fi

## Fetch token from keycloak
echo " "
echo -e "${CYAN}Fetching token from Keycloak... ${NC}"
export onecx_token=$(curl -X POST "http://keycloak-app/realms/onecx/protocol/openid-connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=onecx" -d "password=onecx"  -d "grant_type=password" -d "client_id=onecx-shell-ui-client" | jq -r .access_token)

## Sleep for 30 seconds to wait for services to be operational
if [[ "$SKIP_CONTAINER_MANAGEMENT" == "0" || "$SKIP_CONTAINER_MANAGEMENT" == "false" ]]; then
  echo " "
  echo -e "${CYAN}Waiting 30 seconds to ensure all services are operational...${NC}"
  sleep 30
fi

## Import data

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

cd ../parameters
echo " "
bash ./import-parameters.sh

cd ../workspace
echo " "
bash ./import-workspaces.sh

cd ../theme
echo " "
bash ./import-themes.sh

cd ../permissions
echo " "
bash ./import-permissions.sh

cd ../permission-assignments
echo " "
bash ./import-assignments.sh


cd ../..


if [[ "$SKIP_CONTAINER_MANAGEMENT" == "1" || "$SKIP_CONTAINER_MANAGEMENT" == "true" ]]; then
  exit 0
else
  ## Stop containers
  echo " "
  echo "Stopping containers used for data import..."
  docker compose --profile=data-import down
fi