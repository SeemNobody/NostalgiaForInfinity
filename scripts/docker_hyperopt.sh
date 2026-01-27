#!/bin/bash

# ============================================================
# Docker Hyperopt启动脚本
# ============================================================
# 使用Docker运行NostalgiaForInfinityX7 Hyperopt优化
# ============================================================

set -e

PROJECT_DIR="/Users/colin/IdeaProjects/NostalgiaForInfinity"
cd "$PROJECT_DIR"

PHASE=${1:-1}
EPOCHS=${2:-200}
LOSS_FUNCTION=${3:-SharpeHyperOptLossDaily}

echo "=========================================="
echo "Docker Hyperopt启动脚本"
echo "=========================================="
echo "项目目录: $PROJECT_DIR"
echo "优化阶段: $PHASE"
echo "Epochs: $EPOCHS"
echo "损失函数: $LOSS_FUNCTION"
echo "=========================================="
echo ""

# 定义阶段配置
case $PHASE in
  1)
    SPACES="protection"
    RESULT_DIR="user_data/hyperopt_results/phase1_results"
    ;;
  2)
    SPACES="grinding"
    RESULT_DIR="user_data/hyperopt_results/phase2_results"
    ;;
  3)
    SPACES="buy sell"
    RESULT_DIR="user_data/hyperopt_results/phase3_results"
    ;;
  4)
    SPACES="roi"
    RESULT_DIR="user_data/hyperopt_results/phase4_results"
    ;;
  *)
    echo "错误: 无效的阶段 $PHASE (应为 1-4)"
    exit 1
    ;;
esac

# 创建结果目录
mkdir -p "$RESULT_DIR"

echo "优化空间: $SPACES"
echo "结果目录: $RESULT_DIR"
echo ""

# 构建Docker镜像
echo "📦 构建Docker镜像..."
docker-compose -f docker-compose.yml build

# 运行Hyperopt
echo ""
echo "🚀 启动Hyperopt优化 (阶段 $PHASE)..."
echo ""

docker-compose -f docker-compose.yml run --rm freqtrade hyperopt \
  --strategy NostalgiaForInfinityX7Hyperopt \
  --config configs/hyperopt-x7.json \
  --config configs/pairlist-backtest-static-binance-spot-usdt.json \
  --hyperopt-loss "$LOSS_FUNCTION" \
  --spaces $SPACES \
  --epochs $EPOCHS \
  --timerange 20240101-20250101 \
  --hyperopt-random-state 42 \
  --min-trades 50 \
  --jobs -1 \
  --print-all \
  | tee "$RESULT_DIR/hyperopt_$(date +%Y%m%d_%H%M%S).log"

echo ""
echo "=========================================="
echo "✅ 阶段 $PHASE 优化完成!"
echo "=========================================="
echo ""
echo "结果保存在: $RESULT_DIR/"
echo ""
echo "查看最佳结果:"
echo "  docker-compose -f docker-compose.yml run --rm freqtrade hyperopt-show --best -n 10"
echo ""
echo "导出最佳参数:"
echo "  docker-compose -f docker-compose.yml run --rm freqtrade hyperopt-show --best --print-json > $RESULT_DIR/phase${PHASE}_best_params.json"
echo "=========================================="
