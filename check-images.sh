#!/usr/bin/env bash
#
# List local Docker images
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

printf '%b\n' "${CYAN}List local Docker images with tag, version and size${NC}"

#################################################################
## Script directory detection, change to it to ensure relative path works
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


#################################################################
## Usage
usage () {
  local exit_code=${1:-0}
  printf '  %b\n' \
  "Usage: $0  [-h] [-f <image filter>] [-n <text>]
       -f  Image filter, see https://docs.docker.com/reference/cli/docker/image/ls/#filter
       -h  Display this usage information, ignoring other parameters
       -n  Name filter, find images which have <text> into image name
  Examples:
    $0  -n onecx            => List images filtered by 'onecx' in image name
    $0  -f dangling=true    => List images filtered by 'dangling=true'
  "
  exit "$exit_code"
}


#################################################################
## Defaults
readonly VERSION_LABEL="samo.project.version"
FILTER=""
FILTER_TEXT=""
NAME_FILTER=""
IMAGES=""


#################################################################
## Check options and parameter
while getopts ":hf:n:" opt; do
  case "$opt" in
    f ) if [[ -z "$OPTARG" ]]; then
          printf '  %b\n' "${RED}Missing filter value${NC}"
          usage 1
        else
          FILTER=$OPTARG
        fi
        ;;
    n ) if [[ -z "$OPTARG"  ]]; then
          printf '  %b\n' "${RED}Missing image name${NC}"
          usage 1
        else
          NAME_FILTER=$OPTARG
        fi
        ;;
    h ) usage 0
        ;;
   \? ) printf '  %b\n' "${RED}Unknown shorthand option: ${GREEN}-${OPTARG}${NC}"
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


printf '  %b\t%b\n' "=> OneCX image version label:" "${GREEN}${VERSION_LABEL}${NC}"


#########################################
#### GET and FILTER images
if [[ -n "$FILTER" ]]; then
  FILTER_TEXT=" using filter value"
  printf '  %b\n' "=> Filter value:\t\t${GREEN}${FILTER}${NC}"
  IMAGES=$(docker image ls --format "{{.Repository}}" --filter "$FILTER" | sort | uniq)
else
  IMAGES=$(docker image ls --format "{{.Repository}}" | sort | uniq)
fi

if [[ -n "$NAME_FILTER" ]]; then
  if [[ -n "$FILTER" ]]; then
    FILTER_TEXT+=" and name filter"
  else
    FILTER_TEXT=" using name filter"
  fi
  printf '  %b\t%b\n' "=> Filtered image name:" "${GREEN}${NAME_FILTER}${NC}"
  IMAGES=$(printf '%s' "$IMAGES" | grep "${NAME_FILTER}" || true)
fi


#########################################
#### Check existence
if [[ -z "$IMAGES" ]]; then
  printf '  %b\n' "${YELLOW}No local Docker images found${FILTER_TEXT}${NC}"
  exit 0
fi

#########################################
#### Get local images
printf "\n"
readonly PRINT_FORMAT="%-43s %-13s %-14s %-16s %-16s\n"
# shellcheck disable=SC2059
printf "$PRINT_FORMAT" "IMAGE" "TAG" "LOCAL ID" "VERSION" "SIZE"
printf '%b\n' "-------------------------------------------------------------------------------------------------"


#########################################
#### LIST IMAGES
#########################################
for IMAGE in $IMAGES; do
  # LOCAL
  docker images "$IMAGE" --format "{{.Repository}} {{.Tag}} {{.ID}} {{.Size}}" | while read -r REPO TAG ID SIZE; do
    # Read version label
    LOCAL_VERSION=$(docker inspect --format "{{ index .Config.Labels \"$VERSION_LABEL\" }}" "$ID" 2>/dev/null)
  
    # No label → display placeholder
    if [[ -z "$LOCAL_VERSION" ]] || [[ "$LOCAL_VERSION" = "<no value>" ]]; then
      LOCAL_VERSION="(no Label)"
    fi
    # shellcheck disable=SC2059
    printf "$PRINT_FORMAT" "$REPO" "$TAG" "$ID" "$LOCAL_VERSION" "$SIZE"
  done
done
