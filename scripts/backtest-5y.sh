#!/bin/bash
# =============================================================================
# Binance Futures 5-Year Backtest Runner
# =============================================================================
# Usage:
#   ./scripts/backtest-5y.sh [MODE]
#
# Modes:
#   download      - Download all historical data (required first time)
#   download-lite - Download data for top 30 pairs only
#   full          - Run full 5-year backtest (high memory, 32GB+ recommended)
#   yearly        - Run yearly backtests separately (recommended)
#   lite          - Run lightweight backtest with top 30 pairs
#   2021-2025     - Run backtest for specific year
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
        log_info "Downloading 5 years of Binance Futures data..."
        log_warn "This may take several hours depending on your connection."
        log_warn "Data will be stored in user_data/data/"
        docker compose -f "$COMPOSE_FILE" run --rm download-data
        log_info "Data download completed!"
        ;;

    download-lite)
        log_info "Downloading data for top 30 pairs only..."
        docker compose -f "$COMPOSE_FILE" run --rm download-data-lite
        log_info "Lite data download completed!"
        ;;

    full)
        log_warn "Running FULL 5-year backtest (2021-2026)"
        log_warn "This requires 32GB+ RAM and may take several hours!"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose -f "$COMPOSE_FILE" run --rm backtest
            log_info "Full backtest completed! Check user_data/backtest_results/"
        fi
        ;;

    yearly)
        log_info "Running yearly backtests (2021-2025)..."
        for YEAR in 2021 2022 2023 2024 2025; do
            log_info "Starting backtest for $YEAR..."
            docker compose -f "$COMPOSE_FILE" run --rm "backtest-$YEAR"
            log_info "Backtest $YEAR completed!"
        done
        log_info "All yearly backtests completed! Check user_data/backtest_results/"
        ;;

    lite)
        log_info "Running lightweight 5-year backtest (top 30 pairs)..."
        docker compose -f "$COMPOSE_FILE" run --rm backtest-lite
        log_info "Lite backtest completed!"
        ;;

    2021|2022|2023|2024|2025)
        log_info "Running backtest for $MODE..."
        docker compose -f "$COMPOSE_FILE" run --rm "backtest-$MODE"
        log_info "Backtest $MODE completed!"
        ;;

    help|--help|-h)
        echo "Usage: $0 [MODE]"
        echo ""
        echo "Modes:"
        echo "  download      - Download all historical data (required first time)"
        echo "  download-lite - Download data for top 30 pairs only"
        echo "  full          - Run full 5-year backtest (high memory)"
        echo "  yearly        - Run yearly backtests separately (recommended)"
        echo "  lite          - Run lightweight backtest with top 30 pairs"
        echo "  2021-2025     - Run backtest for specific year"
        echo ""
        echo "Example workflow:"
        echo "  1. $0 download      # First time: download data"
        echo "  2. $0 yearly        # Run all yearly backtests"
        echo ""
        echo "For quick testing:"
        echo "  1. $0 download-lite"
        echo "  2. $0 lite"
        ;;

    *)
        log_error "Unknown mode: $MODE"
        log_info "Run '$0 help' for usage information"
        exit 1
        ;;
esac
