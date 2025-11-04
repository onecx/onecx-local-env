#!/bin/bash
## Define token
export onecx_token=$(curl -X POST "http://keycloak-app/realms/onecx/protocol/openid-connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=onecx" -d "password=onecx"  -d "grant_type=password" -d "client_id=onecx-shell-ui-client" | jq -r .access_token)

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m' # No Color

cd onecx-data/tenant

echo " "
bash ./import-tenants.sh  $1 $2

cd ../theme

echo " "
bash ./import-themes.sh  $1 $2

cd ../product-store

echo " "
bash ./import-products.sh  $1 $2
echo " "
bash ./import-slots.sh  $1 $2
echo " "
bash ./import-microservices.sh  $1 $2
echo " "
bash ./import-microfrontends.sh  $1 $2

cd ../permissions

echo " "
bash ./import-permissions.sh  $1 $2

cd ../parameters

echo " "
bash ./import-parameters.sh  $1 $2

cd ../assignments

echo " "
bash ./import-assignments.sh  $1 $2

cd ../workspace

echo " "
bash ./import-workspaces.sh  $1 $2

cd ../..
