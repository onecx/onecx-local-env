export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Permission Assignments${NC}"

for entry in "."/*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  tenant=`echo $file | cut -d'-' -f1`
  product=`echo $file | cut -d'_' -f2`
  token_var_name=${tenant}_token
  token=${!token_var_name}
  #echo "curl -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-permission-svc//exim/v1/assignments/operator" -d @$entry"
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-permission-svc/exim/v1/assignments/operator" -d @$entry`
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...imported via operator, status: ${GREEN}$status_code${NC}, product: $product"
  else
    echo -e "${RED}...imported via operator, status: $status_code, product: $product ${NC}"
  fi 
done