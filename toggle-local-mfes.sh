#!/bin/bash
#
# Activate/Deactivate local running Microfrontends into OneCX Local Enviroment
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

printf "${CYAN}Integrate Local Microfrontends into OneCX Local Enviroment${NC}\n"


#################################################################
## Defaults
TRAEFIK_ACTIVE_DIR="./init-data/traefik/active"
TRAEFIK_LOCAL_DIR="./init-data/traefik/inactive"
MFES=()
MODE=""
LINE_PREFIX="  * "


#################################################################
## Usage
usage () {
  cat <<USAGE
  Usage: $0  [-ch]  [-a <mfe1> [<mfe2> ...]]  [-d <mfe1> [<mfe2> ...]]
       -a  activate one or more local Microfrontends, see configurations in ${TRAEFIK_LOCAL_DIR}
       -c  cleanup, restore original state
       -d  deactivate one or more local Microfrontends, see configurations in ${TRAEFIK_LOCAL_DIR}
       -h  display this help and exit
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-ch]  [-a <mfe1> [<mfe2> ...]]  [-d <mfe1> [<mfe2> ...]]
USAGE
}


#################################################################
## Enable a given Microfrontend
activate_mfe() {
  local mfe="$1"
  local src="$TRAEFIK_LOCAL_DIR/$mfe.yml"
  local dst="$TRAEFIK_ACTIVE_DIR/$mfe.yml"

  if [[ ! -f "$src" ]]; then
    printf "${LINE_PREFIX}$mfe ⚠️ ${RED}configuration not found${NC}\n"
    return
  fi

  if [[ -f "$dst" ]]; then
    printf "${LINE_PREFIX}$mfe  ${GREEN}already activated${NC}\n"
    return
  fi

  # ln -s "$src" "$dst"
  cp "$src" "$dst"
  printf "${LINE_PREFIX}$mfe\n"
}

#################################################################
## Deactivate a given Microfrontend
deactivate_mfe() {
  local mfe="$1"
  local dst="$TRAEFIK_ACTIVE_DIR/$mfe.yml"

  if [[ -f "$dst" ]]; then
    rm "$dst"
    printf "${LINE_PREFIX}$mfe\n"
  else
    printf "${LINE_PREFIX}$mfe ⚠️ ${RED}not activated${NC}\n"
  fi
}

#################################################################
## Disable all Microfrontends
clean_all() {
  printf "  🧹 Cleaning all local Microfrontend activations\n"
  find "$TRAEFIK_ACTIVE_DIR" -maxdepth 1 -type f -exec rm {} \;
  printf "     All local Microfrontends deactivated\n"
}


#################################################################
## Check flags and parameter
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -a)
            MODE="activate"
            shift
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                MFES+=("$1")
                shift
            done
            ;;
        -c)
            MODE="clean"
            shift
            ;;
        -d)
            MODE="deactivate"
            shift
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                MFES+=("$1")
                shift
            done
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf "${RED}  Unknown shorthand flag: ${GREEN}$1${NC}\n"
            usage
            exit 1
            ;;
    esac
done


#################################################################
## Execute: activate/deactivate
if [[ "$MODE" == "activate" || "$MODE" == "deactivate" ]]; then
  if [[ ${#MFES[@]} -eq 0 ]]; then
    printf "${RED}  No Microfrontends specified for ${MODE}${NC}\n"
    usage
    exit 1
  fi
  if [[ "$MODE" == "activate" ]]; then
    printf " ➕ Activate local Microfrontends\n"
    printf "    Traefik configurations located in ${TRAEFIK_LOCAL_DIR}\n"
    for mfe in "${MFES[@]}"; do
      activate_mfe "$mfe"
    done
  else
    printf " ❌ Deactivate local Microfrontends\n"
    printf "    Traefik configurations located in ${TRAEFIK_ACTIVE_DIR}\n"
    for mfe in "${MFES[@]}"; do
      deactivate_mfe "$mfe"
    done
  fi
  exit 0
fi

#################################################################
## Execute: cleaning
if [[ "$MODE" == "clean" ]]; then
    clean_all
    exit 0
fi

usage
exit 1
