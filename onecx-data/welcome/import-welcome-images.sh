#!/bin/bash
#
# Import Welcome Images from file for Tenant and Workspace
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Welcome Images ${NC}"

for entry in "."/*_*.json
do
  filename=$(basename "$entry")
  filename=`echo $filename | cut -d '.' -f 1`
  tenant=`echo $filename | cut -d'_' -f1`
  workspace=`echo $filename | cut -d'_' -f2`
  token_var_name=${tenant}_token
  token=${!token_var_name}
  
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-welcome-svc/exim/v1/images/$workspace/import" -d @$entry`

  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...import via exim, status: ${GREEN}$status_code${NC}, tenant: $tenant, workspace: $workspace"
  else
    echo -e "${RED}...import via exim, status: $status_code, tenant: $tenant, workspace: $workspace ${NC}"
  fi 
done