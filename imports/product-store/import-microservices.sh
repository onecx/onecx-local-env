echo "##### Importing microservices for product store"

for entry in "./microservices"/*
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  product=${file%%_*}
  appid=`echo $file | cut -d'_' -f2`
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-product-store-svc//operator/ms/v1/$product/$appid" -d @$entry`
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "${GREEN}Microservice $appid for product $product was uploaded with result $status_code ${NC}"
  else
    echo -e "${RED}Microservice $appid for product $product was uploaded with result $status_code ${NC}"
  fi 
done