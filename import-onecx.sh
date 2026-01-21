#!/bin/bash
#
# Start Imports of OneCX Data with options
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

printf "${CYAN}Import data for OneCX Local Environment${NC}\n"

#################################################################
usage () {
  cat <<USAGE
  Usage: $0  [-hsv] [-d <import data type>] [-t <tenant>] [-e <edition>]
    -d  Data type, one of [ all, base, ai, bookmark, assignment, parameter, permission, mfe, ms, product, slot, tenant theme, welcome, workspace], base is default
    -e  Edition, one of [ 'v1', 'v2' ], default: 'v2'
    -h  Display this help and exit
    -s  Secure authentication enabled, default: not enabled (value is inherited from start-onecx.sh)
    -t  Tenant, one of [ 'default', 't1', 't2' ], default: 'default'
    -v  Verbose: display details during import of objects
    -x  Skip checking running Docker services
  Examples:
    $0                    => Import OneCX data used by standard setup (same as "-d base"), default tenant
    $0  -d all -s         => Import all OneCX data, services are running with security context (restarted if req.)
    $0  -d workspace -x   => Import only Worspace data, default tenant, no check for Docker services
    $0  -t t1             => Import all tenant independent OneCX data and for tenant 't1'
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-hsv] [-d <import data type>] [-t <tenant>] [-e <edition>]
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
# defaults
EDITION=v2
VERBOSE=false           # more details on each import request
PROFILE=base            # used as standard in start script
TENANT=default
IMPORT_TYPE=base
SECURITY=false          # used as flag for docker compose start services
SECURITY_AUTH_USED=no   # used for displaying
SECURITY_TENANT_ID_ENABLED=false
CHECKING_SERVICES=true  # check running Docker services before import


#################################################################
# check parameter
while getopts ":hd:svt:e:x" opt; do
  case "$opt" in
    : ) printf "${RED}  Missing paramter for option -${OPTARG}${NC}\n"
        usage
        ;;
    d ) if [[ "$OPTARG" == -* ]]; then
          printf "${RED}  Missing paramter for option -d${NC}\n"
          usage
        elif [[ ! "$OPTARG" =~ ^(all|base|ai|assignment|bookmark|parameter|permission|mfe|ms|product|slot|tenant|theme|welcome|workspace)$ ]]; then
          printf "${RED}  Unknown data type: $OPTARG${NC}\n"
          usage
        else
          IMPORT_TYPE=$OPTARG
        fi
        # use data-import profile to ensure running services
        if [[ "$OPTARG" =~ ^(all|bookmark|welcome)$ ]]; then
          PROFILE=data-import
        fi
        ;;
    e ) if [[ "$OPTARG" == -* ]]; then
          printf "${RED}  Missing paramter for option -e${NC}\n"
          usage
        elif [[ "$OPTARG" != "v1" && "$OPTARG" != "v2" ]]; then
          printf "${RED}  Unknown Edition, should be one of [ 'v1', 'v2' ]${NC}\n"
          usage
        else
          EDITION=$OPTARG
        fi
        ;;
    v ) VERBOSE=true
        ;;
    s ) enable_security
        ;;
    t ) if [[ "$OPTARG" == -* ]]; then
          printf "${RED}  Missing paramter for option -t${NC}\n"
          usage
        elif [[ ! "$OPTARG" =~ ^(default|t1|t2)$ ]]; then
          printf "${RED}  Unknown tenant${NC}\n"
          usage
        else
          enable_security
          TENANT=$OPTARG
        fi
        ;;
    x ) CHECKING_SERVICES=false
        ;;
? | h ) usage
        ;;
   \? ) printf "${RED}  unknown shorthand option: ${GREEN}-${OPTARG}${NC}\n" >&2
        usage
        ;;
  esac
done


#################################################################
## Secure Authentication enabled?
ENV_FILE="versions/$EDITION/.env"

# Check option set by start script
if [ -n $OLE_SECURITY_AUTH_ENABLED ]; then
  if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
    enable_security
  fi
  #
  # If this script was executed directly, check the security settings.:
elif [ -f "$ENV_FILE" ]; then
    OLE_SECURITY_AUTH_ENABLED=$(grep "^ONECX_SECURITY_AUTH_ENABLED=" "$ENV_FILE" | cut -d '=' -f2 )
    # env file enabling or -s
    if [[ $OLE_SECURITY_AUTH_ENABLED == "true" ]]; then
      enable_security
    fi
fi
export OLE_SECURITY_AUTH_ENABLED=$SECURITY


#################################################################
if [[ "$CHECKING_SERVICES" == "true" ]]; then
  printf "  Ensure that all services used by imports are running with secure authentication: ${GREEN}$SECURITY_AUTH_USED${NC}   (skip with -x option)\n"
  
  # Using 'docker compose' (v2). If using older docker, change to 'docker-compose'
  # Docker services are restartet only if some setting was different (e.g. security)
  ONECX_SECURITY_AUTH_ENABLED=${SECURITY}  ONECX_RS_CONTEXT_TENANT_ID_ENABLED=${SECURITY_TENANT_ID_ENABLED}  \
    docker compose --profile $PROFILE  up -d  > /dev/null 2>&1
fi
  
#################################################################
# Import
IMPORT_SCRIPT="./versions/$EDITION/import-onecx.sh"
if [ ! -f "$IMPORT_SCRIPT" ]; then
  printf "${RED}Error: Script not found at $IMPORT_SCRIPT${NC}\n"
  exit 1
fi

chmod +x "$IMPORT_SCRIPT"
"$IMPORT_SCRIPT"  $TENANT  $VERBOSE  $SECURITY  $IMPORT_TYPE


#################################################################
## remove profile helper service, ignoring any error message
if [ -n $PROFILE ]; then
  docker compose down  waiting-on-profile-$PROFILE  > /dev/null 2>&1
fi

printf "\n"
