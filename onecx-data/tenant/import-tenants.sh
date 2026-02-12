#!/usr/bin/env bash
#
# Import Tenants from file
#
# $1 => tenant
# $2 => verbose   (true|false)
#

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

printf '%b\n' "$OLE_LINE_PREFIX${CYAN}Importing Tenants via ExIm${NC}"

for entry in ./*.json
do
  url="http://onecx-tenant-svc/exim/v1/tenants/operator"
  params="--write-out %{http_code} --silent --output /dev/null -X POST"
  if [[ "$OLE_SECURITY_AUTH_ENABLED" == "true" ]]; then
    status_code=$(curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d "@$entry" "$url")
  else
    status_code=$(curl $params -H "$OLE_HEADER_CT_JSON" -d "@$entry" "$url")
  fi

  if [[ "$status_code" =~ (200|201)$  ]]; then
    if [[ "${2:-}" == "true" ]]; then
      printf '    %b\n' "status: ${GREEN}$status_code ${NC}"
    fi
  else
    printf '    %b\n' "${RED}status: $status_code${NC}"
  fi 
done