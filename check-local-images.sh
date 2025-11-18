#!/bin/bash
#
# List versions of local Docker images matching a name prefix
#

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

ONECX_REPO_PATH="ghcr.io/onecx"
ONECX_ORGANIZATION="onecx"
GITHUB_REPO_TAG_BE="main-native"
GITHUB_REPO_TAG_FE="main"
VERSION_LABEL=samo.project.version
IMAGE_NAME_EXTENSION_UI=ui

usage () {
  cat <<USAGE
  Usage: $0  [ <image name prefix for filtering> ]
USAGE
}

set -e

echo -e "${CYAN}Check local Docker images ${NC}"
usage
echo -e "  => OneCX registry path:\t\t${GREEN}${ONECX_REPO_PATH}${NC}"


#########################################
#### Read parameter
if [[ $# == 1 ]]; then
  if [[ $1 =~ "$ONECX_ORGANIZATION" ]]; then
    OLE_IMAGE_PREFIX=${ONECX_REPO_PATH}/$1
  else
    OLE_IMAGE_PREFIX=$1
  fi
  echo -e "  => Filtered image name prefix:\t${GREEN}${OLE_IMAGE_PREFIX}${NC}"
  IMAGES=$(docker images --format "{{.Repository}}" | grep "^${OLE_IMAGE_PREFIX}" | sort | uniq)
else
  IMAGES=$(docker images --format "{{.Repository}}" | sort | uniq)
fi

PRINT_FORMAT="%-43s %-13s %-14s %-16s\n"

echo -e "  => OneCX image version label:\t\t${GREEN}samo.project.version${NC}"


#########################################
#### Get local images

if [ -z "$IMAGES" ]; then
  echo -e "${RED}No local Docker images found${NC}"
  exit 0
fi

echo
PRINT_FORMAT="%-43s %-13s %-14s %-16s\n"
printf "$PRINT_FORMAT" "IMAGE" "MAIN TAG" "LOCAL ID" "VERSION"
echo   "------------------------------------------------------------------------------------"


#########################################
#### LIST IMAGES
#########################################
for IMAGE in $IMAGES; do
  # REMOTE
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

  # LOCAL
  docker images $IMAGE --format "{{.Repository}} {{.Tag}} {{.ID}}" | while read -r REPO TAG ID; do
    # Read version label
    LOCAL_VERSION=$(docker inspect --format "{{ index .Config.Labels \"$VERSION_LABEL\" }}" "$ID" 2>/dev/null)
  
    # No label → display placeholder
    if [ -z "$LOCAL_VERSION" ] || [ "$LOCAL_VERSION" = "<no value>" ]; then
      LOCAL_VERSION="(no Label)"
    fi  
    printf "$PRINT_FORMAT" "$REPO" "$TAG" "$ID" "$LOCAL_VERSION"
  done
done
