#!/bin/bash
#
# Stop OneCX Local Enviroment with options
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


#################################################################
## flags
usage () {
  cat <<USAGE
  Usage: $0  [-h] [-c] [-e <edition>] [-p <profile>]
       -c  cleanup, remove volumes
       -e  edition, one of [ 'v1', 'v2'], default is 'v2'
       -h  display this usage information, ignoring other parameters
       -p  profile, one of [ 'all', 'base', 'data-import', 'minimal' ], default is 'minimal'
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h] [-c] [-e <edition>] [-p <profile>]
USAGE
}


#################################################################
## defaults
CLEANUP=false
EDITION=v2
PROFILE=base

echo -e "${CYAN}Stop OneCX Local Environment${NC}"


#################################################################
## check parameter
while getopts ":ce:hp:" opt; do
  case "$opt" in
        c ) CLEANUP=true ;;
        e ) 
            if [[ $OPTARG != @(v1|v2) ]]; then
              echo -e "${RED} unknown Edition${NC}"
              usage
            else
              EDITION=$OPTARG
            fi
            ;;
        p ) 
            if [[ $OPTARG != @(all|base|data-import|minimal|product) ]]; then
              echo -e "${RED} unknown Docker profile${NC}"
              usage
            else
              PROFILE=$OPTARG
            fi
            ;;
        h ) 
            usage ;; # print usage
       \? )
            echo -e "${RED}  unknown shorthand flag: ${GREEN}-${OPTARG}${NC}" >&2
            usage ;;
  esac
done


#################################################################
## execute
echo -e "  edition: ${GREEN}$EDITION${NC}, profile: ${GREEN}$PROFILE${NC}, cleanup: ${GREEN}$CLEANUP${NC}"

if [[ $# == 0 ]]; then
  usage_short
fi


DOCKER_RUNNING_SERVICES=`docker ps | wc -l`
if [[ $DOCKER_RUNNING_SERVICES == "1" ]]; then
  echo -e "${CYAN}No running services${NC}"
else
  docker compose  -f versions/$EDITION/docker-compose.yaml  --profile $PROFILE  down
fi


#################################################################
## volume
if [[ $CLEANUP == "true" ]]; then
  echo -e "${CYAN}Remove Docker volumes and orphans${NC}"
  
  if [[ $DOCKER_RUNNING_SERVICES == "1" ]]; then
    docker compose down --volumes --remove-orphans 2>/dev/null
  #  docker volume rm -f onecx-local-env_postgres
  fi

  #if [[ $EDITION == "v1" ]]; then
  #  docker compose down --volumes --remove-orphans 
  #else
  #  docker volume rm -f onecx-local-env_postgres
  #fi
fi
