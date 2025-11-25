#!/bin/bash
#
# Activate/Deactivate local running Microfrontends into OneCX Local Enviroment
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

printf "${CYAN}Integrate Local Microfrontends into OneCX Local Enviroment${NC}\n"


#################################################################
## Defaults
TRAEFIK_ACTIVE_DIR="./init-data/traefik/active"
TRAEFIK_LOCAL_DIR="./init-data/traefik/inactive"
MFE_TEMPLATE_NAME="_mfe_template.yml"
MFE_TEMPLATE_PATH="$TRAEFIK_LOCAL_DIR/$MFE_TEMPLATE_NAME"
MFES=()
MODE=""
LINE_PREFIX="  * "
declare -A predefined_onecx_ports=(\
  ["announcement"]="5024" ["bookmark"]="5031" ["help"]="5023" ["iam"]="5029" \
  ["permission"]="5026" ["product-store"]="5021" \
  ["shell"]="5000" ["tenant"]="5022" ["theme"]="5020" \
  ["user-profile"]="5027" ["welcome"]="5028" ["workspace"]="5025")

#################################################################
## Usage
usage () {
  cat <<USAGE
  Usage: $0  [-ch]  [-a <mfe1:port> [<mfe2:port> ...]]  [-d <mfe1> [<mfe2> ...]]
       -a  activate one or more local Microfrontends, port is optional, default is 4200
           if the mfe is one of OneCX Core products then the default port is defined in ${TRAEFIK_LOCAL_DIR}
       -c  cleanup, restore original state
       -d  deactivate one or more local Microfrontends
       -h  display this help and exit
       -l  list of integrated local Microfrontends
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-ch]  [-a <mfe1:port> [<mfe2:port> ...]]  [-d <mfe1> [<mfe2> ...]]
USAGE
}


#################################################################
## Activate/Integrate a Microfrontend with name and port using template
activate_mfe() {
  local name="$1"
  local port="$2"
  local template="$MFE_TEMPLATE_PATH"
  local dst="${name}_${port}"
  local dstf="$TRAEFIK_ACTIVE_DIR/${dst}.yml"
  local path="\/mfe\/"

  if [[ -f "$dstf" ]]; then
    printf "${LINE_PREFIX}$dst  ${GREEN}already activated${NC}\n"
    return
  fi
  if [[ ! -f "$template" ]]; then
    printf " ⚠️ ${RED}template '${template}' not found${NC}\n"
    return
  fi

  sed \
    -e "s/{{MFE_NAME}}/${name}/g" \
    -e "s/{{MFE_PORT}}/${port}/g" \
    -e "s/{{MFE_PATH}}/${path}${name}/g" \
    "$template" > "$dstf"
  printf "${LINE_PREFIX}${dst}\t✔\n"
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
    printf "${LINE_PREFIX}${name}\t✔\n"
  elif [[ -f "$dst2" ]]; then
    rm "$dst2"
    printf "${LINE_PREFIX}${name}:${port}\t✔\n"
  else
    printf "${LINE_PREFIX}${name}\t⚠️ ${RED}not activated${NC}\n"
  fi
}

#################################################################
## Disable all Microfrontends
clean_all() {
  printf " 🧹 Cleaning all local Microfrontend activations\n"
  find "$TRAEFIK_ACTIVE_DIR" -maxdepth 1 -type f -exec rm {} \;
  printf "    All local Microfrontends deactivated\n"
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
        -l)
            MODE="list"
            shift
            ;;
        *)
            printf "${RED}  Unknown shorthand flag: ${GREEN}$1${NC}\n"
            usage
            exit 1
            ;;
    esac
done


#################################################################
## Execute: activate/create/deactivate
if [[ "$MODE" == "activate" || "$MODE" == "deactivate" ]]; then
  if [[ ${#MFES[@]} -eq 0 ]]; then
    printf "${RED}  No Microfrontends specified for ${MODE}${NC}\n"
    usage
    exit 1
  fi
  ###
  if [[ "$MODE" == "activate" ]]; then
    printf " ➕ Activate local Microfrontends\n"
  else
    printf " ➖ Deactivate local Microfrontends\n"
    printf "    Check Traefik configurations in ${TRAEFIK_ACTIVE_DIR}\n"
  fi
  ###
  for mfe in "${MFES[@]}"; do
    IFS=:
    set $mfe   # split by IFS separator to $1...$n
    name=$1
    port=$2
    if [[ -z $port ]]; then  # no port
      if [[ "$name" =~ ^(announcement|help|parameter|permission|product-store|tenant|theme|shell|user-profile|welcome|workspace) ]]; then
        port="${predefined_onecx_ports[$name]}"  # get predefined port
      fi
      if [[ -z $port ]]; then  # no port
        port=4200
      fi
    fi
    if [[ "$MODE" == "activate" ]]; then
      activate_mfe "$name" "$port"
    else
      deactivate_mfe "$name" "$port"
    fi
  done
  exit 0
fi

#################################################################
## Execute: cleaning
if [[ "$MODE" == "clean" ]]; then
  clean_all
  exit 0
fi

#################################################################
## List: all integrated local Microfrontends
if [[ "$MODE" == "list" ]]; then
  mfe_files=`ls $TRAEFIK_ACTIVE_DIR/*.yml  2>/dev/null`
  if [[ $mfe_files == "" ]]; then
    printf " ❌ no active Microfrontends\n"
    exit 0
  fi
  ###
  printf " ✔  Traefik configurations located in ${TRAEFIK_ACTIVE_DIR}\n"
  for mfe in $mfe_files; do
    IFS=/
    set $mfe
    name=`echo $5 | cut -d '.' -f 1`
    printf "${LINE_PREFIX}${name}\n"
  done
  exit 0
fi


usage
exit 1
