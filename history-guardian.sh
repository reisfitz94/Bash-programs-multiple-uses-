#!/bin/bash
################################################################################
# History Guardian: Child-Safe Monitor (Professional Grade)
#
# - Monitors browser (Chrome/Firefox) or terminal history for flagged keywords
# - Uses sqlite3 to query history databases
# - Sends alert/log if flagged terms are found
# - Strict mode, getopts, and logging
################################################################################

set -euo pipefail

LOG_FILE="/var/log/history-guardian.log"
VERBOSE=0
KEYWORDS=("unsupervised" "adult" "gambling" "proxy" "vpn")
BROWSER="chrome"
INTERVAL=300

log() {
    local msg="$1"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    if (( VERBOSE )); then
        echo "[$ts] $msg"
    fi
    echo "[$ts] $msg" >> "$LOG_FILE"
}

usage() {
    cat <<EOF
Usage: $0 [-b chrome|firefox|terminal] [-k KEYWORD,...] [-i INTERVAL] [-v]
  -b BROWSER   chrome, firefox, or terminal (default: chrome)
  -k KEYWORDS  Comma-separated list of flagged terms
  -i SECS      Polling interval in seconds (default: 300)
  -v           Verbose output
  --help       Show this help
EOF
}

while getopts ":b:k:i:v-:" opt; do
    case $opt in
        b) BROWSER="$OPTARG" ;;
        k) IFS=',' read -ra KEYWORDS <<< "$OPTARG" ;;
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

alert() {
    local msg="$1"
    log "ALERT: $msg"
    if command -v notify-send &>/dev/null; then
        notify-send "History Guardian" "$msg"
    fi
}

check_chrome() {
    local histdb="$HOME/.config/google-chrome/Default/History"
    [[ -f "$histdb" ]] || histdb="$HOME/.config/chromium/Default/History"
    [[ -f "$histdb" ]] || { log "Chrome history DB not found."; return; }
    for kw in "${KEYWORDS[@]}"; do
        if sqlite3 "$histdb" "SELECT url FROM urls WHERE url LIKE '%$kw%' OR title LIKE '%$kw%' LIMIT 1;" | grep -q .; then
            alert "Flagged term '$kw' found in Chrome history."
        fi
    done
}

check_firefox() {
    local histdb
    histdb=$(find "$HOME/.mozilla/firefox" -name "places.sqlite" | head -n1)
    [[ -f "$histdb" ]] || { log "Firefox history DB not found."; return; }
    for kw in "${KEYWORDS[@]}"; do
        if sqlite3 "$histdb" "SELECT url FROM moz_places WHERE url LIKE '%$kw%' LIMIT 1;" | grep -q .; then
            alert "Flagged term '$kw' found in Firefox history."
        fi
    done
}

check_terminal() {
    local histfile="$HOME/.bash_history"
    [[ -f "$histfile" ]] || { log "Terminal history file not found."; return; }
    for kw in "${KEYWORDS[@]}"; do
        if grep -qi "$kw" "$histfile"; then
            alert "Flagged term '$kw' found in terminal history."
        fi
    done
}

main_loop() {
    log "Starting History Guardian for $BROWSER, interval $INTERVAL sec."
    while true; do
        case $BROWSER in
            chrome) check_chrome ;;
            firefox) check_firefox ;;
            terminal) check_terminal ;;
        esac
        sleep "$INTERVAL"
    done
}

main_loop
