#!/bin/bash
# =============================================================================
# ETH/BTC Binance Futures Backtest Runner
# =============================================================================
# Usage:
#   ./scripts/backtest-eth-btc.sh [MODE]
#
# Modes:
#   download      - Download ETH/BTC historical data (2019-2026)
#   full          - Run full 7-year backtest
#   yearly        - Run yearly backtests separately (recommended)
#   2019-2025     - Run backtest for specific year
# =============================================================================

set -e

COMPOSE_FILE="docker-compose.backtest.yml"
MODE="${1:-yearly}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create necessary directories
mkdir -p user_data/data
mkdir -p user_data/logs
mkdir -p user_data/backtest_results

case "$MODE" in
    download)
        log_info "Downloading ETH/BTC Binance Futures data (2019-2026)..."
        log_warn "This will download data for ETH/USDT:USDT and BTC/USDT:USDT"
        docker compose -f "$COMPOSE_FILE" run --rm download-data-eth-btc
        log_info "ETH/BTC data download completed!"
        ;;

    full)
        log_warn "Running FULL 7-year ETH/BTC backtest (2019-2026)"
        log_warn "This may take some time but requires less memory than full pair list"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose -f "$COMPOSE_FILE" run --rm backtest-eth-btc-full
            log_info "Full ETH/BTC backtest completed! Check user_data/backtest_results/"
        fi
        ;;

    yearly)
        log_info "Running yearly ETH/BTC backtests (2019-2025)..."
        for YEAR in 2019 2020 2021 2022 2023 2024 2025; do
            log_info "Starting ETH/BTC backtest for $YEAR..."
            docker compose -f "$COMPOSE_FILE" run --rm "backtest-eth-btc-$YEAR"
            log_info "ETH/BTC Backtest $YEAR completed!"
        done
        log_info "All yearly ETH/BTC backtests completed! Check user_data/backtest_results/"
        ;;

    2019|2020|2021|2022|2023|2024|2025)
        log_info "Running ETH/BTC backtest for $MODE..."
        docker compose -f "$COMPOSE_FILE" run --rm "backtest-eth-btc-$MODE"
        log_info "ETH/BTC Backtest $MODE completed!"
        ;;

    help|--help|-h)
        echo "Usage: $0 [MODE]"
        echo ""
        echo "ETH/BTC Binance Futures Backtest Runner"
        echo ""
        echo "Modes:"
        echo "  download      - Download ETH/BTC historical data (2019-2026)"
        echo "  full          - Run full 7-year ETH/BTC backtest"
        echo "  yearly        - Run yearly backtests separately (recommended)"
        echo "  2019-2025     - Run backtest for specific year"
        echo ""
        echo "Example workflow:"
        echo "  1. $0 download      # First: download ETH/BTC data"
        echo "  2. $0 yearly        # Run all yearly backtests"
        echo ""
        echo "For full period analysis:"
        echo "  1. $0 download"
        echo "  2. $0 full"
        ;;

    *)
        log_error "Unknown mode: $MODE"
        log_info "Run '$0 help' for usage information"
        exit 1
        ;;
esac
