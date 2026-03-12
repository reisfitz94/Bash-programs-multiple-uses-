# Stock Trend Analyzer (Hybrid Bash+Python)

## Overview
A robust, production-grade tool for identifying high-growth stock opportunities using multi-indicator confirmation, volatility-adjusted trailing stops, volume confirmation, Bollinger Bands, and automated backtesting. Combines Bash orchestration with a Python analytics engine for reliability and extensibility.

---

## Prerequisites
- Bash 5+
- Python 3.9+
- Python packages: yfinance, pandas, ta, numpy
  - Install with: `pip install yfinance pandas ta numpy`
- (Optional) ShellCheck for Bash linting
- (Optional) Ruff for Python linting/formatting

---

## Usage
```bash
cd scripts/
./stock-trend-analyzer.sh --symbols AAPL,MSFT,GOOG --days 180 --min_gain 2.0
```
- `--symbols` (required): Comma-separated list of stock symbols
- `--days` (optional): Lookback period in days (default: 180)
- `--min_gain` (optional): Minimum gain threshold (default: 2.0 = doubled)
- `--verbose` (optional): Enable verbose logging
- `--help`: Show usage

---

## What It Does
- Fetches historical stock data for each symbol
- Computes technical indicators: SMA, RSI, ATR, Bollinger Bands, volume
- Applies multi-indicator confirmation and backtesting logic
- Outputs a ranked, machine-readable CSV table of buy/hold/sell candidates
- Logs all actions to `/var/log/stock-trend-analyzer.log`
- Cleans up temp files and handles errors gracefully

---

## Output Example
```
Symbol  Start   End     Gain  Cross   RSI   ATR   LastVol  AvgVol  MaxDraw  Sharpe  Action
AAPL    150.12  310.24 2.07  golden  62.1  4.12  120000   90000   -0.18    1.12    BUY
MSFT    200.00  390.00 1.95  golden  58.2  3.98  95000    80000   -0.15    1.05    HOLD
GOOG    100.00  180.00 1.80  death   40.0  5.10  110000   95000   -0.22    0.98    SELL
```

---

## Advanced
- All options are CLI flags: `--symbols`, `--days`, `--min_gain`, `--verbose`
- Output is safe CSV, suitable for further automation or reporting
- See comments at the top of each script for adaptation ideas (crypto, log analysis, etc.)

---

## Troubleshooting
- Check `/var/log/stock-trend-analyzer.log` for errors
- Ensure all Python dependencies are installed
- For large symbol lists, ensure your server has sufficient memory and CPU

---

## Extending
- Adapt the Bash wrapper for other data science workflows (log analysis, security monitoring, etc.)
- Extend the Python engine for new indicators, data sources, or analytics
