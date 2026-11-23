#!/usr/bin/env bash
#
# Import the Voice Mock Agent (Provider, Model, Agent) for onecx-pipecat.
# onecx-pipecat runs with in-memory speech and LLM, so no AI model is connected:
# the provider and model only satisfy the agent configuration it requires.
#
# The import is skipped if an agent with the same name already exists.
#
# $1 => tenant
# $2 => verbose   (true|false)
#

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

readonly BASE_URL="http://onecx-ai-provider-svc/internal"


#################################################################
# files which have the tenant as prefix
provider_file="${1:-default}_voice_provider.json"
model_file="${1:-default}_voice_model.json"
agent_file="${1:-default}_voice_agent.json"

SKIP_MSG=""
for file in "$provider_file" "$model_file" "$agent_file"; do
  if [[ ! -f "$file" ]]; then
    SKIP_MSG=" ==>${RED} skipping${NC}: $file not found"
  fi
done

printf '%b\n' "${OLE_LINE_PREFIX:-  * }${CYAN}Importing Voice Mock Agent${NC}\t$SKIP_MSG"
if [[ -n "$SKIP_MSG" ]]; then
  exit 0
fi


VERBOSE="${2:-false}"
tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT


#################################################################
# HTTP helper: POST a JSON file, set $status_code and $response
headers=(-H "${OLE_HEADER_CT_JSON:-Content-Type: application/json}")
if [[ "${OLE_SECURITY_AUTH_ENABLED:-false}" == "true" ]]; then
  headers+=(-H "$OLE_HEADER_AUTH_TOKEN" -H "$OLE_HEADER_APM_TOKEN")
fi

post_json() {
  local result
  result=$(curl --silent --write-out '\n%{http_code}' -X POST "${headers[@]}" -d "@$2" "$1") || true
  status_code=${result##*$'\n'}
  response=${result%$'\n'*}
}

# Import one item, exit on failure; $1 => label, $2 => path, $3 => JSON file
import_item() {
  post_json "$BASE_URL/$2" "$3"
  if [[ ! "$status_code" =~ ^(200|201)$ ]]; then
    printf '    %b\n' "${RED}status: $status_code, failed to import $1${NC}"
    exit 1
  fi
  if [[ "$VERBOSE" == "true" ]]; then
    printf '    %b\n' "status: ${GREEN}$status_code${NC}, $1: $(printf '%s' "$response" | jq -r '.id // empty')"
  fi
}


#################################################################
# Skip if the agent exists already
agent_name=$(jq -r '.name' "$agent_file")
jq -n --arg name "$agent_name" '{name: $name, pageNumber: 0, pageSize: 100}' > "$tmp_file"
post_json "$BASE_URL/agents/search" "$tmp_file"
if [[ "$status_code" == "200" ]] \
  && [[ "$(printf '%s' "$response" | jq --arg name "$agent_name" '[.stream[]? | select(.name == $name)] | length')" != "0" ]]; then
  printf '    %b\n' "${GREEN}Agent '$agent_name' exists, skipping${NC}"
  exit 0
fi


#################################################################
# Provider => Model (linked to Provider) => Agent (linked to Model)
import_item "provider" "providers" "$provider_file"

jq --argjson provider "$response" '.provider = $provider' "$model_file" > "$tmp_file"
import_item "model" "models" "$tmp_file"

jq --argjson model "$response" '.model = $model' "$agent_file" > "$tmp_file"
import_item "agent" "agents" "$tmp_file"

printf '    %b\n' "${GREEN}Agent '$agent_name' imported${NC}"
