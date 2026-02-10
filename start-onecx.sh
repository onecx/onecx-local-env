#!/usr/bin/env bash
#
# Start OneCX Local Environment with options
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

printf '%b\n' "${CYAN}Starting OneCX Local Environment${NC}"

#################################################################
## Script directory detection, change to it to ensure relative path works
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


#################################################################
## Usage
usage () {
  local exit_code=${1:-0}
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
## Defaults
IMPORT=yes
EDITION=v2
PROFILE=base
SECURITY=false
SECURITY_AUTH_USED=no
SECURITY_TENANT_ID_ENABLED=false


#################################################################
## Check options and parameter
while getopts ":he:p:sx" opt; do
  case "$opt" in
    : ) printf '  %b\n' "${RED}Missing parameter for option -${OPTARG}${NC}"
        usage 1
        ;;
    e ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -e${NC}"
          usage 1
        elif [[ "$OPTARG" != "v1" && "$OPTARG" != "v2" ]]; then
          printf '  %b\n' "${RED}Unacceptable Edition, should be one of [ 'v1', 'v2' ]${NC}"
          usage 1
        else
          EDITION=$OPTARG
        fi
        ;;
    p ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -p${NC}"
          usage 1
        elif [[ "$OPTARG" != "all" && "$OPTARG" != "base" ]]; then
          printf '  %b\n' "${RED}Unacceptable Docker profile, should be one of [ 'all', 'base' ]${NC}"
          usage 1
        else
          PROFILE=$OPTARG
        fi
        ;;
    s ) enable_security
        ;;
    x ) IMPORT=no
        ;;
    h ) usage 0
        ;;
   \? ) printf '  %b\n' "${RED}Unknown shorthand option: ${GREEN}-${OPTARG}${NC}" >&2
        usage 1
        ;;
  esac
done
shift $((OPTIND - 1))

ENV_FILE="versions/$EDITION/.env"


#################################################################
## Secure Authentication enabled?
if [[ $SECURITY == "false" ]]; then
  # read preset
  if [ -f "$ENV_FILE" ]; then
    security_enabled=$(grep "^ONECX_SECURITY_AUTH_ENABLED=" "$ENV_FILE" | cut -d '=' -f2 || echo "")
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
printf '  %b\n' "edition: ${GREEN}$EDITION${NC}, profile: ${GREEN}$PROFILE${NC}, import: ${GREEN}$IMPORT${NC}, secure authentication: ${GREEN}$SECURITY_AUTH_USED${NC}"


# Using 'docker compose' (v2). If using older docker, change to 'docker-compose'
if ! ONECX_SECURITY_AUTH_ENABLED=${SECURITY} ONECX_RS_CONTEXT_TENANT_ID_ENABLED=${SECURITY_TENANT_ID_ENABLED} \
    docker compose -f "versions/$EDITION/compose.yaml" --profile "$PROFILE" up -d; then
  printf '  %b\n' "${RED}Failed to start all Docker compose services${NC}"
  exit 1
fi

# Check running shell bff
shell_is_healthy=$(docker inspect --format='{{.State.Health.Status}}' onecx-shell-bff 2>/dev/null || echo "not_found")


#################################################################
## Import profile data
if [[ $shell_is_healthy == "healthy" && $IMPORT == "yes" ]]; then
  # Ensure script is executable
  if [ -f "./import-onecx.sh" ]; then
    chmod +x ./import-onecx.sh
    if ! ./import-onecx.sh -d "$PROFILE"; then
      printf '  %b\n' "${YELLOW}Warning: Import failed${NC}"
    fi
  else
    printf '  %b\n' "${RED}Error: import-onecx.sh not found.${NC}"
  fi
elif [[ $IMPORT == "yes" ]]; then
  printf '  %b\n' "${YELLOW}Warning: onecx-shell-bff not healthy (status: $shell_is_healthy), skipping import${NC}"
fi

#################################################################
## remove profile helper service, ignoring any error message
docker compose -f "versions/$EDITION/compose.yaml" down waiting-on-profile-"$PROFILE" > /dev/null 2>&1 || true


#################################################################
## End of starting
printf '  %b\n' "To use OneCX, navigate to http://onecx.localhost/onecx-shell/admin/"

printf '\n'
