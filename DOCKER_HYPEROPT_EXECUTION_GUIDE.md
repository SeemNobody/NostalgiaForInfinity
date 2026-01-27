# Docker Hyperopt 执行指南

**创建日期**: 2026-01-27
**项目**: NostalgiaForInfinity X7
**目的**: 完整的 Docker 环境下 Hyperopt 优化执行指南

---

## 📚 文档阅读总结

### 核心文档内容

#### 1. backtesting-execution.md - 回测执行流程
- **完整的回测工作流程**：数据准备 → 标准回测 → 坏买信号检测
- **核心脚本**：
  - `backtesting-all.sh` - 主编排脚本
  - `backtesting-all-years-all-pairs.sh` - 年度全对回测
  - `backtesting-for-hunting-bad-buys.sh` - 坏买信号检测
- **环境变量配置**：
  - `EXCHANGE` - 交易所（binance, kucoin, okx, gateio）
  - `TRADING_MODE` - 交易模式（spot/futures）
  - `STRATEGY_NAME` - 策略名称（默认：NostalgiaForInfinityX6）
  - `TIMERANGE` - 时间范围（如：20230101-20230501）
- **资源需求**：
  - 最小 96GB RAM
  - 多核 CPU
  - 完整执行可能需要 4 天

#### 2. backtesting-data-and-configuration.md - 数据和配置管理
- **静态配对列表**：`pairlist-backtest-static-*.json`
  - 按交易所和交易模式分类
  - 防止动态配对选择引入偏差
- **年份特定的配对可用性文件**：`pairs-available-*-{year}.json`
  - 防止前瞻偏差（lookahead bias）
  - 确保只使用该年实际可用的配对
  - 从 2017 年开始的历史数据
- **焦点组测试配置**：用于高潜力配对的集中评估
- **与 Freqtrade 的集成**：通过配置文件堆叠实现

#### 3. backtesting.md - 回测基础设施
- **完整的回测基础设施概览**
- **数据下载脚本**：`download-necessary-exchange-market-data-for-backtests.sh`
  - 使用 Git sparse checkout 高效下载
  - 支持多个交易所和交易模式
  - 下载主要时间框架（5m）和辅助时间框架（1d, 4h, 1h, 15m, 1m）
- **分析和可视化脚本**：
  - `backtesting-analysis.sh` - 统计分析
  - `backtesting-analysis-plot.sh` - 可视化分析
- **Hyperopt 优化部分**（第9章）
  - 参数空间定义
  - 损失函数选择
  - 验证策略

---

## 🚀 Docker 运行 Hyperopt 的完整指南

### 📋 前置条件检查

```bash
# 检查必要文件
✅ NostalgiaForInfinityX7Hyperopt.py - 已存在
✅ configs/hyperopt-x7.json - 已存在
✅ docker-compose.hyperopt.yml - 已存在
✅ scripts/docker_hyperopt.sh - 已存在
✅ user_data/hyperopt_results/ - 已存在

# 检查 Docker 环境
docker --version
docker compose --version
```

### 🎯 执行步骤

#### **第一步：准备数据**

```bash
cd /Users/colin/IdeaProjects/NostalgiaForInfinity

# 下载必要的历史数据（如果还没有）
# 这将下载 Binance Futures 2021-2026 的 5 分钟数据
docker compose -f docker-compose.backtest.yml run --rm download-data

# 预计下载时间：30-60 分钟
# 预计数据大小：50-100GB
```

#### **第二步：运行 Hyperopt 优化（4个阶段）**

**方案 A：使用 Docker Compose 直接运行**

```bash
# 阶段1：保护参数优化 (2-4小时)
docker compose -f docker-compose.hyperopt.yml run --rm hyperopt-phase1

# 查看阶段1结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10
```

**方案 B：使用便捷脚本运行（推荐）**

```bash
# 阶段1：保护参数 (2-4小时)
bash scripts/docker_hyperopt.sh 1 200

# 阶段2：Grinding参数 (8-12小时)
bash scripts/docker_hyperopt.sh 2 200

# 阶段3：入场信号 (6-8小时)
bash scripts/docker_hyperopt.sh 3 200

# 阶段4：ROI表 (1-2小时)
bash scripts/docker_hyperopt.sh 4 200
```

#### **第三步：查看优化结果**

```bash
# 查看最佳结果（前10个）
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10

# 查看所有结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list

# 导出最佳参数为JSON
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json > user_data/hyperopt_results/best_params.json

# 查看特定阶段的结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list --space protection
```

#### **第四步：验证优化结果**

```bash
# 使用优化后的参数进行完整回测（训练期：2024年）
docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/best_params.json \
  --timerange 20240101-20250101 \
  --breakdown month \
  --export-filename user_data/backtest_results/validation_2024.json

# Walk-Forward验证（测试期：2025年）
docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/best_params.json \
  --timerange 20250101-20260101 \
  --breakdown month \
  --export-filename user_data/backtest_results/validation_2025.json
```

---

## 📊 Hyperopt 优化参数概览

### 4阶段优化结构

| 阶段 | 参数类型 | 数量 | 执行时间 | 优化空间 | 说明 |
|------|---------|------|---------|---------|------|
| **1** | 保护参数 | 6个 | 2-4小时 | `protection` | 止损阈值优化 |
| **2** | Grinding参数 | 24个 | 8-12小时 | `grinding` | DCA和利润目标优化 |
| **3** | 入场/出场信号 | 35个 | 6-8小时 | `buy sell` | 交易信号条件优化 |
| **4** | ROI表 | 4个 | 1-2小时 | `roi` | 收益目标优化 |
| **总计** | - | **69个** | **17-26小时** | - | 完整优化周期 |

### 阶段1：保护参数（6个）

```
- stop_threshold_spot (0.05-0.20)
- stop_threshold_futures (0.05-0.20)
- stop_threshold_rapid_spot (0.10-0.30)
- stop_threshold_rapid_futures (0.10-0.30)
- stop_threshold_scalp_spot (0.10-0.30)
- stop_threshold_scalp_futures (0.10-0.30)
```

### 阶段2：Grinding参数（24个）

```
- Grind 1-6: stop_grinds (-0.80至-0.30)
- Grind 1-6: profit_threshold (0.010-0.050)
```

### 阶段3：入场/出场信号（35个）

```
- 27个多头条件开关
- 8个空头条件开关
```

### 阶段4：ROI表（4个）

```
- ROI时间点和收益率配置
```

---

## ⚙️ 关键配置说明

### hyperopt-x7.json 配置详解

```json
{
  "max_open_trades": 6,                    // 最多同时开6笔交易
  "stake_currency": "USDT",                // 使用USDT作为基础货币
  "stake_amount": "unlimited",             // 无限制的投注金额
  "timeframe": "5m",                       // 主要时间框架：5分钟
  "dry_run": true,                         // 干运行模式（不真实交易）
  "dry_run_wallet": 10000,                 // 虚拟钱包：10000 USDT

  "backtest": {
    "timerange": "20240101-20250101",      // 训练期：2024年全年
    "max_open_trades": 6,
    "stake_amount": "unlimited",
    "dry_run_wallet": 10000,
    "enable_protections": false
  },

  "hyperopt": {
    "hyperopt_loss": "SharpeHyperOptLossDaily",  // 使用Sharpe比率作为损失函数
    "hyperopt_jobs": -1,                         // 使用所有CPU核心
    "hyperopt_epochs": 200,                      // 每个阶段200个epoch
    "hyperopt_min_trades": 50,                   // 最少50笔交易
    "hyperopt_random_state": 42                  // 随机种子（可重复性）
  },

  "nfi_parameters": {
    "grinding_enable": true,               // 启用Grinding模式
    "derisk_enable": true,                 // 启用风险管理
    "stops_enable": true,                  // 启用止损
    "doom_stops_enable": true              // 启用极端止损
  }
}
```

### Docker Compose 配置结构

```yaml
x-common-settings:
  &common-settings
  image: freqtradeorg/freqtrade:stable
  build:
    context: .
    dockerfile: "./docker/Dockerfile.custom"
  volumes:
    - "./user_data:/freqtrade/user_data"
    - "./configs:/freqtrade/configs"
    - "./NostalgiaForInfinityX7Hyperopt.py:/freqtrade/NostalgiaForInfinityX7Hyperopt.py"
  env_file:
    - path: .env
      required: false

services:
  hyperopt-phase1:
    <<: *common-settings
    container_name: nfi_hyperopt_phase1
    command: >
      hyperopt
      --strategy NostalgiaForInfinityX7Hyperopt
      --config configs/hyperopt-x7.json
      --config configs/pairlist-backtest-static-binance-spot-usdt.json
      --hyperopt-loss SharpeHyperOptLossDaily
      --spaces protection
      --epochs 200
      --timerange 20240101-20250101
      --hyperopt-random-state 42
      --min-trades 50
      --jobs -1
      --print-all
```

---

## 🔧 Docker 脚本详解

### docker_hyperopt.sh 脚本功能

```bash
#!/bin/bash
# 用途：简化 Docker Hyperopt 执行
# 用法：bash scripts/docker_hyperopt.sh <PHASE> [EPOCHS] [LOSS_FUNCTION]

# 参数说明：
# PHASE: 1-4（对应4个优化阶段）
# EPOCHS: 默认200（每个阶段的迭代次数）
# LOSS_FUNCTION: 默认SharpeHyperOptLossDaily（损失函数）

# 示例：
bash scripts/docker_hyperopt.sh 1 200 SharpeHyperOptLossDaily
```

### 脚本执行流程

```
1. 验证阶段参数（1-4）
2. 根据阶段设置优化空间（protection/grinding/buy sell/roi）
3. 创建结果目录
4. 构建Docker镜像
5. 运行Hyperopt优化
6. 保存日志到结果目录
7. 显示完成信息和后续步骤
```

---

## 💡 最佳实践建议

### ✅ 执行前检查清单

- [ ] Docker 已安装并运行：`docker --version`
- [ ] Docker Compose 已安装：`docker compose --version`
- [ ] 磁盘空间充足（至少 100GB 可用）
- [ ] 网络连接稳定
- [ ] 备份现有的 hyperopt 结果：`cp -r user_data/hyperopt_results user_data/hyperopt_results.backup`
- [ ] 关闭其他占用 CPU 的应用
- [ ] 系统冷却（避免热启动）

### ⚡ 性能优化

#### 1. 限制 CPU 使用（如果系统过载）

```bash
# 使用4个核心而不是全部
export FREQTRADE__HYPEROPT__HYPEROPT_JOBS=4
bash scripts/docker_hyperopt.sh 1 200
```

#### 2. 减少 Epochs 以加快测试

```bash
# 只运行50个epoch而不是200个（用于快速测试）
bash scripts/docker_hyperopt.sh 1 50
```

#### 3. 使用更短的时间范围进行快速测试

```bash
# 修改 hyperopt-x7.json 中的 timerange
"backtest": {
  "timerange": "20240601-20240901"  // 只测试3个月
}
```

#### 4. 使用内存缓存加速

```bash
# 在 Docker 中启用缓存
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt \
  --strategy NostalgiaForInfinityX7Hyperopt \
  --cache default \  # 使用缓存
  ...
```

### 📈 结果分析

#### 查看优化结果

```bash
# 查看所有优化结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list

# 查看特定阶段的结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list --space protection

# 查看前10个最佳结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10

# 查看特定结果的详细信息
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 1 --print-json
```

#### 生成详细报告

```bash
# 使用提供的报告生成脚本
python scripts/generate_hyperopt_report.py

# 输出文件：HYPEROPT_EXECUTION_REPORT.md
```

#### 导出参数

```bash
# 导出最佳参数为JSON
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json > user_data/hyperopt_results/best_params.json

# 导出特定阶段的最佳参数
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json --space protection > user_data/hyperopt_results/phase1_best_params.json
```

### 🔍 故障排除

#### 问题1：Docker 镜像构建失败

```bash
# 解决方案：清理并重新构建
docker compose -f docker-compose.hyperopt.yml down
docker system prune -a
docker compose -f docker-compose.hyperopt.yml build --no-cache
```

#### 问题2：内存不足

```bash
# 解决方案：减少并发任务
export FREQTRADE__HYPEROPT__HYPEROPT_JOBS=2
bash scripts/docker_hyperopt.sh 1 100  # 减少epochs
```

#### 问题3：数据不足

```bash
# 解决方案：重新下载数据
docker compose -f docker-compose.backtest.yml run --rm download-data --timerange 20240101-20250101
```

#### 问题4：优化停滞

```bash
# 解决方案：检查日志
tail -f user_data/hyperopt_results/phase1_results/hyperopt_*.log

# 查看是否有错误
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list --trials
```

---

## 🎯 快速开始命令

### 最小化执行（快速测试）

```bash
cd /Users/colin/IdeaProjects/NostalgiaForInfinity

# 1. 准备数据（如果还没有）
docker compose -f docker-compose.backtest.yml run --rm download-data

# 2. 运行阶段1优化（快速版本，50个epoch）
bash scripts/docker_hyperopt.sh 1 50

# 3. 查看结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 5
```

### 完整执行（生产环境）

```bash
cd /Users/colin/IdeaProjects/NostalgiaForInfinity

# 1. 准备数据
docker compose -f docker-compose.backtest.yml run --rm download-data

# 2. 运行所有4个阶段
bash scripts/docker_hyperopt.sh 1 200  # 2-4小时
bash scripts/docker_hyperopt.sh 2 200  # 8-12小时
bash scripts/docker_hyperopt.sh 3 200  # 6-8小时
bash scripts/docker_hyperopt.sh 4 200  # 1-2小时

# 3. 导出最佳参数
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json > user_data/hyperopt_results/final_best_params.json

# 4. 验证结果
docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/final_best_params.json \
  --timerange 20250101-20260101 \
  --breakdown month
```

### 监控执行进度

```bash
# 在另一个终端中监控日志
tail -f user_data/hyperopt_results/phase1_results/hyperopt_*.log

# 或使用 watch 命令实时更新
watch -n 5 'docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list --best -n 5'
```

---

## 📁 文件结构

```
NostalgiaForInfinity/
├── configs/
│   ├── hyperopt-x7.json                          # Hyperopt配置
│   ├── exampleconfig.json                        # 基础配置
│   ├── trading_mode-futures.json                 # 期货交易模式
│   ├── pairlist-backtest-static-*.json           # 静态配对列表
│   └── blacklist-*.json                          # 黑名单配置
├── scripts/
│   ├── docker_hyperopt.sh                        # Docker Hyperopt启动脚本
│   ├── run_hyperopt_phase*.sh                    # 各阶段执行脚本
│   └── generate_hyperopt_report.py               # 报告生成脚本
├── user_data/
│   ├── data/                                     # 历史市场数据
│   ├── hyperopt_results/
│   │   ├── phase1_results/                       # 阶段1结果
│   │   ├── phase2_results/                       # 阶段2结果
│   │   ├── phase3_results/                       # 阶段3结果
│   │   └── phase4_results/                       # 阶段4结果
│   ├── backtest_results/                         # 回测结果
│   └── logs/                                     # 执行日志
├── NostalgiaForInfinityX7.py                     # 主策略文件
├── NostalgiaForInfinityX7Hyperopt.py             # Hyperopt策略类
├── docker-compose.yml                           # 主Docker配置
├── docker-compose.hyperopt.yml                  # Hyperopt Docker配置
├── docker-compose.backtest.yml                  # 回测Docker配置
└── DOCKER_HYPEROPT_EXECUTION_GUIDE.md            # 本文档
```

---

## 📞 参考资源

### 相关文档
- `docs/backtesting/backtesting.md` - 回测基础设施
- `docs/backtesting/backtesting-execution.md` - 回测执行流程
- `docs/backtesting/backtesting-data-and-configuration.md` - 数据配置
- `HYPEROPT_GUIDE.md` - 详细的Hyperopt指南
- `HYPEROPT_QUICK_START.md` - 快速参考

### 相关脚本
- `scripts/docker_hyperopt.sh` - Docker Hyperopt启动脚本
- `scripts/run_hyperopt_phase*.sh` - 各阶段执行脚本
- `scripts/generate_hyperopt_report.py` - 报告生成脚本

### Freqtrade 官方资源
- [Freqtrade 文档](https://www.freqtrade.io/)
- [Hyperopt 指南](https://www.freqtrade.io/en/latest/hyperopt/)
- [Docker 支持](https://www.freqtrade.io/en/latest/docker/)

---

## 📝 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|---------|
| 2026-01-27 | 1.0 | 初始版本，包含完整的Docker Hyperopt执行指南 |

---

**文档维护者**: Claude Code
**最后更新**: 2026-01-27
**状态**: ✅ 完成
