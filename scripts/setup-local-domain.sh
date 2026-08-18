#!/bin/bash

# Local Domain Setup Script
# Configures custom domain for WordPress Docker development from .env file

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

DOMAIN="${WP_DOMAIN:-wp.localhost}"
HOSTS_FILE="/etc/hosts"

echo "🌐 Setting up local domain: $DOMAIN"

# Check if domain already exists in hosts file
if grep -q -w "$DOMAIN" "$HOSTS_FILE" 2>/dev/null; then
  echo "✅ Domain $DOMAIN already configured in $HOSTS_FILE"
else
  echo "📝 Adding $DOMAIN to $HOSTS_FILE"
  echo "127.0.0.1    $DOMAIN" | sudo tee -a "$HOSTS_FILE" >/dev/null
  echo "✅ Domain $DOMAIN added to $HOSTS_FILE"
fi

# Verify the entry
echo ""
echo "🔍 Current hosts file entries for $DOMAIN:"
grep -w "$DOMAIN" "$HOSTS_FILE" || echo "No whole-word entries found for $DOMAIN"

echo ""
echo "✅ Local domain setup completed!"
echo ""
echo "🔧 To remove the domain later:"
echo "   sudo sed -i '/$DOMAIN/d' $HOSTS_FILE"
