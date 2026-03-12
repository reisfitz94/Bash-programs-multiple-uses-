#!/bin/bash
################################################################################
# Containerized Micro-Service Health Dashboard (Professional Grade)
#
# - Strict mode (set -euo pipefail)
# - getopts for flag parsing
# - log() function with timestamp, console, and /var/log output
#
# Usage: ./docker-health-dashboard.sh [-w WEBHOOK_URL] [-i INTERVAL]
################################################################################

set -euo pipefail

LOG_FILE="/var/log/docker-health-dashboard.log"
VERBOSE=0
HTML_OUT="/tmp/docker-health-dashboard.html"
INTERVAL=60
WEBHOOK_URL=""
PREV_RESTARTS_FILE="/tmp/docker-health-dashboard.restarts"

log() {
    local msg="$1"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $msg"
    echo "[$ts] $msg" >> "$LOG_FILE"
}

usage() {
    cat <<EOF
Usage: $0 [-w WEBHOOK_URL] [-i INTERVAL] [-v]
  -w URL     Slack/Discord webhook URL
  -i SEC     Update interval in seconds (default: 60)
  -v         Verbose output
  --help     Show this help
EOF
}

while getopts ":w:i:v-:" opt; do
    case $opt in
        w) WEBHOOK_URL="$OPTARG" ;;
        i) INTERVAL="$OPTARG" ;;
        v) VERBOSE=1 ;;
        -)
            case $OPTARG in
                help) usage; exit 0 ;;
                *) echo "Unknown option --$OPTARG"; usage; exit 1 ;;
            esac ;;
        *) echo "Unknown flag: -$OPTARG"; usage; exit 1 ;;
    esac
done

## For large environments, HTML_OUT can be set to a file on a large/fast disk.
# ========== HTML GENERATION ==========
generate_html() {
    local now
    now=$(date '+%Y-%m-%d %H:%M:%S')
    echo "<html><head><title>Docker Health Dashboard</title><meta http-equiv='refresh' content='$INTERVAL'></head><body>" > "$HTML_OUT"
    echo "<h1>Docker Health Dashboard</h1><p>Last updated: $now</p>" >> "$HTML_OUT"
    echo "<table border='1' cellpadding='5'><tr><th>Name</th><th>Status</th><th>Health</th><th>Restarts</th><th>CPU %</th><th>Mem %</th></tr>" >> "$HTML_OUT"
    docker ps --format '{{.ID}} {{.Names}} {{.Status}}' | while read -r id name status; do
        health="$(docker inspect --format='{{.State.Health.Status}}' "$id" 2>/dev/null || echo "-")"
        stats="$(docker stats --no-stream --format '{{.CPUPerc}} {{.MemPerc}}' "$id" 2>/dev/null)"
        cpu="$(echo "$stats" | awk '{print $1}')"
        mem="$(echo "$stats" | awk '{print $2}')"
        restarts="$(docker inspect --format='{{.RestartCount}}' "$id" 2>/dev/null)"
        echo "<tr><td>$name</td><td>$status</td><td>$health</td><td>$restarts</td><td>$cpu</td><td>$mem</td></tr>" >> "$HTML_OUT"
    done
    echo "</table></body></html>" >> "$HTML_OUT"
}

# ========== RESTART DETECTION & WEBHOOK ==========
send_webhook() {
    local name="$1"
    local restarts="$2"
    local msg="Container $name restarted unexpectedly ($restarts restarts)"
    if [[ -n "$WEBHOOK_URL" ]]; then
        curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$msg\"}" "$WEBHOOK_URL"
    fi
}

check_restarts() {
    declare -A prev_restarts
    if [[ -f "$PREV_RESTARTS_FILE" ]]; then
        while IFS=, read -r name count; do
            prev_restarts["$name"]="$count"
        done < "$PREV_RESTARTS_FILE"
    fi
    > "$PREV_RESTARTS_FILE.tmp"
    docker ps --format '{{.ID}} {{.Names}}' | while read -r id name; do
        restarts="$(docker inspect --format='{{.RestartCount}}' "$id" 2>/dev/null)"
        echo "$name,$restarts" >> "$PREV_RESTARTS_FILE.tmp"
        prev="${prev_restarts["$name"]:-0}"
        if (( restarts > prev )); then
            send_webhook "$name" "$restarts"
        fi
    done
    mv "$PREV_RESTARTS_FILE.tmp" "$PREV_RESTARTS_FILE"
}

# ========== MAIN LOOP ==========
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "Starting Docker Health Dashboard. HTML output: $HTML_OUT"
while true; do
    generate_html
    check_restarts
    log "Dashboard updated."
    sleep "$INTERVAL"
done
