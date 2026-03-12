#!/bin/bash

################################################################################
# System Administration Toolkit for Linux Server Management
# 
# Purpose: Automate routine system administration tasks including:
#   - System updates and software installation
#   - User account and permission management
#   - System resource monitoring (disk space, services)
#   - Automated backups and log rotation
#   - Alert notifications for critical issues
#
# Usage: ./system-admin-toolkit.sh [COMMAND] [OPTIONS]
# Commands: update, install, user-add, user-remove, user-modify, monitor, backup
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/sysadmin-toolkit"
LOG_FILE="$LOG_DIR/sysadmin-toolkit.log"
BACKUP_DIR="/var/backups/sysadmin-toolkit"
ALERT_EMAIL="admin@example.com"  # Configure this with your email
DISK_WARNING_THRESHOLD=80  # Alert when disk usage exceeds this percentage
SERVICE_CHECK_INTERVAL=300  # Check services every 5 minutes (in seconds)

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING SETUP
# ============================================================================

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

# Function to log messages
log_message() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo -e "${BLUE}[$level]${NC} $message"
}

log_success() {
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [SUCCESS] $message" >> "$LOG_FILE"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
}

log_error() {
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [ERROR] $message" >> "$LOG_FILE"
    echo -e "${RED}[ERROR]${NC} $message"
}

log_warning() {
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [WARNING] $message" >> "$LOG_FILE"
    echo -e "${YELLOW}[WARNING]${NC} $message"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Send alert notification
send_alert() {
    local subject=$1
    local message=$2
    
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
        log_message "ALERT" "Alert sent: $subject"
    else
        log_warning "Mail utility not found. Skipping email alert for: $subject"
    fi
}

# ============================================================================
# SYSTEM UPDATE & PACKAGE MANAGEMENT
# ============================================================================

# Update system package lists and install available updates
update_system() {
    log_message "INFO" "Starting system update..."
    
    if ! check_root; then
        log_error "System update requires root privileges"
        return 1
    fi
    
    # Detect Linux distribution
    if command -v apt &> /dev/null; then
        log_message "INFO" "Detected Debian/Ubuntu system"
        apt-get update
        log_success "Package list updated"
        
        # Show available upgrades
        log_message "INFO" "Available upgrades:"
        apt-get upgrade --simulate | grep "^Inst" || true
        
        # Perform upgrade
        apt-get upgrade -y
        log_success "System packages upgraded"
        
    elif command -v yum &> /dev/null; then
        log_message "INFO" "Detected RedHat/CentOS system"
        yum check-update
        yum update -y
        log_success "System packages upgraded"
        
    elif command -v pacman &> /dev/null; then
        log_message "INFO" "Detected Arch Linux system"
        pacman -Syu --noconfirm
        log_success "System packages upgraded"
    else
        log_error "Unsupported package manager"
        return 1
    fi
}

# Install a specific package
install_package() {
    local package=$1
    
    if ! check_root; then
        log_error "Package installation requires root privileges"
        return 1
    fi
    
    log_message "INFO" "Installing package: $package"
    
    if command -v apt &> /dev/null; then
        apt-get install -y "$package"
    elif command -v yum &> /dev/null; then
        yum install -y "$package"
    elif command -v pacman &> /dev/null; then
        pacman -S --noconfirm "$package"
    else
        log_error "Unsupported package manager"
        return 1
    fi
    
    if dpkg -l | grep -q "$package" 2>/dev/null || rpm -qa | grep -q "$package" 2>/dev/null; then
        log_success "Package installed: $package"
    else
        log_error "Failed to install package: $package"
        return 1
    fi
}

# ============================================================================
# USER ACCOUNT MANAGEMENT
# ============================================================================

# Add a new user account
user_add() {
    local username=$1
    local fullname=${2:-""}
    local shell=${3:-"/bin/bash"}
    
    if ! check_root; then
        log_error "User management requires root privileges"
        return 1
    fi
    
    if id "$username" &>/dev/null; then
        log_warning "User already exists: $username"
        return 1
    fi
    
    log_message "INFO" "Creating user account: $username"
    
    if [[ -n "$fullname" ]]; then
        useradd -m -c "$fullname" -s "$shell" "$username"
    else
        useradd -m -s "$shell" "$username"
    fi
    
    log_success "User account created: $username"
    log_message "INFO" "Please set password for user: passwd $username"
}

# Remove a user account
user_remove() {
    local username=$1
    local remove_home=${2:-false}
    
    if ! check_root; then
        log_error "User management requires root privileges"
        return 1
    fi
    
    if ! id "$username" &>/dev/null; then
        log_warning "User does not exist: $username"
        return 1
    fi
    
    log_message "INFO" "Removing user account: $username"
    
    if [[ "$remove_home" == "true" ]]; then
        userdel -r "$username"
        log_success "User and home directory removed: $username"
    else
        userdel "$username"
        log_success "User account removed: $username"
    fi
}

# Modify user permissions
user_modify() {
    local username=$1
    local groups=$2  # Comma-separated list of groups
    
    if ! check_root; then
        log_error "User management requires root privileges"
        return 1
    fi
    
    if ! id "$username" &>/dev/null; then
        log_error "User does not exist: $username"
        return 1
    fi
    
    log_message "INFO" "Modifying user groups: $username -> $groups"
    usermod -aG "$groups" "$username"
    log_success "User groups updated: $username"
    log_message "INFO" "Current groups for $username: $(id -Gn $username)"
}

# List all user accounts with details
list_users() {
    log_message "INFO" "System user accounts:"
    echo "-----------------------------------"
    awk -F: '$3 >= 1000 {print $1 "\t" $5 "\t" $6}' /etc/passwd | \
        while IFS=$'\t' read -r user fullname home; do
            groups=$(id -Gn "$user" 2>/dev/null || echo "N/A")
            printf "%-15s | %-30s | Groups: %s\n" "$user" "$fullname" "$groups"
        done
    echo "-----------------------------------"
}

# ============================================================================
# SYSTEM RESOURCE MONITORING
# ============================================================================

# Monitor disk space usage
monitor_disk_space() {
    log_message "INFO" "Monitoring disk space usage..."
    
    echo "-----------------------------------"
    echo "Disk Space Usage Report:"
    echo "-----------------------------------"
    
    df -h | grep -E '^/dev/' | while read line; do
        usage_percent=$(echo "$line" | awk '{print $(NF-1)}' | sed 's/%//')
        mount_point=$(echo "$line" | awk '{print $NF}')
        
        if [[ $usage_percent -gt $DISK_WARNING_THRESHOLD ]]; then
            echo -e "${RED}WARNING${NC}: $mount_point is $usage_percent% full"
            send_alert "Disk Space Alert" "Mount point $mount_point is $usage_percent% full"
        else
            echo -e "${GREEN}OK${NC}: $mount_point is $usage_percent% full"
        fi
    done
    echo "-----------------------------------"
}

# Monitor system resource usage (CPU, Memory)
monitor_system_resources() {
    log_message "INFO" "Monitoring system resources..."
    
    echo "-----------------------------------"
    echo "System Resources:"
    echo "-----------------------------------"
    
    # CPU information
    cpu_count=$(nproc)
    cpu_load=$(uptime | awk -F'load average:' '{print $2}')
    echo "CPU Cores: $cpu_count"
    echo "Load Average: $cpu_load"
    
    # Memory information
    mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    mem_used=$(free -h | awk '/^Mem:/ {print $3}')
    mem_free=$(free -h | awk '/^Mem:/ {print $4}')
    mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", ($3/$2)*100}')
    
    echo "Memory Total: $mem_total"
    echo "Memory Used: $mem_used ($mem_percent%)"
    echo "Memory Free: $mem_free"
    
    if [[ $mem_percent -gt 80 ]]; then
        log_warning "Memory usage is high: $mem_percent%"
        send_alert "High Memory Usage" "Memory usage is at $mem_percent%"
    fi
    
    echo "-----------------------------------"
}

# Monitor service health
monitor_services() {
    local services=("sshd" "cron" "systemd-resolved")  # Add your critical services here
    
    log_message "INFO" "Monitoring service health..."
    echo "-----------------------------------"
    echo "Service Status:"
    echo "-----------------------------------"
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "${GREEN}✓${NC} $service is running"
        else
            echo -e "${RED}✗${NC} $service is NOT running"
            send_alert "Service Alert" "Service $service is not running on $(hostname)"
        fi
    done
    
    echo "-----------------------------------"
}

# Check for failed systemd services
check_failed_services() {
    log_message "INFO" "Checking for failed services..."
    
    failed_count=$(systemctl list-units --failed --no-legend | wc -l)
    
    if [[ $failed_count -gt 0 ]]; then
        log_warning "Found $failed_count failed service(s)"
        systemctl list-units --failed --no-legend
        send_alert "Failed Services Alert" "Found $failed_count failed service(s) on $(hostname)"
    else
        log_success "No failed services detected"
    fi
}

# ============================================================================
# BACKUP AND MAINTENANCE
# ============================================================================

# Perform system backup
backup_system() {
    local backup_name="system-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_message "INFO" "Starting system backup..."
    
    # Backup important configuration directories
    tar -czf "$backup_path" \
        /etc \
        /home \
        --exclude='/home/*/Downloads' \
        --exclude='/home/*/.cache' \
        2>/dev/null || true
    
    if [[ -f "$backup_path" ]]; then
        backup_size=$(du -h "$backup_path" | cut -f1)
        log_success "Backup created: $backup_name ($backup_size)"
    else
        log_error "Backup failed"
        return 1
    fi
}

# Clean up old log files
cleanup_logs() {
    local days_to_keep=${1:-30}
    
    log_message "INFO" "Cleaning up log files older than $days_to_keep days..."
    
    find /var/log -type f -name "*.log" -mtime "+$days_to_keep" -delete
    
    log_success "Log cleanup completed"
}

# Rotate log files manually
rotate_logs() {
    log_message "INFO" "Rotating log files..."
    
    if command -v logrotate &> /dev/null; then
        logrotate -f /etc/logrotate.conf
        log_success "Log rotation completed"
    else
        log_warning "logrotate not found"
    fi
}

# ============================================================================
# CRON SCHEDULING SETUP
# ============================================================================

# Setup automated cron jobs
setup_cron_jobs() {
    log_message "INFO" "Setting up cron jobs for automated maintenance..."
    
    # Create a cron job script
    local cron_script="/usr/local/bin/sysadmin-cron-tasks.sh"
    
    cat > "$cron_script" << 'EOF'
#!/bin/bash
# Automated system administration tasks

SCRIPT_PATH="/path/to/system-admin-toolkit.sh"

# Run system updates daily at 2 AM
# 0 2 * * * $SCRIPT_PATH update

# Monitor resources every hour
# 0 * * * * $SCRIPT_PATH monitor

# Backup system weekly on Sunday at 3 AM
# 0 3 * * 0 $SCRIPT_PATH backup

# Cleanup old logs monthly
# 0 4 1 * * $SCRIPT_PATH cleanup-logs

# Rotate logs daily
# 0 5 * * * $SCRIPT_PATH rotate-logs

# Check failed services every 30 minutes
# */30 * * * * $SCRIPT_PATH check-failed

# Monitor disk space every 6 hours
# 0 */6 * * * $SCRIPT_PATH monitor-disk
EOF
    
    chmod +x "$cron_script"
    log_success "Cron job script created at: $cron_script"
    log_message "INFO" "To enable automated tasks, add entries to 'crontab -e'"
    log_message "INFO" "Example cron entries are available in: $cron_script"
}

# ============================================================================
# MAIN MENU AND HELP
# ============================================================================

show_help() {
    cat << EOF
System Administration Toolkit - Usage Guide

USAGE:
    ./system-admin-toolkit.sh [COMMAND] [OPTIONS]

COMMANDS:

    System Updates:
    ├─ update              : Update system packages
    ├─ install <package>   : Install a specific package

    User Management:
    ├─ user-add <user> [fullname] [shell]    : Add new user
    ├─ user-remove <user> [remove-home]      : Remove user (true to delete home)
    ├─ user-modify <user> <groups>           : Modify user groups (comma-separated)
    └─ list-users          : List all system users

    Monitoring:
    ├─ monitor             : Run all monitoring checks
    ├─ monitor-disk        : Check disk space usage
    ├─ monitor-resources   : Check CPU and memory usage
    ├─ monitor-services    : Check critical services
    └─ check-failed        : Check for failed services

    Backup & Maintenance:
    ├─ backup              : Create system backup
    ├─ cleanup-logs        : Clean old log files
    └─ rotate-logs         : Rotate log files

    Automation:
    └─ setup-cron          : Setup automated cron jobs

    Other:
    ├─ help                : Show this help message
    ├─ status              : Show system status summary

EXAMPLES:
    # Update system
    sudo ./system-admin-toolkit.sh update

    # Add new user
    sudo ./system-admin-toolkit.sh user-add john "John Doe"

    # Monitor all resources
    sudo ./system-admin-toolkit.sh monitor

    # Backup system
    sudo ./system-admin-toolkit.sh backup

CONFIGURATION:
    Edit the CONFIGURATION section in this script to customize:
    - Log directory location
    - Backup directory location
    - Alert email address
    - Disk warning threshold
    - Service check interval

LOGGING:
    All actions are logged to: $LOG_FILE

NOTES:
    - Most commands require root privileges
    - Email alerts require 'mail' utility to be installed
    - Configure cron jobs manually: crontab -e

EOF
}

# Show system status summary
show_status() {
    echo ""
    log_message "INFO" "========== SYSTEM STATUS SUMMARY =========="
    echo ""
    
    # System info
    echo -e "${BLUE}System Information:${NC}"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo ""
    
    # Run all monitoring checks
    monitor_disk_space
    echo ""
    monitor_system_resources
    echo ""
    monitor_services
    echo ""
    
    log_message "INFO" "========== END OF REPORT =========="
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    local command=${1:-"help"}
    
    case "$command" in
        update)
            check_root
            update_system
            ;;
        install)
            if [[ -z "${2:-}" ]]; then
                log_error "Package name required"
                exit 1
            fi
            check_root
            install_package "$2"
            ;;
        user-add)
            if [[ -z "${2:-}" ]]; then
                log_error "Username required"
                exit 1
            fi
            check_root
            user_add "$2" "${3:-}" "${4:-/bin/bash}"
            ;;
        user-remove)
            if [[ -z "${2:-}" ]]; then
                log_error "Username required"
                exit 1
            fi
            check_root
            user_remove "$2" "${3:-false}"
            ;;
        user-modify)
            if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
                log_error "Username and groups required"
                exit 1
            fi
            check_root
            user_modify "$2" "$3"
            ;;
        list-users)
            list_users
            ;;
        monitor)
            check_root
            monitor_disk_space
            echo ""
            monitor_system_resources
            echo ""
            monitor_services
            ;;
        monitor-disk)
            check_root
            monitor_disk_space
            ;;
        monitor-resources)
            monitor_system_resources
            ;;
        monitor-services)
            check_root
            monitor_services
            ;;
        check-failed)
            check_root
            check_failed_services
            ;;
        backup)
            check_root
            backup_system
            ;;
        cleanup-logs)
            check_root
            cleanup_logs "${2:-30}"
            ;;
        rotate-logs)
            check_root
            rotate_logs
            ;;
        setup-cron)
            check_root
            setup_cron_jobs
            ;;
        status)
            check_root
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
