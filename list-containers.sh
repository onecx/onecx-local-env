#!/usr/bin/env bash
#
# List of Docker containers, sorted alphabetically by the image names used.
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

printf '%b\n' "${CYAN}List of Docker containers${NC}"

#################################################################
## Script directory detection, change to it to ensure relative path works
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


#################################################################
## Usage
usage () {
  local exit_code=${1:-0}
  cat <<USAGE
  Usage: $0  [-ahu] [-n <text>]
    -a  List all containers
    -h  Display this usage information, ignoring other parameters
    -n  Name filter, list containers which have <text> into container name
    -u  Show unhealthy containers
  Examples:
    $0  -n theme     => List containers which have "theme" in the container name
    $0  -u           => List unhealthy containers
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
NAME_FILTER=""
UNHEALTHY_FILTER="(exited|unhealthy|dead|restarting)"
SHOW_UNHEALTHY=false
LIST_ALL=false

#################################################################
## Check options and parameter
if [[ "${1:-}" == "--help" ]]; then
  usage 0
fi
while getopts ":ahun:" opt; do
  case "$opt" in
    : ) printf '%b\n' "${RED}  Missing parameter for option -${OPTARG}${NC}"
        usage 1
        ;;
    a ) LIST_ALL=true
        ;;
    h ) usage 0
        ;;
    n ) if [[ "$OPTARG" == -* ]]; then
          printf '%b\n' "${RED}  Missing parameter for option -n${NC}"
          usage 1
        else
          NAME_FILTER=$OPTARG
        fi
        ;;
    u ) SHOW_UNHEALTHY=true
        ;;
   \? ) printf '%b\n' "${RED}  Unknown shorthand option: ${GREEN}-${OPTARG}${NC}"
        usage 1
        ;;
  esac
done
shift $((OPTIND - 1))


#################################################################
## Check Docker availability
if ! command -v docker &> /dev/null; then
  printf '%b\n' "${RED}Docker is not installed or not in PATH${NC}"
  exit 1
elif ! docker info &> /dev/null; then
  printf '%b\n' "${RED}Docker daemon is not running or user has no permission to access it${NC}"
  exit 1
fi


#################################################################
## Get all running Docker Compose containers
header=""
all_containers=""
output=$(docker compose ps -a --format 'table {{.ID}}\t{{.Service}}\t{{.Image}}\t{{.Status}}')
if [[ -n "$output" ]]; then
  header=$(printf '%s\n' "$output" | head -1)
  all_containers=$(printf '%s\n' "$output" | tail -n +2 | sort -k2)
fi
count=$(count_lines "$all_containers")
printf '  %b\n' "${GREEN}$count containers exist in total${NC}"


# Filter containers
if [[ "$count" -gt 0 ]]; then
  filtered_containers="$all_containers"
  if [[ -n "$NAME_FILTER" && "$SHOW_UNHEALTHY" = true ]]; then
    filtered_containers=$(printf '%s\n' "$all_containers" | grep -iF -- "$NAME_FILTER" | grep -iE -- "$UNHEALTHY_FILTER") || true
  elif [[ -n "$NAME_FILTER" ]]; then
    filtered_containers=$(printf '%s\n' "$all_containers" | grep -iF -- "$NAME_FILTER") || true
  elif [[ "$SHOW_UNHEALTHY" = true ]]; then
    filtered_containers=$(printf '%s\n' "$all_containers" | grep -iE -- "$UNHEALTHY_FILTER") || true
  elif [[ "$LIST_ALL" = false ]]; then
    printf '%b\n' "${RED}  Missing name filter. Execution aborted${NC}"
    exit 1
  fi
  count=$(count_lines "$filtered_containers")
  if [[ "$count" -eq 0 ]]; then
    printf '%b\n' "${GREEN}  No matching containers found${NC}"
  else
    printf '%s\n' "$header"
    printf '%s\n' "$filtered_containers"
  fi
fi

printf '\n'
