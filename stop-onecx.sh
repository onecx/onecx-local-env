#!/bin/bash

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# check script parameter

if [[ ( $# == 0  ) ]]
then
  profile=all
elif [[ ( $# == 1  ) ]]
then
  if [[ $1 == @(all|base|announcement|help|iam|iam|parameter|permission|product-store|shell|tenant|theme|welcome|workspace|user-profile) ]]
  then
    profile=$1
  else
    echo "unknown Docker profile - use one of these:"
    echo "  all, base, announcement, help, iam, parameter, permission, product-store, shell, tenant, theme, welcome, workspace, user-profile"
    exit 1
  fi
else
  echo
  echo "usage:  $0  [ profile ]"
  echo "  profile:  [ all | base | <product> ]    optional, all is default"
  echo "            <product> in (announcement, help, iam, parameter, permission, product-store, shell, tenant, theme, welcome, workspace, user-profile)"
  exit 1
fi


echo -e "${CYAN}Stop OneCX local running services using profile '$profile'${NC}"

docker compose -f versions/v2/docker-compose.v2.yaml  --env-file versions/v2/.env  --profile $profile  down
