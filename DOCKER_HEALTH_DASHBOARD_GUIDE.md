# Docker Micro-Service Health Dashboard

## Overview
A Bash script that monitors Docker containers, generates a static HTML status page every 60 seconds, and sends a notification to a Slack/Discord webhook if a container restarts unexpectedly.

---

## Usage
```bash
./docker-health-dashboard.sh [WEBHOOK_URL]
```
- `WEBHOOK_URL` — (Optional) Slack or Discord webhook URL for notifications

---

## Features
- Monitors all running Docker containers
- Reports container name, status, health, restart count, CPU %, and memory %
- Generates `/tmp/docker-health-dashboard.html` (auto-refreshes every 60s)
- Detects and notifies on unexpected container restarts
- Sends JSON payload to webhook (Slack/Discord compatible)

---

## Example: Run with Slack Webhook
```bash
./docker-health-dashboard.sh https://hooks.slack.com/services/XXX/YYY/ZZZ
```

## Example: Run without Webhook
```bash
./docker-health-dashboard.sh
```

---

## HTML Output Example
Open `/tmp/docker-health-dashboard.html` in your browser to view live status.

---

## Requirements
- Docker CLI
- curl (for webhook notifications)

---

## Customization
- Change `INTERVAL` in the script to adjust update frequency
- Edit HTML output path as needed
