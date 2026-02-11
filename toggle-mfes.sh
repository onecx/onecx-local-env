#!/usr/bin/env bash
#
# Integrating local running Microfrontends into OneCX Local Environment
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

printf '%b\n' "${CYAN}Integrate Local Microfrontends into OneCX Local Environment${NC}"

#################################################################
## Script directory detection, change to it to ensure relative path works
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


#################################################################
## Defaults
ANGULAR_DEFAULT_PORT="4200"
TRAEFIK_ACTIVE_DIR="./init-data/traefik/active"
TRAEFIK_LOCAL_DIR="./init-data/traefik/inactive"
MFE_TEMPLATE_NAME="_mfe_template.yml"
MFE_TEMPLATE_PATH="$TRAEFIK_LOCAL_DIR/$MFE_TEMPLATE_NAME"
MFE_COUNT=0
MFES=()
MODE=""
LINE_PREFIX="   * "
onecx_products="announcement|bookmark|help|iam|parameter|permission|product-store|tenant|theme|shell|user-profile|welcome|workspace"
declare -A onecx_products_predefined_ports=( \
  ["announcement"]="5024" ["bookmark"]="5031" ["help"]="5023" ["iam"]="5029" \
  ["parameter"]="5030" ["permission"]="5026" ["product-store"]="5021" \
  ["shell"]="5000" ["tenant"]="5022" ["theme"]="5020" \
  ["user-profile"]="5027" ["welcome"]="5028" ["workspace"]="5025")

#################################################################
## Usage
usage () {
  local exit_code=${1:-0}
  printf '  %b\n' \
  "Usage: $0  [-chl]  [-a <mfe1:port1:path1> [<mfe2:port2:path2> ...]]  [-d <mfe1:port1> [<mfe2:port2> ...]]
        ${CYAN}All options may only be used separately!${NC}
    -a  Activate one or more local Microfrontends, port is optional, default is 4200
        If the mfe is one of OneCX Core products and no port is specified then predefined ports are used.
    -c  Cleanup, remove all, restore original state
    -d  Deactivate one or more local Microfrontends
    -h  Display this help and exit
    -l  List of currently integrated local microfrontends
  Examples:
    $0  -a workspace  user-profile:12345   => Enable workspace on standard port and user-profile with port 12345
    $0  -a my-app::/my-app-path            => Enable my-app with port 4200 and path /my-app-path
    $0  -a my-app:4567:/my-app-path        => Enable my-app with port 4567 and path /my-app-path
    $0  -l                                 => List all local microfrontends that are enabled
    $0  -c                                 => Remove all local microfrontends that are enabled
"
  exit "$exit_code"
}


#################################################################
## Activate/Integrate a Microfrontend with name and port using template
activate_mfe() {
  local name="$1"
  local port="$2"
  local path="$3"
  local strippath="$4"
  local template="$MFE_TEMPLATE_PATH"
  local dst="${name}_${port}"
  local dstf="$TRAEFIK_ACTIVE_DIR/${dst}.yml"
  local mfe_path="/mfe/${name}" # onecx standard path

  if [[ -f "$dstf" ]]; then
    printf '%b\n' "${LINE_PREFIX}$dst  ${YELLOW}already activated${NC}"
    return
  fi
  if [[ ! -f "$template" ]]; then
    printf ' %b\n' "⚠️ ${RED}template '${template}' not found${NC}"
    exit 1
  fi
  if [[ -n "$path" ]]; then
    mfe_path="$path"
  fi
  if [[ -z "$strippath" ]]; then # no strip path = normal case: same path
    strippath="$mfe_path"
  fi
  if [[ ${mfe_path: -1} != "/" ]]; then  # add slash if not already present
    mfe_path="${mfe_path}/"
  fi

  # replace variables and copy to target, don't use '/' as delimiter
  sed \
    -e "s|{{MFE_NAME}}|${name}|g" \
    -e "s|{{MFE_PORT}}|${port}|g" \
    -e "s|{{MFE_PATH}}|${mfe_path}|g" \
    -e "s|{{MFE_STRIPPATH}}|${strippath}|g" \
    "$template" > "$dstf"
  printf '%b\t%-10b%s\n' "${LINE_PREFIX}${GREEN}${dst}${NC}" "✔" "mapping: ${mfe_path} => localhost:${port}"
}

#################################################################
## Deactivate a Microfrontend with name and optional port
deactivate_mfe() {
  local name="$1"
  local port="$2"
  local dst1="$TRAEFIK_ACTIVE_DIR/${name}.yml"
  local dst2="$TRAEFIK_ACTIVE_DIR/${name}_${port}.yml"

  if [[ -f "$dst1" ]]; then
    rm "$dst1"
    printf '%b%-20b %s\n' "${LINE_PREFIX}" "${GREEN}${name}${NC}" "✔"
  elif [[ -f "$dst2" ]]; then
    rm "$dst2"
    printf '%b%-20b %s\n' "${LINE_PREFIX}" "${GREEN}${name}:${port}${NC}" "✔"
  else
    printf '%b%-20b %b\n' "${LINE_PREFIX}" "${name}" "⚠️ ${RED}not activated${NC}"

  fi
}

#################################################################
## Count integrated Microfrontends, returns count
count_mfes() {
  find "$TRAEFIK_ACTIVE_DIR" -name "*.yml" -type f 2>/dev/null | wc -l | tr -d '[:space:]' || echo 0
}

#################################################################
## Disable all Microfrontends
clean_all() {
  list_all
  if [[ "$MFE_COUNT" -eq 0 ]]; then
    printf '     %b\n' "${YELLOW}Nothing to clean${NC}"
    return 0
  fi
  printf '  %b\n' "🧹 Cleaning ${GREEN}$MFE_COUNT${NC} local Microfrontend activation(s)"
  find "$TRAEFIK_ACTIVE_DIR" -name "*.yml" -type f -delete 2>/dev/null
  printf '     %b\n' "${CYAN}All local Microfrontends deactivated${NC}"
}

#################################################################
## List all Microfrontends
list_all() {
  local name mfe_files
  MFE_COUNT=$(count_mfes)
  if [[ "$MFE_COUNT" -eq 0 ]]; then
    printf '  %b\n' "❌ No integrated Microfrontends found in ${TRAEFIK_ACTIVE_DIR}"
  else
    printf '  %b\n' "✔  Traefik configurations located in ${TRAEFIK_ACTIVE_DIR}"
    mfe_files=$(find "$TRAEFIK_ACTIVE_DIR" -name "*.yml" -type f 2>/dev/null)
    while read -r mfe; do
      [[ -z "$mfe" ]] && continue
      name=$(basename "$mfe" .yml)
      printf '%b\n' "${LINE_PREFIX}${GREEN}${name}${NC}"
    done <<< "$mfe_files"
  fi
}


#################################################################
## Check options and parameter
while [[ "$#" -gt 0 ]]; do
  if [[ -n "$MODE" ]]; then
    printf '  %b\n' "${RED}Multiple options have been used. Please choose only one.${NC}"
    usage 1
  fi
  case "$1" in
    -a) MODE="activate"
        shift
        while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
          MFES+=("$1")
          shift
        done
        ;;
    -c) MODE="clean"
        shift
        ;;
    -d) MODE="deactivate"
        shift
        while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
          MFES+=("$1")
          shift
        done
        ;;
    -h|--help)
        usage 0
        ;;
    -l) MODE="list"
        shift
        ;;
    * ) printf '  %b\n' "${RED}Unknown shorthand option: ${GREEN}$1${NC}"
        usage 1
        ;;
  esac
done

if [[ -z "$MODE" ]]; then
  usage 0
fi

#################################################################
## Execute: activate/create/deactivate
if [[ "$MODE" == "activate" || "$MODE" == "deactivate" ]]; then
  if [[ ${#MFES[@]} -eq 0 ]]; then
    printf '  %b\n' "${RED}No Microfrontends specified for ${MODE}${NC}"
    usage 1
  fi
  ###
  if [[ "$MODE" == "activate" ]]; then
    printf '  %b\n' "➕ Integrate local Microfrontends"
  else
    printf '  %b\n' "➖ Deintegrate local Microfrontends"
    printf '  %b\n' "   ${CYAN}Check Traefik configurations in ${GREEN}${TRAEFIK_ACTIVE_DIR}${NC}"
  fi
  ###
  for mfe in "${MFES[@]}"; do
    IFS=: read -r name port path strippath <<< "$mfe"
    if [[ -z "$port" ]]; then  # no port
      if [[ "$name" =~ ^($onecx_products)$ ]]; then
        port="${onecx_products_predefined_ports[$name]}"  # get predefined port
      fi
      if [[ -z "$port" ]]; then  # no port => use Angular default
        port="${ANGULAR_DEFAULT_PORT}"
      fi
    fi
    if [[ "$MODE" == "activate" ]]; then
      activate_mfe "$name" "$port" "$path" "$strippath"
    else
      deactivate_mfe "$name" "$port"
    fi
  done
fi


#################################################################
## Execute: clean/list
case "$MODE" in
  clean) clean_all ;;
  list) list_all ;;
esac

printf '\n'
