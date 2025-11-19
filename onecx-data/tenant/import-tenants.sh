#!/bin/bash
#
# Import Tenants from file
#
# $1 => tenant
# $2 => verbose   (true|false)
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "$OLE_LINE_PREFIX${CYAN}Importing Tenants ${NC}"

for entry in "."/*.json
do
  url="http://onecx-tenant-svc/exim/v1/tenants/operator"
  params="--write-out %{http_code} --silent --output /dev/null -X POST"
  if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
    status_code=`curl  $params  -H "$OLE_HEADER_CT_JSON"  -H "$OLE_HEADER_AUTH_TOKEN"  -H "$OLE_HEADER_AUTH_TOKEN"  -d @$entry  $url`
  else
    status_code=`curl  $params  -H "$OLE_HEADER_CT_JSON"  -d @$entry  $url`
  fi

  if [[ "$status_code" =~ (200|201)$  ]]; then
    if [[ $2 == "true" ]]; then
      echo -e "  import: exim, status: ${GREEN}$status_code ${NC}"
    fi
  else
    echo -e "${RED}  import: exim, status: $status_code${NC}"
  fi 
done