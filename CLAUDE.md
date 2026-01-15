# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NostalgiaForInfinity (NFI) is an advanced cryptocurrency trading strategy framework for Freqtrade. It implements a multi-mode trading system supporting both long and short positions across various market conditions.

**Key Characteristics:**
- Main strategy file: `NostalgiaForInfinityX7.py` (~73,000 lines, latest version)
- Required timeframe: 5 minutes (`timeframe = "5m"`)
- Multi-timeframe analysis: 5m, 15m, 1h, 4h, 1d + BTC reference
- Startup candles: 800

## Common Commands

### Testing
```bash
# Run all tests (parallel execution)
pytest

# Run specific test file
pytest tests/unit/test_NFIX5.py -v

# Run backtests only
pytest tests/backtests/ -v

# Run with coverage
pytest --cov=. --cov-report=html
```

### Code Quality
```bash
# Format code
ruff format .

# Lint check
ruff check .

# Fix linting issues
ruff check --fix .

# Run pre-commit hooks
pre-commit run --all-files
```

### Docker Development
```bash
# Start trading bot
docker compose up -d

# Run tests in container
docker compose -f docker-compose.tests.yml up

# View logs
docker compose logs -f
```

### Backtesting (via Freqtrade)
```bash
# Basic backtest
freqtrade backtesting --strategy NostalgiaForInfinityX7 --timerange 20240101-20250101

# With specific config
freqtrade backtesting --strategy NostalgiaForInfinityX7 -c configs/exampleconfig.json
```

## Architecture

### Core Lifecycle Methods (NostalgiaForInfinityX7)

| Method | Purpose |
|--------|---------|
| `populate_indicators()` | Calculates all technical indicators across timeframes |
| `populate_entry_trend()` | Generates long/short entry signals with mode tags |
| `populate_exit_trend()` | Generates exit signals |
| `custom_exit()` | Routes exits by trading mode via `enter_tag` |
| `adjust_trade_position()` | Handles DCA (averaging down) and profit-taking |

### Trading Mode System

Trades are tagged with `enter_tag` to route to appropriate exit logic:

| Mode | Long Tags | Short Tags | Purpose |
|------|-----------|------------|---------|
| Normal | 1-13 | 501-502 | Standard trading |
| Pump | 21-26 | 521-526 | Quick upward momentum |
| Quick | 41-53 | 541-550 | Short-term profits |
| Rebuy | 61-63 | 561 | Position averaging |
| Rapid | 101-110 | 601-610 | High-frequency entry |
| Grind | 120 | 620 | DCA-focused |
| Scalp | 161-163 | 661 | Micro-profit trades |
| Top Coins | 141-145 | 641-642 | Large-cap focused |
| BTC | 121 | N/A | Bitcoin-specific |

### Data Flow
```
populate_indicators() → Calculate 5m + merge 15m/1h/4h/1d + BTC indicators
         ↓
populate_entry_trend() → Evaluate conditions → Assign enter_tag
         ↓
Trade Execution → adjust_trade_position() (DCA/profit-taking)
         ↓
custom_exit() → Route by enter_tag → mode-specific exit method
```

### Key Design Patterns

1. **Strategy Pattern**: Trading modes via `enter_tag` routing
2. **Configuration Pattern**: `NFI_SAFE_PARAMETERS` whitelist for JSON overrides
3. **Cache Pattern**: `process_only_new_candles = True` + persistent profit targets

## Configuration

### Required Settings (in Freqtrade config)
```json
{
  "use_exit_signal": true,
  "exit_profit_only": false,
  "ignore_roi_if_entry_signal": true
}
```

### Strategy Parameter Override (via nfi_parameters)
```json
{
  "nfi_parameters": {
    "futures_mode_leverage": 3.0,
    "stop_threshold_spot": 0.10
  }
}
```

### Config Files Structure
- `configs/exampleconfig.json` - Base template
- `configs/trading_mode-*.json` - Spot/futures specific
- `configs/pairlist-*.json` - Exchange pair lists
- `configs/blacklist-*.json` - Excluded pairs

## Code Style

- Line length: 119 (Black)
- Linter: Ruff (rules: E4, E9, F, B, Q)
- Max complexity: 12 (McCabe)
- Pre-commit: Ruff check + format

## Testing Strategy

### CI/CD Backtests (`.github/workflows/backtests.yml`)
- Triggered on X7 strategy changes
- Tests across 24 months (2024-01 to 2026-01)
- Three exchange configurations: Kucoin Spot, Binance Spot, Binance Futures
- Generates JUnit XML reports

### Unit Tests
- Located in `tests/unit/`
- Focus on cache functionality and strategy components

## Version History

Multiple strategy versions exist (X through X7). **X7 is the active development version.**
- Signal tuning commits follow pattern: "signal X: fine tune"
- All changes validated via automated backtesting
