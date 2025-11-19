#!/bin/bash
#
# Stop OneCX Local Enviroment with options
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Stop OneCX Local Environment${NC}"


#################################################################
## Usage
usage () {
  cat <<USAGE
  Usage: $0  [-h] [-c] [-e <edition>] [-p <profile>]
       -c  cleanup, remove volumes
       -e  edition, one of [ 'v1', 'v2'], default is 'v2'
       -h  display this usage information, ignoring other parameters
       -p  profile, one of [ 'all', 'base' ], default is 'base'
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h] [-c] [-e <edition>] [-p <profile>]
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
            if [[ $OPTARG != @(v1|v2) ]]; then
              echo -e "${RED}  Missing Edition${NC}"
              usage
            else
              EDITION=$OPTARG
            fi
            ;;
        p ) 
            if [[ $OPTARG != @(all|base) ]]; then
              echo -e "${RED}  Missing Docker profile${NC}"
              usage
            else
              PROFILE=$OPTARG
            fi
            ;;
        h ) 
            usage ;; # print usage
       \? )
            echo -e "${RED}  Unknown shorthand flag: ${GREEN}-${OPTARG}${NC}" >&2
            usage ;;
  esac
done


#################################################################
## Execute
echo -e "  edition: ${GREEN}$EDITION${NC}, profile: ${GREEN}$PROFILE${NC}, cleanup: ${GREEN}$CLEANUP${NC}"

if [[ $# == 0 ]]; then
  usage_short
fi


#################################################################
## Check and Downing
number_of_running_services=`docker ps | wc -l`
number_of_running_services=$(($number_of_running_services -1))
if [[ $number_of_running_services == 0 ]]; then
  echo -e "${CYAN}No running services${NC}"
else
  docker compose  -f versions/$EDITION/docker-compose.yaml  --profile $PROFILE  down
fi


#################################################################
## Check success after downing
number_of_running_services=`docker ps | wc -l`
number_of_running_services=$(($number_of_running_services -1))
if [[ $number_of_running_services != 0 ]]; then
  if [[ $CLEANUP == "true" ]]; then
    cannot_remove_text=" ...cannot remove volumes and network - use 'all' profile to remove all services"
  fi
  echo -e "${CYAN}Remaining running services: $number_of_running_services${NC}$cannot_remove_text"
  ./list-containers.sh
fi


#################################################################
## Cleanup volume?
if [[ ($number_of_running_services == 0) && ($CLEANUP == "true") ]]; then
  echo -e "${CYAN}Remove Docker volumes and orphans${NC}"
  docker compose down --volumes --remove-orphans 2>/dev/null
  docker volume rm -f ${OLE_DOCKER_COMPOSE_PROJECT}_postgres
fi
