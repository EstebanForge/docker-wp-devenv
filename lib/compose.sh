#!/usr/bin/env bash
#
# Resolve the compose command across container engines (Docker, Podman).
# Sourced by every script that shells out to compose. Populates the
# DOCKER_COMPOSE array for use as "${DOCKER_COMPOSE[@]}".
#
# Order: v1 binary, v2 plugin (`docker compose`; also what the Podman
# docker-shim serves), native `podman compose`.

# shellcheck disable=SC2034  # consumed by every sourcing script
if command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE=(docker-compose)
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE=(docker compose)
elif command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE=(podman compose)
else
  echo "❌ Error: No compose command found. Install docker-compose, the 'docker compose' plugin, or podman-compose." >&2
  # Sourced context returns; direct execution exits. shellcheck cannot
  # see the dual mode.
  # shellcheck disable=SC2317
  return 1 2>/dev/null || exit 1
fi
