#!/bin/bash
# Wrapper script to run docker-compose up and then set source permissions.

set -e # Exit immediately if a command exits with a non-zero status.

# Get the directory where this script is located (should be project root)
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERMISSION_SCRIPT_PATH="${PROJECT_ROOT_DIR}/scripts/set-src-permissions.sh"

# Check if SETUP-INFO.md exists
if [ ! -f "${PROJECT_ROOT_DIR}/SETUP-INFO.md" ]; then
  echo "🔴 Error: SETUP-INFO.md not found in '${PROJECT_ROOT_DIR}'."
  echo "   Please run './setup.sh' first to generate the necessary configuration and information file."
  exit 1
fi

echo "🚀 Bringing up Docker services via docker-compose..."

# Change to the project root directory to ensure docker-compose finds its file
cd "${PROJECT_ROOT_DIR}" || exit

# Check if --build flag is passed to force a permissions check
force_permission_check=false
for arg in "$@"; do
  if [[ "$arg" == "--build" ]]; then
    force_permission_check=true
    break
  fi
done

# Check if any arguments were passed
if [ $# -eq 0 ]; then
  echo "   No arguments provided, defaulting to detached mode (-d)."
  docker-compose up -d
  was_detached_by_default=true
else
  echo "   Passing arguments to docker-compose up: $@"
  docker-compose up "$@"
  was_detached_by_default=false
fi

# The docker-compose up command has finished.
# Now, conditionally run the permissions script.
PERMISSION_FLAG_FILE="${PROJECT_ROOT_DIR}/.permissions_set"

# We run the script if the flag file doesn't exist (first run) or if --build was passed.
if [ ! -f "${PERMISSION_FLAG_FILE}" ] || [ "$force_permission_check" = true ]; then
  echo ""
  if [ ! -f "${PERMISSION_FLAG_FILE}" ]; then
    echo "🔐 First start detected. Applying host permissions for the ./src directory..."
  else
    echo "🔐 --build flag detected. Re-applying host permissions for the ./src directory..."
  fi

  if [ -f "${PERMISSION_SCRIPT_PATH}" ]; then
    if [ ! -x "${PERMISSION_SCRIPT_PATH}" ]; then
      chmod +x "${PERMISSION_SCRIPT_PATH}"
    fi
    
    # Execute the permission script and create the flag file on success
    if "${PERMISSION_SCRIPT_PATH}"; then
      touch "${PERMISSION_FLAG_FILE}"
      echo "   Permissions applied successfully."
    else
      echo "⚠️ Error: Permission script failed. It will be run again on the next start."
    fi
  else
    echo "⚠️ Error: Permission script not found at ${PERMISSION_SCRIPT_PATH}"
    exit 1
  fi
else
  echo ""
  echo "✅ Permissions already set. Skipping."
fi

echo ""
echo "🎉 Docker environment is up and ./src permissions have been processed."

# Determine if services are running in detached mode for the final message
running_detached=false
if [ "$was_detached_by_default" = true ]; then
  running_detached=true
else
  # Check if -d or --detach is in the arguments provided by the user
  for arg in "$@"; do
    if [[ "$arg" == "-d" ]] || [[ "$arg" == "--detach" ]]; then
      running_detached=true
      break
    fi
  done
fi

if [ "$running_detached" = true ]; then
  echo "   Services are running in detached mode."
else
  echo "   Services were started in the foreground. If you stop them (Ctrl+C), permissions are already set for the next run."
fi

echo "   Usage: './start.sh' (defaults to detached mode)."
echo "   You can pass any 'docker-compose up' arguments, e.g., './start.sh --build -d', './start.sh wordpress'."
echo "   If arguments are provided and '-d' or '--detach' is not among them, services will likely start in the foreground (e.g., './start.sh --build')."
