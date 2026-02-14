#!/bin/sh
# Generate a 32 hex-character secret for MTProxy
# Usage: ./generate-secret.sh

secret=$(head -c 16 /dev/urandom | xxd -ps)
echo "$secret"
echo "" 1>&2
echo "Add to .env: SECRET=$secret" 1>&2
