# System Administration Toolkit - Documentation

## Overview

The **System Administration Toolkit** is a comprehensive Bash script designed for IT professionals and system administrators to automate critical server management tasks. It handles four main areas of responsibility:

1. **System Updates & Package Management** - Automate updates and package installation
2. **User Account Management** - Create, modify, and manage user accounts and permissions
3. **System Resource Monitoring** - Track disk space, CPU, memory, and service health
4. **Backup & Maintenance** - Automated backups, log rotation, and cleanup

---

## Prerequisites

- **Root/sudo access** - Most commands require elevated privileges
- **Linux distribution** - Supports Debian/Ubuntu (apt), RedHat/CentOS (yum), and Arch (pacman)
- **Optional**: Mail utility (`mailutils` or `postfix`) for email alerts

### Installation

```bash
# Copy the script to a system location
sudo cp system-admin-toolkit.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/system-admin-toolkit.sh

# Or use it directly from your current location
chmod +x ./system-admin-toolkit.sh
```

---

## Quick Start

### 1. View Help
```bash
./system-admin-toolkit.sh help
```

### 2. Get System Status Summary
```bash
sudo ./system-admin-toolkit.sh status
```

### 3. Update System
```bash
sudo ./system-admin-toolkit.sh update
```

### 4. Monitor Resources
```bash
sudo ./system-admin-toolkit.sh monitor
```

---

## Command Reference

### System Updates

#### `update` - Update all system packages
```bash
sudo ./system-admin-toolkit.sh update
```
- Detects the Linux distribution automatically
- Updates package lists
- Displays available upgrades
- Applies all security patches and updates
- Logs all actions to `/var/log/sysadmin-toolkit/sysadmin-toolkit.log`

#### `install <package>` - Install a specific package
```bash
sudo ./system-admin-toolkit.sh install curl
sudo ./system-admin-toolkit.sh install git vim
```
- Installs the specified package using the appropriate package manager
- Verifies successful installation
- Supports multiple packages by running the command multiple times

---

### User Account Management

#### `user-add <username> [fullname] [shell]` - Create a new user
```bash
# Basic user creation
sudo ./system-admin-toolkit.sh user-add john

# With full name
sudo ./system-admin-toolkit.sh user-add john "John Doe"

# With specific shell
sudo ./system-admin-toolkit.sh user-add john "John Doe" /bin/bash
```
- Creates home directory automatically
- Sets specified shell (defaults to `/bin/bash`)
- Prompts admin to set password: `passwd john`

#### `user-remove <username> [remove-home]` - Remove a user
```bash
# Remove user, keep home directory
sudo ./system-admin-toolkit.sh user-remove john

# Remove user and home directory
sudo ./system-admin-toolkit.sh user-remove john true
```
- Use with caution - home directory deletion is permanent

#### `user-modify <username> <groups>` - Manage user group membership
```bash
# Add user to sudo group
sudo ./system-admin-toolkit.sh user-modify john sudo

# Add to multiple groups (comma-separated)
sudo ./system-admin-toolkit.sh user-modify john sudo,docker,www-data
```
- Adds user to specified groups
- Useful for granting permissions without root access

#### `list-users` - Display all system users
```bash
./system-admin-toolkit.sh list-users
```
- Shows all non-system users (UID >= 1000)
- Displays username, full name, and group membership

---

### System Monitoring

#### `monitor` - Run comprehensive system checks
```bash
sudo ./system-admin-toolkit.sh monitor
```
Performs all monitoring checks:
- Disk space usage
- CPU and memory usage
- Critical service health
- Displays color-coded alerts (Green=OK, Yellow=Warning, Red=Critical)

#### `monitor-disk` - Check disk space usage
```bash
sudo ./system-admin-toolkit.sh monitor-disk
```
- Shows disk usage for all mounted filesystems
- Alerts if usage exceeds threshold (default: 80%)
- Color-coded output for quick assessment

**Example Output:**
```
Disk Space Usage Report:
OK: /dev/sda1 is 45% full
OK: /dev/sda2 is 72% full
WARNING: /dev/sda3 is 85% full
```

#### `monitor-resources` - Check CPU and memory
```bash
./system-admin-toolkit.sh monitor-resources
```
- CPU cores and load average
- Memory total, used, and free
- Memory percentage alert if > 80%

#### `monitor-services` - Check critical services
```bash
sudo ./system-admin-toolkit.sh monitor-services
```
Services monitored (configurable):
- `sshd` - SSH server
- `cron` - Task scheduler
- `systemd-resolved` - DNS resolver

#### `check-failed` - Find failed systemd services
```bash
sudo ./system-admin-toolkit.sh check-failed
```
- Lists all failed services
- Helpful for identifying problem services
- Automatically sends alert if failures detected

---

### Backup & Maintenance

#### `backup` - Create system backup
```bash
sudo ./system-admin-toolkit.sh backup
```
- Creates compressed tarball of:
  - `/etc` - System configuration
  - `/home` - User data (excludes cache and downloads)
- Stored in `/var/backups/sysadmin-toolkit/`
- Backup filename includes timestamp: `system-backup-20240312_143022.tar.gz`

#### `cleanup-logs` - Remove old log files
```bash
# Remove logs older than 30 days (default)
sudo ./system-admin-toolkit.sh cleanup-logs

# Remove logs older than 90 days
sudo ./system-admin-toolkit.sh cleanup-logs 90
```
- Safely removes old log files from `/var/log`
- Parameter specifies days to keep

#### `rotate-logs` - Rotate application logs
```bash
sudo ./system-admin-toolkit.sh rotate-logs
```
- Uses `logrotate` to compress and archive logs
- Manages log file growth
- Prevents disk space issues from excessive logging

---

### Automation & Scheduling

#### `setup-cron` - Generate cron job templates
```bash
sudo ./system-admin-toolkit.sh setup-cron
```
- Creates `/usr/local/bin/sysadmin-cron-tasks.sh` with cron examples
- Shows you how to schedule automated tasks

---

## Cron Job Setup Guide

### Setting Up Automated Tasks

After running `setup-cron`, edit your crontab:
```bash
sudo crontab -e
```

### Recommended Cron Schedule

```bash
# Daily system updates at 2 AM
0 2 * * * /usr/local/bin/system-admin-toolkit.sh update

# Monitor resources every 6 hours
0 */6 * * * /usr/local/bin/system-admin-toolkit.sh monitor

# System backup every Sunday at 3 AM
0 3 * * 0 /usr/local/bin/system-admin-toolkit.sh backup

# Clean old logs monthly (1st of month)
0 4 1 * * /usr/local/bin/system-admin-toolkit.sh cleanup-logs 30

# Rotate logs daily at 5 AM
0 5 * * * /usr/local/bin/system-admin-toolkit.sh rotate-logs

# Check failed services every 30 minutes
*/30 * * * * /usr/local/bin/system-admin-toolkit.sh check-failed

# Monitor disk space every 6 hours
0 */6 * * * /usr/local/bin/system-admin-toolkit.sh monitor-disk
```

### Cron Schedule Syntax
```
Minute   Hour   Day-of-Month   Month   Day-of-Week   Command
  0       2         *           *         *           command
  ↑       ↑         ↑           ↑         ↑
  |       |         |           |         └─ 0-6 (Sun-Sat)
  |       |         |           └─ 1-12
  |       |         └─ 1-31
  |       └─ 0-23
  └─ 0-59
```

**Common Patterns:**
- `0 2 * * *` - Daily at 2 AM
- `0 */6 * * *` - Every 6 hours
- `0 3 * * 0` - Weekly on Sunday at 3 AM
- `*/30 * * * *` - Every 30 minutes

---

## Configuration

### Customize the Script

Edit the CONFIGURATION section at the top of the script:

```bash
# Email for alerts
ALERT_EMAIL="admin@example.com"

# Disk warning threshold
DISK_WARNING_THRESHOLD=80

# Log directory
LOG_DIR="/var/log/sysadmin-toolkit"

# Backup directory
BACKUP_DIR="/var/backups/sysadmin-toolkit"
```

### Custom Service Monitoring

To monitor your own services, edit the `monitor_services()` function:

```bash
monitor_services() {
    local services=("sshd" "nginx" "mysql" "redis")  # Add your services
    # ... rest of function
}
```

---

## Logging

All actions are logged to: `/var/log/sysadmin-toolkit/sysadmin-toolkit.log`

### View Logs
```bash
# View last 50 log entries
tail -50 /var/log/sysadmin-toolkit/sysadmin-toolkit.log

# Search logs for errors
grep "ERROR" /var/log/sysadmin-toolkit/sysadmin-toolkit.log

# Watch logs in real-time
tail -f /var/log/sysadmin-toolkit/sysadmin-toolkit.log
```

### Log Format
```
[2024-03-12 14:30:22] [INFO] Starting system update...
[2024-03-12 14:30:45] [SUCCESS] System packages upgraded
[2024-03-12 14:31:10] [WARNING] Memory usage is high: 85%
[2024-03-12 14:32:00] [ERROR] Failed to install package: unknown-pkg
```

---

## Alert System

### Email Alerts

The script can send email notifications for critical events:

**Prerequisites:**
```bash
# Install mail utility (Ubuntu/Debian)
sudo apt-get install mailutils

# OR (for sendmail)
sudo apt-get install sendmail
```

**Configure Alert Email:**
Edit the script and set:
```bash
ALERT_EMAIL="your-admin@example.com"
```

**Alert Triggers:**
- Disk usage exceeds threshold
- Memory usage exceeds 80%
- Critical service is not running
- Failed services detected

---

## Practical Examples

### Daily System Maintenance Routine

```bash
# 1. Check system status
sudo ./system-admin-toolkit.sh status

# 2. Review and install updates
sudo ./system-admin-toolkit.sh update

# 3. Check for failed services
sudo ./system-admin-toolkit.sh check-failed

# 4. Monitor resources
sudo ./system-admin-toolkit.sh monitor

# 5. Create backup
sudo ./system-admin-toolkit.sh backup
```

### Create New Developer User with Permissions

```bash
# Add user
sudo ./system-admin-toolkit.sh user-add alice "Alice Developer"

# Give sudo access
sudo ./system-admin-toolkit.sh user-modify alice sudo,docker

# Set password
sudo passwd alice

# Verify
./system-admin-toolkit.sh list-users
```

### Automated Weekly Maintenance

```bash
# Add to crontab
sudo crontab -e

# Add this line for Sunday at 3 AM
0 3 * * 0 /usr/local/bin/system-admin-toolkit.sh backup && \
            /usr/local/bin/system-admin-toolkit.sh cleanup-logs 30
```

---

## Troubleshooting

### "Permission Denied" Error
```bash
# Make script executable
chmod +x system-admin-toolkit.sh

# Run with sudo
sudo ./system-admin-toolkit.sh [command]
```

### "Mail utility not found"
```bash
# Install mail utility
sudo apt-get install mailutils

# Or configure to use different mail service
# Edit the send_alert() function in the script
```

### Can't Log In After User Modification
```bash
# Set password immediately after user creation
sudo passwd username

# Verify user exists and has correct shell
cat /etc/passwd | grep username
```

### Cron Jobs Not Running
```bash
# Check crontab is set correctly
sudo crontab -l

# Check cron logs
grep CRON /var/log/syslog

# Ensure command paths are absolute
use: /usr/local/bin/system-admin-toolkit.sh
not: ./system-admin-toolkit.sh
```

---

## Best Practices

1. **Always use absolute paths in cron jobs** - Cron jobs don't have the same PATH as interactive shells

2. **Test commands manually first** - Before adding to cron:
   ```bash
   sudo ./system-admin-toolkit.sh monitor
   ```

3. **Monitor the logs regularly** - Check `/var/log/sysadmin-toolkit/sysadmin-toolkit.log`

4. **Set up email alerts** - Know immediately when issues arise

5. **Backup before major changes** - Always backup before system updates

6. **Keep scripts updated** - Review and update scripts periodically

7. **Document your cron schedule** - Keep notes of what you've scheduled and why

---

## Support & Maintenance

### Version Information
- **Script**: System Administration Toolkit v1.0
- **Tested On**: Ubuntu 20.04+, CentOS 7+, Arch Linux
- **Requirements**: Bash 4.0+, root/sudo access

### Adding New Features

To extend the toolkit with custom functions:

```bash
# Add your function
my_custom_function() {
    log_message "INFO" "Running custom task..."
    # Your code here
    log_success "Custom task completed"
}

# Add to main() case statement
custom)
    my_custom_function
    ;;
```

---

## License & Usage

This script is designed for system administrators and should be used responsibly on production systems. Always test in a non-production environment first.

---

**Last Updated**: March 2024
