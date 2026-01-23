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

OLE_LINE_PREFIX="    - "

params="--write-out %{http_code} --silent -X POST"
api_key_file="../../api-key"

#################################################################
# files witch have tenant as prefix
kb_file="${1}_knowledgebase.json"
context_file="${1}_configuration.json"

SKIP_MSG=""
if [[ ! -f "$kb_file" ]]; then
  SKIP_MSG="==> ${RED} skipping${NC}: Knowledgebase file not found for tenant ${GREEN}${1}${NC}"
fi
if [[ ! -f "$context_file" ]]; then
  SKIP_MSG="==> ${RED} skipping${NC}: Configuration file not found for tenant ${GREEN}${1}${NC}"
fi


#################################################################
# Read API Key from file or prompt user
APIKEY_MSG=""
APIKEY_SOURCE=""
if [[ -z "$SKIP_MSG" ]]; then
  if [[ -f "$api_key_file" ]]; then
    apiKey=$(cat "$api_key_file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -n "$apiKey" ]]; then
      APIKEY_SOURCE="file"
    else
      printf "${YELLOW}  API Key file is empty${NC}\n"
    fi
  else
    APIKEY_MSG="==> API Key file not found"
  fi
fi

#################################################################
# Check and go ahead or skip
printf "${CYAN}  * Importing AI data${NC}\t${SKIP_MSG}${APIKEY_MSG}\n"

if [[ ! -z "$SKIP_MSG" ]]; then
  exit 0
fi

#################################################################
# Prompt user for API Key
if [[ -z "$apiKey" ]]; then
  printf "    Enter the API Key for the AI Provider (or leave empty to skip the import):\n"
  read -p "    > " apiKey
  APIKEY_SOURCE="user input"
fi

if [[ -z "$apiKey" ]]; then
  printf "${YELLOW}${OLE_LINE_PREFIX}Skipping import ==> no API Key provided${NC}\n"
  exit 0
fi
printf "${CYAN}${OLE_LINE_PREFIX}API Key read from: ${GREEN}${APIKEY_SOURCE}${NC}\n"


#################################################################
# Step 1: Import Knowledgebase and capture its ID
printf "${CYAN}${OLE_LINE_PREFIX}Importing Knowledgebase${NC}\n"
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
    printf "${GREEN}${OLE_LINE_PREFIX}Knowledgebase imported, status: %s, ID: %s${NC}\n" "$status_code" "$kbId"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}Failed to import Knowledgebase, status: %s${NC}\n" "$status_code"
  rm -f "$response_output" "$status_output"
  exit 1
fi
rm -f "$response_output" "$status_output"
# rm -f "$response_output" "$status_output"


#################################################################
# Step 2: Update Context with API Key and import it
printf "${CYAN}${OLE_LINE_PREFIX}Preparing Context with API Key${NC}\n"
if command -v jq &> /dev/null; then
  context_temp=$(mktemp)
  jq ".llmProvider.apiKey = \"$apiKey\"" "$context_file" > "$context_temp"
  if [[ $2 == "true" ]]; then
    printf "${GREEN}${OLE_LINE_PREFIX}Context prepared with API Key${NC}\n"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}jq not found, cannot update Context with API Key${NC}\n"
  exit 1
fi

#################################################################
# Step 3: Import Context (using temporary file)
printf "${CYAN}${OLE_LINE_PREFIX}Importing Context${NC}\n"
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
    printf "${GREEN}${OLE_LINE_PREFIX}Context imported, status: %s${NC}\n" "$status_code"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}Failed to import Context, status: %s${NC}\n" "$status_code"
  rm -f "$response_output" "$status_output" "$context_temp"
  exit 1
fi
rm -f "$response_output" "$status_output" "$context_temp"

if [[ $2 == "true" ]]; then
  printf "${GREEN}${OLE_LINE_PREFIX}All AI data imported successfully${NC}\n"
fi
