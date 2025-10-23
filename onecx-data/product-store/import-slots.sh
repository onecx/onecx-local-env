#!/bin/bash
#
# Import Slots from file for Product and App
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Slots in Product Store ${NC}"

for entry in "./slots"/*
do
  filename=$(basename "$entry")
  file=`echo $filename | cut -d '.' -f 1`
  product=${filename%%_*}
  appid=`echo $filename | cut -d'_' -f2`
  slot=`echo $filename | cut -d'_' -f3`
  
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-product-store-svc/operator/slot/v1/$product/$appid" -d @$entry`

  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...import via operator, status: ${GREEN}$status_code${NC}, product: $product, slot: $slot"
  else
    echo -e "${RED}...import via operator, status: $status_code, product: $product, slot: $slot ${NC}"
  fi
done