#!/bin/bash
################################################################################
# System Resource Watchdog
#
# Monitors CPU, RAM, and Disk I/O for a specific process. Logs events and
# throttles (renices) the process if thresholds are exceeded.
#
# Usage: ./resource-watchdog.sh [process_name|PID] [CPU%] [MEM%] [IO_KB/s]
################################################################################

set -euo pipefail

TARGET="${1:-}"           # Process name or PID
CPU_THRESHOLD="${2:-80}"  # CPU usage %
MEM_THRESHOLD="${3:-80}"  # Memory usage %
IO_THRESHOLD="${4:-10240}" # Disk I/O in KB/s (default: 10MB/s)
LOG_FILE="/var/log/resource-watchdog.log"
INTERVAL=10               # Check every 10 seconds
NICE_LEVEL=10             # Renice to this level if throttling

log() {
    local msg="$1"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $msg" | tee -a "$LOG_FILE"
}

get_pid() {
    if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
        echo "$TARGET"
    else
        pgrep -f "$TARGET" | head -n1
    fi
}

get_stats() {
    local pid="$1"
    # CPU and MEM from ps
    read -r cpu mem <<< "$(ps -p "$pid" -o %cpu,%mem --no-headers | awk '{print $1, $2}')"
    # Disk I/O from /proc
    local io_prev io_curr delta_io
    io_prev=$(awk '/^read_bytes|^write_bytes/ {sum+=$2} END{print sum}' /proc/$pid/io 2>/dev/null || echo 0)
    sleep 1
    io_curr=$(awk '/^read_bytes|^write_bytes/ {sum+=$2} END{print sum}' /proc/$pid/io 2>/dev/null || echo 0)
    delta_io=$(( (io_curr - io_prev) / 1024 )) # KB/s
    echo "$cpu $mem $delta_io"
}

throttle_process() {
    local pid="$1"
    log "Throttling process $pid (renice to $NICE_LEVEL)"
    renice -n "$NICE_LEVEL" -p "$pid" >/dev/null
}

main() {
    log "Starting resource watchdog for $TARGET (CPU>$CPU_THRESHOLD%, MEM>$MEM_THRESHOLD%, IO>$IO_THRESHOLD KB/s)"
    while true; do
        pid=$(get_pid)
        if [[ -z "$pid" ]]; then
            log "Process $TARGET not found. Sleeping."
            sleep "$INTERVAL"
            continue
        fi
        read -r cpu mem io <<< "$(get_stats "$pid")"
        cpu_int=${cpu%.*}
        mem_int=${mem%.*}
        if (( cpu_int > CPU_THRESHOLD )); then
            log "CPU threshold exceeded: $cpu% (PID $pid)"
            throttle_process "$pid"
        fi
        if (( mem_int > MEM_THRESHOLD )); then
            log "MEM threshold exceeded: $mem% (PID $pid)"
            throttle_process "$pid"
        fi
        if (( io > IO_THRESHOLD )); then
            log "Disk I/O threshold exceeded: $io KB/s (PID $pid)"
            throttle_process "$pid"
        fi
        sleep "$INTERVAL"
    done
}

main "$@"
