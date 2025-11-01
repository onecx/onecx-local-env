#!/bin/bash
#
# Import Permissions from file for Product
#
# $1 => tenant
# $2 => verbose   (true|false)
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


#################################################################
# files witch have tenant as prefix
tenant_files=`ls *.json 2>/dev/null`
if [[ $tenant_files == "" ]]; then
  SKIP_MSG=" ==>${RED} skipping${NC}: no tenant files found"
fi

echo -e "$OLE_LINE_PREFIX${CYAN}Importing Permissions${NC}\t$SKIP_MSG"


#################################################################
# operate on found files
for entry in $tenant_files
do
  filename=$(basename "$entry")
  filename=`echo $filename | cut -d '.' -f 1`
  product=`echo $filename | cut -d '_' -f 1`
  appid=`echo $filename | cut -d '_' -f 2`
  
  url="http://onecx-permission-svc/operator/v1/$product/$appid"
  params="--write-out %{http_code} --silent --output /dev/null -X PUT"
  if [[ $OLE_SECURITY_AUTH_ENABLED == 1 ]]; then
    status_code=`curl  $params  -H "$OLE_HEADER_CT_JSON"  -H "$OLE_HEADER_AUTH_TOKEN"  -H "$OLE_HEADER_AUTH_TOKEN"  -d @$entry  $url`
  else
    status_code=`curl  $params  -H "$OLE_HEADER_CT_JSON"  -d @$entry  $url`
  fi

  if [[ "$status_code" =~ (200|201)$  ]]; then
    if [[ $2 == "true" ]]; then
      echo -e "  import: exim, status: ${GREEN}$status_code${NC}, product: $product, app: $appid"
    fi
  else
    echo -e "${RED}  import: exim, status: $status_code, product: $product, app: $appid ${NC}"
  fi
done
