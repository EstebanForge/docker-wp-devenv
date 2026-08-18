#!/bin/bash

# SSL Certificate Setup Script
# Generates trusted local SSL certificates using mkcert

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
SSL_DIR="nginx-conf"

echo "🔒 Setting up SSL certificates for: $DOMAIN"

# Check if mkcert is installed
if ! command -v mkcert &>/dev/null; then
  echo "📦 Installing mkcert..."

  # Detect OS and install mkcert
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v dnf &>/dev/null; then
      # Fedora/RHEL
      sudo dnf install -y mkcert
    elif command -v apt &>/dev/null; then
      # Ubuntu/Debian
      sudo apt update && sudo apt install -y mkcert
    else
      echo "❌ Unsupported Linux distribution. Please install mkcert manually."
      echo "   Visit: https://github.com/FiloSottile/mkcert#installation"
      exit 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &>/dev/null; then
      brew install mkcert
    else
      echo "❌ Homebrew not found. Please install mkcert manually."
      exit 1
    fi
  else
    echo "❌ Unsupported operating system. Please install mkcert manually."
    exit 1
  fi
fi

# Create SSL directory
mkdir -p "$SSL_DIR"

# Install local CA
echo "🏛️  Installing local Certificate Authority..."
mkcert -install

# Generate certificates
echo "📜 Generating SSL certificates..."
mkcert -cert-file "$SSL_DIR/$DOMAIN.crt" -key-file "$SSL_DIR/$DOMAIN.key" "$DOMAIN" "www.$DOMAIN"

# Set proper permissions
chmod 600 "$SSL_DIR/$DOMAIN.key"
chmod 644 "$SSL_DIR/$DOMAIN.crt"

echo "✅ SSL certificates generated successfully!"
echo ""
echo "📋 Certificate Details:"
echo "   Domain: $DOMAIN"
echo "   Certificate: $SSL_DIR/$DOMAIN.crt"
echo "   Private Key: $SSL_DIR/$DOMAIN.key"
echo ""
echo "🔒 The certificates are now trusted by your browser!"
