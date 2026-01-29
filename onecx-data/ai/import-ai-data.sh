#!/bin/bash
#
# Import AI Data (Providers, MCP Servers, Configurations) from files
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
provider_file="${1}_provider.json"
mcp_server_file="${1}_mcp-server.json"
configuration_file="${1}_configuration.json"

SKIP_MSG=""
if [[ ! -f "$provider_file" ]]; then
  SKIP_MSG="==> ${RED} skipping${NC}: Provider file not found for tenant ${GREEN}${1}${NC}"
fi
if [[ ! -f "$mcp_server_file" ]]; then
  SKIP_MSG="==> ${RED} skipping${NC}: MCP Server file not found for tenant ${GREEN}${1}${NC}"
fi
if [[ ! -f "$configuration_file" ]]; then
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
# Step 1: Import Provider and capture its response
printf "${CYAN}${OLE_LINE_PREFIX}Importing Provider${NC}\n"
url="http://onecx-ai-svc/internal/providers"
response_output=$(mktemp)
status_output=$(mktemp)

# Prepare provider file with API Key
provider_temp=$(mktemp)
if command -v jq &> /dev/null; then
  jq ".apiKey = \"$apiKey\"" "$provider_file" > "$provider_temp"
else
  printf "${RED}${OLE_LINE_PREFIX}jq not found, cannot update Provider with API Key${NC}\n"
  exit 1
fi

if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d @"$provider_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
else
  curl $params -H "$OLE_HEADER_CT_JSON" -d @"$provider_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
fi
status_code=$(cat "$status_output")
provider_response=$(cat "$response_output")
providerId=$(echo "$provider_response" | jq -r '.id // empty')

if [[ "$status_code" =~ (200|201)$ ]]; then
  if [[ $2 == "true" ]]; then
    printf "${GREEN}${OLE_LINE_PREFIX}Provider imported, status: %s, ID: %s${NC}\n" "$status_code" "$providerId"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}Failed to import Provider, status: %s${NC}\n" "$status_code"
  rm -f "$response_output" "$status_output" "$provider_temp"
  exit 1
fi
rm -f "$provider_temp" "$response_output" "$status_output"


#################################################################
# Step 2: Import MCP Server and capture its response
printf "${CYAN}${OLE_LINE_PREFIX}Importing MCP Server${NC}\n"
url="http://onecx-ai-svc/internal/mcpServer"
response_output=$(mktemp)
status_output=$(mktemp)
if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d @"$mcp_server_file" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
else
  curl $params -H "$OLE_HEADER_CT_JSON" -d @"$mcp_server_file" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
fi
status_code=$(cat "$status_output")
mcp_response=$(cat "$response_output")
mcpServerId=$(echo "$mcp_response" | jq -r '.id // empty')

if [[ "$status_code" =~ (200|201)$ ]]; then
  if [[ $2 == "true" ]]; then
    printf "${GREEN}${OLE_LINE_PREFIX}MCP Server imported, status: %s, ID: %s${NC}\n" "$status_code" "$mcpServerId"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}Failed to import MCP Server, status: %s${NC}\n" "$status_code"
  rm -f "$response_output" "$status_output"
  exit 1
fi
rm -f "$response_output" "$status_output"


#################################################################
# Step 3: Prepare Configuration with Provider and MCP Server responses
printf "${CYAN}${OLE_LINE_PREFIX}Preparing Configuration with imported Provider and MCP Server${NC}\n"
configuration_temp=$(mktemp)
if command -v jq &> /dev/null; then
  jq ".llmProvider = $provider_response | .mcpServers = [$mcp_response]" "$configuration_file" > "$configuration_temp"
  if [[ $2 == "true" ]]; then
    printf "${GREEN}${OLE_LINE_PREFIX}Configuration prepared with Provider and MCP Server${NC}\n"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}jq not found, cannot update Configuration${NC}\n"
  exit 1
fi

#################################################################
# Step 4: Import Configuration
printf "${CYAN}${OLE_LINE_PREFIX}Importing Configuration${NC}\n"
url="http://onecx-ai-svc/internal/configurations"
response_output=$(mktemp)
status_output=$(mktemp)
if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d @"$configuration_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
else
  curl $params -H "$OLE_HEADER_CT_JSON" -d @"$configuration_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
fi
status_code=$(cat "$status_output")

if [[ "$status_code" =~ (200|201)$ ]]; then
  if [[ $2 == "true" ]]; then
    printf "${GREEN}${OLE_LINE_PREFIX}Configuration imported, status: %s${NC}\n" "$status_code"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}Failed to import Configuration, status: %s${NC}\n" "$status_code"
  rm -f "$response_output" "$status_output" "$configuration_temp"
  exit 1
fi
rm -f "$response_output" "$status_output" "$configuration_temp"

if [[ $2 == "true" ]]; then
  printf "${GREEN}${OLE_LINE_PREFIX}All AI data imported successfully${NC}\n"
fi
