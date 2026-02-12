#!/usr/bin/env bash
#
# Setup Java Truststore with custom certificates
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

printf '%b\n' "${CYAN}Setup Java Truststore with Custom Certificates${NC}"

#################################################################
## Script directory detection, change to it to ensure relative path works
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


#################################################################
## Usage
usage () {
  local exit_code=${1:-0}
  printf '  %b\n' \
  "Usage: $0  [-h] [-d <directory>] [-p <password>]
    -d  Certificate directory, default: './certs'
    -h  Display this help and exit
    -p  Truststore password, length > 5, default: 'trustjava'
  Examples:
    $0                  => Create truststore from ./certs with default password
    $0  -d /path/certs  => Use custom certificate directory
    $0  -p mypassword   => Use custom truststore password
  "
  exit "$exit_code"
}


#################################################################
## Defaults
CERT_DIR=./certs               # Directory containing PEM certs
STORE_PASS="trustjava"         # Password for the Java Truststore


#################################################################
## Check options and parameter
if [[ "${1:-}" == "--help" ]]; then
  usage 0
fi
while getopts ":hd:p:" opt; do
  case "$opt" in
    : ) printf '  %b\n' "${RED}Missing parameter for option -${OPTARG}${NC}"
        usage 1
        ;;
    d ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -d${NC}"
          usage 1
        else
          CERT_DIR=$OPTARG
        fi
        ;;
    h ) usage 0
        ;;
    p ) if [[ "$OPTARG" == -* ]]; then
          printf '  %b\n' "${RED}Missing parameter for option -p${NC}"
          usage 1
        elif [[ ${#OPTARG} -lt 6 ]]; then
          printf '  %b\n' "${RED}Password must be at least 6 characters (keytool requirement)${NC}"
          usage 1
        else
          STORE_PASS=$OPTARG
        fi
        ;;
    \?) printf '  %b\n' "${RED}Unknown option: -${OPTARG}${NC}"
        usage 1
        ;;
  esac
done
shift $((OPTIND -1))


#################################################################
## Configuration
TRUSTSTORE_PATH="$CERT_DIR/truststore.jks"

printf '  %b\t%b\n'   "=> Certificate directory:" "${GREEN}${CERT_DIR}${NC}"
printf '  %b\t\t%b\n' "=> Truststore path:" "${GREEN}${TRUSTSTORE_PATH}${NC}"
printf '  %b\t%b\n'   "=> Truststore password:" "${GREEN}${STORE_PASS}${NC} (length: ${#STORE_PASS})"


#################################################################
## Check if directory exists
if [[ ! -d "$CERT_DIR" ]]; then
  printf '  %b\n' "${RED}Certificate directory '$CERT_DIR' not found. Please create and store your certificates there.${NC}"
  exit 1
fi
## Check keytool availability
if ! command -v keytool &>/dev/null; then
  printf '  %b\n' "${RED}keytool not found. Please install a JDK.${NC}"
  exit 1
fi

#################################################################
## Check if there are any certificates
cert_count=$(find "$CERT_DIR" -maxdepth 1 -type f \( -name "*.crt" -o -name "*.pem" \) | wc -l)
if [[ $cert_count -eq 0 ]]; then
  printf '  %b\n' "${RED}No certificate files (*.crt or *.pem) found in '$CERT_DIR'${NC}"
  exit 1
fi


#################################################################
## Cleanup: removing existing Truststore
if [[ -f "$TRUSTSTORE_PATH" ]]; then
  printf '  %b\n' "${YELLOW}Removing existing truststore at $TRUSTSTORE_PATH${NC}"
  rm -f "$TRUSTSTORE_PATH"
fi

if [[ -d "$TRUSTSTORE_PATH" ]]; then
  printf '  %b\n' "${YELLOW}Removing existing truststore directory at $TRUSTSTORE_PATH${NC}"
  sudo rm -rf "$TRUSTSTORE_PATH"
fi


#################################################################
## Create truststore and import certificates
printf '  %b\n' "${GREEN}Creating truststore and importing certificates${NC}"

## Show certificate count
printf '  %b\n' "Found ${GREEN}$cert_count${NC} certificate(s) to import"

while IFS= read -r cert_file; do
  filename=$(basename "$cert_file")
  alias="${filename%.*}"  # Remove extension to use as alias
  
  ## Wrap keytool with error handling
  if ! keytool -importcert -noprompt -trustcacerts \
               -alias "$alias" \
               -file "$cert_file" \
               -keystore "$TRUSTSTORE_PATH" \
               -storepass "$STORE_PASS"; then
    printf '  %b\n' "${RED}Failed to import: $filename${NC}"
    continue  # or exit 1 for strict mode
  fi  
  
  printf '  %b\n' "${CYAN}Imported: ${GREEN}$filename${NC} (alias: $alias)"
done < <(find "$CERT_DIR" -maxdepth 1 -type f \( -name "*.crt" -o -name "*.pem" \) | sort)

printf '  %b\n' "${GREEN}Truststore created successfully${NC}"

printf '\n'
