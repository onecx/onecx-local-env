#!/usr/bin/env bash
#
# Stop OneCX Local Environment with options
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

printf '%b\n' "${CYAN}Stopping OneCX Local Environment${NC}"

#################################################################
## Script directory detection, change to it to ensure relative path works
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


#################################################################
## Usage
usage () {
  local exit_code=${1:-0}
  cat <<USAGE
  Usage: $0  [-ch] [-e <edition>] [-p <profile>]
    -c  Cleanup, remove volumes
    -e  Edition, one of [ 'v1', 'v2'], default: 'v2'
    -h  Display this help and exit
    -p  Profile, one of [ 'all', 'base' ], default: 'base'
  Examples:
    $0              => Standard OneCX setup is stopped, existing data remains
    $0  -p all -c   => Complete OneCX setup is stopped and all data are removed
USAGE
  exit "$exit_code"
}

## Count lines in a string, return 0 if the string is empty
count_lines () {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo 0
  else
    printf '%s\n' "$input" | wc -l | tr -d '[:space:]'
  fi
}


#################################################################
## Defaults
OLE_DOCKER_COMPOSE_PROJECT="onecx-local-env"
CLEANUP=false
EDITION=v2
PROFILE=base


#################################################################
## Check options and parameter
while getopts ":ce:hp:" opt; do
  case "$opt" in
    : ) printf '  %b\n' "${RED}Missing parameter for option -${OPTARG}${NC}"
        usage 1
        ;;
    c ) CLEANUP=true
        ;;
    e ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -e${NC}"
          usage 1
        elif [[ "$OPTARG" != "v1" && "$OPTARG" != "v2" ]]; then
          printf '  %b\n' "${RED}Unacceptable Edition, should be one of [ 'v1', 'v2' ]${NC}"
          usage 1
        else
          EDITION=$OPTARG
        fi
        ;;
    p ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -p${NC}"
          usage 1
        elif [[ "$OPTARG" != "all" && "$OPTARG" != "base" ]]; then
          printf '  %b\n' "${RED}Unacceptable Docker profile, should be one of [ 'all', 'base' ]${NC}"
          usage 1
        else
          PROFILE=$OPTARG
        fi
        ;;
    h ) usage 0
        ;;
   \? ) printf '  %b\n' "${RED}Unknown shorthand option: ${GREEN}-${OPTARG}${NC}"
        usage 1
        ;;
  esac
done


#################################################################
## Execute
printf '  %b\n' "edition: ${GREEN}$EDITION${NC}, profile: ${GREEN}$PROFILE${NC}, cleanup: ${GREEN}$CLEANUP${NC}"


#################################################################
## Check and Downing the profile
number_of_services=$(count_lines "$(docker compose -f "versions/$EDITION/compose.yaml" ps)")
((number_of_services--)) || true  # Decrement in place
if [[ $number_of_services == 0 ]]; then
  printf '  %b\n' "${CYAN}No running OneCX services${NC}"
else
  printf '  %b\n' "${GREEN}$number_of_services ${CYAN}OneCX services running in total${NC}"
  docker compose -f "versions/$EDITION/compose.yaml" --profile "$PROFILE" down || true
  ## Check project after downing: remaining services?
  number_of_services=$(count_lines "$(docker compose -f "versions/$EDITION/compose.yaml" ps)")
  ((number_of_services--)) || true  # Decrement in place
  if [[ $number_of_services == 0 ]]; then
    printf '  %b\n' "${GREEN}OneCX stopped successfully${NC}"
  else
    cannot_remove_text=""
    if [[ $CLEANUP == "true" ]]; then
      cannot_remove_text=" ...cannot remove OneCX volumes and network - use 'all' profile to remove all services"
    fi
    printf '  %b\n' "${YELLOW}Remaining running services: $number_of_services${NC}$cannot_remove_text"
    if [ -f "./list-containers.sh" ]; then
      ./list-containers.sh -n onecx
    fi
  fi
fi


#################################################################
## Cleanup volumes of project 'onecx-local-env'?
if [[ $number_of_services == 0 && $CLEANUP == "true" ]]; then
  number_of_volumes=$(count_lines "$(docker volume ls --filter "label=${OLE_DOCKER_COMPOSE_PROJECT}.volume")")
  ((number_of_volumes--)) || true  # Decrement in place
  if [[ $number_of_volumes == 0 ]]; then
    printf '  %b\n' "${CYAN}No OneCX volumes exist${NC}"
  else
    printf '  %b\n' "${CYAN}Remove OneCX volumes and orphans${NC}"
    docker compose -f "versions/$EDITION/compose.yaml" down --volumes --remove-orphans 2> /dev/null || true
    docker volume rm -f "${OLE_DOCKER_COMPOSE_PROJECT}_postgres" 2> /dev/null || true
    docker volume rm -f "${OLE_DOCKER_COMPOSE_PROJECT}_pgadmin"  2> /dev/null || true
    docker volume rm -f "${OLE_DOCKER_COMPOSE_PROJECT}_traefik"  2> /dev/null || true
  fi
  number_of_volumes=$(count_lines "$(docker volume ls --filter "label=${OLE_DOCKER_COMPOSE_PROJECT}.volume")")
  ((number_of_volumes--)) || true  # Decrement in place
  if [[ $number_of_volumes == 0 ]]; then
    printf '  %b\n' "${GREEN}OneCX volumes removed${NC}"
  fi
fi

printf '\n'
