echo "##### Importing parameters"

for entry in "."/*.json
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  product=${file%%_*}
  appid=`echo $file | cut -d'_' -f2`
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-parameter-svc/operator/v1/parameters/$product/$appid" -d @$entry`
  if [[ "$status_code" =~ (200|201|204)$  ]]; then
    echo -e "${GREEN}Parameters for app $appid and product $product was uploaded with result $status_code ${NC}"
  else
    echo -e "${RED}Parameters for app $appid and product $product was uploaded with result $status_code ${NC}"
  fi 
done
