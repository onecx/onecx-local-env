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
usage () {
  cat <<USAGE
  Usage: $0  [-h|?] [-c] [-e <edition>] [-p <profile>]
       -c  cleanup, remove volumes
       -e  edition, one of [ 'v1', 'v2'], default is 'v2'
       -h  display this usage information
       -p  profile, one of [ 'all', 'base', 'data-import', 'minimal' ], default is 'minimal'
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h|?] [-c] [-e <edition>] [-p <profile>]
USAGE
}


#################################################################
# defaults
CLEANUP=false
EDITION=v2
PROFILE=minimal


#################################################################
# check parameter
while getopts ":hce:p:" opt; do
  case "$opt" in
        c) CLEANUP=true ;;
        e) 
            if [[ $OPTARG != @(v1|v2) ]]; then
              echo -e "${RED} ...unknown Edition${NC}"
              usage
            else
              EDITION=$OPTARG
            fi
           ;;
        p) 
            if [[ $OPTARG != @(all|base|data-import|minimal|product) ]]; then
              echo -e "${RED} ...unknown Docker profile${NC}"
              usage
            else
              PROFILE=$OPTARG
            fi
           ;;
    ? | h) usage ;; # print usage
  esac
done


#################################################################
echo -e "${CYAN}Stop OneCX Local Environment with edition: ${GREEN}$EDITION${NC}${CYAN}, profile: ${GREEN}$PROFILE${NC}${CYAN}, cleanup: ${GREEN}$CLEANUP${NC}"

if [[ $# == 0 ]]; then
  usage_short
fi

docker compose -f versions/$EDITION/docker-compose.$EDITION.yaml --profile $PROFILE  down

if [[ $CLEANUP == "true" ]]; then
  echo -e "${CYAN}Remove Docker volumes${NC}"
  if [[ $EDITION == "v1" ]]; then
    docker compose -v -f versions/$EDITION/docker-compose.$EDITION.yaml  down --volumes
  else
    docker volume rm -f onecx-local-env_postgres
  fi
fi
