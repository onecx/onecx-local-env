#!/usr/bin/env bash
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

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color
export RED GREEN CYAN YELLOW NC

#################################################################
# defaults
readonly OLE_EDITION="v2"
readonly OLE_LINE_PREFIX="  * "
readonly OLE_HEADER_CT_JSON="Content-Type: application/json"
export OLE_EDITION OLE_LINE_PREFIX OLE_HEADER_CT_JSON


#################################################################
## Check and set import type
IMPORT_TYPE="base"

if [[ -n "${4:-}" && "${4:-}" =~ ^(all|base|ai|bookmark|assignment|parameter|permission|mfe|ms|product|slot|tenant|theme|welcome|workspace)$ ]]; then
  IMPORT_TYPE="${4}"
fi


#################################################################
## Support starting from different directories: base, vx
current_path=$(pwd)
current_dir=$(basename "$current_path")
import_start_dir=.

# Import started from version/edition directory?
if [[ "$current_dir" == "$OLE_EDITION" ]]; then
  import_start_dir="../.."
fi

## Data Directory availability
if [[ ! -d "$import_start_dir/onecx-data" ]]; then
  printf '  %b\n' "${YELLOW}Warning: $$import_start_dir/onecx-data not found${NC}"
  exit 0
fi

## File availability
ENV_FILE="$import_start_dir/versions/${OLE_EDITION}/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  printf '  %b\n' "${YELLOW}Warning: $ENV_FILE not found${NC}"
  exit 0
fi


#################################################################
## Secure Authentication enabled?
# Check option set by start script
if [[ -n "${3:-}" ]]; then
  if [[ "${3}" == "true" ]]; then
    OLE_SECURITY_AUTH_ENABLED=true
  else
    OLE_SECURITY_AUTH_ENABLED=false
  fi
elif [[ -f "$ENV_FILE" ]]; then
  OLE_SECURITY_AUTH_ENABLED=$(grep "^ONECX_SECURITY_AUTH_ENABLED=" "$ENV_FILE" | cut -d '=' -f2 )
else
  OLE_SECURITY_AUTH_ENABLED=false
fi
export OLE_SECURITY_AUTH_ENABLED

# translate for displaying only:
[[ "$OLE_SECURITY_AUTH_ENABLED" == "true" ]] && security_auth_used="yes" || security_auth_used="no"


#################################################################
## KEYCLOAK
kc_realm=$(grep "^KC_REALM=" "$ENV_FILE" | cut -d '=' -f2)
kc_base_url=$(grep "^KC_URL=" "$ENV_FILE" | cut -d '=' -f2)
kc_apm_client_id=$(grep "^KC_CLIENT_ID=" "$ENV_FILE" | cut -d '=' -f2)
kc_auth_client_id=$(grep "^ONECX_OIDC_CLIENT_CLIENT_ID=" "$ENV_FILE" | cut -d '=' -f2)
kc_auth_client_secret=$(grep "^ONECX_OIDC_CLIENT_S_E_C_R_E_T=" "$ENV_FILE" | cut -d '=' -f2)

# Check existence
declare -A required_vars=(
  [KC_REALM]=kc_realm
  [KC_URL]=kc_base_url
  [KC_CLIENT_ID]=kc_apm_client_id
  [ONECX_OIDC_CLIENT_CLIENT_ID]=kc_auth_client_id
  [ONECX_OIDC_CLIENT_S_E_C_R_E_T]=kc_auth_client_secret
)
for key in "${!required_vars[@]}"; do
  var="${required_vars[$key]}"
  if [[ -z "${!var:-}" ]]; then
    printf '  %b\n' "${RED}Could not read '$key' from $ENV_FILE${NC}"
    exit 1
  fi
done

# Identify user for tenants
case "${1:-}" in
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


#################################################################
#################################################################
## Display startup summary
printf '  %b\n' "edition: ${GREEN}${OLE_EDITION}${NC}, tenant: ${GREEN}${1:-}${NC}, type: ${GREEN}${IMPORT_TYPE}${NC}, user: ${GREEN}${KC_USER}${NC}, secure authentication: ${GREEN}${security_auth_used}${NC}"

## jq available?
command -v jq >/dev/null 2>&1 || \
  { printf '  %b\n' "${RED}jq is required but not installed${NC}"; exit 1; }


#################################################################
## If Secure Authentication is enabled then get tokens
unset OLE_HEADER_APM_TOKEN
unset OLE_HEADER_AUTH_TOKEN
if [[ "${OLE_SECURITY_AUTH_ENABLED}" == "true" ]]; then
  kc_token_url="${kc_base_url}/realms/${kc_realm}/protocol/openid-connect/token"
  printf '  %b\n' "${CYAN}Fetching tokens (APM, AUTH) from Keycloak (realm: ${kc_realm}, user: ${KC_USER})${NC}"

  ## Get APM (ID) token for user: User info, roles, scope: Organization_ID
  curl_params=(--silent -d "username=${KC_USER}" -d "password=${KC_PWD}" -d "grant_type=password" -d "scope=openid" -d "client_id=${kc_apm_client_id}")
  # Capture token, handle potential curl errors cleanly
  TOKEN_RES=$(curl "${curl_params[@]}" "$kc_token_url")
  id_token=$(printf '%s' "${TOKEN_RES}" | jq -r '.id_token // empty')
  if [[ -z "$id_token" ]]; then
    printf '  %b\n' "${RED}Failed to fetch APM token${NC}"
    exit 1
  fi
  printf '  %-9s%s%b\n' "==> APM" "token: " "${GREEN}${id_token:0:5}..${id_token:350:5}...${NC}  (KC client id: ${kc_apm_client_id})"
  export OLE_HEADER_APM_TOKEN="apm-principal-token: ${id_token}"

  ## Get AUTH (Bearer, access) token: scopes for SVCs
  curl_params=(--silent -d "client_secret=${kc_auth_client_secret}" -d "grant_type=client_credentials" -d "client_id=${kc_auth_client_id}")
  # Capture token, handle potential curl errors cleanly
  TOKEN_RES=$(curl "${curl_params[@]}" "$kc_token_url")
  access_token=$(printf '%s' "${TOKEN_RES}" | jq -r '.access_token // empty')
  if [[ -z "$access_token" ]]; then
    printf '  %b\n' "${RED}Failed to fetch AUTH token${NC}"
    exit 1
  fi
  printf '  %-9s%s%b\n' "==> AUTH" "token: " "${GREEN}${access_token:0:5}..${access_token:350:5}...${NC}  (KC client id: ${kc_auth_client_id})"
  export OLE_HEADER_AUTH_TOKEN="Authorization: Bearer ${access_token}"
fi


#################################################################
## IMPORT OneCX data
cd "$import_start_dir/onecx-data" || exit 1

if [[ "$IMPORT_TYPE" =~ ^(all|base|slot|product|ms|mfe)$ ]]; then
  pushd product-store > /dev/null
  if [[ "$IMPORT_TYPE" =~ ^(all|base|product)$ ]]; then
    bash ./import-products.sh "${1:-}" "${2:-}"
  fi
  if [[ "$IMPORT_TYPE" =~ ^(all|base|mfe)$ ]]; then
    bash ./import-microfrontends.sh "${1:-}" "${2:-}"
  fi
  if [[ "$IMPORT_TYPE" =~ ^(all|base|ms)$ ]]; then
    bash ./import-microservices.sh "${1:-}" "${2:-}"
  fi
  if [[ "$IMPORT_TYPE" =~ ^(all|base|slot)$ ]]; then
    bash ./import-slots.sh "${1:-}" "${2:-}"
  fi
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|parameter)$ ]]; then
  pushd parameter > /dev/null
  bash ./import-parameters.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|permission)$ ]]; then
  pushd permission > /dev/null
  bash ./import-permissions.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|assignment)$ ]]; then
  pushd permission-assignment > /dev/null
  bash ./import-assignments.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|tenant)$ ]]; then
  pushd tenant > /dev/null
  bash ./import-tenants.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|theme)$ ]]; then
  pushd theme > /dev/null
  bash ./import-themes.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(all|base|workspace)$ ]]; then
  pushd workspace > /dev/null
  bash ./import-workspaces.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(all|welcome)$ ]]; then
  pushd welcome > /dev/null
  bash ./import-welcome-images.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(all|bookmark)$ ]]; then
  pushd bookmark > /dev/null
  bash ./import-bookmarks.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi

if [[ "$IMPORT_TYPE" =~ ^(ai)$ ]]; then
  pushd ai > /dev/null
  bash ./import-ai-data.sh "${1:-}" "${2:-}"
  popd > /dev/null
fi
