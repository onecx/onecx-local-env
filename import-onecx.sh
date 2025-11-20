#!/bin/bash
#
# Start Imports of OneCX Data with options
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Import data for OneCX Local Environment${NC}"

#################################################################
usage () {
  cat <<USAGE
  $0  [-h] [-d <import data type>] [-v] [-s] [-t <tenant>]
       -d  data type, one of [ all, base, bookmark, assignment, permission, mfe, ms, product, slot, theme, welcome, workspace], base is default
       -e  edition, one of [ 'v1', 'v2' ], default is 'v2'
       -h  display this usage information
       -s  security authentication enabled, default not enabled
       -t  tenant, one of [ 'default', 't1', 't2' ], default is 'default'
       -v  verbose: display details on imports
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h] [-d <import data type>] [-v] [-s] [-t <tenant>]
USAGE
}


#################################################################
# defaults
EDITION=v2
SECURITY=false
TENANT=default
VERBOSE=false
PROFILE=base


#################################################################
# check parameter
while getopts ":hd:svt:" opt; do
  case "$opt" in
        d ) 
            if [[ $OPTARG != @(all|base|assignment|bookmark|permission|mfe|ms|product|slot|theme|welcome|workspace) ]]; then
              usage
            else
              IMPORT_TYPE=$OPTARG
            fi
            # use data-import profile to ensure running services
            if [[ $OPTARG == @(all|bookmark|welcome) ]]; then
              PROFILE=data-import
            fi
            ;;
        v ) VERBOSE=true ;;
        s ) SECURITY=true ;;
        t ) 
            if [[ $OPTARG != @(default|t1|t2) ]]; then
              usage
            else
              TENANT=$OPTARG
            fi
            ;;
    ? | h ) usage ;;
       \? )
            echo -e "${RED}  unknown shorthand flag: ${GREEN}-${OPTARG}${NC}" >&2
            usage ;;
  esac
done


#################################################################
## Security Authentication enabled?
OLE_SECURITY_AUTH_ENABLED_INT=`grep -c "ONECX_SECURITY_AUTH_ENABLED=true" versions/$EDITION/.env`
# translate for displaying only:
SECURITY_AUTH_USED="no"
if [[ ($OLE_SECURITY_AUTH_ENABLED_INT == 1) || ($SECURITY == "true") ]]; then
  SECURITY_AUTH_USED="yes"
else
  SECURITY=false
fi
export ONECX_SECURITY_AUTH_ENABLED=$SECURITY


#################################################################
echo -e "  Ensure that all services used by imports are running, security authentication: ${GREEN}$SECURITY_AUTH_USED${NC}"
ONECX_SECURITY_AUTH_ENABLED=$SECURITY  docker compose -f versions/$EDITION/docker-compose.yaml  --profile $PROFILE  up -d  > /dev/null 2>&1

if [[ $# == 0 ]]; then
  usage_short
fi

./versions/$EDITION/import-onecx.sh  $TENANT  $VERBOSE  $SECURITY  $IMPORT_TYPE


#################################################################
## remove profile helper service, ignoring any error message
if [[ $PROFILE == "data-import" ]]; then
  docker compose down   waiting-on-profile-$PROFILE  > /dev/null 2>&1
fi
