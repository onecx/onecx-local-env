#!/bin/bash
#
# Import Tenants from file
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Tenants ${NC}"

for entry in "."/*.json
do
  #filename=$(basename "$entry")
  #filename=`echo $filename | cut -d '.' -f 1`
  
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H 'Content-Type: application/json' "http://onecx-tenant-svc/exim/v1/tenants/operator" -d @$entry`
  # status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H 'Content-Type: application/json' "http://onecx-tenant-svc/import/tenant" -d @$entry`
  
  if [[ "$status_code" =~ (200|201)$  ]]; then
    if [[ $1 != "silent" ]]; then
      echo -e "...import via exim, status: ${GREEN}$status_code${NC}"
    fi
  else
    echo -e "${RED}...import via exim, status: $status_code"
  fi 
done