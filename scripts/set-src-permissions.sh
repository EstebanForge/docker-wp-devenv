#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SRC_DIR="${PROJECT_ROOT_DIR}/src"

echo "🚀 Starting host permission setup for '${SRC_DIR}'..."

# Check if src directory exists
if [ ! -d "${SRC_DIR}" ]; then
  echo "❌ Error: Directory '${SRC_DIR}' does not exist. Please create it first or ensure your docker-compose setup creates it."
  exit 1
fi

# Navigate to project root for docker-compose commands
cd "${PROJECT_ROOT_DIR}"

# 1. Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: docker-compose could not be found. Please install it and ensure it's in your PATH."
    exit 1
fi

# 2. Check if wordpress service is running
echo "🔎 Checking if 'wordpress' service is running..."
if ! docker-compose ps wordpress 2>/dev/null | grep -q "Up"; then
    echo "⚠️ 'wordpress' service is not running or not found. Attempting to start services (wordpress, db)..."
    docker-compose up -d wordpress db # Start only necessary services if not up
    sleep 8 # Give them a moment to start
    if ! docker-compose ps wordpress 2>/dev/null | grep -q "Up"; then
        echo "❌ Error: 'wordpress' service could not be started or is not running. Please ensure your Docker environment is correctly set up and services are running."
        exit 1
    fi
fi
echo "✅ 'wordpress' service is running."

# 3. Get GID of www-data user from wordpress container
echo "🔎 Retrieving GID for 'www-data' user from 'wordpress' container..."
WWW_DATA_GID=$(docker-compose exec -T wordpress id -g www-data 2>/dev/null | tr -d '\r')

if [ -z "${WWW_DATA_GID}" ] || ! [[ "${WWW_DATA_GID}" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Could not retrieve a valid GID for 'www-data' from the 'wordpress' container."
    echo "   Please check if the 'wordpress' container is running correctly and the 'www-data' user exists."
    exit 1
fi
echo "✅ GID for 'www-data' is: ${WWW_DATA_GID}"

# 4. Apply ownership to current host user
HOST_USER_ID=$(id -u)
HOST_GROUP_ID=$(id -g)
HOST_USER_NAME=$(id -u -n)
echo "🔐 Applying ownership of '${SRC_DIR}' to current host user '${HOST_USER_NAME}' (UID:${HOST_USER_ID} GID:${HOST_GROUP_ID})..."
if sudo chown -R "${HOST_USER_ID}:${HOST_GROUP_ID}" "${SRC_DIR}"; then
    echo "✅ Ownership applied to host user."
else
    echo "❌ Error applying ownership with sudo. Please check sudo permissions."
    exit 1
fi

# 5. Apply permissions for www-data GID
echo "🔐 Applying permissions for GID ${WWW_DATA_GID} to '${SRC_DIR}'..."
if command -v setfacl &> /dev/null; then
    echo "   Using 'setfacl' for fine-grained permissions (recommended)."
    if sudo setfacl -R -m "g:${WWW_DATA_GID}:rwx" "${SRC_DIR}" && \
       sudo setfacl -dR -m "g:${WWW_DATA_GID}:rwx" "${SRC_DIR}"; then
        echo "✅ ACL permissions applied successfully for GID ${WWW_DATA_GID}."
    else
        echo "❌ Error applying ACL permissions with sudo. Please check sudo permissions and if ACLs are enabled on the filesystem."
        exit 1
    fi
else
    echo "   'setfacl' not found. Using 'chgrp' and 'chmod' as a fallback."
    echo "   Consider installing 'acl' package for more precise permission control (e.g., 'sudo dnf install acl' on Fedora)."
    if sudo chgrp -R "${WWW_DATA_GID}" "${SRC_DIR}" && \
       sudo chmod -R g+w "${SRC_DIR}"; then
       # Apply setgid bit to directories to ensure new files/subdirs inherit group
       find "${SRC_DIR}" -type d -exec sudo chmod g+s {} \;
       echo "✅ chgrp/chmod permissions applied successfully for GID ${WWW_DATA_GID}."
    else
        echo "❌ Error applying chgrp/chmod permissions with sudo. Please check sudo permissions."
        exit 1
    fi
fi

echo "🎉 Host permission setup for '${SRC_DIR}' completed successfully!"
echo "   Both your host user and WordPress (in container) should now have appropriate write access."
