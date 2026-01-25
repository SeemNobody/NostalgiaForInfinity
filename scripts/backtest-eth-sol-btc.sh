#!/bin/bash
# =============================================================================
# ETH/SOL/BTC Binance Futures Backtest Runner - 1 Year (2025-2026)
# =============================================================================
# Usage:
#   ./scripts/backtest-eth-sol-btc.sh [MODE]
#
# Modes:
#   download      - Download ETH/SOL/BTC historical data (1 year: 2025-2026)
#   backtest      - Run 1-year backtest (recommended)
#   help          - Show this help message
#
# Example workflow:
#   1. ./scripts/backtest-eth-sol-btc.sh download  # Download 1 year of data
#   2. ./scripts/backtest-eth-sol-btc.sh backtest  # Run the backtest
#
# =============================================================================

set -e

COMPOSE_FILE="docker-compose.backtest.yml"
MODE="${1:-backtest}"

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

log_header() {
    echo -e "${BLUE}===========================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================================${NC}"
}

# Create necessary directories
mkdir -p user_data/data
mkdir -p user_data/logs
mkdir -p user_data/backtest_results

case "$MODE" in
    download)
        log_header "Downloading ETH/SOL/BTC Binance Futures Data (2025-2026)"
        log_info "Time range: 2025-01-16 to 2026-01-16 (1 year)"
        log_info "Trading pairs: ETH/USDT:USDT, SOL/USDT:USDT, BTC/USDT:USDT"
        log_warn "This will download data for 1 year with 5 timeframes (5m, 15m, 1h, 4h, 1d)"
        log_warn "Download time depends on your internet connection speed"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose -f "$COMPOSE_FILE" run --rm download-data-eth-sol-btc
            log_info "ETH/SOL/BTC data download completed!"
            log_info "Data saved to: user_data/data/binance/futures/"
        else
            log_info "Download cancelled."
        fi
        ;;

    backtest)
        log_header "Running ETH/SOL/BTC Binance Futures Backtest (2025-2026)"
        log_info "Strategy: NostalgiaForInfinityX7"
        log_info "Time range: 2025-01-16 to 2026-01-16 (1 year)"
        log_info "Trading pairs: ETH/USDT:USDT, SOL/USDT:USDT, BTC/USDT:USDT"
        log_info "Trading mode: Futures (Isolated Margin)"
        log_warn "Make sure you have downloaded the data first!"
        log_warn "Run './scripts/backtest-eth-sol-btc.sh download' if you haven't yet"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose -f "$COMPOSE_FILE" run --rm backtest-eth-sol-btc-2025
            log_info "Backtest completed!"
            log_info "Results saved to: user_data/backtest_results/"
            log_info "Report: user_data/logs/backtest-eth-sol-btc-2025-2026.log"
        else
            log_info "Backtest cancelled."
        fi
        ;;

    help|--help|-h)
        echo "Usage: $0 [MODE]"
        echo ""
        echo "ETH/SOL/BTC Binance Futures Backtest Runner - 1 Year (2025-2026)"
        echo ""
        echo "Modes:"
        echo "  download      - Download ETH/SOL/BTC historical data (1 year)"
        echo "  backtest      - Run 1-year backtest (default)"
        echo "  help          - Show this help message"
        echo ""
        echo "Example workflow:"
        echo "  1. $0 download      # First: download ETH/SOL/BTC data"
        echo "  2. $0 backtest      # Run the backtest"
        echo ""
        echo "Strategy Details:"
        echo "  - Strategy: NostalgiaForInfinityX7"
        echo "  - Timeframe: 5 minutes (5m, 15m, 1h, 4h, 1d multi-timeframe analysis)"
        echo "  - Trading Mode: Futures with Isolated Margin"
        echo "  - Pairs: ETH/USDT:USDT, SOL/USDT:USDT, BTC/USDT:USDT"
        echo "  - Reporting: Daily breakdown with signals export"
        ;;

    *)
        log_error "Unknown mode: $MODE"
        log_info "Run '$0 help' for usage information"
        exit 1
        ;;
esac
