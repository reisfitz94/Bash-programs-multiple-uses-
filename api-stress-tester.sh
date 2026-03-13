#!/bin/bash
################################################################################
# API Stress Tester (Curl + GNU Parallel, Professional Grade)
#
# - Strict mode (set -euo pipefail)
# - getopts for flag parsing
# - log() function with timestamp, console, and /var/log output
#
# Usage: ./api-stress-tester.sh -u URL -n NUM -c CONCURRENCY [-M METHOD] [-b BODY_FILE] [-v]
################################################################################

set -euo pipefail

LOG_FILE="/var/log/api-stress-tester.log"
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
Usage: $0 -u URL -n NUM -c CONCURRENCY [-M METHOD] [-b BODY_FILE] [-v]
  -u URL        API endpoint
  -n NUM        Number of requests
  -c CONC       Concurrency (parallel jobs)
  -M METHOD     HTTP method (default: GET)
  -b BODY_FILE  Request body file
  -v            Verbose output
  --help        Show this help
EOF
}

URL=""
NUM_REQUESTS=1000
CONCURRENCY=$(nproc)
METHOD="GET"
BODY_FILE=""
while getopts ":u:n:c:M:b:v-:" opt; do
    case $opt in
        u) URL="$OPTARG" ;;
        n) NUM_REQUESTS="$OPTARG" ;;
        c) CONCURRENCY="$OPTARG" ;;
        M) METHOD="$OPTARG" ;;
        b) BODY_FILE="$OPTARG" ;;
        v) VERBOSE=1 ;;
        -)
            case $OPTARG in
                help) usage; exit 0 ;;
                *) echo "Unknown option --$OPTARG"; usage; exit 1 ;;
            esac ;;
        *) echo "Unknown flag: -$OPTARG"; usage; exit 1 ;;
    esac
done

if [[ -z "$URL" ]]; then
    usage; exit 1
fi

run_curl() {
    local i="$1"
    local start end ms http_code
    local -a curl_args
    curl_args=(-s -o /dev/null -w "%{http_code}" -X "$METHOD")
    if [[ -n "$BODY_FILE" ]]; then
        if [[ "$BODY_FILE" == "-" ]]; then
            curl_args+=(--data-binary @-)
            start=$(date +%s%3N)
            http_code=$(cat | curl "${curl_args[@]}" "$URL")
            end=$(date +%s%3N)
        else
            curl_args+=(--data-binary "@$BODY_FILE")
            start=$(date +%s%3N)
            http_code=$(curl "${curl_args[@]}" "$URL")
            end=$(date +%s%3N)
        fi
    else
        start=$(date +%s%3N)
        http_code=$(curl "${curl_args[@]}" "$URL")
        end=$(date +%s%3N)
    fi
    ms=$((end - start))
    echo "$i,$http_code,$ms" >> "$LOG_FILE"
}

export -f run_curl
export URL METHOD BODY_FILE LOG_FILE

log "Starting API stress test: $NUM_REQUESTS requests to $URL with $CONCURRENCY concurrency."
rm -f "$LOG_FILE"
seq 1 "$NUM_REQUESTS" | parallel -j "$CONCURRENCY" run_curl {}

log "Test complete. Results in $LOG_FILE."

# Summary
awk -F, '{codes[$2]++; sum+=$3; n++} END {for (c in codes) print "Status",c,":",codes[c],"responses"; print "Avg response time:",sum/n,"ms"}' "$LOG_FILE"
