#!/usr/bin/env bash
#
# backup-db.sh - Dump the WordPress database to a timestamped gzip file.
#
# Runs mysqldump inside the `db` container as root (localhost socket), so the
# mariadb client SSL quirk that affects the `php` container does not apply.
#
# Usage:
#   scripts/backup-db.sh
#
# Output:
#   backups/wp-YYYYMMDD_HHMMSS.sql.gz
#
set -euo pipefail

# Resolve repo root (parent of this scripts/ dir) so the command works from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$REPO_ROOT/backups"

mkdir -p "$BACKUP_DIR"

cd "$REPO_ROOT"

# Require the db container to be up.
if ! docker compose ps db --format '{{.Status}}' 2>/dev/null | grep -qi 'Up'; then
	echo "Error: the 'db' container is not running." >&2
	echo "Start the stack first: docker compose up -d" >&2
	exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$BACKUP_DIR/wp-${STAMP}.sql.gz"

# --single-transaction: consistent InnoDB snapshot without locking.
# --quick: stream rows instead of buffering (keeps memory flat on big tables).
# --add-drop-table: makes the dump restorable over an existing DB.
echo "Dumping database..."
docker compose exec -T db sh -c \
	'exec mysqldump --single-transaction --quick --add-drop-table -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' \
	| gzip > "$OUT"

# Fail loudly if the dump produced nothing (e.g. wrong creds, empty pipe).
if [ ! -s "$OUT" ]; then
	echo "Error: backup file is empty - dump failed. Removing $OUT" >&2
	rm -f "$OUT"
	exit 1
fi

SIZE="$(du -h "$OUT" | cut -f1)"
echo "Backup created: ${OUT#$REPO_ROOT/} ($SIZE)"
