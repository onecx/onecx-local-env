echo "##### Importing slots for product store"

for entry in "./slots"/*
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  product=${file%%_*}
  appid=`echo $file | cut -d'_' -f2`
  slot=`echo $file | cut -d'_' -f3`
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-product-store-svc//operator/slot/v1/$product/$appid" -d @$entry`
  if [[ "$status_code" =~ (200|201)$  ]]; then
    echo -e "${GREEN}Slot $slot for app $appid and product $product was uploaded with result $status_code ${NC}"
  else
    echo -e "${RED}Slot $slot for app $appid and product $product was uploaded with result $status_code ${NC}"
  fi 
done