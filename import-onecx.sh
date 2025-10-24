#!/bin/bash
#
# Start Imports of OneCX Data in version 2
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Ensure that all services used by imports are running${NC}"
docker compose -f versions/v2/docker-compose.v2.yaml  --profile data-import   up -d

echo
bash ./versions/v2/import-onecx.v2.sh silent