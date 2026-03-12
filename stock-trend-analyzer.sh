#!/bin/bash
# Strict mode: safer Bash
set -euo pipefail

################################################################################
# Stock Trend Analyzer: Find High-Growth Stocks (Professional Grade)
#
# Example Use Cases / Adaptations:
#   - Stock trend analysis (default)
#   - Crypto trend analysis (swap yfinance for crypto API)
#   - Batch analytics on CSVs (pass CSV file to Python engine)
#   - Data pipeline orchestration (call multiple analytics engines)
#   - Automated reporting (schedule via cron, email results)
#   - Any data science workflow: Bash for orchestration, Python for analytics
#
# This Bash wrapper can be adapted for:
#   - Log file analysis
#   - Security monitoring (call Python/R for anomaly detection)
#   - Cloud resource monitoring (call Python for AWS/GCP/Azure metrics)
#   - API stress testing (call Python for requests, stats)
#   - Database migration/validation (call Python for DB ops)
#
# See the Python analytics engine for more data science examples.
################################################################################

set -euo pipefail

LOG_FILE="/var/log/stock-trend-analyzer.log"
VERBOSE=0
SYMBOLS=""
DAYS=180
MIN_GAIN=2.0
API_TOOL="yfinance"

log() {

    # Call Python analytics engine
    python3 "$(dirname "$0")/stock_trend_engine.py" -s "$SYMBOLS" -d "$DAYS" -g "$MIN_GAIN" > /tmp/stock_trend_results.csv

    log "Analysis complete. Candidates:"
    column -t -s, /tmp/stock_trend_results.csv | tee /dev/tty

# Helper: Calculate Bollinger Bands (N-day, 2 stddev)
bollinger() {
    local file="$1"; local n="$2"
    awk -F, -v N="$n" 'NR>1{a[NR]=$5} END{for(i=N+1;i<=NR;i++){s=0;for(j=i-N;j<i;j++)s+=a[j];m=s/N;sd=0;for(j=i-N;j<i;j++)sd+=(a[j]-m)^2;sd=sqrt(sd/N);print m, m+2*sd, m-2*sd, a[i]}}' "$file"
}

# Helper: Calculate 10-day average volume
avg_vol() {
    local file="$1"
    awk -F, 'NR>1{a[NR]=$7} END{s=0; for(i=NR-9;i<=NR;i++)s+=a[i]; print s/10}' "$file"
}

# Main analysis function
analyze_stock() {
    local symbol="$1"
    local days="$2"
    local min_gain="$3"
    local csv="/tmp/${symbol}_hist.csv"
    yfinance history "$symbol" --period ${days}d --interval 1d --csv > "$csv" 2>/dev/null || {
        log "Failed to fetch data for $symbol"; return 1; }
    local first last
    first=$(awk -F, 'NR==2{print $5}' "$csv")
    last=$(awk -F, 'END{print $5}' "$csv")
    if [[ -z "$first" || -z "$last" ]]; then
        log "No data for $symbol"; return 1
    fi
    local gain
    gain=$(awk -v f="$first" -v l="$last" 'BEGIN{printf "%.2f", l/f}')
    # Multi-indicator confirmation
    # 1. Golden/Death Cross
    local sma50 sma200 cross
    sma50=$(sma "$csv" 50 | tail -1)
    sma200=$(sma "$csv" 200 | tail -1)
    cross="none"
    if [[ $(echo "$sma50 > $sma200" | bc -l) -eq 1 ]]; then cross="golden"; fi
    if [[ $(echo "$sma50 < $sma200" | bc -l) -eq 1 ]]; then cross="death"; fi
    # 2. RSI filter
    local rsi14
    rsi14=$(rsi "$csv" 14 | tail -1)
    # 3. ATR trailing stop (use 2x ATR below last close)
    local atr14 stop
    atr14=$(atr "$csv" 14 | tail -1)
    stop=$(awk -v l="$last" -v a="$atr14" 'BEGIN{printf "%.2f", l-2*a}')
    # 4. Volume confirmation
    local avgvol lastvol
    avgvol=$(avg_vol "$csv")
    lastvol=$(awk -F, 'END{print $7}' "$csv")
    local volspike=0
    if [[ $(echo "$lastvol > 1.5 * $avgvol" | bc -l) -eq 1 ]]; then volspike=1; fi
    # 5. Bollinger Bands
    local bbmean bbup bblow
    read bbmean bbup bblow _ < <(bollinger "$csv" 20 | tail -1)
    # 6. Backtest: max drawdown, win/loss, Sharpe (simple)
    # (For brevity, only max drawdown shown here)
    local maxdraw=0 peak=0 trough=0
    awk -F, 'NR>1{if($5>p)p=$5;if(p-$5>m)m=p-$5} END{print m}' "$csv" | { read maxdraw; }
    # Decision logic
    local action="HOLD"
    if (( $(echo "$gain >= $min_gain" | bc -l) )) && [[ "$cross" == "golden" ]] && (( $(echo "$rsi14 > 30" | bc -l) )) && (( volspike == 1 )) && (( $(echo "$last > $bblow" | bc -l) )); then
        action="BUY"
    elif [[ "$cross" == "death" ]] && (( $(echo "$rsi14 > 30" | bc -l) )) && (( volspike == 1 )) && (( $(echo "$last < $stop" | bc -l) )); then
        action="SELL"
    elif (( $(echo "$last < $bblow" | bc -l) )); then
        action="HOLD (Mean Reversion)"
    fi
    echo "$symbol,$first,$last,$gain,$cross,$rsi14,$atr14,$lastvol,$avgvol,$maxdraw,$action"
}

log "Analyzing stocks: $SYMBOLS for $DAYS days, min gain $MIN_GAIN"
results="/tmp/stock_trend_results.csv"
echo "Symbol,Start,End,Gain,Cross,RSI,ATR,LastVol,AvgVol,MaxDrawdown,Action" > "$results"
for sym in "${SYMBOL_ARR[@]}"; do
    res=$(analyze_stock "$sym" "$DAYS" "$MIN_GAIN") && [[ -n "$res" ]] && echo "$res" >> "$results"
done

log "Analysis complete. Candidates:"
column -t -s, "$results" | tee /dev/tty
