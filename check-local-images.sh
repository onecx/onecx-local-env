#!/bin/bash
#
# List local Docker images
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e
#   * Replaced @(...) with Regex =~ ^(...)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}List local Docker images with tag, version and size${NC}"


#################################################################
## flags
usage () {
  cat <<USAGE
  Usage: $0  [-h] [-f <image filter>] [-n <text>]
       -f  Image filter, see https://docs.docker.com/reference/cli/docker/image/ls/#filter
       -h  Display this usage information, ignoring other parameters
       -n  Name filter, find images which have <text> into image name
  Examples:
    $0  -n onecx            => List images filtered by 'onecx' in image name
    $0  -f dangling=true    => List images filtered by "dangling=true"
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h] [-f <filter>] [-n <text>]
USAGE
}


#################################################################
## Defaults
ONECX_REPO_PATH="ghcr.io/onecx"
VERSION_LABEL=samo.project.version


#################################################################
## Check flags and parameter
while getopts ":hf:n:" opt; do
  case "$opt" in
        f ) 
            if [ -z "$OPTARG" ]; then
              printf "${RED}  Missing filter value${NC}\n"
              usage
            else
              FILTER=$OPTARG
            fi
            ;;
        n ) 
            if [ -z "$OPTARG"  ]; then
              printf "${RED}  Missing image name${NC}\n"
              usage
            else
              NAME_FILTER=$OPTARG
            fi
            ;;
        h ) 
            usage ;; # print usage
       \? )
            printf "${RED}  Unknown shorthand flag: ${GREEN}-${OPTARG}${NC}\n"
            usage ;;
  esac
done


usage_short

set -e

printf "  => OneCX image version label:\t\t${GREEN}samo.project.version${NC}\n"

#########################################
#### Parameter
if [[ -n $FILTER ]]; then
  printf "  => Filter value:\t\t\t${GREEN}${FILTER}${NC}\n"
fi

if [[ -n $NAME_FILTER ]]; then
  printf "  => Filtered image name prefix:\t${GREEN}${NAME_FILTER}${NC}\n"
  IMAGES=$(docker image ls --format "{{.Repository}}" --filter "$FILTER" | grep "${NAME_FILTER}" | sort | uniq)
else
  IMAGES=$(docker image ls --format "{{.Repository}}"  --filter "$FILTER" | sort | uniq)
fi

PRINT_FORMAT="%-43s %-13s %-14s %-16s\n"


#########################################
#### Check existence
if [ -z "$IMAGES" ]; then
  if [ -n "$FILTER" ]; then
    FILTER_TEXT="using filter value"
  fi
  printf "${RED}No local Docker images found ${FILTER_TEXT}${NC}\n"
  exit 0
fi

#########################################
#### Get local images
echo
PRINT_FORMAT="%-43s %-13s %-14s %-16s %-16s\n"
printf "$PRINT_FORMAT" "IMAGE" "TAG" "LOCAL ID" "VERSION" "SIZE"
echo   "-------------------------------------------------------------------------------------------------"


#########################################
#### LIST IMAGES
#########################################
for IMAGE in $IMAGES; do
  # LOCAL
  docker images $IMAGE --format "{{.Repository}} {{.Tag}} {{.ID}} {{.Size}}" | while read -r REPO TAG ID SIZE; do
    # Read version label
    LOCAL_VERSION=$(docker inspect --format "{{ index .Config.Labels \"$VERSION_LABEL\" }}" "$ID" 2>/dev/null)
  
    # No label → display placeholder
    if [ -z "$LOCAL_VERSION" ] || [ "$LOCAL_VERSION" = "<no value>" ]; then
      LOCAL_VERSION="(no Label)"
    fi  
    printf "$PRINT_FORMAT" "$REPO" "$TAG" "$ID" "$LOCAL_VERSION" "$SIZE"
  done
done
