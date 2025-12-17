#!/bin/bash
#
# Import AI Data (Knowledgebase, Providers, Contexts) from files
#
# $1 => tenant
# $2 => verbose   (true|false)
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

params="--write-out %{http_code} --silent -X POST"

#################################################################
# Prompt for API Key
echo -e "${YELLOW}=================================${NC}"
echo -e "${CYAN}AI Data Import - API Key Configuration${NC}"
echo -e "${YELLOW}=================================${NC}"
echo -e "\nEnter the API Key for the Provider (or leave empty to skip the import):"
read -p "> " apiKey

if [[ -z "$apiKey" ]]; then
  echo -e "${YELLOW}Skipping import - no API Key provided${NC}"
  exit 0
fi
echo -e "${GREEN}API Key configured${NC}\n"

#################################################################
# files witch have tenant as prefix
kb_file="${1}_knowledgebase.json"
context_file="${1}_context.json"

SKIP_MSG=""
if [[ ! -f "$kb_file" || ! -f "$context_file" ]]; then
  SKIP_MSG=" ==>${RED} skipping${NC}: not all required files found"
fi

echo -e "$OLE_LINE_PREFIX${CYAN}Importing AI data${NC}\t$SKIP_MSG"

if [[ ! -z "$SKIP_MSG" ]]; then
  exit 0
fi

#################################################################
# Step 1: Import Knowledgebase and capture its ID
echo -e "    ${CYAN}Step 1: Importing Knowledgebase${NC}"
url="http://onecx-ai-svc/internal/ai/ai-knowledgebases"
response_output=$(mktemp)
status_output=$(mktemp)
if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d @"$kb_file" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
else
  curl $params -H "$OLE_HEADER_CT_JSON" -d @"$kb_file" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
fi
status_code=$(cat "$status_output")
response_body=$(cat "$response_output")
kbId=$(echo "$response_body" | jq -r '.id // empty')

if [[ "$status_code" =~ (200|201)$ ]]; then
  if [[ $2 == "true" ]]; then
    echo -e "    ${GREEN}Knowledgebase imported, status: $status_code, ID: $kbId${NC}"
  fi
else
  echo -e "    ${RED}Failed to import Knowledgebase, status: $status_code${NC}"
  rm -f "$response_output" "$status_output"
  exit 1
fi
rm -f "$response_output" "$status_output"

rm -f "$response_output" "$status_output"

#################################################################
# Step 2: Update Context with API Key and import it
echo -e "    ${CYAN}Step 2: Preparing Context with API Key${NC}"
if command -v jq &> /dev/null; then
  context_temp=$(mktemp)
  jq ".llmProvider.apiKey = \"$apiKey\"" "$context_file" > "$context_temp"
  if [[ $2 == "true" ]]; then
    echo -e "    ${GREEN}Context prepared with API Key${NC}"
  fi
else
  echo -e "    ${RED}jq not found, cannot update Context with API Key${NC}"
  exit 1
fi

#################################################################
# Step 3: Import Context (using temporary file)
echo -e "    ${CYAN}Step 3: Importing Context${NC}"
url="http://onecx-ai-svc/internal/ai/ai-knowledgebases/${kbId}/ai-contexts"
response_output=$(mktemp)
status_output=$(mktemp)
if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d @"$context_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
else
  curl $params -H "$OLE_HEADER_CT_JSON" -d @"$context_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
fi
status_code=$(cat "$status_output")

if [[ "$status_code" =~ (200|201)$ ]]; then
  if [[ $2 == "true" ]]; then
    echo -e "    ${GREEN}Context imported, status: $status_code${NC}"
  fi
else
  echo -e "    ${RED}Failed to import Context, status: $status_code${NC}"
  rm -f "$response_output" "$status_output" "$context_temp"
  exit 1
fi
rm -f "$response_output" "$status_output" "$context_temp"

if [[ $2 == "true" ]]; then
  echo -e "    ${GREEN}All AI data imported successfully${NC}"
fi
