#!/bin/bash
#
# Import AI Data (Provider, Model, Tool, Agent) from files
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
model_file="${1}_model.json"
tool_file="${1}_tool.json"
agent_file="${1}_agent.json"

SKIP_MSG=""
if [[ ! -f "$provider_file" ]]; then
  SKIP_MSG="==> ${RED} skipping${NC}: Provider file not found for tenant ${GREEN}${1}${NC}"
fi
if [[ ! -f "$model_file" ]]; then
  SKIP_MSG="==> ${RED} skipping${NC}: Model file not found for tenant ${GREEN}${1}${NC}"
fi
if [[ ! -f "$tool_file" ]]; then
  SKIP_MSG="==> ${RED} skipping${NC}: Tool file not found for tenant ${GREEN}${1}${NC}"
fi
if [[ ! -f "$agent_file" ]]; then
  SKIP_MSG="==> ${RED} skipping${NC}: Agent file not found for tenant ${GREEN}${1}${NC}"
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
url="http://onecx-ai-provider-svc/internal/providers"
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
# Step 2: Import Model, linked to the imported Provider
printf "${CYAN}${OLE_LINE_PREFIX}Importing Model${NC}\n"
url="http://onecx-ai-provider-svc/internal/models"
response_output=$(mktemp)
status_output=$(mktemp)

model_temp=$(mktemp)
jq ".provider = $provider_response" "$model_file" > "$model_temp"

if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d @"$model_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
else
  curl $params -H "$OLE_HEADER_CT_JSON" -d @"$model_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
fi
status_code=$(cat "$status_output")
model_response=$(cat "$response_output")
modelId=$(echo "$model_response" | jq -r '.id // empty')

if [[ "$status_code" =~ (200|201)$ ]]; then
  if [[ $2 == "true" ]]; then
    printf "${GREEN}${OLE_LINE_PREFIX}Model imported, status: %s, ID: %s${NC}\n" "$status_code" "$modelId"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}Failed to import Model, status: %s${NC}\n" "$status_code"
  rm -f "$response_output" "$status_output" "$model_temp"
  exit 1
fi
rm -f "$model_temp" "$response_output" "$status_output"


#################################################################
# Step 3: Import Tool and capture its response
printf "${CYAN}${OLE_LINE_PREFIX}Importing Tool${NC}\n"
url="http://onecx-ai-provider-svc/internal/tools"
response_output=$(mktemp)
status_output=$(mktemp)

if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d @"$tool_file" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
else
  curl $params -H "$OLE_HEADER_CT_JSON" -d @"$tool_file" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
fi
status_code=$(cat "$status_output")
tool_response=$(cat "$response_output")
toolId=$(echo "$tool_response" | jq -r '.id // empty')

if [[ "$status_code" =~ (200|201)$ ]]; then
  if [[ $2 == "true" ]]; then
    printf "${GREEN}${OLE_LINE_PREFIX}Tool imported, status: %s, ID: %s${NC}\n" "$status_code" "$toolId"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}Failed to import Tool, status: %s${NC}\n" "$status_code"
  rm -f "$response_output" "$status_output"
  exit 1
fi
rm -f "$response_output" "$status_output"


#################################################################
# Step 4: Import Agent, linked to the imported Model and Tool
printf "${CYAN}${OLE_LINE_PREFIX}Importing Agent${NC}\n"
url="http://onecx-ai-provider-svc/internal/agents"
response_output=$(mktemp)
status_output=$(mktemp)

agent_temp=$(mktemp)
jq ".model = $model_response | .tools = [$tool_response]" "$agent_file" > "$agent_temp"

if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
  curl $params -H "$OLE_HEADER_CT_JSON" -H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN" -d @"$agent_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
else
  curl $params -H "$OLE_HEADER_CT_JSON" -d @"$agent_temp" -w "%{http_code}" -o "$response_output" "$url" > "$status_output" 2>&1
fi
status_code=$(cat "$status_output")
agent_response=$(cat "$response_output")
agentId=$(echo "$agent_response" | jq -r '.id // empty')

if [[ "$status_code" =~ (200|201)$ ]]; then
  if [[ $2 == "true" ]]; then
    printf "${GREEN}${OLE_LINE_PREFIX}Agent imported, status: %s, ID: %s${NC}\n" "$status_code" "$agentId"
  fi
else
  printf "${RED}${OLE_LINE_PREFIX}Failed to import Agent, status: %s${NC}\n" "$status_code"
  rm -f "$response_output" "$status_output" "$agent_temp"
  exit 1
fi
rm -f "$agent_temp" "$response_output" "$status_output"

if [[ $2 == "true" ]]; then
  printf "${GREEN}${OLE_LINE_PREFIX}All AI data imported successfully${NC}\n"
fi
