#!/usr/bin/env bash
#
# Import Permission Assignments from file for Tenant and Product
#
# A file contains the assignment of permissions (defined by product/app)
# to roles
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


#################################################################
# files (tenant independent)
files=$(ls ./*.json 2>/dev/null) || true
SKIP_MSG=""
if [[ -z "$files" ]]; then
  SKIP_MSG=" ==>${RED} skipping${NC}: no files found"
fi

printf '%b\n' "$OLE_LINE_PREFIX${CYAN}Importing Permission Assignments via ExIm${NC}\t$SKIP_MSG"


#################################################################
# operate on found files
for entry in $files
do
  filename=$(basename "$entry")
  product=$(printf '%s' "$filename" | cut -d '.' -f 1)
  
  url="http://onecx-permission-svc/exim/v1/assignments/operator"
  params="--write-out %{http_code} --silent --output /dev/null -X POST"
  if [[ "$OLE_SECURITY_AUTH_ENABLED" == "true" ]]; then
    status_code=$(curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d "@$entry" "$url")
  else
    status_code=$(curl $params -H "$OLE_HEADER_CT_JSON" -d "@$entry" "$url")
  fi

  if [[ "$status_code" =~ (200|201)$  ]]; then
    if [[ "${2:-}" == "true" ]]; then
      printf '    %b\n' "status: ${GREEN}$status_code${NC}, product: $product"
    fi
  else
    printf '    %b\n' "${RED}status: $status_code, product: $product ${NC}"
  fi
done
