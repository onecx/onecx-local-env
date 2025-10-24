#!/bin/bash
#
# Start OneCX Local Enviroment by using a profile (default: all)
#

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

echo -e "${CYAN}Start OneCX Local Environment${NC}"

profile=minimal
print_usage=1
stop=0

# check script parameter

if [[ ( $# == 0  ) ]]
then
  echo -e " ...use profile ${GREEN}'$profile'${NC}"
elif [[ ( $# == 1  ) ]]
then
  if [[ $1 == @(all|base|minimal|data-import) ]]
  then
    profile=$1
    print_usage=0
    echo -e " ...use profile ${GREEN}'$profile'${NC}"
  else
    stop=1
    echo -e "${RED} ...unknown Docker profile${NC}"
  fi
else
  stop=1
fi

if [[ ( $print_usage == 1  ) ]]
then
  echo "    usage:  $0  [ profile ]  with profile in (all, base, minimal, data-import ), optional, 'minimal' is default"
fi

if [[ ( $stop == 1  ) ]]
then
  exit 1
fi

docker compose -f versions/v2/docker-compose.v2.yaml  --profile $profile   up -d
