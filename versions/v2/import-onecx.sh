#!/bin/bash
#
# Import OneCX data from files below ./onecx-data
#
# $1 => tenant
# $2 => verbose      (true|false)
# $3 => security     (true|false)
# $4 => import type  (all|base|slot|theme|workspace)
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

export OLE_EDITION="v2"
export OLE_LINE_PREFIX="  * "
export OLE_HEADER_CT_JSON="Content-Type: application/json"


#################################################################
## Check and set import type
IMPORT_TYPE="base"
if [[ (-n $4) && ($4 == @(all|base|bookmark|assignment|permission|mfe|ms|product|slot|theme|welcome|workspace)) ]]; then
  IMPORT_TYPE=$4
fi


#################################################################
## Support starting from different directories: base, vx
current_path=`pwd`
current_dir=$(basename $current_path)
import_start_dir=.

# import started from version directory?
if [[ $current_dir == "$OLE_EDITION" ]]; then
  import_start_dir="../.."
fi


#################################################################
## Security Authentication enabled?
OLE_SECURITY_AUTH_ENABLED_INT=`grep -c "ONECX_SECURITY_AUTH_ENABLED=true" $import_start_dir/versions/$OLE_EDITION/.env`
# translate for displaying only:
OLE_SECURITY_AUTH_USED="no"
if [[ ($OLE_SECURITY_AUTH_ENABLED_INT == 1) || ($3 == "true") ]]; then
  OLE_SECURITY_AUTH_USED="yes"
  export OLE_SECURITY_AUTH_ENABLED=true
else
  export OLE_SECURITY_AUTH_ENABLED=false
fi


#################################################################
## KEYCLOAK

# Usernames and passwords for clients that exist in Keycloak
declare -A KC_TENANT_USER=()
KC_TENANT_USER['default']="onecx"
KC_TENANT_USER['t1']="onecx_t1_admin"
KC_TENANT_USER['t2']="onecx_t2_admin"
declare -A KC_TENANT_PWD=()
KC_TENANT_PWD['default']="onecx"
KC_TENANT_PWD['t1']="onecx_t1_admin"
KC_TENANT_PWD['t2']="onecx_t2_admin"

KC_USER=${KC_TENANT_USER[$1]}
KC_PWD=${KC_TENANT_PWD[$1]}
KC_REALM="onecx"
KC_TOKEN_URL="http://keycloak-app/realms/$KC_REALM/protocol/openid-connect/token"
KC_TOKEN_CT="Content-Type: application/x-www-form-urlencoded"
KC_APM_CLIENT_ID="onecx-shell-ui-client"
KC_AUTH_CLIENT_ID="onecx-local-env-import"
KC_AUTH_CLIENT_SECRET="t4LXKbpxedZoHn9mynwSih9Cz9W1VbS8u9vaDz5A"


echo -e "  edition: ${GREEN}$OLE_EDITION${NC}, tenant: ${GREEN}$1${NC}, type: ${GREEN}$IMPORT_TYPE${NC}, user: ${GREEN}$KC_USER${NC}, security authentication: ${GREEN}$OLE_SECURITY_AUTH_USED${NC}"


unset OLE_HEADER_APM_TOKEN
unset OLE_HEADER_AUTH_TOKEN
#################################################################
## If Security Authentication is enabled then get tokens
if [[ $OLE_SECURITY_AUTH_ENABLED == "1" ]]; then
  ## Get APM token for user: User info, roles, scope: Organization_ID
  echo -e "${CYAN}Fetching tokens (APM, AUTH) from Keycloak (realm: $KC_REALM, user: $KC_USER)... ${NC}"
  OLE_CURL_PARAMETER="--silent -d username=$KC_USER -d password=$KC_PWD -d grant_type=password -d client_id=$KC_APM_CLIENT_ID"
  export OLE_HEADER_APM_TOKEN="apm-principal-token: `curl $OLE_CURL_PARAMETER  $KC_TOKEN_URL  | jq -r .access_token`"
  
  ## Get AUTH (Bearer, access) token: scopes for SVCs
  OLE_CURL_PARAMETER="--silent -d client_secret=$KC_AUTH_CLIENT_SECRET -d grant_type=client_credentials -d client_id=$KC_AUTH_CLIENT_ID"
  export OLE_HEADER_AUTH_TOKEN="Authorization: Bearer `curl $OLE_CURL_PARAMETER  $KC_TOKEN_URL  | jq -r .access_token`"
fi


#################################################################
## IMPORT OneCX data
cd $import_start_dir/onecx-data

if [[ $IMPORT_TYPE == @(all|base|tenant) ]]; then
  cd tenant
  bash ./import-tenants.sh $1 $2
  cd ..
fi

if [[ $IMPORT_TYPE == @(all|base|slot|product|ms|mfe) ]]; then
  cd product-store
  if [[ $IMPORT_TYPE == @(all|base|product) ]]; then
    bash ./import-products.sh $1 $2
  fi
  if [[ $IMPORT_TYPE == @(all|base|mfe) ]]; then
    bash ./import-microfrontends.sh $1 $2
  fi
  if [[ $IMPORT_TYPE == @(all|base|ms) ]]; then
    bash ./import-microservices.sh $1 $2
  fi
  if [[ $IMPORT_TYPE == @(all|base|slot) ]]; then
    bash ./import-slots.sh $1 $2
  fi
  cd ..
fi

if [[ $IMPORT_TYPE == @(all|base|parameter) ]]; then
  cd parameter
  bash ./import-parameters.sh $1 $2
  cd ..
fi

if [[ $IMPORT_TYPE == @(all|base|permission) ]]; then
  cd permission
  bash ./import-permissions.sh $1 $2
  cd ..
fi

if [[ $IMPORT_TYPE == @(all|base|assignment) ]]; then
  cd permission-assignment
  bash ./import-assignments.sh $1 $2
  cd ..
fi

if [[ $IMPORT_TYPE == @(all|base|theme) ]]; then
  cd theme
  bash ./import-themes.sh $1 $2
  cd ..
fi

if [[ $IMPORT_TYPE == @(all|base|workspace) ]]; then
  cd workspace
  bash ./import-workspaces.sh $1 $2
  cd ..
fi

if [[ $IMPORT_TYPE == @(all|welcome) ]]; then
  cd welcome
  bash ./import-welcome-images.sh $1 $2
  cd ..
fi

if [[ $IMPORT_TYPE == @(all|bookmark) ]]; then
  cd bookmark
  bash ./import-bookmarks.sh $1 $2
  cd ..
fi


if [[ ( $current_dir != "$OLE_EDITION"  ) ]]
then
  cd ..
fi
