#!/bin/bash
# Strict mode: safer Bash
set -euo pipefail
IFS=$'\n\t'
umask 077

# Trap signals for cleanup
TMP_RESULTS="$(mktemp "${TMPDIR:-/tmp}/stock_trend_results.XXXXXX.csv")"
cleanup() { [[ -f "$TMP_RESULTS" ]] && rm -f "$TMP_RESULTS"; }
trap cleanup EXIT INT TERM

LOG_FILE="/var/log/stock-trend-analyzer.log"
VERBOSE=0
SYMBOLS=""
DAYS=180
MIN_GAIN=2.0

usage() {
	echo "Usage: $0 --symbols SYMBOL1,SYMBOL2 [--days N] [--min_gain X]"
	exit 2
}

# Parse CLI args
while [[ $# -gt 0 ]]; do
	case $1 in
		--symbols)
			SYMBOLS="$2"; shift 2;;
		--days)
			DAYS="$2"; shift 2;;
		--min_gain)
			MIN_GAIN="$2"; shift 2;;
		--verbose)
			VERBOSE=1; shift;;
		-h|--help)
			usage;;
		*)
			echo "Unknown option: $1" >&2; usage;;
	esac
done

if [[ -z "$SYMBOLS" ]]; then
	echo "[ERROR] No symbols provided. Use --symbols AAPL,MSFT,..." >&2
	usage
fi

log() {
		local msg="$1"
		if (( VERBOSE )); then
			echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" >&2
		fi
		echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG_FILE"
}

log "Starting stock analysis for: $SYMBOLS"
if ! python3 "$(dirname "$0")/stock_trend_engine.py" -s "$SYMBOLS" -d "$DAYS" -g "$MIN_GAIN" > "$TMP_RESULTS" 2>>"$LOG_FILE"; then
		log "Python analytics failed. See $LOG_FILE for details."
		exit 1
fi

log "Analysis complete. Candidates:"
column -t -s, "$TMP_RESULTS" | tee /dev/tty
