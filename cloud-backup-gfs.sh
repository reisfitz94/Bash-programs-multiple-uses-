
#!/bin/bash
################################################################################
# Cloud-Agnostic Encrypted Backup Engine with GFS Rotation (Professional Grade)
#
# - Strict mode (set -euo pipefail)
# - getopts for flag parsing
# - log() function with timestamp, console, and /var/log output
#
# Usage: ./cloud-backup-gfs.sh -s /path/to/source -m [aws|gcs|rsync] -d DEST -p PASSPHRASE [-v]
################################################################################

set -euo pipefail

LOG_FILE="/var/log/cloud-backup-gfs.log"
VERBOSE=0

log() {
    local msg="$1"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $msg"
    echo "[$ts] $msg" >> "$LOG_FILE"
}

usage() {
    cat <<EOF
Usage: $0 -s SOURCE -m METHOD -d DEST -p PASSPHRASE [-v]
  -s SOURCE      Directory to back up
  -m METHOD      aws|gcs|rsync
  -d DEST        Destination (bucket or rsync target)
  -p PASSPHRASE  Encryption passphrase
  -v             Verbose output
  --help         Show this help
EOF
}

SRC=""
METHOD=""
DEST=""
PASSPHRASE=""
while getopts ":s:m:d:p:v-:" opt; do
    case $opt in
        s) SRC="$OPTARG" ;;
        m) METHOD="$OPTARG" ;;
        d) DEST="$OPTARG" ;;
        p) PASSPHRASE="$OPTARG" ;;
        v) VERBOSE=1 ;;
        -)
            case $OPTARG in
                help) usage; exit 0 ;;
                *) echo "Unknown option --$OPTARG"; usage; exit 1 ;;
            esac ;;
        *) echo "Unknown flag: -$OPTARG"; usage; exit 1 ;;
    esac
done

if [[ -z "$SRC" || -z "$METHOD" || -z "$DEST" || -z "$PASSPHRASE" ]]; then
    usage; exit 1
fi

# ===================== CONFIGURATION =====================
BACKUP_ROOT="/var/backups/cloud-gfs"
RETENTION_SONS=7      # Daily backups to keep
RETENTION_FATHERS=4   # Weekly backups to keep
RETENTION_GRAND=12    # Monthly backups to keep
ENCRYPT_CMD="openssl enc -aes-256-cbc -pbkdf2"
COMPRESS_CMD="tar czf"

# ===================== UTILITY FUNCTIONS =====================


# ===================== GFS ROTATION =====================
# Write a Bash function for a GFS rotation logic using timestamps
rotate_gfs() {
    local backup_dir="$1"
    local prefix="$2"
    # Sons: keep last 7 daily
    find "$backup_dir" -name "${prefix}-son-*.tar.gz.enc" | sort -r | tail -n +$((RETENTION_SONS+1)) | xargs -r rm -f
    # Fathers: keep last 4 weekly
    find "$backup_dir" -name "${prefix}-father-*.tar.gz.enc" | sort -r | tail -n +$((RETENTION_FATHERS+1)) | xargs -r rm -f
    # Grandfathers: keep last 12 monthly
    find "$backup_dir" -name "${prefix}-grand-*.tar.gz.enc" | sort -r | tail -n +$((RETENTION_GRAND+1)) | xargs -r rm -f
}

# ===================== BACKUP CREATION =====================
create_backup() {
    local src="$1"
    local passphrase="$2"
    local now
    now=$(date +%Y%m%d-%H%M%S)
    local day_of_week=$(date +%u)
    local day_of_month=$(date +%d)
    local prefix=$(basename "$src")
    local backup_dir="$BACKUP_ROOT/$prefix"
    mkdir -p "$backup_dir"
    local type="son"
    if [[ "$day_of_month" == "01" ]]; then
        type="grand"
    elif [[ "$day_of_week" == "7" ]]; then
        type="father"
    fi
    local backup_file="$backup_dir/${prefix}-${type}-${now}.tar.gz"
    log "Creating $type backup: $backup_file"
    if [[ "$src" == "-" ]]; then
        log "Reading tar input from stdin (streaming)"
        cat | $ENCRYPT_CMD -salt -pass pass:"$passphrase" -out "$backup_file.enc"
    else
        $COMPRESS_CMD "$backup_file" -C "$(dirname "$src")" "$(basename "$src")"
        log "Encrypting backup..."
        $ENCRYPT_CMD -salt -pass pass:"$passphrase" -in "$backup_file" -out "$backup_file.enc"
        rm "$backup_file"
    fi
    rotate_gfs "$backup_dir" "$prefix"
    echo "$backup_file.enc"
}

# ===================== CLOUD SYNC =====================
sync_backup() {
    local file="$1"
    local method="$2"
    local dest="$3"
    case "$method" in
        aws)
            aws s3 cp "$file" "$dest" --storage-class STANDARD_IA
            ;;
        gcs)
            gsutil cp "$file" "$dest"
            ;;
        rsync)
            rsync -avz "$file" "$dest"
            ;;
        *)
            log "Unknown sync method: $method"
            exit 1
            ;;
    esac
}

# ===================== INTEGRITY CHECK =====================
verify_backup() {
    local file="$1"
    local passphrase="$2"
    local tmpdir
    tmpdir=$(mktemp -d)
    log "Verifying backup integrity..."
    $ENCRYPT_CMD -d -pass pass:"$passphrase" -in "$file" -out "$tmpdir/restore.tar.gz"
    tar tzf "$tmpdir/restore.tar.gz" > "$tmpdir/list.txt"
    local random_file
    random_file=$(shuf -n1 "$tmpdir/list.txt")
    tar xzf "$tmpdir/restore.tar.gz" -C "$tmpdir" "$random_file"
    if [[ -f "$tmpdir/$random_file" ]]; then
        log "Integrity check PASSED: $random_file"
    else
        log "Integrity check FAILED: $random_file"
        exit 2
    fi
    rm -rf "$tmpdir"
}

# ===================== MAIN =====================
if [[ $# -lt 4 ]]; then
    echo "Usage: $0 /path/to/source [aws|gcs|rsync] [DESTINATION] [PASSPHRASE]"
    exit 1
fi
SRC="$1"
METHOD="$2"
DEST="$3"
PASSPHRASE="$4"

BACKUP_FILE=$(create_backup "$SRC" "$PASSPHRASE")
sync_backup "$BACKUP_FILE" "$METHOD" "$DEST"
verify_backup "$BACKUP_FILE" "$PASSPHRASE"
    log "Backup completed and verified."
