#!/usr/bin/env python3
import runpy
from pathlib import Path

ENGINE_PATH = Path(__file__).resolve().parents[1] / "stock_trend_engine.py"
runpy.run_path(str(ENGINE_PATH), run_name="__main__")
