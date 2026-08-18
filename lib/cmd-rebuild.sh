#!/bin/bash
# Full rebuild script: stop containers, remove them, rebuild images, and start fresh.

set -e # Exit immediately if a command exits with a non-zero status.

# Get the directory where this script is located (should be project root)
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔄 Starting full rebuild process..."

# Change to the project root directory to ensure docker-compose finds its file
cd "${PROJECT_ROOT_DIR}" || exit

# Step 1: Stop all running containers
echo "🛑 Stopping all Docker containers..."
if docker-compose down --remove-orphans; then
    echo "✅ All containers stopped successfully"
else
    echo "⚠️  Warning: Some containers might not have been running"
fi

# Step 2: Remove all containers and volumes to ensure clean state
echo "🗑️  Removing all containers, networks, and volumes..."
if docker-compose down -v --remove-orphans; then
    echo "✅ All containers, networks, and volumes removed"
else
    echo "⚠️  Warning: Some resources might not have been removed"
fi

# Step 3: Remove all built images to force rebuild
echo "🔨 Removing all built Docker images..."
if docker-compose down --rmi all --remove-orphans; then
    echo "✅ All Docker images removed"
else
    echo "⚠️  Warning: Some images might not have been removed"
fi

# Step 4: Check if Docker daemon is running, try to start if not
if ! docker info >/dev/null 2>&1; then
  echo "🔄 Docker daemon is not running. Attempting to start Docker..."
  if command -v systemctl >/dev/null 2>&1; then
    if sudo systemctl start docker; then
      echo "   Docker daemon started via systemctl."
      # Wait for Docker to be ready
      for _ in {1..10}; do
        if docker info >/dev/null 2>&1; then
          break
        fi
        sleep 1
      done
      if ! docker info >/dev/null 2>&1; then
        echo "🔴 Error: Docker daemon did not start successfully."
        exit 1
      fi
    else
      echo "🔴 Error: Failed to start Docker daemon with systemctl."
      exit 1
    fi
  else
    echo "🔴 Error: Docker is not running and systemctl is not available. Please start Docker manually."
    exit 1
  fi
fi

# Step 5: Force rebuild all images and start containers
echo "🏗️  Rebuilding all Docker images and starting containers..."
if docker-compose up --build -d; then
    echo "✅ All images rebuilt and containers started successfully"
else
    echo "🔴 Error: Failed to rebuild and start containers"
    exit 1
fi

# Step 6: Reset permissions flag to force fresh permission setup
PERMISSION_FLAG_FILE="${PROJECT_ROOT_DIR}/.permissions_set"
if [ -f "${PERMISSION_FLAG_FILE}" ]; then
    echo "🔄 Resetting permissions flag to force fresh setup..."
    rm -f "${PERMISSION_FLAG_FILE}"
fi

# Step 6.5: Remove any wp-content directory that might exist in wp-core
echo "🗑️ Removing any existing wp-content directory from wp-core..."
if [ -d "${PROJECT_ROOT_DIR}/src/wp-core/wp-content" ]; then
    rm -rf "${PROJECT_ROOT_DIR}/src/wp-core/wp-content"
    echo "   wp-content directory removed from wp-core"
else
    echo "   No wp-content directory found in wp-core"
fi

# Step 7: Run the start script to handle permissions and WordPress setup
echo "🚀 Running start script for permissions and WordPress setup..."
if bash "${PROJECT_ROOT_DIR}/lib/cmd-start.sh"; then
    echo "✅ Start script completed successfully"
else
    echo "🔴 Error: Start script failed"
    exit 1
fi

echo "🔍 Verifying wp-content bind mount..."
if docker-compose exec -T php test -d /var/www/html/wp-content; then
  echo "   wp-content directory present inside container."
else
  echo "⚠️  wp-content directory missing inside container; ensure ./src/app exists."
fi

echo ""
echo "🎉 Full rebuild completed successfully!"
echo "   All containers have been stopped, removed, rebuilt from scratch, and started fresh."
echo "   Permissions have been reset and reapplied."
echo "   WordPress setup has been re-run if needed."
echo "   Volume mounts have been verified."
echo ""
echo "   Your environment is now in a completely fresh state."
