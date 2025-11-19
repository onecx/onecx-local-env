#!/bin/bash
#
# List local Docker images
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Check local Docker images ${NC}"


#################################################################
## flags
usage () {
  cat <<USAGE
  Usage: $0  [-h] [-f <filter>] [-n <name-prefix>]
       -f  filter, see https://docs.docker.com/reference/cli/docker/image/ls/#filter
       -h  display this usage information, ignoring other parameters
       -n  name prefix
USAGE
  exit 0
}
usage_short () {
  cat <<USAGE
  Usage: $0  [-h] [-f <filter>] [-n <name-prefix>]
USAGE
}


#################################################################
## Defaults
ONECX_REPO_PATH="ghcr.io/onecx"
ONECX_ORGANIZATION="onecx"
GITHUB_REPO_TAG_BE="main-native"
GITHUB_REPO_TAG_FE="main"
VERSION_LABEL=samo.project.version
IMAGE_NAME_EXTENSION_UI=ui


#################################################################
## Check flags and parameter
while getopts ":hf:n:" opt; do
  case "$opt" in
        f ) 
            if [ -z "$OPTARG" ]; then
              echo -e "${RED}  Missing filter value${NC}"
              usage
            else
              FILTER=$OPTARG
            fi
            ;;
        n ) 
            if [ -z "$OPTARG"  ]; then
              echo -e "${RED}  Missing name prefix${NC}"
              usage
            else
              NAME_PREFIX=$OPTARG
            fi
            ;;
        h ) 
            usage ;; # print usage
       \? )
            echo -e "${RED}  Unknown shorthand flag: ${GREEN}-${OPTARG}${NC}" >&2
            usage ;;
  esac
done


set -e

#########################################
#### Start
usage_short
echo -e "  => OneCX registry path:\t\t${GREEN}${ONECX_REPO_PATH}${NC}"
echo -e "  => OneCX image version label:\t\t${GREEN}samo.project.version${NC}"


if [[ -n $FILTER ]]; then
  echo -e "  => Filter value:\t\t\t${GREEN}${FILTER}${NC}"
fi



#########################################
#### Parameter
if [[ -n $NAME_PREFIX ]]; then
  if [[ $NAME_PREFIX =~ "$ONECX_ORGANIZATION" ]]; then
    OLE_IMAGE_PREFIX=${ONECX_REPO_PATH}/$NAME_PREFIX
  else
    OLE_IMAGE_PREFIX=$NAME_PREFIX
  fi
  echo -e "  => Filtered image name prefix:\t${GREEN}${OLE_IMAGE_PREFIX}${NC}"
  IMAGES=$(docker image ls --format "{{.Repository}}" --filter "$FILTER" | grep "^${OLE_IMAGE_PREFIX}" | sort | uniq)
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
  echo -e "${RED}No local Docker images found ${FILTER_TEXT}${NC}"
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
  #########################################
  # REMOTE
  #   => this does not work completely at the moment
  #
  #IMAGE_TYPE=`echo $IMAGE | cut -d '-' -f3`
  #if [[ $IMAGE_TYPE == $IMAGE_NAME_EXTENSION_UI ]]; then
  #  IMAGE_TAG=$GITHUB_REPO_TAG_FE
  #else
  #  IMAGE_TAG=$GITHUB_REPO_TAG_BE
  #fi

  #MANIFEST=$(docker manifest inspect $IMAGE:$IMAGE_TAG 2>/dev/null)
  #if [ -z "$MANIFEST" ]; then
  #  echo -e "${RED}Could not retrieve manifest. Is the image public?${NC}"
  #  exit 1
  #fi

  DIGEST=$(echo "$MANIFEST" \
    | grep -o '"digest"[[:space:]]*:[[:space:]]*"sha256:[a-f0-9]\+"' \
    | head -n 1 | sed -E 's/.*"(sha256:[a-f0-9]+)".*/\1/')

  # Extract version label
  #REMOTE_VERSION=$(echo "$MANIFEST" | grep -o "\"$VERSION_LABEL\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed -E "s/.*: \"(.*)\"/\1/")

  #########################################
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
