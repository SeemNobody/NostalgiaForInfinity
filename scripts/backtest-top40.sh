#!/bin/bash
# =============================================================================
# Binance Futures Top 40 Pairs - 1 Year Backtest Runner
# =============================================================================
# Usage:
#   ./scripts/backtest-top40.sh [MODE]
#
# Modes:
#   download  - Download historical data for top 40 pairs
#   backtest  - Run 1-year backtest (2025-01-01 to 2026-01-01)
#   full      - Download data and run backtest
#   help      - Show usage information
# =============================================================================

set -e

MODE="${1:-help}"
COMPOSE_FILE="docker-compose.backtest.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Create necessary directories
mkdir -p user_data/data/binance
mkdir -p user_data/logs
mkdir -p user_data/backtest_results

download_data() {
    log_info "=========================================="
    log_info "Downloading historical data for Top 40 pairs"
    log_info "Time range: 2025-01-01 to 2026-01-16"
    log_info "Timeframes: 5m, 15m, 1h, 4h, 1d"
    log_info "=========================================="

    log_step "Downloading data... (this may take 15-30 minutes)"

    docker compose -f "$COMPOSE_FILE" run --rm download-data-top40

    log_info "Data download completed!"
    log_info "Data stored in: user_data/data/binance/"
}

run_backtest() {
    log_info "=========================================="
    log_info "Running Backtest: NostalgiaForInfinityX7"
    log_info "Time range: 2025-01-01 to 2026-01-01"
    log_info "Pairs: Top 40 by volume"
    log_info "Mode: Futures (3x leverage)"
    log_info "Initial wallet: 10,000 USDT"
    log_info "Max open trades: 6"
    log_info "=========================================="

    log_step "Starting backtest... (this may take 30-60 minutes)"

    docker compose -f "$COMPOSE_FILE" run --rm backtest-top40

    log_info "Backtest completed!"
    log_info "Results stored in: user_data/backtest_results/"
    log_info "Log file: user_data/logs/backtest-top40-futures-2025.log"
}

show_help() {
    echo "=========================================="
    echo "Binance Top 40 Pairs Backtest Script"
    echo "=========================================="
    echo ""
    echo "Usage: $0 [MODE]"
    echo ""
    echo "Modes:"
    echo "  download  - Download historical data for top 40 pairs"
    echo "  backtest  - Run 1-year backtest (requires data)"
    echo "  full      - Download data and run backtest"
    echo "  help      - Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Strategy:    NostalgiaForInfinityX7"
    echo "  Time range:  2025-01-01 to 2026-01-01"
    echo "  Trading:     Futures (isolated margin, 3x leverage)"
    echo "  Wallet:      10,000 USDT"
    echo "  Max trades:  6"
    echo "  Pairs:       40 (top by volume)"
    echo ""
    echo "Files created:"
    echo "  - configs/pairlist-backtest-top40-binance-futures-usdt.json"
    echo "  - configs/backtest-top40-futures.json"
    echo ""
    echo "Example workflow:"
    echo "  1. $0 download   # First: download historical data"
    echo "  2. $0 backtest   # Then: run backtest"
    echo ""
    echo "Or run everything:"
    echo "  $0 full"
    echo ""
}

case "$MODE" in
    download)
        download_data
        ;;

    backtest)
        run_backtest
        ;;

    full)
        log_info "Running full workflow: download + backtest"
        download_data
        echo ""
        run_backtest
        ;;

    help|--help|-h|"")
        show_help
        ;;

    *)
        log_error "Unknown mode: $MODE"
        log_info "Run '$0 help' for usage information"
        exit 1
        ;;
esac
