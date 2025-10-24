#!/bin/bash
#
# Import Permission Assignments from file for Tenant and Product
#
# A file contains the assignment of permissions (defined by product/app)
# to roles

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Permission Assignments${NC}"

for entry in "."/*.json
do
  filename=$(basename "$entry")
  filename=`echo $filename | cut -d '.' -f 1`
  tenant=`echo $filename | cut -d'-' -f1`

  product=`echo $filename | cut -d'_' -f2`
  token_var_name=${tenant}_token
  token=${!token_var_name}

  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-permission-svc/exim/v1/assignments/operator" -d @$entry`

  if [[ "$status_code" =~ (200|201)$  ]]; then
    if [[ $1 != "silent" ]]; then
      echo -e "...import via operator, status: ${GREEN}$status_code${NC}, product: $product"
    fi
  else
    echo -e "${RED}...import via operator, status: $status_code, product: $product ${NC}"
  fi 
done