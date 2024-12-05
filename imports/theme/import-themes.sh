echo "##### Importing themes"

for entry in "."/*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  tenant=`echo $file | cut -d'_' -f1`
  theme=`echo $file | cut -d'_' -f2`
  token_var_name=${tenant}_token
  token=${!token_var_name}
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-theme-svc/exim/v1/themes/operator" -d @$entry`
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "${GREEN}Theme $theme were uploaded for tenant $tenant with status code $status_code ${NC}"
  else
    echo -e "${RED}Theme $theme were uploaded for tenant $tenant with status code $status_code ${NC}"
  fi 
done