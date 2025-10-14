echo "##### Importing assignments"

for entry in "."/*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  tenant=`echo $file | cut -d'_' -f1`
  product=`echo $file | cut -d'_' -f2`
  token_var_name=${tenant}_token
  token=${!token_var_name}
  #echo "curl -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-permission-svc//exim/v1/assignments/operator" -d @$entry"
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H "apm-principal-token: $token" -H 'Content-Type: application/json' "http://onecx-permission-svc/exim/v1/assignments/operator" -d @$entry`
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "${GREEN}Assignments uploaded for product $product were uploaded with status code $status_code ${NC}"
  else
    echo -e "${RED}Assignments uploaded for product $product were uploaded with status code $status_code ${NC}"
  fi 
done