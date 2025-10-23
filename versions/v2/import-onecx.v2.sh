#!/bin/bash
#
# Import One data from files
#


export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Import OneCX v2 data${NC}"


## Set SKIP_CONTAINER_MANAGEMENT to 0 or false to starting/stopping containers for data import:
##  export SKIP_CONTAINER_MANAGEMENT=0
##  default: 1 = SKIP
##  Can be useful if containers are already running and are still needed after the imports are done (e.g. to run additional custom import scripts)
SKIP_CONTAINER_MANAGEMENT=${SKIP_CONTAINER_MANAGEMENT:-1}

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

## Support starting from different directories: base, v2

current_path=`pwd`
current_dir=$(basename $current_path)

import_start_dir=./

# import started from v2 directory?
if [[ ( $current_dir == "v2"  ) ]]
then
  import_start_dir="../.."
fi


## Import OneCX data
cd $import_start_dir/onecx-data

cd tenant
echo " "
bash ./import-tenants.sh
cd ..

cd parameter
echo " "
bash ./import-parameters.sh
cd ..

cd product-store
echo " "
bash ./import-products.sh
echo " "
bash ./import-slots.sh
echo " "
bash ./import-microservices.sh
echo " "
bash ./import-microfrontends.sh
cd ..

cd permission
echo " "
bash ./import-permissions.sh
cd ..

cd permission-assignment
echo " "
bash ./import-assignments.sh
cd ..

cd theme
echo " "
bash ./import-themes.sh
cd ..

cd welcome
echo " "
bash ./import-welcome-images.sh
cd ..

cd workspace
echo " "
bash ./import-workspaces.sh
cd ..


if [[ ( $current_dir != "v2"  ) ]]
then
  cd ..
fi


if [[ "$SKIP_CONTAINER_MANAGEMENT" == "1" || "$SKIP_CONTAINER_MANAGEMENT" == "true" ]]; then
  exit 0
else
  ## Stop containers
  echo " "
  echo -e "${CYAN}Stopping containers used for data import...${NC}"
  docker compose --profile=data-import down
fi