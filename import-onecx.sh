#!/usr/bin/env bash
#
# Start Imports of OneCX Data with options
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0;00m' # No Color

printf '%b\n' "${CYAN}Import data for OneCX Local Environment${NC}"

#################################################################
## Script directory detection, change to it to ensure relative path works
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


#################################################################
## Usage
usage () {
  local exit_code=${1:-0}
  printf '  %b\n' \
  "Usage: $0  [-hsv] [-d <import data type>] [-t <tenant>] [-e <edition>]
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
    $0  -d workspace -x   => Import only Workspace data, default tenant, no check for Docker services
    $0  -t t1             => Import all tenant independent OneCX data and for tenant 't1'
  "
  exit "$exit_code"
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
if [[ "${1:-}" == "--help" ]]; then
  usage 0
fi
while getopts ":hd:svt:e:x" opt; do
  case "$opt" in
    : ) printf '  %b\n' "${RED}Missing parameter for option -${OPTARG}${NC}"
        usage 1
        ;;
    d ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -d${NC}"
          usage 1
        elif [[ ! "$OPTARG" =~ ^(all|base|ai|assignment|bookmark|parameter|permission|mfe|ms|product|slot|tenant|theme|welcome|workspace)$ ]]; then
          printf '  %b\n' "${RED}Unknown data type: $OPTARG${NC}"
          usage 1
        else
          IMPORT_TYPE=$OPTARG
        fi
        # use data-import profile to ensure running services
        if [[ "$OPTARG" =~ ^(all|bookmark|welcome)$ ]]; then
          PROFILE=data-import
        fi
        ;;
    e ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -e${NC}"
          usage 1
        elif [[ "$OPTARG" != "v1" && "$OPTARG" != "v2" ]]; then
          printf '  %b\n' "${RED}Unknown Edition, should be one of [ 'v1', 'v2' ]${NC}"
          usage 1
        else
          EDITION=$OPTARG
        fi
        ;;
    v ) VERBOSE=true
        ;;
    s ) enable_security
        ;;
    t ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -t${NC}"
          usage 1
        elif [[ ! "$OPTARG" =~ ^(default|t1|t2)$ ]]; then
          printf '  %b\n' "${RED}Unknown tenant${NC}"
          usage 1
        else
          enable_security
          TENANT=$OPTARG
        fi
        ;;
    x ) CHECKING_SERVICES=false
        ;;
    h ) usage 0
        ;;
   \? ) printf '  %b\n' "${RED}unknown shorthand option: ${GREEN}-${OPTARG}${NC}" >&2
        usage 1
        ;;
  esac
done
shift $((OPTIND - 1))


#################################################################
## Check Docker availability
if ! command -v docker &> /dev/null; then
  printf '  %b\n' "${RED}Docker is not installed or not in PATH${NC}"
  exit 1
elif ! docker info &> /dev/null; then
  printf '  %b\n' "${RED}Docker daemon is not running or user has no permission to access it${NC}"
  exit 1
fi
if ! docker compose version &> /dev/null; then
  printf '  %b\n' "${RED}Docker Compose v2 is required${NC}"
  exit 1
fi

## Check File availability
if [[ ! -f "compose.yaml" ]]; then
  printf '  %b\n' "${YELLOW}No compose.yaml found in current directory${NC}"
  exit 0
fi
ENV_FILE="versions/$EDITION/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  printf '  %b\n' "${YELLOW}Warning: $ENV_FILE not found${NC}"
  exit 0
fi
if [[ ! -f "versions/$EDITION/compose.yaml" ]]; then
  printf '  %b\n' "${YELLOW}No compose.yaml found for edition $EDITION${NC}"
  exit 0
fi


#################################################################
## Secure Authentication enabled?

# Check option set by start script
if [[ -n "${OLE_SECURITY_AUTH_ENABLED:-}" ]]; then
  if [[ "$OLE_SECURITY_AUTH_ENABLED" == "true" ]]; then
    enable_security
  fi
  #
elif grep -q "^ONECX_SECURITY_AUTH_ENABLED=true" "$ENV_FILE" 2>/dev/null; then
  enable_security
fi
export OLE_SECURITY_AUTH_ENABLED=$SECURITY


#################################################################
if [[ "$CHECKING_SERVICES" == "true" ]]; then
  printf '  %b\n' "Ensure that all services used by imports are running with secure authentication: ${GREEN}$SECURITY_AUTH_USED${NC}   (skip with -x option)"
  
  # Using 'docker compose' (v2). If using older docker, change to 'docker-compose'
  # Docker services are restartet only if some setting was different (e.g. security)
  ONECX_SECURITY_AUTH_ENABLED=${SECURITY}  ONECX_RS_CONTEXT_TENANT_ID_ENABLED=${SECURITY_TENANT_ID_ENABLED}  \
    docker compose --profile "$PROFILE"  up -d  >/dev/null 2>&1
fi
  
#################################################################
# Import
IMPORT_SCRIPT="./versions/$EDITION/import-onecx.sh"
if [[ ! -f "$IMPORT_SCRIPT" ]]; then
  printf '  %b\n' "${RED}Error: Script not found at $IMPORT_SCRIPT${NC}"
  exit 1
fi
chmod +x "$IMPORT_SCRIPT"
"$IMPORT_SCRIPT"  "$TENANT"  "$VERBOSE"  "$SECURITY"  "$IMPORT_TYPE"


#################################################################
## remove profile helper service, ignoring any error message
docker compose down waiting-on-profile-"$PROFILE"  >/dev/null 2>&1 || true

printf '\n'
