#!/bin/bash
#
# Update local Docker images
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

printf "${CYAN}Update local Docker images${NC}\n"


#################################################################
## Usage
usage () {
  cat <<USAGE
  Usage: $0  [-ch] [-n <text>]
    -c  Cleanup, remove orphan images
    -h  Display this usage information, ignoring other parameters
    -n  Name filter, update images which have <text> into image name
  Examples:
    $0               => If no name filter is specified, additional confirmation is required
    $0  -n onecx     => Check and retrieve new images if "onecx" is included in the image name
    $0  -n ui        => Check and retrieve new images if "ui" is included in the image name
    $0  -c           => Remove orphaned images and images whose name contains <none>
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-ch] [-n <text>]
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
CLEANUP=false
NAME_FILTER=""


#################################################################
## Check flags and parameter
while getopts ":hcn:" opt; do
  case "$opt" in
    c ) CLEANUP=true
        ;;
    n )
        if [[ -z "$OPTARG" ]]; then
          printf "${RED}  Missing image name${NC}\n"
          usage
        else
          NAME_FILTER=$OPTARG
        fi
        ;;
    h ) usage 
        ;;
   \? ) printf "${RED}  Unknown shorthand flag: ${GREEN}-${OPTARG}${NC}\n"
        usage
        ;;
  esac
done


usage_short


#################################################################
## Collect images
if [ -n "$NAME_FILTER" ]; then
  IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}" | grep -E "$NAME_FILTER" || true)
else
  IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}")
fi
## Check images
if [ -z "$IMAGES" ]; then
  printf "  No images matched your filter ${GREEN}$NAME_FILTER${NC}.\n"
  exit 0
fi
## Count images
number_of_images=$(echo "$IMAGES" | wc -l)

# Confirmation?
if [ -z "$NAME_FILTER" ]; then
  confirm "  No filter specified. ${number_of_images} images could be affected. Do you really want to continue?"
fi


#################################################################
# Process images
printf "${CYAN}Process ${number_of_images} images${NC}\n"


while IFS= read -r IMAGE; do
  [[ -z "$IMAGE" ]] && continue
  IFS=:
  set $IMAGE   # split by IFS separator to $1...$n

  if [[ "$2" =~ "<none>" ]]; then
    ORPHAN_TEXT="  * ${GREEN}$1:$2:$3  orphan${NC}"
    if [[ $CLEANUP == "true" ]]; then
      printf "$ORPHAN_TEXT  remove\n"
      docker image rm "$3" || printf "${RED}    Failed to remove${NC}\n"
    else
      printf "$ORPHAN_TEXT  skip pulling\n"
    fi
  else
    printf "  * ${GREEN}$1:$2${NC}\n"
    docker pull "$1:$2" || printf "    ${RED}Failed to pull $1:$2${NC}\n"
  fi
done <<< "$IMAGES"
