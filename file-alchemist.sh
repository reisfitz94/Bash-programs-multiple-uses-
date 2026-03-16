#!/bin/bash
################################################################################
# File Alchemist: Universal Format Converter (Professional Grade)
#
# - Converts between CSV, JSON, Markdown, HTML, PDF, etc.
# - Batch mode: convert all files in a directory
# - Uses csvkit, jq, and pandoc for conversions
# - Strict mode, getopts, and logging
################################################################################

set -euo pipefail

LOG_FILE="/var/log/file-alchemist.log"
VERBOSE=0
BATCH_MODE=0
SRC=""
DEST=""
TO_FORMAT=""

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
File Alchemist: Universal Format Converter

Usage: $0 -s SRC -t TO_FORMAT [-d DEST] [-b] [-v] [--map MAP] [--filter FILTER]

    -s SRC        Source file or directory
    -t TO_FORMAT  Target format (csv, json, md, html, pdf)
    -d DEST       Output file or directory (default: auto)
    -b            Batch mode (convert all files in directory)
    -v            Verbose output
    --map MAP     Custom jq/csvkit mapping (e.g., '.[] | {id, value}')
    --filter F    Filter rows/records (e.g., 'value > 10')
    --example     Show detailed examples
    --help        Show this help

Examples:
    # Convert a CSV to JSON with custom mapping
    $0 -s data.csv -t json --map '.[] | {id,score}'

    # Batch convert all Markdown files to PDF in a directory
    $0 -s ./mds -t pdf -b

    # Convert JSON to CSV, filtering for value > 10
    $0 -s data.json -t csv --filter 'value > 10'

    # Interactive mode (prompts for all options)
    $0 --interactive
EOF
}

MAP=""
FILTER=""
INTERACTIVE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        -s) SRC="$2"; shift 2 ;;
        -t) TO_FORMAT="$2"; shift 2 ;;
        -d) DEST="$2"; shift 2 ;;
        -b) BATCH_MODE=1; shift ;;
        -v) VERBOSE=1; shift ;;
        --map) MAP="$2"; shift 2 ;;
        --filter) FILTER="$2"; shift 2 ;;
        --interactive) INTERACTIVE=1; shift ;;
        --example) usage; exit 0 ;;
        --help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done


if (( INTERACTIVE )); then
    read -rp "Source file or directory: " SRC
    read -rp "Target format (csv, json, md, html, pdf): " TO_FORMAT
    read -rp "Output file or directory (optional): " DEST
    read -rp "Batch mode? (y/n): " bm; [[ $bm == y* ]] && BATCH_MODE=1
    read -rp "Custom mapping (jq/csvkit, optional): " MAP
    read -rp "Filter (optional): " FILTER
fi
if [[ -z "$SRC" || -z "$TO_FORMAT" ]]; then
    usage; exit 1
fi

convert_file() {
    local infile="$1"
    local outformat="$2"
    local outfile="$3"
    local ext="${infile##*.}"
    case "$ext" in
        csv)
            case "$outformat" in
                json)
                    log "Converting $infile (CSV→JSON)"
                    if [[ -n "$MAP" ]]; then
                        csvjson "$infile" | jq "$MAP" > "$outfile"
                    else
                        csvjson "$infile" > "$outfile"
                    fi
                    ;;
                *)
                    log "Unsupported conversion: $ext → $outformat"; return 1 ;;
            esac
            ;;
        json)
            case "$outformat" in
                csv)
                    log "Converting $infile (JSON→CSV)"
                    if [[ -n "$FILTER" ]]; then
                        jq "map(select($FILTER))" "$infile" | in2csv - > "$outfile"
                    else
                        in2csv "$infile" > "$outfile"
                    fi
                    ;;
                *)
                    log "Unsupported conversion: $ext → $outformat"; return 1 ;;
            esac
            ;;
        md|markdown)
            case "$outformat" in
                html)
                    log "Converting $infile (Markdown→HTML)"
                    pandoc "$infile" -o "$outfile"
                    ;;
                pdf)
                    log "Converting $infile (Markdown→PDF)"
                    pandoc "$infile" -o "$outfile"
                    ;;
                *)
                    log "Unsupported conversion: $ext → $outformat"; return 1 ;;
            esac
            ;;
        *)
            log "Unsupported source format: $ext"; return 1 ;;
    esac
    log "Output: $outfile"
}

if (( BATCH_MODE )); then
    if [[ ! -d "$SRC" ]]; then log "Batch mode requires a directory as source."; exit 1; fi
    outdir="${DEST:-$SRC/converted}"
    mkdir -p "$outdir"
    for f in "$SRC"/*; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f" | cut -d. -f1)"
        outfile="$outdir/$base.$TO_FORMAT"
        convert_file "$f" "$TO_FORMAT" "$outfile"
    done
else
    if [[ ! -f "$SRC" ]]; then log "Source file not found: $SRC"; exit 1; fi
    base="$(basename "$SRC" | cut -d. -f1)"
    outfile="${DEST:-$base.$TO_FORMAT}"
    convert_file "$SRC" "$TO_FORMAT" "$outfile"
fi
