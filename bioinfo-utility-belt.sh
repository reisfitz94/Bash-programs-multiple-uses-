
#!/bin/bash
################################################################################
# Bioinformatics Utility Belt - Interactive CLI Tool (Professional Grade)
#
# - Strict mode (set -euo pipefail)
# - getopts for flag parsing
# - log() function with timestamp, console, and /var/log output
#
# Usage: ./bioinfo-utility-belt.sh [-v] [--help]
################################################################################

set -euo pipefail

LOG_FILE="/var/log/bioinfo-utility-belt.log"
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
Usage: $0 [-v] [--help]
  -v        Verbose output
  --help    Show this help
EOF
}

while getopts ":v-:" opt; do
    case $opt in
        v) VERBOSE=1 ;;
        -)
            case $OPTARG in
                help) usage; exit 0 ;;
                *) echo "Unknown option --$OPTARG"; usage; exit 1 ;;
            esac ;;
        *) echo "Unknown flag: -$OPTARG"; usage; exit 1 ;;
    esac
done

run_blast() {
    log "[BLAST] Run BLASTN (supports large FASTA files, streaming)"
    read -rp "Enter query FASTA file (or '-' for stdin): " query
    read -rp "Enter BLAST database: " db
    read -rp "Enter output file: " out
    if ! command -v blastn &>/dev/null; then
        log "blastn not found. Please install BLAST+ suite."
        return
    fi
    if [[ "$query" == "-" ]]; then
        log "Reading FASTA from stdin (streaming)"
        blastn -query /dev/stdin -db "$db" -out "$out"
    elif [[ -f "$query" ]]; then
        log "Running: blastn -query $query -db $db -out $out"
        blastn -query "$query" -db "$db" -out "$out"
    else
        log "Query file not found: $query"; return
    fi
    log "[BLAST] Complete. Results in $out"
}

    log "[FastQ] Format/validate a FastQ file (streaming for large files)"
    read -rp "Enter input FastQ file (or '-' for stdin): " inq
    read -rp "Enter output file: " outq
    if [[ "$inq" == "-" ]]; then
        awk 'NR%4==1 && $1!~/^@/ {print "[ERROR] Bad header at line " NR; exit 1} NR%4==3 && $1!~/^\+/ {print "[ERROR] Bad plus at line " NR; exit 1} {print}' > "$outq"
    elif [[ -f "$inq" ]]; then
        awk 'NR%4==1 && $1!~/^@/ {print "[ERROR] Bad header at line " NR; exit 1} NR%4==3 && $1!~/^\+/ {print "[ERROR] Bad plus at line " NR; exit 1} {print}' "$inq" > "$outq"
    else
        log "Input file not found: $inq"; return
    fi
    if [[ $? -eq 0 ]]; then
        log "[FastQ] Reformatted and validated. Output: $outq"
    else
        log "[FastQ] Formatting failed."
    fi
}

cleanup_temp() {
    log "[Cleanup] Remove temp files (*.tmp, *.temp, /tmp >7d)"
    read -rp "Enter directory to clean (default: .): " dir
    dir=${dir:-.}
    if [[ ! -d "$dir" ]]; then
        log "Directory not found: $dir"; return
    fi
    find "$dir" -type f \( -name '*.tmp' -o -name '*.temp' \) -print -delete
    log "[Cleanup] Removed temp files in $dir."
    log "[Cleanup] Removing files in /tmp older than 7 days..."
    find /tmp -type f -mtime +7 -print -delete
    log "[Cleanup] Complete."
}

main_menu() {
    PS3=$'\nSelect a bioinformatics task: '
    options=("Run BLAST" "Format FastQ" "Cleanup Temp Files" "Exit")
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_blast ;;
            2) format_fastq ;;
            3) cleanup_temp ;;
            4) log "Goodbye!"; break ;;
            *) log "Invalid option. Try again." ;;
        esac
    done
}

main_menu
