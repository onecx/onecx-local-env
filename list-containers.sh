#!/bin/bash
#
# List of Docker containers, sorted alphabetically by the image names used.
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

printf "${CYAN}List of Docker containers${NC}\n"

#################################################################
## Usage
usage () {
  cat <<USAGE
  Usage: $0  [-hu] [-n <text>]
    -h  Display this usage information, ignoring other parameters
    -n  Name filter, list containers which have <text> into container name
    -u  Show unhealthy containers
  Examples:
    $0               => If no name filter is specified, additional confirmation is required
    $0  -n theme     => List containers which have "theme" in the container name
    $0  -u           => List unhealthy containers
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-hu] [-n <text>]
USAGE
}
confirm() {
  read -p "$1 (y/N): " answer
  case "$answer" in
    [yY]* ) ;;
    * ) printf "${GREEN}  Execution aborted${NC}\n"
        exit 1
        ;;
  esac
}


#################################################################
## Defaults
NAME_FILTER=""
SHOW_UNHEALTHY=false

#################################################################
## Check options and parameter
while getopts ":hun:" opt; do
  case "$opt" in
    : ) printf "${RED}  Missing paramter for option -${OPTARG}${NC}\n"
        usage
        ;;
    n ) if [[ "$OPTARG" == -* ]]; then
          printf "${RED}  Missing paramter for option -n${NC}\n"
          usage
        else
          NAME_FILTER=$OPTARG
        fi
        ;;
    h ) usage
        ;;
    u ) SHOW_UNHEALTHY=true
        ;;
   \? ) printf "${RED}  Unknown shorthand option: ${GREEN}-${OPTARG}${NC}\n"
        usage
        ;;
  esac
done

usage_short



# print header only
# \t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}
header=`docker compose ps --format 'table {{.ID}}\t{{.Service}}\t{{.Image}}\t{{.Status}}'  | head -1`

# print without header and sorted by image name
cmd=`docker compose ps -a --format '{{.ID}} \t{{.Service}} \t{{.Image}} \t{{.Status}}' | sort -k2 | column -t -s $'\t'`

if [ -n "$NAME_FILTER" ]; then
  printf "%s\n" "$header"
  printf "%s\n" "$cmd" | grep -i "$NAME_FILTER"
elif [ "$SHOW_UNHEALTHY" = true ]; then
  printf "%s\n" "$header"
  printf "%s\n" "$cmd" | grep -i unhealthy
else
  confirm "No name filter specified. Do you want to list all containers?"
  printf "%s\n" "$header"
  printf "%s\n" "$cmd"
fi

printf "\n"