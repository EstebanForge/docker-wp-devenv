#!/bin/bash
# Restart script: fully reset compose state, then start the environment.

set -e

PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Compose command resolution: v1 binary or v2 plugin, Docker or Podman.
# shellcheck source=lib/compose.sh
source "${PROJECT_ROOT_DIR}/lib/compose.sh"

cd "${PROJECT_ROOT_DIR}" || exit

echo "🔄 Restarting Docker environment..."
echo "🧹 Running 'docker-compose down --remove-orphans' to clear stale container/network state..."
"${DOCKER_COMPOSE[@]}" down --remove-orphans || true

bash "${PROJECT_ROOT_DIR}/lib/cmd-start.sh" "$@"
