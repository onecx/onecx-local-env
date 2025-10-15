export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Tenants ${NC}"

for entry in "."/*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H 'Content-Type: application/json' "http://onecx-tenant-svc/exim/v1/tenants/operator" -d @$entry`
  
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...imported via exim, status: ${GREEN}$status_code${NC}"
  else
    echo -e "${RED}...imported via exim, status: $status_code"
  fi 
done