#!/usr/bin/env bash
#
# restore-db.sh - Restore the WordPress database from a backup file.
#
# Piping into mysql inside the `db` container as root avoids the mariadb client
# SSL quirk present in the `php` container.
#
# Usage:
#   scripts/restore-db.sh <backup-file>
#   scripts/restore-db.sh backups/wp-20260728_173715.sql.gz
#
# This OVERWRITES the current database. You will be asked to confirm.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FILE="${1:-}"

if [[ -z "$FILE" ]]; then
	echo "Usage: $0 <backup-file>" >&2
	echo "Available backups:" >&2
	find "$REPO_ROOT/backups" -maxdepth 1 -name "*.gz" -printf "  %f\\n" 2>/dev/null >&2 || true
	exit 1
fi

# Resolve relative paths against the repo root.
[[ "$FILE" = /* ]] || FILE="$REPO_ROOT/$FILE"

if [[ ! -f "$FILE" ]]; then
	echo "Error: backup file not found: $FILE" >&2
	exit 1
fi

cd "$REPO_ROOT"

# Compose command resolution: v1 binary or v2 plugin, Docker or Podman.
# shellcheck source=lib/compose.sh
source "$REPO_ROOT/lib/compose.sh"

# podman-compose 'ps' takes no service argument; state wording differs per
# engine ('Up' vs 'running').
if ! "${DOCKER_COMPOSE[@]}" ps 2>/dev/null | grep -E '_db_1|-db-1' | grep -Eqi 'Up|running'; then
	echo "Error: the 'db' container is not running." >&2
	echo "Start the stack first: ${DOCKER_COMPOSE[*]} up -d" >&2
	exit 1
fi

DB_NAME="$("${DOCKER_COMPOSE[@]}" exec -T db printenv MYSQL_DATABASE </dev/null | tr -d '\r\n')"

echo "WARNING: this will OVERWRITE the '$DB_NAME' database."
echo "Source:  ${FILE#"$REPO_ROOT"/}"
read -r -p "Continue? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

echo "Restoring..."
if [[ "$FILE" == *.gz ]]; then
	gunzip -c "$FILE" | "${DOCKER_COMPOSE[@]}" exec -T db sh -c \
		'exec mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"'
else
	cat "$FILE" | "${DOCKER_COMPOSE[@]}" exec -T db sh -c \
		'exec mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"'
fi

echo "Restore complete: ${FILE#"$REPO_ROOT"/}"
