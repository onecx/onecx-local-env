#!/bin/bash
#
# Import Products from file for Product
#
# $1 => tenant
# $2 => verbose   (true|false)
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


#################################################################
# files 
files=`ls ./products/*.json 2>/dev/null`
if [[ $files == "" ]]; then
  SKIP_MSG=" ==>${RED} skipping${NC}: no files found"
fi

echo -e "$OLE_LINE_PREFIX${CYAN}Importing Products in Product Store ${NC}\t$SKIP_MSG"


#################################################################
# operate on found files
for entry in $files
do
  filename=$(basename "$entry")
  product=`echo $filename | cut -d '.' -f 1`
  
  url="http://onecx-product-store-svc/operator/product/v1/update/$product"
  params="--write-out %{http_code} --silent --output /dev/null -X PUT"
  if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
    status_code=`curl  $params  -H "$OLE_HEADER_CT_JSON"  -H "$OLE_HEADER_AUTH_TOKEN"  -H "$OLE_HEADER_AUTH_TOKEN"  -d @$entry  $url`
  else
    status_code=`curl  $params  -H "$OLE_HEADER_CT_JSON"  -d @$entry  $url`
  fi

  if [[ "$status_code" =~ (200|201)$  ]]; then
    if [[ $2 == "true" ]]; then
      echo -e "  import: operator, status: ${GREEN}$status_code${NC}, product: $product"
    fi
  else
    echo -e "${RED}  import: operator, status: $status_code, product: $product ${NC}"
  fi
done
