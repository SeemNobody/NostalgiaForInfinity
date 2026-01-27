#!/bin/bash

# ============================================================
# 阶段3: 入场信号优化
# ============================================================
# 目标: 优化信号组合,提升胜率
# 参数数量: 35个 (27个多头 + 8个空头)
# Epochs: 300
# 损失函数: SharpeHyperOptLossDaily
# 时间范围: 20240101-20250101
# 预计时间: 6-8小时
# ============================================================

set -e

STRATEGY="NostalgiaForInfinityX7Hyperopt"
TIMERANGE="20240101-20250101"
EPOCHS=300
HYPEROPT_LOSS="SharpeHyperOptLossDaily"
SPACES="buy sell"
RESULT_DIR="user_data/hyperopt_results/phase3_results"
PHASE1_RESULT_DIR="user_data/hyperopt_results/phase1_results"
PHASE2_RESULT_DIR="user_data/hyperopt_results/phase2_results"

echo "=========================================="
echo "阶段3: 入场信号优化"
echo "=========================================="
echo "策略: $STRATEGY"
echo "时间范围: $TIMERANGE"
echo "Epochs: $EPOCHS"
echo "优化空间: $SPACES"
echo "损失函数: $HYPEROPT_LOSS"
echo "=========================================="
echo ""

# 创建结果目录
mkdir -p "$RESULT_DIR"

# 检查前序阶段最佳参数
PHASE1_PARAMS="$PHASE1_RESULT_DIR/phase1_best_params.json"
PHASE2_PARAMS="$PHASE2_RESULT_DIR/phase2_best_params.json"

EXTRA_CONFIGS=""

if [ -f "$PHASE1_PARAMS" ]; then
  echo "✓ 加载阶段1最佳参数: $PHASE1_PARAMS"
  EXTRA_CONFIGS="$EXTRA_CONFIGS --config $PHASE1_PARAMS"
else
  echo "⚠ 警告: 未找到阶段1参数文件"
fi

if [ -f "$PHASE2_PARAMS" ]; then
  echo "✓ 加载阶段2最佳参数: $PHASE2_PARAMS"
  EXTRA_CONFIGS="$EXTRA_CONFIGS --config $PHASE2_PARAMS"
else
  echo "⚠ 警告: 未找到阶段2参数文件"
fi

echo ""
echo "开始Hyperopt优化..."
freqtrade hyperopt \
  --strategy "$STRATEGY" \
  --config configs/hyperopt-x7.json \
  --config configs/pairlist-backtest-static-binance-spot-usdt.json \
  $EXTRA_CONFIGS \
  --hyperopt-loss "$HYPEROPT_LOSS" \
  --spaces "$SPACES" \
  --epochs "$EPOCHS" \
  --timerange "$TIMERANGE" \
  --hyperopt-random-state 42 \
  --min-trades 50 \
  --jobs -1 \
  --print-all \
  | tee "$RESULT_DIR/hyperopt_$(date +%Y%m%d_%H%M%S).log"

echo ""
echo "=========================================="
echo "阶段3优化完成!"
echo "=========================================="
echo ""
echo "结果保存在: $RESULT_DIR/"
echo ""
echo "查看最佳结果 (前10个):"
echo "  freqtrade hyperopt-show --best -n 10"
echo ""
echo "导出最佳参数到JSON:"
echo "  freqtrade hyperopt-show --best --print-json > $RESULT_DIR/phase3_best_params.json"
echo ""
echo "下一步: 执行阶段4优化"
echo "  bash scripts/run_hyperopt_phase4.sh"
echo "=========================================="
