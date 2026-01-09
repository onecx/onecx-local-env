#!/bin/bash
set -euo pipefail

CERT_DIR=${1:-certs}                     # directory containing PEM certs (default: ./certs)
OUT_DIR=${2:-certs}                      # output dir for truststore (default: ./certs)
STORE_PASS=${3:-changeit}                # truststore password (default: changeit)

if [[ ! -d "$CERT_DIR" ]]; then
  echo "❌ Certificate directory '$CERT_DIR' not found. Provide the path, e.g.:"
  echo "   ./setup-truststore.sh /path/to/certs"
  exit 1
fi

# Check if there are any certificates
cert_count=$(find "$CERT_DIR" -maxdepth 1 -type f \( -name "*.crt" -o -name "*.pem" \) | wc -l)
if [[ $cert_count -eq 0 ]]; then
  echo "❌ No certificate files (*.crt or *.pem) found in '$CERT_DIR'"
  exit 1
fi

mkdir -p "$OUT_DIR"

TRUSTSTORE_PATH="$OUT_DIR/truststore.jks"

# Create new truststore or remove existing one
if [[ -f "$TRUSTSTORE_PATH" ]]; then
  echo "ℹ️ Removing existing truststore at $TRUSTSTORE_PATH"
  rm -f "$TRUSTSTORE_PATH"
fi

echo "✅ Creating truststore at $TRUSTSTORE_PATH"

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
