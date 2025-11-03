#!/bin/bash
#
# Start OneCX Local Enviroment with options
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


#################################################################
usage () {
  cat <<USAGE
  Usage: $0  [-h|?] [-e <edition>] [-p <profile>] [-s]
       -e  edition, one of [ 'v1', 'v2'], default is 'v2'
       -h  display this usage information
       -p  profile, one of [ 'all', 'base', 'data-import', 'minimal' ], default is 'minimal'
       -s  security authentication enabled
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h|?] [-e <edition>] [-p <profile>] [-s]
USAGE
}


#################################################################
# defaults
EDITION=v2
PROFILE=minimal
SECURITY=false


#################################################################
# check parameter
while getopts ":hse:p:" opt; do
  case "$opt" in
        s) SECURITY=true ;;
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
## Security Authentication enabled?
OLE_SECURITY_AUTH_ENABLED=`grep -c "ONECX_SECURITY_AUTH_ENABLED=true" versions/$EDITION/.env`
# translate for displaying only:
SECURITY_AUTH_USED="no"
if [[ ($OLE_SECURITY_AUTH_ENABLED == 1) || ($SECURITY == "true") ]]; then
  SECURITY_AUTH_USED="yes"
fi


#################################################################
echo -e "${CYAN}Start OneCX Local Environment with edition: ${GREEN}$EDITION${NC}${CYAN}, profile: ${GREEN}$PROFILE${NC}${CYAN}, security authentication: ${GREEN}$SECURITY_AUTH_USED${NC}"

if [[ $# == 0 ]]; then
  usage_short
fi

ONECX_SECURITY_AUTH_ENABLED=$SECURITY  docker compose -f versions/$EDITION/docker-compose.$EDITION.yaml  --profile $PROFILE  up -d

