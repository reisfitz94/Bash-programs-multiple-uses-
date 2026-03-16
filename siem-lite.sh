#!/bin/bash
################################################################################
# cspell:ignore SIEM siem Unban unban
# SIEM-Lite: Real-Time Security Log Monitor & Auto-Ban Tool
#
# Monitors /var/log/auth.log for brute-force SSH attacks and unauthorized sudo
# attempts. Automatically bans offending IPs using iptables or ufw.
#
# Features:
#   - Real-time log monitoring (tail -F)
#   - Detects SSH brute-force (multiple failed logins)
#   - Detects unauthorized sudo attempts
#   - Auto-bans IPs via iptables or ufw
#   - Maintains a ban list and avoids duplicate bans
#   - Logs all actions to /var/log/siem-lite.log
#
# Usage: sudo ./siem-lite.sh
################################################################################

set -euo pipefail
umask 077

# ===================== CONFIGURATION =====================
AUTH_LOG="/var/log/auth.log"
BAN_LOG="/var/log/siem-lite.log"
BAN_LIST="/var/log/siem-lite.banned"
SSH_FAIL_THRESHOLD=5      # Number of failed attempts before ban
SUDO_FAIL_THRESHOLD=3     # Number of failed sudo attempts before ban
BAN_DURATION=86400        # Ban duration in seconds (24h)
FIREWALL="auto"           # "iptables", "ufw", or "auto"

# ===================== LOGGING =====================
log_action() {
    local msg="$1"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $msg" | tee -a "$BAN_LOG"
}

# ===================== BAN MANAGEMENT =====================
ban_ip() {
    local ip="$1"
    local reason="$2"
    # Check if already banned
    if grep -q "^$ip," "$BAN_LIST" 2>/dev/null; then
        log_action "IP $ip already banned. Skipping."
        return
    fi
    # Ban with iptables or ufw
    if [[ "$FIREWALL" == "auto" ]]; then
        if command -v ufw &>/dev/null; then
            FIREWALL="ufw"
        elif command -v iptables &>/dev/null; then
            FIREWALL="iptables"
        else
            log_action "No supported firewall found. Cannot ban $ip."
            return
        fi
    fi
    if [[ "$FIREWALL" == "ufw" ]]; then
        ufw deny from "$ip" comment "SIEM-Lite ban: $reason" || true
    elif [[ "$FIREWALL" == "iptables" ]]; then
        iptables -I INPUT -s "$ip" -j DROP || true
    fi
    echo "$ip,$(date +%s),$reason" >> "$BAN_LIST"
    log_action "BANNED $ip for $reason"
}

# Unban expired IPs
unban_expired() {
    local now
    now=$(date +%s)
    if [[ ! -f "$BAN_LIST" ]]; then return; fi
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/siem-lite.bans.XXXXXX")
    while IFS=, read -r ip ts reason; do
        if (( now - ts > BAN_DURATION )); then
            # Unban
            if [[ "$FIREWALL" == "ufw" ]]; then
                ufw delete deny from "$ip" || true
            elif [[ "$FIREWALL" == "iptables" ]]; then
                iptables -D INPUT -s "$ip" -j DROP || true
            fi
            log_action "UNBANNED $ip (expired ban)"
        else
            echo "$ip,$ts,$reason" >> "$tmpfile"
        fi
    done < "$BAN_LIST"
    mv "$tmpfile" "$BAN_LIST"
}

# ===================== LOG PARSING =====================
declare -A ssh_failures
declare -A sudo_failures

parse_log_line() {
    local line="$1"
    # SSH brute-force detection
    # Example: "Failed password for invalid user bob from 192.168.1.100 port 54321 ssh2"
    if [[ "$line" =~ Failed\ password\ for.*from\ ([0-9.]+) ]]; then
        local ip="${BASH_REMATCH[1]}"
        ssh_failures["$ip"]=$(( ${ssh_failures["$ip"]:-0} + 1 ))
        log_action "SSH fail from $ip (${ssh_failures["$ip"]} attempts)"
        if (( ssh_failures["$ip"] >= SSH_FAIL_THRESHOLD )); then
            ban_ip "$ip" "SSH brute-force (${ssh_failures["$ip"]} fails)"
            unset 'ssh_failures[$ip]'
        fi
    fi
    # Unauthorized sudo detection
    # Example: "sudo: 3 incorrect password attempts ; TTY=pts/0 ; PWD=/home/user ; USER=root ; COMMAND=/bin/ls"
    if [[ "$line" =~ sudo:.*incorrect\ password.*from\ ([0-9.]+) ]]; then
        local ip="${BASH_REMATCH[1]}"
        sudo_failures["$ip"]=$(( ${sudo_failures["$ip"]:-0} + 1 ))
        log_action "SUDO fail from $ip (${sudo_failures["$ip"]} attempts)"
        if (( sudo_failures["$ip"] >= SUDO_FAIL_THRESHOLD )); then
            ban_ip "$ip" "Unauthorized sudo (${sudo_failures["$ip"]} fails)"
            unset 'sudo_failures[$ip]'
        fi
    fi
    # Sudo: more generic detection (no IP, fallback to user)
    if [[ "$line" =~ sudo:.*authentication\ failure ]]; then
        # Optionally, handle user-based bans here
        log_action "SUDO authentication failure detected (no IP)"
    fi
}

# ===================== MAIN MONITOR LOOP =====================
main() {
    log_action "Starting SIEM-Lite security monitor."
    touch "$BAN_LIST"
    touch "$BAN_LOG"
    chmod 600 "$BAN_LIST" "$BAN_LOG"
    unban_expired
    tail -F "$AUTH_LOG" | while read -r line; do
        parse_log_line "$line"
        unban_expired
    done
}

# ===================== ENTRY POINT =====================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "Run as root (sudo) to manage firewall rules." >&2
        exit 1
    fi
    main
fi
