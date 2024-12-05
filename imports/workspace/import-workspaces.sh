echo "##### Importing workspaces"

for entry in "."/*_*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  tenant=`echo $file | cut -d'_' -f1`
  workspace=`echo $file | cut -d'_' -f2`
  token_var_name=${tenant}_token
  token=${!token_var_name}
  #echo "curl -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-workspace-svc/exim/v1/workspace/operator" -d @$entry"
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-workspace-svc/exim/v1/workspace/operator" -d @$entry`
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "${GREEN}Uploaded workspace $workspace for tenant $tenant with status code $status_code ${NC}"
  else
    echo -e "${RED}Uploaded workspace $workspace for tenant $tenant with status code $status_code ${NC}"
  fi 
done