echo "##### Importing tenants"

for entry in "."/*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X POST -H 'Content-Type: application/json' "http://onecx-tenant-svc//exim/v1/tenants/operator" -d @$entry`
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "${GREEN}Tenants were uploaded with status code $status_code ${NC}"
  else
    echo -e "${RED}Tenants were uploaded with status code $status_code ${NC}"
  fi 
done