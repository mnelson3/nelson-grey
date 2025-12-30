#!/usr/bin/env bash
# Scan workspace for credential artifacts and extract expiry dates where possible.
# Outputs CSV: inventory-credentials.csv

set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="/Users/marknelson/Circus/Repositories"
OUT_DIR="$ROOT_DIR/nelson-grey/inventory"
OUT_CSV="$OUT_DIR/inventory-credentials.csv"
TMP_DIR="/tmp/credentials-scan-$$"
mkdir -p "$OUT_DIR" "$TMP_DIR"

# CSV header
echo "repo,path,filename,type,expiry,notes" > "$OUT_CSV"

# Helpers
is_p12() { [[ "$1" =~ \.(p12|pfx)$ ]]; }
is_pem() { [[ "$1" =~ \.(pem|cer|crt)$ ]]; }
is_p8() { [[ "$1" =~ \.p8$ ]]; }
is_mobileprovision() { [[ "$1" =~ \.mobileprovision$ ]]; }

# Iterate files
find "$ROOT_DIR" -type f \(
  -iname "*.p12" -o -iname "*.pfx" -o -iname "*.pem" -o -iname "*.cer" -o -iname "*.crt" -o -iname "*.p8" -o -iname "*.mobileprovision" -o -iname "firebase-service-account-*.json" -o -iname "*.plist" -o -iname ".github-app-private-key.pem" 
\) | while read -r file; do
  repo=$(echo "$file" | sed -E "s#^$ROOT_DIR/([^/]+)/.*#\1#")
  filename=$(basename "$file")
  type="unknown"
  expiry=""
  notes=""

  if is_p12 "$file"; then
    type="p12"
    # Try to extract cert expiry - may require password. We'll attempt without password; if fails, note it.
    if openssl pkcs12 -in "$file" -nokeys -nodes -passin pass: 2>/dev/null | openssl x509 -noout -enddate >/dev/null 2>&1; then
      expiry=$(openssl pkcs12 -in "$file" -nokeys -nodes -passin pass: 2>/dev/null | openssl x509 -noout -enddate | sed 's/notAfter=//')
    else
      # try with temporary copy with no pass (best effort)
      notes="password-protected-or-unreadable"
    fi
  elif is_pem "$file"; then
    type="pem"
    if openssl x509 -in "$file" -noout -enddate >/dev/null 2>&1; then
      expiry=$(openssl x509 -in "$file" -noout -enddate | sed 's/notAfter=//')
    else
      notes="not-x509-pem-or-unreadable"
    fi
  elif is_p8 "$file"; then
    type="p8"
    notes="App Store Connect private key or other private key (no expiry)"
  elif is_mobileprovision "$file"; then
    type="mobileprovision"
    if security cms -D -i "$file" > "$TMP_DIR/provision.plist" 2>/dev/null; then
      # Try to read ExpirationDate from plist
      expiry=$(defaults read "$TMP_DIR/provision" ExpirationDate 2>/dev/null || true)
      if [ -z "$expiry" ]; then
        # Fallback to parsing XML
        expiry=$(plutil -convert xml1 -o - "$TMP_DIR/provision.plist" 2>/dev/null | xmllint --xpath "string(//key[.='ExpirationDate']/following-sibling::date[1])" - 2>/dev/null || true)
      fi
      if [ -z "$expiry" ]; then
        notes="could-not-parse-expiry"
      fi
    else
      notes="security-cms-failed"
    fi
  elif [[ "$filename" == firebase-service-account-*.json ]]; then
    type="firebase-service-account"
    # try to read client_email
    client_email=$(jq -r '.client_email // empty' "$file" 2>/dev/null || true)
    notes="client_email=$client_email"
  elif [[ "$filename" == *.plist ]]; then
    type="plist"
    notes="launch-agent or other plist"
  elif [[ "$filename" == .github-app-private-key.pem ]]; then
    type="github-app-key"
    notes="private key file (no expiry)"
  else
    type="other"
  fi

  # Escape commas
  notes_esc=$(echo "$notes" | sed 's/,/;/g')
  expiry_esc=$(echo "$expiry" | sed 's/,/;/g')

  echo "$repo,$file,$filename,$type,$expiry_esc,$notes_esc" >> "$OUT_CSV"

done

# Summarize
wc -l "$OUT_CSV" || true

echo "CSV written to: $OUT_CSV"

exit 0
