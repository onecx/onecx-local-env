#!/bin/bash
#
# Start OneCX Local Enviroment with options
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

printf "${CYAN}Starting OneCX Local Environment${NC}\n"


#################################################################
## Usage
usage () {
  cat <<USAGE
  Usage: $0  [-hsx] [-e <edition>] [-p <profile>]
    -e  Edition, one of [ 'v1', 'v2'], default: 'v2'
    -h  Display this help and exit
    -p  Profile, one of [ 'all', 'base' ], default: 'base'
    -s  Secure authentication enabled, default: not enabled
    -x  Skip imports
  Examples:
    $0              => Standard OneCX setup is started and initialized
    $0  -s          => Standard OneCX setup is started with security
    $0  -p all      => Complete OneCX setup is started and initialized
    $0  -p all -x   => Complete OneCX setup is started only (no imports)
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-hsx] [-e <edition>] [-p <profile>]
USAGE
}
#################################################################
## Enable secure authentication
enable_security () {
  SECURITY=true
  SECURITY_AUTH_USED=yes
  SECURITY_TENANT_ID_ENABLED=true
}

#################################################################
## Defaults
IMPORT=yes
EDITION=v2
PROFILE=base
SECURITY=false
SECURITY_AUTH_USED=no
SECURITY_TENANT_ID_ENABLED=false
ENV_FILE="versions/$EDITION/.env"


#################################################################
## Check options and parameter
while getopts ":he:p:sx" opt; do
  case "$opt" in
    : ) printf "${RED}  Missing paramter for option -${OPTARG}${NC}\n"
        usage
        ;;
    e ) if [[ "$OPTARG" == -* ]]; then
          printf "${RED}  Missing paramter for option -e${NC}\n"
          usage
        elif [[ "$OPTARG" != "v1" && "$OPTARG" != "v2" ]]; then
          printf "${RED}  Inacceptable Edition, should be one of [ 'v1', 'v2' ]${NC}\n"
          usage
        else
          EDITION=$OPTARG
        fi
        ;;
    p ) if [[ "$OPTARG" == -* ]]; then
          printf "${RED}  Missing paramter for option -p${NC}\n"
          usage
        elif [[ "$OPTARG" != "all" && "$OPTARG" != "base" ]]; then
          printf "${RED}  Inacceptable Docker profile, should be one of [ 'all', 'base' ]${NC}\n"
          usage
        else
          PROFILE=$OPTARG
        fi
        ;;
    s ) enable_security
        ;;
    x ) IMPORT=no
        ;;
    h ) usage
        ;;
   \? ) printf "${RED}  Unknown shorthand option: ${GREEN}-${OPTARG}${NC}\n" >&2
        usage
        ;;
  esac
done


#################################################################
## Secure Authentication enabled?
if [[ $SECURITY == "false" ]]; then
  # read preset
  if [ -f "$ENV_FILE" ]; then
    security_enabled=$(grep "^ONECX_SECURITY_AUTH_ENABLED=" "$ENV_FILE" | cut -d '=' -f2)
    if [[ $security_enabled == "true" ]]; then
      enable_security
    fi
  fi
fi
# Visible for subsequent scripts
export OLE_SECURITY_AUTH_ENABLED=$SECURITY


#################################################################
#################################################################
## Start profile services
printf "  edition: ${GREEN}$EDITION${NC}, profile: ${GREEN}$PROFILE${NC}, import: ${GREEN}$IMPORT${NC}, secure authentication: ${GREEN}$SECURITY_AUTH_USED${NC}\n"

if [[ $# == 0 ]]; then
  usage_short
fi

# Using 'docker compose' (v2). If using older docker, change to 'docker-compose'
ONECX_SECURITY_AUTH_ENABLED=${SECURITY}  ONECX_RS_CONTEXT_TENANT_ID_ENABLED=${SECURITY_TENANT_ID_ENABLED}  \
    docker compose -f versions/$EDITION/compose.yaml --profile $PROFILE  up -d

# Check running shell bff
shell_is_healthy=`docker inspect --format='{{.State.Health.Status}}'  onecx-shell-bff`


#################################################################
## Import profile data
if [[ $shell_is_healthy == "healthy" && $IMPORT == "yes" ]]; then
  # Ensure script is executable
  if [ -f "./import-onecx.sh" ]; then
    chmod +x ./import-onecx.sh
    ./import-onecx.sh -d $PROFILE
  else
    printf "${RED}Error: import-onecx.sh not found.${NC}\n"
  fi
fi

#################################################################
## remove profile helper service, ignoring any error message
ocker compose down waiting-on-profile-$PROFILE > /dev/null 2>&1


#################################################################
## End of starting
printf "To use OneCX, navigate to http://proxy.localhost/onecx-shell/admin/\n"

printf "\n"
