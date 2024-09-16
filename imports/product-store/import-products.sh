echo "##### Importing products for product store"

for entry in "./products"/*
do
  #echo "$entry"
  file=$(basename "$entry")
  file=`echo $file | cut -d '.' -f 1`
  status_code=`curl --write-out %{http_code} --silent --output /dev/null -X PUT -H 'Content-Type: application/json' "http://onecx-product-store-svc//operator/product/v1/update/$file" -d @$entry`
  echo "$file uploaded with result $status_code"
done