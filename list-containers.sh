#!/bin/bash
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
readonly NC='\033[0m' # No Color

printf "${CYAN}List of Docker containers${NC}\n"

#################################################################
## Usage
usage () {
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
  exit 0
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
  usage
fi
while getopts ":ahun:" opt; do
  case "$opt" in
    : ) printf "${RED}  Missing parameter for option -${OPTARG}${NC}\n"
        usage
        ;;
    a ) LIST_ALL=true
        ;;
    h ) usage
        ;;
    n ) if [[ "$OPTARG" == -* ]]; then
          printf "${RED}  Missing parameter for option -n${NC}\n"
          usage
        else
          NAME_FILTER=$OPTARG
        fi
        ;;
    u ) SHOW_UNHEALTHY=true
        ;;
   \? ) printf "${RED}  Unknown shorthand option: ${GREEN}-${OPTARG}${NC}\n"
        usage
        ;;
  esac
done
shift $((OPTIND - 1))


#################################################################
## Check Docker availability
if ! command -v docker &> /dev/null; then
  printf "${RED}Docker is not installed or not in PATH${NC}\n"
  exit 1
elif ! docker info &> /dev/null; then
  printf "${RED}Docker daemon is not running or user has no permission to access it${NC}\n"
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
printf "${GREEN}  %d containers exist in total${NC}\n" "$count"


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
    printf "${RED}  Missing name filter. Execution aborted${NC}\n"
    exit 1
  fi
  count=$(count_lines "$filtered_containers")
  if [[ "$count" -eq 0 ]]; then
    printf "${GREEN}  No matching containers found${NC}\n"
  else
    printf '%s\n' "$header"
    printf '%s\n' "$filtered_containers"
  fi
fi

printf '\n'
exit 0