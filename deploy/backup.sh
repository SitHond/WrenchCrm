#!/usr/bin/env sh
# Encrypted PostgreSQL backup of WrenchCRM. Run from the folder with compose.yaml and .env, e.g. daily from cron:
#   30 3 * * * root cd /opt/wrenchcrm && ./backup.sh >> backups/backup.log 2>&1
# Needs BACKUP_PASSPHRASE in .env. Restore: see README.md in this folder.
set -eu
cd "$(dirname "$0")"

passphrase=$(sed -n 's/^BACKUP_PASSPHRASE=//p' .env)
[ -n "$passphrase" ] || { echo "Set BACKUP_PASSPHRASE in .env" >&2; exit 1; }
keep_days=$(sed -n 's/^BACKUP_KEEP_DAYS=//p' .env)
keep_days=${keep_days:-14}

if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"; else COMPOSE="podman compose"; fi

mkdir -p backups
chmod 700 backups
file="backups/wrenchcrm-$(date +%Y-%m-%d-%H%M).dump.enc"

$COMPOSE exec -T db pg_dump -U wrench_crm -Fc wrench_crm_production |
  BACKUP_PASSPHRASE="$passphrase" openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -pass env:BACKUP_PASSPHRASE -out "$file"
chmod 600 "$file"

size=$(wc -c < "$file")
[ "$size" -gt 1024 ] || { echo "Backup looks empty: $file" >&2; exit 1; }
find backups -name 'wrenchcrm-*.dump.enc' -mtime +"$keep_days" -delete
echo "$(date '+%F %T') saved $file ($size bytes)"
