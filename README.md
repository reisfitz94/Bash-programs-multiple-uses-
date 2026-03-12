# Why
Automated pipelines and professional scripts for IT, security, and data science workflows. Example: "Automated pipeline for detecting high-volatility stock trends using multi-indicator confirmation and backtesting."


# How (Quick Start)

## Stock Trend Analyzer (Hybrid Bash+Python)

### Prerequisites
- Python 3.9+
- Bash 5+
- Python packages: `yfinance`, `pandas`, `ta`, `numpy`
	- Install with: `pip install yfinance pandas ta numpy`
- (Optional) ShellCheck for Bash linting
- (Optional) Ruff for Python linting/formatting

### Usage
```bash
cd scripts/
# Basic usage (analyze Apple, Microsoft, Google for 180 days, min gain 2x):
./stock-trend-analyzer.sh --symbols AAPL,MSFT,GOOG --days 180 --min_gain 2.0

# Show help:
./stock-trend-analyzer.sh --help
```

### What it does
- Orchestrates a robust Python analytics engine from Bash
- Fetches historical stock data, computes technical indicators (SMA, RSI, ATR, Bollinger Bands, etc.)
- Applies multi-indicator confirmation and backtesting logic
- Outputs a ranked, machine-readable CSV table of buy/hold/sell candidates
- Logs all actions to `/var/log/stock-trend-analyzer.log`
- Cleans up temp files and handles errors gracefully

### Output Example
```
Symbol  Start   End     Gain  Cross   RSI   ATR   LastVol  AvgVol  MaxDraw  Sharpe  Action
AAPL    150.12  310.24 2.07  golden  62.1  4.12  120000   90000   -0.18    1.12    BUY
MSFT    200.00  390.00 1.95  golden  58.2  3.98  95000    80000   -0.15    1.05    HOLD
GOOG    100.00  180.00 1.80  death   40.0  5.10  110000   95000   -0.22    0.98    SELL
```

### Advanced
- All options are CLI flags: `--symbols`, `--days`, `--min_gain`, `--verbose`
- Output is safe CSV, suitable for further automation or reporting
- See comments at the top of each script for adaptation ideas (crypto, log analysis, etc.)

---

## Template for Other Scripts

### Prerequisites
- See the top of each script for required tools and dependencies

### Usage
```bash
# Example for a generic script
./script-name.sh [options]
# Or for Python
python3 script_name.py [options]
```

### What it does
- See the script's comments or its dedicated GUIDE.md for a summary, features, and options

---

## General Usage
- All scripts use strict mode (`set -euo pipefail` for Bash).
- Python scripts are linted and formatted with Ruff.
- Bash scripts are ShellCheck clean.

# Prerequisites
- Bash 5+
- Python 3.9+
- Python packages: yfinance, pandas, ta, numpy
- (Optional) ShellCheck for Bash linting
- (Optional) Ruff for Python linting/formatting

# Project Structure

```
my-portfolio/
├── README.md            <-- The "Face" of the project
├── .gitignore           <-- Keeping the trash out
├── scripts/
│   ├── stock-trend-analyzer.sh <-- Polished with 'set -euo'
│   └── stock_trend_engine.py    <-- Linted with Ruff
└── tests/
	└── test_logic.py    <-- (Optional) Shows you know how to test
```

# Clean Code Practices
- No hardcoded secrets. Use a `.env` file for sensitive data (not included in repo).
- Workspace is free of .pyc, __pycache__, .DS_Store, and log files (see .gitignore).
- All Python functions use Google-style docstrings.
- All scripts are modular, robust, and ready for production.

# Linting & Formatting
- Python: `pip install ruff && ruff format .`
- Bash: `shellcheck scripts/*.sh`

# Example Extensions
- Adapt Bash wrappers for log analysis, security monitoring, cloud resource checks, API testing, or database ops.
- Adapt Python engine for crypto analytics, anomaly detection, forecasting, or ML scoring.

---

For more, see comments at the top of each script for adaptation ideas and usage examples.
# Bash-programs-multiple-uses-
I created several Bash programs that have several uses, such as software development, automation, and IT and system administration.

---

## 📋 Programs Overview

### 1. System Administration Toolkit (`system-admin-toolkit.sh`)

A comprehensive Bash script designed for IT professionals and system administrators to manage Linux servers efficiently.

**Key Features:**
- ✅ **System Updates** - Automate package updates and software installation
- ✅ **User Management** - Create, modify, and manage user accounts and permissions
- ✅ **Resource Monitoring** - Track disk space, CPU, memory, and service health
- ✅ **Automated Backups** - Schedule system backups and log rotation
- ✅ **Alert System** - Email notifications for critical issues
- ✅ **Cron Integration** - Ready-to-use cron job templates for automation

**Supported Linux Distributions:**
- Debian/Ubuntu (apt package manager)
- RedHat/CentOS (yum package manager)
- Arch Linux (pacman package manager)

**Quick Start:**
```bash
# Make executable
chmod +x system-admin-toolkit.sh

# View help
./system-admin-toolkit.sh help

# Check system status
sudo ./system-admin-toolkit.sh status

# Update system
sudo ./system-admin-toolkit.sh update

# Monitor resources
sudo ./system-admin-toolkit.sh monitor

# Manage users
sudo ./system-admin-toolkit.sh user-add john "John Doe"
sudo ./system-admin-toolkit.sh user-modify john sudo,docker

# Backup system
sudo ./system-admin-toolkit.sh backup
```

**Available Commands:**

**System Updates:**
- `update` - Update all system packages
- `install <package>` - Install specific package

**User Management:**
- `user-add <user> [name] [shell]` - Create user account
- `user-remove <user> [remove-home]` - Delete user account
- `user-modify <user> <groups>` - Modify user group membership
- `list-users` - Display all system users

**Monitoring:**
- `monitor` - Run comprehensive system checks
- `monitor-disk` - Check disk space usage
- `monitor-resources` - Check CPU and memory
- `monitor-services` - Check critical services
- `check-failed` - Find failed systemd services

**Backup & Maintenance:**
- `backup` - Create system backup
- `cleanup-logs` - Remove old log files
- `rotate-logs` - Rotate log files

**Automation:**
- `setup-cron` - Generate cron job templates
- `status` - Display system status summary

**Documentation:**
- 📖 [System Admin Toolkit Guide](SYSTEM_ADMIN_TOOLKIT_GUIDE.md) - Complete documentation and examples
- 📋 [Cron Setup Template](CRON_SETUP_TEMPLATE.sh) - Ready-to-use cron job configurations

**Features:**
- Automatic Linux distribution detection
- Comprehensive logging to `/var/log/sysadmin-toolkit/sysadmin-toolkit.log`
- Color-coded terminal output (Green/Yellow/Red)
- Email alerts for critical events (requires mail utility)
- Template-based cron job setup
- Group-based user permission management
- Service health monitoring with automated alerting
- Disk space warnings with configurable thresholds

**Real-World Use Cases:**
1. **Automated Daily Updates** - Keep all servers patched automatically
2. **User Onboarding** - Quickly create user accounts with proper permissions
3. **Infrastructure Monitoring** - Track resource usage across servers
4. **Disaster Recovery** - Automated backups on a schedule
5. **Log Management** - Prevent disk space issues from excessive logs
6. **Alert System** - Get notified immediately of critical issues
7. **Compliance** - Maintain audit logs of all administrative actions

--- 
