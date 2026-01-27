# NostalgiaForInfinityX7 Hyperopt 快速参考

## 🚀 一键执行

```bash
# 阶段1: 保护参数 (2-4小时)
bash scripts/run_hyperopt_phase1.sh

# 阶段2: Grinding参数 (8-12小时)
bash scripts/run_hyperopt_phase2.sh

# 阶段3: 入场信号 (6-8小时)
bash scripts/run_hyperopt_phase3.sh

# 阶段4: ROI表 (1-2小时)
bash scripts/run_hyperopt_phase4.sh
```

## 📊 导出最佳参数

```bash
# 每个阶段完成后执行
freqtrade hyperopt-show --best --print-json > user_data/hyperopt_results/phase{N}_results/phase{N}_best_params.json
```

## ✅ 最终验证

```bash
# 完整回测 (训练期)
freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/phase4_results/phase4_best_params.json \
  --timerange 20240101-20250101 \
  --breakdown month

# Walk-Forward验证 (测试期)
freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/phase4_results/phase4_best_params.json \
  --timerange 20250101-20260101 \
  --breakdown month
```

## 📁 创建的文件

| 文件 | 说明 |
|------|------|
| `NostalgiaForInfinityX7Hyperopt.py` | Hyperopt策略类 |
| `configs/hyperopt-x7.json` | Hyperopt配置 |
| `scripts/run_hyperopt_phase*.sh` | 4个执行脚本 |
| `user_data/hyperopts/loss_functions/profit_drawdown_ratio.py` | 自定义损失函数 |
| `user_data/hyperopt_results/phase*_results/` | 4个结果目录 |
| `HYPEROPT_GUIDE.md` | 完整指南 |

## 🎯 参数概览

### 阶段1: 保护参数 (6个)
- `stop_threshold_spot/futures` (0.05-0.20)
- `stop_threshold_rapid_spot/futures` (0.10-0.30)
- `stop_threshold_scalp_spot/futures` (0.10-0.30)

### 阶段2: Grinding参数 (24个)
- Grind 1-6: `stop_grinds` (-0.80至-0.30)
- Grind 1-6: `profit_threshold` (0.010-0.050)

### 阶段3: 入场信号 (35个)
- 27个多头条件开关
- 8个空头条件开关

### 阶段4: ROI表 (4个)
- ROI时间点和收益率

## ⏱️ 时间估算

| 阶段 | 执行时间 | 总计 |
|------|----------|------|
| 1 | 2-4小时 | 2-4小时 |
| 2 | 8-12小时 | 10-16小时 |
| 3 | 6-8小时 | 16-24���时 |
| 4 | 1-2小时 | 17-26小时 |
| **总计** | - | **17-26小时** |

## ✨ 关键特性

✅ 继承式设计 - 保持X7主文件不变
✅ 4阶段优化 - 避免维度灾难
✅ 自动化脚本 - 一键执行
✅ 自定义损失函数 - 收益/回撤比优化
✅ 完整文档 - 详细指南和故障排除

## 📞 需要帮助?

查看完整指南: `HYPEROPT_GUIDE.md`
