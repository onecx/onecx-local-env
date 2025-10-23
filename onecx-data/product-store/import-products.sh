#!/bin/bash
#
# Import Products from file for Product
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Products in Product Store ${NC}"

for entry in "./products"/*
do
  filename=$(basename "$entry")
  product=`echo $filename | cut -d '.' -f 1`
  
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-product-store-svc/operator/product/v1/update/$product" -d @$entry`

  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...import via operator, status: ${GREEN}$status_code${NC}, product: $product"
  else
    echo -e "${RED}...import via operator, status: $status_code, product: $product ${NC}"
  fi
done