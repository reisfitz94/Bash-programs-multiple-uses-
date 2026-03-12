#!/bin/bash
# System Administration Toolkit - Cron Job Configuration Template
# 
# This file provides ready-to-use cron job definitions for automating
# system administration tasks using system-admin-toolkit.sh
#
# How to use:
# 1. Edit the SCRIPT_PATH variable below to match your installation location
# 2. Uncomment the cron jobs you want to enable
# 3. Run: sudo crontab -e
# 4. Paste the cron entries (without the #!/bin/bash header)
# 5. Save and exit
#
# Verify installation:
# sudo crontab -l      # List scheduled jobs
# grep CRON /var/log/syslog  # View cron execution logs

# ============================================================================
# CONFIGURATION
# ============================================================================

# Path to system-admin-toolkit.sh
SCRIPT_PATH="/usr/local/bin/system-admin-toolkit.sh"

# Or if installed in home directory:
# SCRIPT_PATH="/home/username/system-admin-toolkit.sh"

# Logging
LOG_FILE="/var/log/sysadmin-toolkit/cron-execution.log"

# ============================================================================
# CRON JOB TEMPLATES
# ============================================================================

# EXAMPLE 1: Daily System Updates
# This will check for and install updates every day at 2 AM
# 0 2 * * * /usr/local/bin/system-admin-toolkit.sh update >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# EXAMPLE 2: Hourly System Resource Monitoring
# Checks disk space, CPU, memory, and service health every hour
# 0 * * * * /usr/local/bin/system-admin-toolkit.sh monitor >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# EXAMPLE 3: Weekly System Backup
# Creates a complete system backup every Sunday at 3 AM
# 0 3 * * 0 /usr/local/bin/system-admin-toolkit.sh backup >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# EXAMPLE 4: Monthly Log Cleanup
# Removes log files older than 30 days on the first day of each month at 4 AM
# 0 4 1 * * /usr/local/bin/system-admin-toolkit.sh cleanup-logs 30 >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# EXAMPLE 5: Daily Log Rotation
# Rotates log files daily at 5 AM to manage disk space
# 0 5 * * * /usr/local/bin/system-admin-toolkit.sh rotate-logs >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# EXAMPLE 6: Frequent Service Health Checks
# Monitors critical services every 30 minutes
# */30 * * * * /usr/local/bin/system-admin-toolkit.sh check-failed >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# EXAMPLE 7: Disk Space Monitoring
# Checks disk usage every 6 hours (0:00, 6:00, 12:00, 18:00)
# 0 */6 * * * /usr/local/bin/system-admin-toolkit.sh monitor-disk >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# EXAMPLE 8: Comprehensive Morning Check
# Runs full system status check every morning at 8 AM
# 0 8 * * * /usr/local/bin/system-admin-toolkit.sh status >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# ============================================================================
# RECOMMENDED BASIC SETUP
# ============================================================================
# Copy and paste these lines into: sudo crontab -e
#
# 0 2 * * * /usr/local/bin/system-admin-toolkit.sh update >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
# 0 */6 * * * /usr/local/bin/system-admin-toolkit.sh monitor >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
# 0 3 * * 0 /usr/local/bin/system-admin-toolkit.sh backup >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
# */30 * * * * /usr/local/bin/system-admin-toolkit.sh check-failed >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# ============================================================================
# RECOMMENDED COMPREHENSIVE SETUP
# ============================================================================
# Copy and paste these lines into: sudo crontab -e
#
# # Daily updates at 2 AM
# 0 2 * * * /usr/local/bin/system-admin-toolkit.sh update >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
#
# # Full monitoring every 6 hours
# 0 */6 * * * /usr/local/bin/system-admin-toolkit.sh monitor >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
#
# # Disk space check every hour
# 0 * * * * /usr/local/bin/system-admin-toolkit.sh monitor-disk >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
#
# # Service health check every 15 minutes
# */15 * * * * /usr/local/bin/system-admin-toolkit.sh check-failed >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
#
# # System backup every Sunday at 3 AM
# 0 3 * * 0 /usr/local/bin/system-admin-toolkit.sh backup >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
#
# # Log cleanup on the 1st of each month
# 0 4 1 * * /usr/local/bin/system-admin-toolkit.sh cleanup-logs 30 >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
#
# # Daily log rotation
# 0 5 * * * /usr/local/bin/system-admin-toolkit.sh rotate-logs >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1

# ============================================================================
# SETUP INSTRUCTIONS
# ============================================================================
#
# Step 1: Take note of your SCRIPT_PATH
#   sudo cp system-admin-toolkit.sh /usr/local/bin/
#   sudo chmod +x /usr/local/bin/system-admin-toolkit.sh
#
# Step 2: Create log directory for cron executions
#   sudo mkdir -p /var/log/sysadmin-toolkit
#   sudo chmod 755 /var/log/sysadmin-toolkit
#
# Step 3: Edit root crontab
#   sudo crontab -e
#
# Step 4: Paste the cron jobs you want to enable
#
# Step 5: Verify installation
#   sudo crontab -l
#
# Step 6: Check cron logs
#   tail -f /var/log/sysadmin-toolkit/cron-execution.log
#   or
#   grep CRON /var/log/syslog | tail -20

# ============================================================================
# CRON SCHEDULE REFERENCE
# ============================================================================
#
# Minute (0-59)         Hour (0-23)      Day of Month (1-31)
# │                     │                │
# │         Day of Week (0-6)            │
# │         │                            │
# │         │    Month (1-12)            │
# │         │    │                       │
# *  *  *  *  *  command
#
# Common patterns:
# 0 2 * * *     - Every day at 2 AM
# 0 */6 * * *   - Every 6 hours (0:00, 6:00, 12:00, 18:00)
# */30 * * * *  - Every 30 minutes
# 0 3 * * 0     - Weekly on Sunday at 3 AM
# 0 4 1 * *     - Monthly on the 1st at 4 AM
# */5 * * * *   - Every 5 minutes (use sparingly)

# ============================================================================
# MONITORING CRON JOB EXECUTION
# ============================================================================
#
# Check if cron is running:
#   sudo systemctl status cron
#
# View all scheduled jobs:
#   sudo crontab -l
#
# View cron system logs:
#   sudo journalctl -u cron --since "1 hour ago"
#   or
#   grep CRON /var/log/syslog | tail -50
#
# Monitor log output in real-time:
#   tail -f /var/log/sysadmin-toolkit/cron-execution.log
#
# Check specific command execution:
#   grep "system-admin-toolkit.sh" /var/log/syslog

# ============================================================================
# TROUBLESHOOTING
# ============================================================================
#
# Q: My cron jobs are not running
# A: 1. Check cron is running: sudo systemctl restart cron
#    2. Verify crontab: sudo crontab -l
#    3. Use absolute paths: /usr/local/bin/system-admin-toolkit.sh (not relative)
#    4. Check logs: grep CRON /var/log/syslog
#
# Q: Email notifications not working
# A: 1. Install mailutils: sudo apt-get install mailutils
#    2. Configure email in the script
#    3. Test: echo "test" | mail -s "test" admin@example.com
#
# Q: Cron jobs running but output not captured
# A: Add redirection: >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1
#
# Q: Permission denied errors
# A: Run as root: sudo crontab -e (not user crontab)
#    Ensure script is executable: sudo chmod +x /usr/local/bin/system-admin-toolkit.sh
#
# Q: Jobs not completing - "command not found"
# A: Use absolute paths in cron (not relative paths or aliases)
#    Check: which system-admin-toolkit.sh

# ============================================================================
# EXAMPLE SETUP SCRIPT
# ============================================================================
#
# If you want to automate cron setup, create a setup script:
#
# #!/bin/bash
# # Copy script to system location
# sudo cp system-admin-toolkit.sh /usr/local/bin/
# sudo chmod +x /usr/local/bin/system-admin-toolkit.sh
#
# # Create log directory
# sudo mkdir -p /var/log/sysadmin-toolkit
# sudo chmod 755 /var/log/sysadmin-toolkit
#
# # Install cron jobs
# (sudo crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/system-admin-toolkit.sh update >> /var/log/sysadmin-toolkit/cron-execution.log 2>&1") | sudo crontab -
#
# # Verify
# echo "Cron jobs installed:"
# sudo crontab -l

# ============================================================================
# ADDITIONAL RESOURCES
# ============================================================================
#
# Cron format generator:
#   https://crontab.guru/
#
# Bash scripting best practices:
#   https://mywiki.wooledge.org/BashGuide
#
# Linux System Administration:
#   man crontab
#   man cron

