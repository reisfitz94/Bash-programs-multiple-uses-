# Bash Programs Multiple Uses

This repository contains Bash-first automation scripts (plus a few Python helpers) for system administration, monitoring, backups, CI checks, and data workflows.

## Quick Start

- Bash: 5+
- Python: 3.9+
- Optional Python deps for stock analytics: `yfinance`, `pandas`, `numpy`, `ta`

```bash
pip install yfinance pandas numpy ta
```

## Stock Trend Analyzer

Run from repository root:

```bash
./stock-trend-analyzer.sh --symbols AAPL,MSFT,GOOG --days 180 --min_gain 2.0
./stock-trend-analyzer.sh --help
```

The root entrypoint forwards to `scripts/stock-trend-analyzer.sh` for compatibility.

## Repository Layout

```text
.
├── *.sh                          # Standalone Bash tools
├── stock_trend_engine.py         # Analytics engine
├── stock-trend-analyzer.sh       # Canonical stock analyzer entrypoint
├── scripts/
│   ├── stock-trend-analyzer.sh   # Analyzer implementation
│   └── stock_trend_engine.py     # Engine compatibility shim
├── SECURITY.md                   # Vulnerability reporting policy
└── SECURITY_BASELINE.md          # Hardening summary
```

## Security

- See `SECURITY.md` for vulnerability reporting.
- See `SECURITY_BASELINE.md` for the current hardening baseline.

## Notes

- Most scripts log to `/var/log/...`; run with suitable permissions.
- Several scripts use strict Bash mode (`set -euo pipefail`).
