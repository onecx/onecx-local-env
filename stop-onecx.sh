#!/bin/bash
#
# Stop OneCX Local Enviroment with options
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

printf "${CYAN}Stopping OneCX Local Environment${NC}\n"


#################################################################
## Usage
usage () {
  cat <<USAGE
  Usage: $0  [-ch] [-e <edition>] [-p <profile>]
    -c  Cleanup, remove volumes
    -e  Edition, one of [ 'v1', 'v2'], default is 'v2'
    -h  Display this help and exit
    -p  Profile, one of [ 'all', 'base' ], default is 'base'
  Examples:
    $0              => standard OneCX setup is stoppend, existing data remains
    $0  -p all -c   => complete OneCX setup is stopped and data are removed completely
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-ch] [-e <edition>] [-p <profile>]
USAGE
}


#################################################################
## Defaults
OLE_DOCKER_COMPOSE_PROJECT="onecx-local-env"
CLEANUP=false
EDITION=v2
PROFILE=base


#################################################################
## Check flags and parameter
while getopts ":ce:hp:" opt; do
  case "$opt" in
    c ) CLEANUP=true ;;
    e ) 
        if [[ "$OPTARG" != "v1" && "$OPTARG" != "v2" ]]; then
          printf "${RED}  Inacceptable Edition, should be one of [ 'v1', 'v2' ]${NC}\n"
          usage
        else
          EDITION=$OPTARG
        fi
        ;;
    p ) 
        if [[ "$OPTARG" != "all" && "$OPTARG" != "base" ]]; then
          printf "${RED}  Inacceptable Docker profile, should be one of [ 'all', 'base' ]${NC}\n"
          usage
        else
          PROFILE=$OPTARG
        fi
        ;;
    h ) 
        usage
        ;;
   \? )
        printf "${RED}  Unknown shorthand flag: ${GREEN}-${OPTARG}${NC}\n"
        usage
        ;;
  esac
done


#################################################################
## Execute
printf "  edition: ${GREEN}$EDITION${NC}, profile: ${GREEN}$PROFILE${NC}, cleanup: ${GREEN}$CLEANUP${NC}\n"

if [[ $# == 0 ]]; then
  usage_short
fi


#################################################################
## Check and Downing the profile
number_of_services=`docker compose ps | wc -l`
number_of_services=$(($number_of_services -1))
if [[ $number_of_services == 0 ]]; then
  printf "${CYAN}No running services${NC}\n"
else
  docker compose  -f versions/$EDITION/docker-compose.yaml  --profile $PROFILE  down
fi


#################################################################
## Check project after downing: remaining services?
number_of_services=`docker compose ps | wc -l`
number_of_services=$(($number_of_services -1))
if [[ $number_of_services != 0 ]]; then
  if [[ $CLEANUP == "true" ]]; then
    cannot_remove_text=" ...cannot remove volumes and network - use 'all' profile to remove all services"
  fi
  printf "${CYAN}Remaining running services: $number_of_services${NC}$cannot_remove_text\n"
  ./list-containers.sh
fi


#################################################################
## Cleanup volumes of project 'onecx-local-env'?
number_of_volumes=`docker volume ls --filter "label=onecx-local-env.volume" | wc -l`
number_of_volumes=$(($number_of_running_volumes -1))
if [[ ($number_of_services == 0) && ($CLEANUP == "true") ]]; then
  if [[ ($number_of_volumes == 0 ) ]]; then
    printf "${CYAN}No project volumes exist${NC}\n"
  else
    printf "${CYAN}Remove project volumes and orphans${NC}\n"
    docker compose down --volumes --remove-orphans              2> /dev/null
    docker volume rm -f ${OLE_DOCKER_COMPOSE_PROJECT}_postgres  2> /dev/null
    docker volume rm -f ${OLE_DOCKER_COMPOSE_PROJECT}_pgadmin   2> /dev/null
  fi
fi
