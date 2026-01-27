#!/bin/bash

# ============================================================
# 阶段4: ROI表优化
# ============================================================
# 目标: 微调退出时机
# 参数数量: 4个 (ROI表)
# Epochs: 100
# 损失函数: SharpeHyperOptLossDaily
# 时间范围: 20240101-20250101
# 预计时间: 1-2小时
# 注意: X7使用 ignore_roi_if_entry_signal=True, ROI影响较小
# ============================================================

set -e

STRATEGY="NostalgiaForInfinityX7Hyperopt"
TIMERANGE="20240101-20250101"
EPOCHS=100
HYPEROPT_LOSS="SharpeHyperOptLossDaily"
SPACES="roi"
RESULT_DIR="user_data/hyperopt_results/phase4_results"
PHASE1_RESULT_DIR="user_data/hyperopt_results/phase1_results"
PHASE2_RESULT_DIR="user_data/hyperopt_results/phase2_results"
PHASE3_RESULT_DIR="user_data/hyperopt_results/phase3_results"

echo "=========================================="
echo "阶段4: ROI表优化"
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
PHASE3_PARAMS="$PHASE3_RESULT_DIR/phase3_best_params.json"

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

if [ -f "$PHASE3_PARAMS" ]; then
  echo "✓ 加载阶段3最佳参数: $PHASE3_PARAMS"
  EXTRA_CONFIGS="$EXTRA_CONFIGS --config $PHASE3_PARAMS"
else
  echo "⚠ 警告: 未找到阶段3参数文件"
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
echo "阶段4优化完成!"
echo "=========================================="
echo ""
echo "结果保存在: $RESULT_DIR/"
echo ""
echo "查看最佳结果 (前10个):"
echo "  freqtrade hyperopt-show --best -n 10"
echo ""
echo "导出最佳参数到JSON:"
echo "  freqtrade hyperopt-show --best --print-json > $RESULT_DIR/phase4_best_params.json"
echo ""
echo "=========================================="
echo "所有4个阶段优化完成!"
echo "=========================================="
echo ""
echo "最终回测验证:"
echo "  freqtrade backtesting \\"
echo "    --strategy NostalgiaForInfinityX7 \\"
echo "    --config configs/exampleconfig.json \\"
echo "    --config $RESULT_DIR/phase4_best_params.json \\"
echo "    --timerange 20240101-20250101 \\"
echo "    --breakdown month"
echo ""
echo "Walk-Forward验证 (测试期):"
echo "  freqtrade backtesting \\"
echo "    --strategy NostalgiaForInfinityX7 \\"
echo "    --config configs/exampleconfig.json \\"
echo "    --config $RESULT_DIR/phase4_best_params.json \\"
echo "    --timerange 20250101-20260101 \\"
echo "    --breakdown month"
echo "=========================================="
