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

printf "${CYAN}Starting OneCX Local Environment ...${NC}\n"


#################################################################
## Usage
usage () {
  cat <<USAGE
  Usage: $0  [-h] [-e <edition>] [-p <profile>] [-s] [-x]
       -e  edition, one of [ 'v1', 'v2'], default: 'v2'
       -h  display this usage information, ignoring other parameters
       -p  profile, one of [ 'all', 'base' ], default: 'base'
       -s  security authentication enabled, default: not enabled
       -x  skip import
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h] [-e <edition>] [-p <profile>] [-s] [-x]
USAGE
}


#################################################################
## Defaults
EDITION=v2
PROFILE=base
SECURITY=false
IMPORT=yes


#################################################################
## Check flags and parameter
while getopts ":he:p:sx" opt; do
  case "$opt" in
        e ) 
            if [[ "$OPTARG" != "v1" && "$OPTARG" != "v2" ]]; then
              printf "${RED}  inacceptable Edition, should be one of [ 'v1', 'v2' ]${NC}\n"
              usage
            else
              EDITION=$OPTARG
            fi
            ;;
        p ) 
            if [[ "$OPTARG" != "all" && "$OPTARG" != "base" ]]; then
              printf "${RED}  Inacceptable Docker profile, should be one of [ 'all', 'base' ]${NC}\n"
              usage
            else
              PROFILE=$OPTARG
            fi
            ;;
        s ) SECURITY=true ;;
        x ) IMPORT=no ;;
        h ) usage ;; # print usage
       \? )
            printf "${RED}  Unknown shorthand flag: ${GREEN}-${OPTARG}${NC}\n" >&2
            usage ;;
  esac
done


#################################################################
## Security Authentication enabled?
ENV_FILE="versions/$EDITION/.env"
SECURITY_AUTH_USED="no"

if [ -f "$ENV_FILE" ]; then
    OLE_SECURITY_AUTH_ENABLED_INT=$(grep -c "ONECX_SECURITY_AUTH_ENABLED=true" "$ENV_FILE")
    if [[ ($OLE_SECURITY_AUTH_ENABLED_INT == 1) || ($SECURITY == "true") ]]; then
      SECURITY_AUTH_USED="yes"
    fi
else 
    if [[ "$SECURITY" == "true" ]]; then
      SECURITY_AUTH_USED="yes"
    fi
fi


#################################################################
## Start profile services
printf "  edition: ${GREEN}$EDITION${NC}, profile: ${GREEN}$PROFILE${NC}, import: ${GREEN}$IMPORT${NC}, security authentication: ${GREEN}$SECURITY_AUTH_USED${NC}\n"

if [[ $# == 0 ]]; then
  usage_short
fi

# Using 'docker compose' (v2). If using older docker, change to 'docker-compose'
ONECX_SECURITY_AUTH_ENABLED=$SECURITY docker compose -f versions/$EDITION/docker-compose.yaml --profile $PROFILE up -d


#################################################################
## Import profile data
if [[ $IMPORT == "yes" ]]; then
  # Ensure script is executable
  if [ -f "./import-onecx.sh" ]; then
      chmod +x ./import-onecx.sh
      ./import-onecx.sh -d $PROFILE
  else
      printf "${RED}Error: import-onecx.sh not found.${NC}\n"
  fi
fi


#################################################################
## Remove profile helper service, ignoring any error message
docker compose down waiting-on-profile-$PROFILE > /dev/null 2>&1


#################################################################
## End of starting
printf "To use OneCX, navigate to http://local-proxy/onecx-shell/admin/\n"