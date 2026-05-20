#!/bin/bash

set -e

CERT_DIR="/usr/share/elasticsearch/config/certs"
CA_FILE="$CERT_DIR/ca.crt"
P12_FILE="$CERT_DIR/elastic-certificates.p12"
CRT_FILE="$CERT_DIR/instance.crt"
KEY_FILE="$CERT_DIR/instance.key"

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Step 1: Generate CA certificate if it doesn't exist
if [ ! -f "$CA_FILE" ]; then
    echo "Step 1: Generating CA certificate..."
    bin/elasticsearch-certutil ca \
        --out "$CA_FILE" \
        --pass ''
    echo "CA certificate generated: $CA_FILE"
fi

# Step 2: Generate signed certificate using the CA
if [ ! -f "$P12_FILE" ]; then
    echo "Step 2: Generating signed certificate with correct hostname..."
    bin/elasticsearch-certutil cert \
        --name elasticsearch-dina \
        --dns elasticsearch-dina,elasticsearch,instance,localhost \
        --ip 127.0.0.1 \
        --ca "$CA_FILE" \
        --ca-pass '' \
        --out "$P12_FILE" \
        --pass ''
    echo "Signed certificate generated: $P12_FILE"
fi

# Step 3: Convert PKCS12 to PEM format if not already done
if [ ! -f "$CRT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Step 3: Converting PKCS12 to PEM format..."
    
    # Extract server certificate
    openssl pkcs12 -in "$P12_FILE" -clcerts -nokeys -out "$CRT_FILE" -passin pass:
    
    # Extract private key
    openssl pkcs12 -in "$P12_FILE" -nocerts -nodes -out "$KEY_FILE" -passin pass:
    
    # Set correct permissions
    chmod 644 "$CRT_FILE" "$KEY_FILE" "$CA_FILE"

    echo "PEM certificates generated:"
    echo "  - CA: $CA_FILE"
    echo "  - Certificate: $CRT_FILE"
    echo "  - Key: $KEY_FILE"
fi

# Step 4: Verify certificate
echo ""
echo "=== Certificate Details ==="
echo "Subject:"
openssl x509 -in "$CRT_FILE" -noout -subject
echo ""
echo "Issuer:"
openssl x509 -in "$CRT_FILE" -noout -issuer
echo ""
echo "Validity:"
openssl x509 -in "$CRT_FILE" -noout -dates
echo ""
echo "Subject Alternative Names:"
openssl x509 -in "$CRT_FILE" -noout -text | grep -A1 "Subject Alternative Name" || echo "No SANs found"
echo ""
echo "=== Starting Elasticsearch ==="

# Call the original entrypoint
/usr/local/bin/docker-entrypoint.sh eswrapper
