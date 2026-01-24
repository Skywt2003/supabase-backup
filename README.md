# Supabase Backup (Encrypted, GitHub Actions)

Twice-weekly encrypted backups of a Supabase project using the official CLI dump flow.

## What gets backed up

- Database roles, schema, and data via `supabase db dump`
- Includes `auth` schema contents (Auth data is stored in the database)
- Does not include Storage objects

## Schedule

- Runs every Sunday and Wednesday at 02:00 UTC
- Retains the most recent 30 days of backups

## Setup

1. Create the following GitHub Actions secrets:
   - `SUPABASE_DB_URL`: your connection string (session pooler recommended)
   - `BACKUP_PASSPHRASE`: encryption passphrase
2. Enable Actions in the repository.

## Output layout

```
backups/
  YYYY-MM-DD/
    backup-YYYY-MM-DD.tar.gz.enc
```

## Restore

1. Decrypt and extract:

```
openssl enc -d -aes-256-cbc -pbkdf2 -pass env:BACKUP_PASSPHRASE \
  -in backup-YYYY-MM-DD.tar.gz.enc \
  -out backup-YYYY-MM-DD.tar.gz

tar -xzf backup-YYYY-MM-DD.tar.gz
```

2. Restore using the Supabase guide:

```
psql \
  --single-transaction \
  --variable ON_ERROR_STOP=1 \
  --file roles.sql \
  --file schema.sql \
  --command 'SET session_replication_role = replica' \
  --file data.sql \
  --dbname "YOUR_CONNECTION_STRING"
```

## Notes

- Backups are encrypted with OpenSSL (AES-256-CBC + PBKDF2).
- Backup retention is controlled by `BACKUP_RETENTION_DAYS` in the workflow.
