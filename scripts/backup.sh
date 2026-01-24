#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
  echo "SUPABASE_DB_URL is required" >&2
  exit 1
fi

if [[ -z "${BACKUP_PASSPHRASE:-}" ]]; then
  echo "BACKUP_PASSPHRASE is required" >&2
  exit 1
fi

RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
BACKUP_DATE="${BACKUP_DATE:-$(date -u +%F)}"
BACKUPS_DIR="${BACKUPS_DIR:-backups}"

umask 077

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

supabase db dump --db-url "$SUPABASE_DB_URL" -f "$WORK_DIR/roles.sql" --role-only
supabase db dump --db-url "$SUPABASE_DB_URL" -f "$WORK_DIR/schema.sql"
supabase db dump --db-url "$SUPABASE_DB_URL" -f "$WORK_DIR/data.sql" --use-copy --data-only

mkdir -p "$BACKUPS_DIR/$BACKUP_DATE"

TARBALL="$WORK_DIR/backup-$BACKUP_DATE.tar.gz"
tar -C "$WORK_DIR" -czf "$TARBALL" roles.sql schema.sql data.sql

ENCRYPTED_FILE="$BACKUPS_DIR/$BACKUP_DATE/backup-$BACKUP_DATE.tar.gz.enc"
openssl enc -aes-256-cbc -salt -pbkdf2 -pass env:BACKUP_PASSPHRASE -in "$TARBALL" -out "$ENCRYPTED_FILE"

if [[ -d "$BACKUPS_DIR" ]]; then
  find "$BACKUPS_DIR" -mindepth 1 -maxdepth 1 -type d -name "????-??-??" -mtime "+$RETENTION_DAYS" -exec rm -rf {} +
fi
