#!/bin/bash
#
# Start Imports of OneCX Data in version 2
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

usage () {
  cat <<USAGE
  $0  [-h] [-v] [-t <tenant>]
       -h  display this usage information
       -v  verbose, if set then details are displayed on imports
       -t  tenant, one of [ 'default', 't1', 't2' ], default is 'default'
USAGE
  exit 0
}

# defaults
TENANT=default
VERBOSE=false

# check parameter
while getopts ":hvt:" opt; do
  case "$opt" in
        v) VERBOSE=true ;;
        t) 
            if [[ $OPTARG != @(default|t1|t2) ]]; then
              usage
            else
              TENANT=$OPTARG
            fi
           ;;
    ? | h) usage ;; # print usage
  esac
done

echo -e "${CYAN}Ensure that all services used by imports are running${NC}"
#docker compose -f versions/v2/docker-compose.v2.yaml  --profile data-import   up -d
bash ./versions/v2/import-onecx.v2.sh  $TENANT  $VERBOSE