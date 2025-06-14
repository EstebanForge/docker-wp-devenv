#!/bin/bash
# Wrapper script to stop Docker services for the project.

set -e # Exit immediately if a command exits with a non-zero status.

# Check if SETUP-INFO.md exists
if [ ! -f "${PROJECT_ROOT_DIR}/SETUP-INFO.md" ]; then
  echo "🔴 Error: SETUP-INFO.md not found in '${PROJECT_ROOT_DIR}'."
  echo "   What are you trying to do?"
  exit 1
fi

# Get the directory where this script is located (should be project root)
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🛑 Stopping Docker services via docker-compose..."

# Change to the project root directory to ensure docker-compose finds its file
cd "${PROJECT_ROOT_DIR}" || exit

# Check if any arguments were passed
if [ $# -eq 0 ]; then
  echo "   No arguments provided, running 'docker-compose down'."
  docker-compose down
else
  echo "   Passing arguments to 'docker-compose down': $@"
  docker-compose down "$@"
fi

echo "✅ Docker services stopped."
