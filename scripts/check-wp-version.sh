#!/bin/bash

# WordPress Version Check Script
# Displays current WordPress versions from different sources

set -e

# Compose command resolution: v1 binary or v2 plugin, Docker or Podman.
# shellcheck source=lib/compose.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/compose.sh"

echo "🔍 WordPress Version Information"
echo "================================"

# Check WordPress version in Docker container (if running)
# podman-compose 'ps' takes no service argument, so list all and match the
# php container name; state wording differs per engine ('Up' vs 'running').
if "${DOCKER_COMPOSE[@]}" ps 2>/dev/null | grep -E '_php_1|-php-1' | grep -Eqi 'Up|running'; then
  echo "📦 Container WordPress version:"
  ./wp core version 2>/dev/null || echo "   Container not accessible"
else
  echo "📦 Container: Not running"
fi

# Check Composer WordPress core version
if [ -f "composer.lock" ]; then
  echo "🎼 Composer WordPress core:"
  grep -A 2 '"name": "johnpbloch/wordpress-core"' composer.lock | grep '"version"' | cut -d'"' -f4 || echo "   Not found in composer.lock"
else
  echo "🎼 Composer: No composer.lock file"
fi

# Check latest available version from WordPress API
echo "🌐 Latest WordPress version:"
# shellcheck disable=SC2016
curl -s "https://api.wordpress.org/core/version-check/1.7/" |
  php -r '$json = json_decode(file_get_contents("php://stdin"), true); echo "   " . $json["offers"][0]["version"] . "\n";' 2>/dev/null ||
  echo "   Unable to fetch from API"

# Check Docker image tags
echo "🐳 Docker image info:"
docker image inspect php:8.3-fpm --format '{{.RepoTags}}' 2>/dev/null |
  sed 's/\[//g; s/\]//g; s/php://g' | tr ' ' '\n' | grep php8.3-fpm ||
  echo "   Image not found locally"

echo ""
echo "💡 To update to latest:"
echo "   docker-compose pull"
echo "   composer update johnpbloch/wordpress-core"
echo "   docker-compose up -d --build"
