#!/usr/bin/env bash
#
# Updating local Docker images
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

printf '%b\n' "${CYAN}Updating local Docker images${NC}"

#################################################################
## Script directory detection, change to it to ensure relative path works
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


#################################################################
## Usage
usage () {
  local exit_code=${1:-0}
  cat <<USAGE
  Usage: $0  [-ach] [-n <text>]
    -a  Update all images
    -c  Cleanup, remove orphan images and stopped containers
    -h  Display this usage information, ignoring other parameters
    -n  Name filter, update images which have <text> into image name
  Examples:
    $0  -a -n onecx -c  => Update all images, ignoring name filter, then remove all orphan images
    $0  -n onecx        => Check and retrieve new images if "onecx" is included in the image name
    $0  -n ui -c        => Update images and removing orphan images matching name filter
    $0  -c              => Remove orphaned images and images whose name contains <none>
USAGE
  exit "$exit_code"
}

## Count lines in a string, return 0 if the string is empty
count_lines () {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo 0
  else
    printf '%s\n' "$input" | wc -l | tr -d '[:space:]'
  fi
}

#################################################################
## Defaults
CLEANUP=false
CLEANUP_ONLY=false
ALL_IMAGES=false
NAME_FILTER=""


#################################################################
## Check options and parameter
if [[ "${1:-}" == "--help" ]]; then
  usage 0
fi
while getopts ":achn:" opt; do
  case "$opt" in
    : ) printf '  %b\n' "${RED}Missing parameter for option -${OPTARG}${NC}"
        usage 1
        ;;
    a ) ALL_IMAGES=true
        ;;
    c ) CLEANUP=true
        ;;
    n ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -n${NC}"
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


#################################################################
## Collect images
number_of_images=0
if [[ -n "$NAME_FILTER" && "$ALL_IMAGES" == "false" ]]; then
  IMAGES=$(docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ID}}" | grep -iF -- "$NAME_FILTER" || true)
else
  IMAGES=$(docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ID}}")
fi
## Check images
if [[ -z "$IMAGES" ]]; then
  printf '  %b\n' "${YELLOW}No images matched your filter ${GREEN}$NAME_FILTER${NC}"
  exit 0
fi
## Count images
if [[ -n "$IMAGES" ]]; then
  number_of_images=$(count_lines "$IMAGES")
fi


#################################################################
# In case no name filter was provided
if [[ -z "$NAME_FILTER" ]]; then
  if [[ "$CLEANUP" == "true" ]]; then
    CLEANUP_ONLY=true
  elif [[ "$ALL_IMAGES" == "false" ]]; then
    printf '  %b\n' "${YELLOW}Missing options: use -n for name filter, -a to update all images, -c to cleanup or -h for help.${NC}"
    exit 1
  fi
fi


#################################################################
# Process images
if [[ "$ALL_IMAGES" == "true" ]]; then
  printf '  %b\n' "${CYAN}Process ${GREEN}all ${CYAN}images${NC}, cleanup: ${GREEN}${CLEANUP}${NC}"
else
  printf '  %b\n' "${CYAN}Process ${GREEN}${number_of_images} ${CYAN}images${NC}, cleanup: ${GREEN}${CLEANUP}${NC}"
fi

# PULL
PULL_FAILURES=0
if [[ "$CLEANUP_ONLY" == "false" ]]; then
  if [[ "$ALL_IMAGES" == "true" ]]; then
    echo "$IMAGES" | awk -F'\t' '$2 != "<none>" {print $1":"$2}' | \
      xargs -P 4 -I {} sh -c 'docker pull "$1" || printf "    * $1" ' _ {}
  else
    current=0
    while IFS=$'\t' read -r repo tag id; do
      [[ -z "$repo" ]] && continue
      ((current++)) || true
      if [[ "$tag" != "<none>" ]]; then
        printf '    * [%d] %b\n' "$current" "${GREEN}$repo:$tag${NC}"
        docker pull "$repo:$tag" || { printf '    %b\n' "${RED}Failed to pull $repo:$tag${NC}"; ((PULL_FAILURES++)); }
      fi
    done <<< "$IMAGES"
  fi
fi

# CLEAN
if [[ "$CLEANUP" == "true" ]]; then
  printf '  %b\n' "${CYAN}Cleanup${NC}"
  if [[ "$ALL_IMAGES" == "true" ]]; then
    docker image prune -f || printf '  %b\n' "${RED}Failed to prune images${NC}"
    docker container prune -f || printf '  %b\n' "${RED}Failed to prune containers${NC}"
  fi
  while IFS=$'\t' read -r repo tag id; do
    [[ -z "$repo" ]] && continue
    if [[ "$tag" == "<none>" ]]; then
      printf '    * %b\n' "${CYAN}orphan: ${GREEN}$repo:$tag:$id${NC}"
      docker image rm -f "$id" || printf '     %b\n' "${RED}Failed to remove${NC}"
    fi
  done <<< "$IMAGES"
fi

# Summary with exit code 1 if there were pull failures
if [[ $PULL_FAILURES -gt 0 ]]; then
  printf '  %b\n' "${YELLOW}Finished with ${RED}${PULL_FAILURES}${NC} pull failures${NC}"
  exit 1
fi

printf "\n"
