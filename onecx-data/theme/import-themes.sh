#!/bin/bash
#
# Import Themes from file for Tenant
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Themes ${NC}"

for entry in "."/*.json
do
  filename=$(basename "$entry")
  filename=`echo $filename | cut -d '.' -f 1`
  tenant=`echo $filename | cut -d'_' -f1`
  theme=`echo $filename | cut -d'_' -f2`
  token_var_name=${tenant}_token
  token=${!token_var_name}
  
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-theme-svc/exim/v1/themes/operator" -d @$entry`

  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...import via exim, status: ${GREEN}$status_code${NC}, tenant: $tenant, theme: $theme"
  else
    echo -e "${RED}...import via exim, status: $status_code, tenant: $tenant, theme: $theme ${NC}"
  fi 
done