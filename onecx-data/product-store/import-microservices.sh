#!/usr/bin/env bash
#
# Import Microservices from file for Product and App
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
# files 
files=$(ls ./microservices/*.json 2>/dev/null) || true
SKIP_MSG=""
if [[ -z "$files" ]]; then
  SKIP_MSG=" ==>${YELLOW} skipping${NC}: no files found"
fi

printf '%b\n' "$OLE_LINE_PREFIX${CYAN}Importing Microservices in Product Store via Operator${NC}\t$SKIP_MSG"


#################################################################
# operate on found files
for entry in $files
do
  filename=$(basename "$entry")
  filename=$(printf '%s' "$filename" | cut -d '.' -f 1)
  product=$(printf '%s' "$filename" | cut -d '_' -f 1)
  appid=$(printf '%s' "$filename" | cut -d '_' -f 2)
  
  url="http://onecx-product-store-svc/operator/ms/v1/$product/$appid"
  params="--write-out %{http_code} --silent --output /dev/null -X PUT"
  if [[ "$OLE_SECURITY_AUTH_ENABLED" == "true" ]]; then
    status_code=$(curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d "@$entry" "$url")
  else
    status_code=$(curl $params -H "$OLE_HEADER_CT_JSON" -d "@$entry" "$url")
  fi

  if [[ "$status_code" =~ (200|201)$  ]]; then
    if [[ "${2:-}" == "true" ]]; then
      printf '    %b\n' "status: ${GREEN}$status_code${NC}, product: $product, ms: $appid"
    fi
  else
    printf '    %b\n' "${RED}status: $status_code, product: $product, ms: $appid ${NC}"
  fi
done
