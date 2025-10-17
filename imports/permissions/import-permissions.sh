export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Permissions${NC}"

for entry in "."/*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  product=${file%%_*}
  appid=`echo $file | cut -d'_' -f2`
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-permission-svc/operator/v1/$product/$appid" -d @$entry`
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...imported via operator, status: ${GREEN}$status_code${NC}, product: $product, app: $appid"
  else
    echo -e "...imported via operator, status: ${RED}$status_code${NC}, product: $product, app: $appid"
  fi 
done