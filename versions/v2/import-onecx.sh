#!/bin/bash
#
# Import OneCX data from files below ./onecx-data
#
# $1 => tenant
# $2 => verbose      (true|false)
# $3 => security     (true|false)
# $4 => import type  (all|base|slot|theme|workspace)
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)
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

if [[ -n "$4" && "$4" =~ ^(all|base|bookmark|assignment|parameter|permission|mfe|ms|product|slot|tenant|theme|welcome|workspace)$ ]]; then
  IMPORT_TYPE=$4
fi


#################################################################
## Support starting from different directories: base, vx
current_path=$(pwd)
current_dir=$(basename "$current_path")
import_start_dir=.

# import started from version directory?
if [[ "$current_dir" == "$OLE_EDITION" ]]; then
  import_start_dir="../.."
fi

ENV_FILE="$import_start_dir/versions/${OLE_EDITION}/.env"

#################################################################
## Secure Authentication enabled?
# Check option set by start script
if [ -n $3 ]; then
  if [[ $3 == "true" ]]; then
    OLE_SECURITY_AUTH_ENABLED=true
  fi
elif [ -f "$ENV_FILE" ]; then
  OLE_SECURITY_AUTH_ENABLED=$(grep "^ONECX_SECURITY_AUTH_ENABLED=" "$ENV_FILE" | cut -d '=' -f2 )
else
    OLE_SECURITY_AUTH_ENABLED=false
fi

# translate for displaying only:
OLE_SECURITY_AUTH_USED="no"
if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  OLE_SECURITY_AUTH_USED="yes"
fi
export OLE_SECURITY_AUTH_ENABLED


#################################################################
## KEYCLOAK
if [ -f "$ENV_FILE" ]; then
  kc_realm=$(grep "^KC_REALM=" "$ENV_FILE" | cut -d '=' -f2)
  kc_apm_client_id=$(grep "^KC_CLIENT_ID=" "$ENV_FILE" | cut -d '=' -f2)
  kc_auth_client_id=$(grep "^ONECX_OIDC_CLIENT_CLIENT_ID=" "$ENV_FILE" | cut -d '=' -f2)
  kc_auth_client_secret=$(grep "^ONECX_OIDC_CLIENT_S_E_C_R_E_T=" "$ENV_FILE" | cut -d '=' -f2)
fi
# Missing?
if [ -z "$kc_realm" ]; then
  printf "${RED}Could not read 'KC_REALM' from "$ENV_FILE"${NC}\n"
  exit 1
elif [ -z "$kc_apm_client_id" ]; then
  printf "${RED}Could not read 'KC_CLIENT_ID' from "$ENV_FILE"${NC}\n"
  exit 1
elif [ -z "$kc_auth_client_id" ]; then
  printf "${RED}Could not read 'ONECX_OIDC_CLIENT_CLIENT_ID' from "$ENV_FILE"${NC}\n"
  exit 1
elif [ -z "$kc_auth_client_secret" ]; then
  printf "${RED}Could not read 'ONECX_OIDC_CLIENT_S_E_C_R_E_T' from "$ENV_FILE"${NC}\n"
  exit 1
fi

KC_TOKEN_URL="http://keycloak-app/realms/${kc_realm}/protocol/openid-connect/token"
KC_TOKEN_CT="Content-Type: application/x-www-form-urlencoded"

# Identify user for tenants
case "$1" in
    "t1")
        KC_USER="onecx_t1_admin"
        KC_PWD="onecx_t1_admin"
        ;;
    "t2")
        KC_USER="onecx_t2_admin"
        KC_PWD="onecx_t2_admin"
        ;;
    *)
        # Default case
        KC_USER="onecx"
        KC_PWD="onecx"
        ;;
esac

printf "  edition: ${GREEN}${OLE_EDITION}${NC}, tenant: ${GREEN}$1${NC}, type: ${GREEN}${IMPORT_TYPE}${NC}, user: ${GREEN}${KC_USER}${NC}, secure authentication: ${GREEN}${OLE_SECURITY_AUTH_USED}${NC}\n"


unset OLE_HEADER_APM_TOKEN
unset OLE_HEADER_AUTH_TOKEN
#################################################################
## If Secure Authentication is enabled then get tokens
if [[ "${OLE_SECURITY_AUTH_ENABLED}" == "true" ]]; then
  ## Get APM token for user: User info, roles, scope: Organization_ID
  printf "${CYAN}Fetching tokens (APM, AUTH) from Keycloak (realm: ${kc_realm}, user: ${KC_USER})... ${NC}\n"
  
  OLE_CURL_PARAMETER="--silent -d username=${KC_USER} -d password=${KC_PWD} -d grant_type=password -d client_id=${kc_apm_client_id}"
  
  # Capture token, handle potential curl errors cleanly
  TOKEN_RES=$(curl $OLE_CURL_PARAMETER "$KC_TOKEN_URL")
  export OLE_HEADER_APM_TOKEN="apm-principal-token: $(echo "${TOKEN_RES}" | jq -r .access_token)"

  ## Get AUTH (Bearer, access) token: scopes for SVCs
  OLE_CURL_PARAMETER="--silent -d client_secret=${kc_auth_client_secret} -d grant_type=client_credentials -d client_id=${kc_auth_client_id}"
  
  TOKEN_RES=$(curl $OLE_CURL_PARAMETER "$KC_TOKEN_URL")
  export OLE_HEADER_AUTH_TOKEN="Authorization: Bearer $(echo "${TOKEN_RES}" | jq -r .access_token)"
fi


#################################################################
## IMPORT OneCX data
cd "$import_start_dir/onecx-data" || exit 1


if [[ "$IMPORT_TYPE" =~ ^(all|base|slot|product|ms|mfe)$ ]]; then
  cd product-store
  if [[ "$IMPORT_TYPE" =~ ^(all|base|product)$ ]]; then
    bash ./import-products.sh "$1" "$2"
  fi
  if [[ "$IMPORT_TYPE" =~ ^(all|base|mfe)$ ]]; then
    bash ./import-microfrontends.sh "$1" "$2"
  fi
  if [[ "$IMPORT_TYPE" =~ ^(all|base|ms)$ ]]; then
    bash ./import-microservices.sh "$1" "$2"
  fi
  if [[ "$IMPORT_TYPE" =~ ^(all|base|slot)$ ]]; then
    bash ./import-slots.sh "$1" "$2"
  fi
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|parameter)$ ]]; then
  cd parameter
  bash ./import-parameters.sh "$1" "$2"
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|permission)$ ]]; then
  cd permission
  bash ./import-permissions.sh "$1" "$2"
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|assignment)$ ]]; then
  cd permission-assignment
  bash ./import-assignments.sh "$1" "$2"
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|tenant)$ ]]; then
  cd tenant
  bash ./import-tenants.sh "$1" "$2"
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|theme)$ ]]; then
  cd theme
  bash ./import-themes.sh "$1" "$2"
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|workspace)$ ]]; then
  cd workspace
  bash ./import-workspaces.sh "$1" "$2"
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|welcome)$ ]]; then
  cd welcome
  bash ./import-welcome-images.sh "$1" "$2"
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|bookmark)$ ]]; then
  cd bookmark
  bash ./import-bookmarks.sh "$1" "$2"
  cd ..
fi

if [[ "$IMPORT_TYPE" =~ ^(all|ai)$ ]]; then
  cd ai
  bash ./import-ai-data.sh "$1" "$2"
  cd ..
fi


if [[ "$current_dir" != "$OLE_EDITION" ]]; then
  cd ..
fi