#!/bin/bash
## Define token
export onecx_token=$(curl -X POST "http://keycloak-app/realms/onecx/protocol/openid-connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=onecx" -d "password=onecx"  -d "grant_type=password" -d "client_id=onecx-shell-ui-client" | jq -r .access_token)

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m' # No Color

cd imports/tenant

echo " "
bash ./import-tenants.sh

cd ../theme

echo " "
bash ./import-themes.sh

cd ../product-store

echo " "
bash ./import-products.sh
echo " "
bash ./import-slots.sh
echo " "
bash ./import-microservices.sh
echo " "
bash ./import-microfrontends.sh

cd ../permissions

echo " "
bash ./import-permissions.sh

cd ../assignments

echo " "
bash ./import-assignments.sh

cd ../workspace

echo " "
bash ./import-workspaces.sh

cd ../..
