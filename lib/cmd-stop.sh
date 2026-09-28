#!/bin/bash
# Wrapper script to stop Docker services for the project.

set -e # Exit immediately if a command exits with a non-zero status.

# Get the directory where this script is located (should be project root)
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Compose command resolution: v1 binary or v2 plugin, Docker or Podman.
# shellcheck source=lib/compose.sh
source "${PROJECT_ROOT_DIR}/lib/compose.sh"

# Check if SETUP-INFO.md exists
if [ ! -f "${PROJECT_ROOT_DIR}/SETUP-INFO.md" ]; then
  echo "🔴 Error: SETUP-INFO.md not found in '${PROJECT_ROOT_DIR}'."
  echo "   What are you trying to do?"
  exit 1
fi

echo "🛑 Stopping Docker services via docker-compose..."

# Change to the project root directory to ensure docker-compose finds its file
cd "${PROJECT_ROOT_DIR}" || exit

# Check if any arguments were passed
if [ $# -eq 0 ]; then
  echo "   No arguments provided, running 'docker-compose down'."
  "${DOCKER_COMPOSE[@]}" stop
else
  echo "   Passing arguments to docker-compose stop: $*"
  "${DOCKER_COMPOSE[@]}" stop "$@"
fi

echo "✅ Docker services stopped."
