#!/usr/bin/env python3
"""
Stock Trend Analytics Engine (Python)

Example Use Cases / Adaptations:
    - Stock trend analysis (default)
    - Crypto analytics (use ccxt or requests for crypto data)
    - Batch CSV analytics (read CSVs from Bash, output results)
    - Log file anomaly detection (parse logs, compute stats)
    - Time series forecasting (add ARIMA, Prophet, etc.)
    - Data cleaning/validation (preprocess, output clean CSV)
    - API data aggregation (fetch, analyze, summarize)
    - Any data science workflow: Python for analytics, Bash for orchestration

This Python engine can be adapted for:
    - Security event analysis
    - Cloud resource usage analytics
    - Automated reporting (generate plots, send emails)
    - Database migration/validation (connect to DB, run checks)
    - Machine learning model scoring (load model, score data)
    - Interactive CLI tools (argparse, prompt user)
    - R integration (call R via subprocess or rpy2)
"""

import sys
import argparse
import csv

def calculate_indicators(df):
    """
    Calculates technical indicators for a stock DataFrame.

    Args:
        df (pd.DataFrame): DataFrame with columns ['Open', 'High', 'Low', 'Close', 'Volume']

    Returns:
        pd.DataFrame: DataFrame with added indicator columns.
    """
    df['SMA50'] = SMAIndicator(df['Close'], window=50).sma_indicator()
    df['SMA200'] = SMAIndicator(df['Close'], window=200).sma_indicator()
    df['RSI'] = RSIIndicator(df['Close'], window=14).rsi()
    df['ATR'] = AverageTrueRange(df['High'], df['Low'], df['Close'], window=14).average_true_range()
    bb = BollingerBands(df['Close'], window=20, window_dev=2)
    df['BB_MID'] = bb.bollinger_mavg()
    df['BB_UP'] = bb.bollinger_hband()
    df['BB_LOW'] = bb.bollinger_lband()
    df['Volume_MA10'] = df['Volume'].rolling(10).mean()
    return df

parser = argparse.ArgumentParser(description='Stock Trend Analytics Engine')
parser.add_argument('-s', '--symbols', required=True, help='Comma-separated stock symbols')
parser.add_argument('-d', '--days', type=int, default=180, help='Lookback period (days)')
parser.add_argument('-g', '--min_gain', type=float, default=2.0, help='Min gain (2.0=doubled)')
args = parser.parse_args()

try:
    import numpy as np
    import yfinance as yf
    from ta.momentum import RSIIndicator
    from ta.volatility import AverageTrueRange, BollingerBands
    from ta.trend import SMAIndicator
except ImportError as e:
    print(
        "MISSING_DEPENDENCY," + str(e) + ",install with: pip install pandas numpy yfinance ta",
        file=sys.stderr,
    )
    sys.exit(1)

symbols = [s.strip().upper() for s in args.symbols.split(',')]
results = []

for symbol in symbols:
    try:
        df = yf.download(symbol, period=f'{args.days}d', interval='1d', progress=False)
        if df.empty or len(df) < 200:
            print(f"{symbol},NO_DATA", file=sys.stderr)
            continue
        df['SMA50'] = SMAIndicator(df['Close'], window=50).sma_indicator()
        df['SMA200'] = SMAIndicator(df['Close'], window=200).sma_indicator()
        df['RSI'] = RSIIndicator(df['Close'], window=14).rsi()
        df['ATR'] = AverageTrueRange(df['High'], df['Low'], df['Close'], window=14).average_true_range()
        bb = BollingerBands(df['Close'], window=20, window_dev=2)
        df['BB_MID'] = bb.bollinger_mavg()
        df['BB_UP'] = bb.bollinger_hband()
        df['BB_LOW'] = bb.bollinger_lband()
        df['Volume_MA10'] = df['Volume'].rolling(10).mean()
        # Golden/Death Cross
        cross = 'none'
        if df['SMA50'].iloc[-1] > df['SMA200'].iloc[-1]:
            cross = 'golden'
        if df['SMA50'].iloc[-1] < df['SMA200'].iloc[-1]:
            cross = 'death'
        # Gain
        gain = df['Close'].iloc[-1] / df['Close'].iloc[0]
        # RSI
        rsi = df['RSI'].iloc[-1]
        # ATR trailing stop
        stop = df['Close'].iloc[-1] - 2 * df['ATR'].iloc[-1]
        # Volume spike
        volspike = int(df['Volume'].iloc[-1] > 1.5 * df['Volume_MA10'].iloc[-1])
        # Bollinger mean reversion
        bblow = df['BB_LOW'].iloc[-1]
        # Max drawdown
        roll_max = df['Close'].cummax()
        drawdown = (df['Close'] - roll_max) / roll_max
        maxdraw = drawdown.min()
        # Sharpe ratio (simple, risk-free=0)
        returns = df['Close'].pct_change().dropna()
        sharpe = np.sqrt(252) * returns.mean() / returns.std() if returns.std() > 0 else 0
        # Decision logic
        action = 'HOLD'
        if gain >= args.min_gain and cross == 'golden' and rsi > 30 and volspike and df['Close'].iloc[-1] > bblow:
            action = 'BUY'
        elif cross == 'death' and rsi > 30 and volspike and df['Close'].iloc[-1] < stop:
            action = 'SELL'
        elif df['Close'].iloc[-1] < bblow:
            action = 'HOLD (Mean Reversion)'
        results.append({
            'Symbol': symbol,
            'Start': round(df['Close'].iloc[0],2),
            'End': round(df['Close'].iloc[-1],2),
            'Gain': round(gain,2),
            'Cross': cross,
            'RSI': round(rsi,2),
            'ATR': round(df['ATR'].iloc[-1],2),
            'LastVol': int(df['Volume'].iloc[-1]),
            'AvgVol': int(df['Volume_MA10'].iloc[-1]),
            'MaxDraw': round(maxdraw,2),
            'Sharpe': round(sharpe,2),
            'Action': action
        })
    except Exception as e:
        print(f"{symbol},ERROR,{e}", file=sys.stderr)

# Output CSV
writer = csv.DictWriter(sys.stdout, fieldnames=[
    'Symbol','Start','End','Gain','Cross','RSI','ATR','LastVol','AvgVol','MaxDraw','Sharpe','Action'])
writer.writeheader()
for row in results:
    writer.writerow(row)
