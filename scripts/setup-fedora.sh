#!/bin/bash

# Fedora 42 Docker WordPress Setup Script
# Handles permissions, SELinux, and directory creation

set -e

echo "🐧 Setting up WordPress Docker environment for Fedora 42..."

# Check if running on Fedora
if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
  echo "⚠️  Warning: This script is optimized for Fedora. Proceeding anyway..."
fi

# Create required directories
echo "📁 Creating project directories..."
mkdir -p src/{wp-core,themes,plugins,uploads,mu-plugins}
mkdir -p php-conf
mkdir -p nginx-conf

# Set proper ownership (current user)
echo "👤 Setting directory ownership..."
sudo chown -R $USER:$USER src/
sudo chown -R $USER:$USER php-conf/
sudo chown -R $USER:$USER nginx-conf/

# Set proper permissions for WordPress
echo "🔐 Setting directory permissions..."
# WordPress needs write access to uploads and potential plugin/theme management
find src/ -type d -exec chmod 775 {} \;
find src/ -type f -exec chmod 664 {} \;
# Ensure uploads directory is writable by WordPress
chmod -R 775 src/uploads/
# Make scripts executable
chmod 755 scripts/

# SELinux contexts for Docker volumes
echo "🛡️  Configuring SELinux contexts..."
if command -v setsebool >/dev/null 2>&1; then
  # Allow container access to user content
  sudo setsebool -P container_manage_cgroup on

  # Set proper SELinux contexts
  sudo chcon -Rt container_file_t src/ 2>/dev/null || echo "ℹ️  SELinux context setting skipped (may not be enabled)"
  sudo chcon -Rt container_file_t php-conf/ 2>/dev/null || echo "ℹ️  SELinux context setting skipped"
  sudo chcon -Rt container_file_t nginx-conf/ 2>/dev/null || echo "ℹ️  SELinux context setting skipped"
  sudo chcon -Rt container_file_t scripts/ 2>/dev/null || echo "ℹ️  SELinux context setting skipped"
else
  echo "ℹ️  SELinux tools not found, skipping SELinux configuration"
fi

# Check Docker daemon status
echo "🐳 Checking Docker status..."
if ! systemctl is-active --quiet docker; then
  echo "🔄 Starting Docker daemon..."
  sudo systemctl start docker
  sudo systemctl enable docker
fi

# Add user to docker group if not already
if ! groups $USER | grep -q docker; then
  echo "👥 Adding user to docker group..."
  sudo usermod -aG docker $USER
  echo "⚠️  You need to log out and back in for docker group changes to take effect"
  echo "   Or run: newgrp docker"
fi

# Create placeholder files to prevent permission issues
echo "📝 Creating placeholder files..."
touch src/themes/.gitkeep
touch src/plugins/.gitkeep
touch src/uploads/.gitkeep
touch src/mu-plugins/.gitkeep

echo "✅ Fedora 42 setup completed!"
echo ""
echo "🔧 If you encounter permission issues:"
echo "   - Run: sudo chown -R $USER:$USER src/"
echo "   - Or run: sudo chmod -R 755 src/"
echo ""
echo "🛡️  SELinux notes:"
echo "   - Volume mounts use :Z flag for proper labeling"
echo "   - If issues persist, check: sudo ausearch -m avc -ts recent"
