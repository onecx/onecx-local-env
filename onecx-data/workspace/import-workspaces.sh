export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Importing Workspaces ${NC}"

for entry in "."/*_*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  tenant=`echo $file | cut -d'_' -f1`
  workspace=`echo $file | cut -d'_' -f2`
  token_var_name=${tenant}_token
  token=${!token_var_name}
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-workspace-svc/exim/v1/workspace/operator" -d @$entry`

  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "...imported via exim, status: ${GREEN}$status_code${NC}, tenant: $tenant, workspace: $workspace"
  else
    echo -e "${RED}...imported via exim, status: $status_code, tenant: $tenant, workspace: $workspace ${NC}"
  fi 
done