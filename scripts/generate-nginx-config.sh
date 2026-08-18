#!/bin/bash

# Generate Nginx Configuration Script
# Creates nginx.conf from template using .env variables

set -e

# Load environment variables from .env file
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
else
  echo "❌ .env file not found! Please create it first."
  exit 1
fi

TEMPLATE_FILE="nginx-conf/nginx.conf.template"
OUTPUT_FILE="nginx-conf/nginx.conf"

echo "🔧 Generating Nginx configuration..."

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "❌ Template file $TEMPLATE_FILE not found!"
  exit 1
fi

# Replace environment variables in template
# shellcheck disable=SC2016
envsubst '${WP_DOMAIN}' <"$TEMPLATE_FILE" >"$OUTPUT_FILE"

echo "✅ Nginx configuration generated: $OUTPUT_FILE"
echo "   Domain: ${WP_DOMAIN:-wp.localhost}"
