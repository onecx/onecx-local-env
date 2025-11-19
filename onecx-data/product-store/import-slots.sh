#!/bin/bash
#
# Import Slots from file for Product and App
#
# $1 => tenant
# $2 => verbose   (true|false)
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

get_app_count() {
  node -e "const arr = require('$1');  console.log(arr.length)"
}
get_app_id() {
  node -e "const arr = require('$1');  console.log(arr[$2].appId)"
}
get_app_item() {
  node -e "const arr = require('$1');  console.log(JSON.stringify(arr[$2].slots[$3]))"
}
get_app_item_name() {
  node -e "const arr = require('$1');  console.log(arr[$2].slots[$3].name)"
}
get_app_item_count() {
  node -e "const arr = require('$1');  console.log(arr[$2].slots.length)"
}


SKIP_MSG=""
app_id="0"
app_count="0"
app_item=""
app_item_count="0"
app_item_name=""


#################################################################
# files 
files=`ls ./slots/*.json 2>/dev/null`
if [[ $files == "" ]]; then
  SKIP_MSG=" ==>${RED} skipping${NC}: no files found"
fi

echo -e "$OLE_LINE_PREFIX${CYAN}Importing Slots in Product Store ${NC}\t$SKIP_MSG"


#################################################################
# operate on found product files
for entry in $files
do
  filename=$(basename "$entry")
  product=`echo $filename | cut -d '.' -f 1`
  app_count=$(get_app_count "$entry") 

  # for each app
  for ((i = 0 ; i < $app_count ; i++ )); do 
    app_id=$(get_app_id  "$entry"  $i) 
    app_item_count=$(get_app_item_count "$entry" $i) 

    # for each item
    for ((j = 0 ; j < $app_item_count ; j++ )); do 
      app_item=$(get_app_item            "$entry"  $i  $j) 
      app_item_name=$(get_app_item_name  "$entry"  $i  $j) 

      url="http://onecx-product-store-svc/operator/slot/v1/$product/$app_id"
      params="--write-out %{http_code} --silent --output /dev/null -X PUT"

      status_code=200
      if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
        status_code=`curl  $params  -H "$OLE_HEADER_CT_JSON"  -H "$OLE_HEADER_AUTH_TOKEN"  -H "$OLE_HEADER_AUTH_TOKEN"  -d "${app_item}"  $url`
      else
        status_code=`curl  $params  -H "$OLE_HEADER_CT_JSON"  -d "${app_item}"  $url`
      fi
    
      if [[ "$status_code" =~ (200|201)$  ]]; then
        if [[ $2 == "true" ]]; then
          echo -e "  import: operator, status: ${GREEN}$status_code${NC}, product: $product, app: $app_id, slot: $app_item_name"
        fi
      else
        echo -e "${RED}  import: operator, status: $status_code, product: $product, app: $app_id, slot: $app_item_name ${NC}"
      fi
    done
  done
done
