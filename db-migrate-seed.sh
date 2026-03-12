#!/bin/bash
################################################################################
# Database Migration and Seeding Tool
#
# Automates backups, schema migrations, and seeding for PostgreSQL (psql) or
# MySQL (mysql). Supports anonymized test data for genetic/financial use cases.
#
# Usage:
#   ./db-migrate-seed.sh [psql|mysql] [DB_NAME] [USER] [HOST] [MIGRATIONS_DIR] [SEED_FILE]
################################################################################

set -euo pipefail

DB_TYPE="${1:-psql}"
DB_NAME="${2:-testdb}"
DB_USER="${3:-postgres}"
DB_HOST="${4:-localhost}"
MIGRATIONS_DIR="${5:-./migrations}"
SEED_FILE="${6:-./seed.sql}"
BACKUP_DIR="./db_backups"
DATE=$(date +%Y%m%d-%H%M%S)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

backup_db() {
    mkdir -p "$BACKUP_DIR"
    case "$DB_TYPE" in
        psql)
            log "Backing up PostgreSQL database $DB_NAME..."
            PGPASSWORD="${PGPASSWORD:-}" pg_dump -h "$DB_HOST" -U "$DB_USER" "$DB_NAME" > "$BACKUP_DIR/${DB_NAME}_$DATE.sql"
            ;;
        mysql)
            log "Backing up MySQL database $DB_NAME..."
            mysqldump -h "$DB_HOST" -u "$DB_USER" --password="${MYSQL_PWD:-}" "$DB_NAME" > "$BACKUP_DIR/${DB_NAME}_$DATE.sql"
            ;;
        *)
            log "Unknown DB_TYPE: $DB_TYPE"; exit 1
            ;;
    esac
    log "Backup saved to $BACKUP_DIR/${DB_NAME}_$DATE.sql"
}

    log "Applying migrations from $MIGRATIONS_DIR (supports large files, streaming)..."
    for f in $(ls "$MIGRATIONS_DIR"/*.sql | sort); do
        log "Applying migration: $f"
        case "$DB_TYPE" in
            psql)
                if [[ "$f" == "-" ]]; then
                    log "Reading migration from stdin (streaming)"
                    PGPASSWORD="${PGPASSWORD:-}" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME"
                else
                    PGPASSWORD="${PGPASSWORD:-}" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$f"
                fi
                ;;
            mysql)
                if [[ "$f" == "-" ]]; then
                    log "Reading migration from stdin (streaming)"
                    mysql -h "$DB_HOST" -u "$DB_USER" --password="${MYSQL_PWD:-}" "$DB_NAME"
                else
                    mysql -h "$DB_HOST" -u "$DB_USER" --password="${MYSQL_PWD:-}" "$DB_NAME" < "$f"
                fi
                ;;
        esac
    done
    log "All migrations applied."
}

    log "Seeding database with $SEED_FILE (supports stdin for large files)..."
    case "$DB_TYPE" in
        psql)
            if [[ "$SEED_FILE" == "-" ]]; then
                log "Reading seed from stdin (streaming)"
                PGPASSWORD="${PGPASSWORD:-}" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME"
            else
                PGPASSWORD="${PGPASSWORD:-}" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SEED_FILE"
            fi
            ;;
        mysql)
            if [[ "$SEED_FILE" == "-" ]]; then
                log "Reading seed from stdin (streaming)"
                mysql -h "$DB_HOST" -u "$DB_USER" --password="${MYSQL_PWD:-}" "$DB_NAME"
            else
                mysql -h "$DB_HOST" -u "$DB_USER" --password="${MYSQL_PWD:-}" "$DB_NAME" < "$SEED_FILE"
            fi
            ;;
    esac
    log "Database seeded."
}

main() {
    log "Starting DB migration/seeding for $DB_TYPE on $DB_HOST/$DB_NAME"
    backup_db
    migrate_db
    seed_db
    log "Done."
}

main "$@"
