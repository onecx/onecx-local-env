#!/bin/bash
#
# Start OneCX Local Enviroment with options
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Starting OneCX Local Environment ...${NC}"


#################################################################
## flags
usage () {
  cat <<USAGE
  Usage: $0  [-h] [-e <edition>] [-p <profile>] [-s]
       -e  edition, one of [ 'v1', 'v2'], default: 'v2'
       -h  display this usage information, ignoring other parameters
       -p  profile, one of [ 'all', 'base' ], default: 'base'
       -s  security authentication enabled, default: not enabled
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h] [-e <edition>] [-p <profile>] [-s]
USAGE
}


#################################################################
## defaults
EDITION=v2
PROFILE=base
SECURITY=false


#################################################################
## check parameter
while getopts ":he:p:s" opt; do
  case "$opt" in
        e ) 
            if [[ $OPTARG != @(v1|v2) ]]; then
              echo -e "${RED}  unknown Edition${NC}"
              usage
            else
              EDITION=$OPTARG
            fi
            ;;
        p ) 
            if [[ $OPTARG != @(all|base) ]]; then
              echo -e "${RED}  unknown Docker profile${NC}"
              usage
            else
              PROFILE=$OPTARG
            fi
            ;;
        s ) SECURITY=true ;;
        h ) 
            usage ;; # print usage
       \? )
            echo -e "${RED}  unknown shorthand flag: ${GREEN}-${OPTARG}${NC}" >&2
            usage ;;
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
## start profile services
echo -e "  edition: ${GREEN}$EDITION${NC}, profile: ${GREEN}$PROFILE${NC}, security authentication: ${GREEN}$SECURITY_AUTH_USED${NC}"

if [[ $# == 0 ]]; then
  usage_short
fi

ONECX_SECURITY_AUTH_ENABLED=$SECURITY  docker compose -f versions/$EDITION/docker-compose.yaml  --profile $PROFILE  up -d


#################################################################
## import profile data
./import-onecx.sh -d $PROFILE


#################################################################
## remove profile helper service, ignoring any error message
docker compose down   waiting-on-profile-$PROFILE  > /dev/null 2>&1


#################################################################
## End of starting
echo -e "To use OneCX, navigate to http://local-proxy/onecx-shell/admin/"
