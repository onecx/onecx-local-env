export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Microfrontends in Product Store ${NC}"

for entry in "./microfrontends"/*
do
  #echo "$entry"
  filename=$(basename "$entry")
  filename=`echo $filename | cut -d '.' -f 1`
  product=${filename%%_*}
  appid=`echo $filename | cut -d'_' -f2`
  mfe=`echo $filename | cut -d'_' -f3`
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-product-store-svc/operator/mfe/v1/$product/$appid" -d @$entry`

  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...imported via operator, status: ${GREEN}$status_code${NC}, product: $product, app: $appid, microfrontend: $mfe"
  else
    echo -e "${RED}...imported via operator, status: $status_code, product: $product, app: $appid, microfrontend: $mfe ${NC}"
  fi
done