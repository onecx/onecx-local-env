#!/bin/bash
#
# Import Parameters from file for Tenant and Product
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Parameters ${NC}"

for entry in "."/*.json
do
  filename=$(basename "$entry")
  filename=`echo $filename | cut -d '.' -f 1`
  product=${filename%%_*}
  appid=`echo $filename | cut -d'_' -f2`
  
  url="http://onecx-parameter-svc/operator/v1/parameters/$product/$appid"
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "$url" -d @$entry`
  
  if [[ "$status_code" =~ (200|201|204)$  ]]; then
    if [[ $1 != "silent" ]]; then
      echo -e "...import via operator, status: ${GREEN}$status_code${NC}, product: $product, app: $appid"
    fi
  else
    echo -e "${RED}...import via operator, status: $status_code, product: $product, app: $appid ${NC}"
  fi 
done
