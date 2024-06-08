#!/bin/bash

echo "Starting SSL Proxy Test..."

# Paths to certificate and key files
CERT_PATH="/Users/josephmccraw/Library/Containers/com.ShowBlender.JoeProxy/Data/Documents/certificate.crt"
PEM_PATH="/Users/josephmccraw/Library/Containers/com.ShowBlender.JoeProxy/Data/Documents/privateKey.pem"

echo "Verifying the certificate and PEM files..."

# Check if certificate and PEM files exist
if [[ -f "$CERT_PATH" && -f "$PEM_PATH" ]]; then
    echo "Certificate and PEM files are present."
else
    echo "Certificate and/or PEM files are missing."
    exit 1
fi

echo "Testing the proxy request..."
curl --proxy-insecure -v -x http://localhost:443 https://example.com

echo "SSL Proxy Test completed."