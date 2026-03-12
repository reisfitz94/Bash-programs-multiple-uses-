#!/bin/bash
################################################################################
# Bash Professional Script Template
#
# - Strict mode (set -euo pipefail)
# - getopts for flag parsing
# - log() function with timestamp, console, and /var/log output
################################################################################

set -euo pipefail

LOG_FILE="/var/log/$(basename "$0" .sh).log"
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
Usage: $0 [-v] [-f FILE] [--help]
  -v        Verbose output
  -f FILE   Input file
  --help    Show this help
EOF
}

FILE=""
while getopts ":vf:-:" opt; do
    case $opt in
        v) VERBOSE=1 ;;
        f) FILE="$OPTARG" ;;
        -)
            case $OPTARG in
                help) usage; exit 0 ;;
                *) echo "Unknown option --$OPTARG"; usage; exit 1 ;;
            esac ;;
        *) echo "Unknown flag: -$OPTARG"; usage; exit 1 ;;
    esac
done

log "Script started."
# ...main logic here...
log "Script finished."
