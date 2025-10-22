export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Products in Product Store ${NC}"

for entry in "./products"/*
do
  #echo "entry: $entry"
  file_name=$(basename "$entry")
  file_name=`echo $file_name | cut -d '.' -f 1`
  #echo "file name: $file_name"
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-product-store-svc/operator/product/v1/update/$file_name" -d @$entry`

  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...imported via operator, status: ${GREEN}$status_code${NC}, product: $file_name"
  else
    echo -e "${RED}...imported via operator, status: $status_code, product: $file_name ${NC}"
  fi
done