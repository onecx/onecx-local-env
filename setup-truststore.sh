#!/bin/bash
#
# Setup Java Truststore with custom certificates
#
# For macOS Bash compatibility:
#   * Use printf instead of echo -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


set -euo pipefail

CERT_DIR=./certs               # Directory containing PEM certs
STORE_PASS="trustjava"         # Password for the Java Truststore
TRUSTSTORE_PATH="$CERT_DIR/truststore.jks"

printf "${CYAN}Setup Java Truststore with custom certificates in ${GREEN}$CERT_DIR${NC}\n"

# Check if directory exists
if [[ ! -d "$CERT_DIR" ]]; then
  printf "  ❌ Certificate directory '$CERT_DIR' not found. Please create and store your certificates there.\n"
  exit 1
fi

# Check if there are any certificates
cert_count=$(find "$CERT_DIR" -maxdepth 1 -type f \( -name "*.crt" -o -name "*.pem" \) | wc -l)
if [[ $cert_count -eq 0 ]]; then
  printf "  ❌ No certificate files (*.crt or *.pem) found in '$CERT_DIR'\n"
  exit 1
fi


# Cleanup: removing existing Truststore (as file)
if [[ -f "$TRUSTSTORE_PATH" ]]; then
  printf "  ℹ️ Removing existing truststore at $TRUSTSTORE_PATH\n"
  rm -f "$TRUSTSTORE_PATH"
fi

# Cleanup: removing existing Truststore (as directory, in case of misconfiguration)
if [[ -d "$TRUSTSTORE_PATH" ]]; then
  printf "  ℹ️ Removing existing truststore at $TRUSTSTORE_PATH\n"
  sudo rm -rf "$TRUSTSTORE_PATH"
fi


printf "  ✅ Creating truststore at ${GREEN}$TRUSTSTORE_PATH${NC} and import certificates\n"
# Import all certificates
while IFS= read -r cert_file; do
  filename=$(basename "$cert_file")
  alias="${filename%.*}"  # Remove extension to use as alias
  
  keytool -importcert -noprompt -trustcacerts \
    -alias "$alias" \
    -file "$cert_file" \
    -keystore "$TRUSTSTORE_PATH" \
    -storepass "$STORE_PASS"
done < <(find "$CERT_DIR" -maxdepth 1 -type f \( -name "*.crt" -o -name "*.pem" \) | sort)
