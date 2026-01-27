# 03 - Docker Hyperopt 详细指南

**文档编号**: 03
**创建日期**: 2026-01-27
**用途**: 深入了解 Docker Hyperopt 的完整执行流程

---

## 📖 概述

本文档提供了 Docker 环境中运行 Hyperopt 优化的完整详细指南，包括配置、执行、监控和验证。

---

## 🔧 完整执行步骤

### 第一步：环境准备

#### 1.1 检查 Docker 环境

```bash
# 检查 Docker 版本
docker --version
# 预期输出: Docker version 20.10+

# 检查 Docker Compose 版本
docker compose --version
# 预期输出: Docker Compose version 2.0+

# 检查 Docker 守护进程
docker ps
# 预期输出: 容器列表（可能为空）
```

#### 1.2 检查磁盘空间

```bash
# 检查可用空间
df -h /Users/colin/IdeaProjects/NostalgiaForInfinity
# 需要至少 100GB 可用空间

# 检查项目大小
du -sh /Users/colin/IdeaProjects/NostalgiaForInfinity
```

#### 1.3 备份现有数据

```bash
# 备份 hyperopt 结果
cp -r user_data/hyperopt_results user_data/hyperopt_results.backup

# 备份数据库
cp -r user_data/*.sqlite* user_data/backup/
```

### 第二步：数据准备

#### 2.1 下载历史数据

```bash
cd /Users/colin/IdeaProjects/NostalgiaForInfinity

# 下载数据（首次运行）
docker compose -f docker-compose.backtest.yml run --rm download-data
```

**预期输出**:
```
Cloning into 'HistoricalDataForTradeBacktest'...
Configuring sparse checkout...
Adding patterns...
Checking out files...
Downloaded data size: XX GB
```

**下载内容**:
- Binance Futures 5m 数据（2021-2026）
- 辅助时间框架（1d, 4h, 1h, 15m, 1m）

#### 2.2 验证数据

```bash
# 检查数据目录
ls -lh user_data/data/binance/futures/5m/ | head -20

# 检查数据文件数量
find user_data/data -name "*.feather" | wc -l

# 检查最新数据
ls -lt user_data/data/binance/futures/5m/ | head -5
```

### 第三步：运行 Hyperopt 优化

#### 3.1 阶段1：保护参数优化

```bash
# 运行阶段1
bash scripts/docker_hyperopt.sh 1 200
```

**执行流程**:
1. 构建 Docker 镜像
2. 启动容器
3. 运行 Hyperopt 优化
4. 保存日志

**预期时间**: 2-4小时

**日志位置**: `user_data/hyperopt_results/phase1_results/hyperopt_*.log`

#### 3.2 阶段2：Grinding参数优化

```bash
# 运行阶段2
bash scripts/docker_hyperopt.sh 2 200
```

**预期时间**: 8-12小时

#### 3.3 阶段3：入场/出场信号优化

```bash
# 运行阶段3
bash scripts/docker_hyperopt.sh 3 200
```

**预期时间**: 6-8小时

#### 3.4 阶段4：ROI表优化

```bash
# 运行阶段4
bash scripts/docker_hyperopt.sh 4 200
```

**预期时间**: 1-2小时

### 第四步：结果分析

#### 4.1 查看优化结果

```bash
# 查看最佳结果（前10个）
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10

# 查看所有结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list

# 查看特定阶段的结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list --space protection
```

#### 4.2 导出最佳参数

```bash
# 导出最佳参数为JSON
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json > user_data/hyperopt_results/best_params.json

# 导出特定阶段的最佳参数
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json --space protection > user_data/hyperopt_results/phase1_best_params.json
```

### 第五步：结果验证

#### 5.1 使用优化参数回测

```bash
# 训练期回测（2024年）
docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/best_params.json \
  --timerange 20240101-20250101 \
  --breakdown month \
  --export-filename user_data/backtest_results/validation_2024.json

# 测试期回测（2025年）
docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/best_params.json \
  --timerange 20250101-20260101 \
  --breakdown month \
  --export-filename user_data/backtest_results/validation_2025.json
```

#### 5.2 分析验证结果

```bash
# 查看回测结果
freqtrade backtesting-analysis \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/best_params.json
```

---

## ⚙️ 配置文件详解

### hyperopt-x7.json

```json
{
  "max_open_trades": 6,                    // 最多同时开6笔交易
  "stake_currency": "USDT",                // 使用USDT
  "stake_amount": "unlimited",             // 无限制投注
  "timeframe": "5m",                       // 主要时间框架
  "dry_run": true,                         // 干运行模式
  "dry_run_wallet": 10000,                 // 虚拟钱包10000 USDT

  "backtest": {
    "timerange": "20240101-20250101",      // 训练期：2024年
    "max_open_trades": 6,
    "stake_amount": "unlimited",
    "dry_run_wallet": 10000
  },

  "hyperopt": {
    "hyperopt_loss": "SharpeHyperOptLossDaily",  // 损失函数
    "hyperopt_jobs": -1,                         // 使用所有CPU核心
    "hyperopt_epochs": 200,                      // 每阶段200个epoch
    "hyperopt_min_trades": 50,                   // 最少50笔交易
    "hyperopt_random_state": 42                  // 随机种子
  }
}
```

### docker-compose.hyperopt.yml

```yaml
services:
  hyperopt-phase1:
    image: freqtradeorg/freqtrade:stable
    volumes:
      - "./user_data:/freqtrade/user_data"
      - "./configs:/freqtrade/configs"
      - "./NostalgiaForInfinityX7Hyperopt.py:/freqtrade/NostalgiaForInfinityX7Hyperopt.py"
    command: >
      hyperopt
      --strategy NostalgiaForInfinityX7Hyperopt
      --config configs/hyperopt-x7.json
      --hyperopt-loss SharpeHyperOptLossDaily
      --spaces protection
      --epochs 200
      --timerange 20240101-20250101
      --jobs -1
```

---

## 📊 性能优化

### 1. 限制 CPU 使用

```bash
# 使用4个核心而不是全部
export FREQTRADE__HYPEROPT__HYPEROPT_JOBS=4
bash scripts/docker_hyperopt.sh 1 200
```

### 2. 减少 Epochs

```bash
# 快速测试：50个epoch
bash scripts/docker_hyperopt.sh 1 50

# 标准优化：200个epoch
bash scripts/docker_hyperopt.sh 1 200

# 深度优化：500个epoch
bash scripts/docker_hyperopt.sh 1 500
```

### 3. 使用更短的时间范围

```bash
# 修改 hyperopt-x7.json
"backtest": {
  "timerange": "20240601-20240901"  // 只测试3个月
}
```

### 4. 启用缓存

```bash
# 在 Docker 中启用缓存
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt \
  --strategy NostalgiaForInfinityX7Hyperopt \
  --cache default \
  ...
```

---

## 🔍 监控和调试

### 实时监控

```bash
# 在另一个终端监控日志
tail -f user_data/hyperopt_results/phase1_results/hyperopt_*.log

# 使用 watch 命令实时更新
watch -n 5 'docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list --best -n 5'
```

### 检查容器状态

```bash
# 列出运行中的容器
docker ps

# 查看容器日志
docker logs nfi_hyperopt_phase1

# 进入容器调试
docker exec -it nfi_hyperopt_phase1 /bin/bash
```

### 性能监控

```bash
# 监控 CPU 和内存使用
docker stats nfi_hyperopt_phase1

# 监控磁盘使用
du -sh user_data/

# 监控网络连接
netstat -an | grep ESTABLISHED | wc -l
```

---

## 📈 结果分析

### 查看优化结果

```bash
# 查看最佳结果的详细信息
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 1 --print-json | jq .

# 比较不同阶段的结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list --space protection
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list --space grinding
```

### 生成报告

```bash
# 使用提供的报告生成脚本
python scripts/generate_hyperopt_report.py

# 输出文件：HYPEROPT_EXECUTION_REPORT.md
```

---

## 🔗 相关文档

- [00-README.md](00-README.md) - 文档总览
- [01-backtesting-framework-overview.md](01-backtesting-framework-overview.md) - 回测框架
- [02-docker-hyperopt-quick-start.md](02-docker-hyperopt-quick-start.md) - 快速开始
- [04-hyperopt-parameters-reference.md](04-hyperopt-parameters-reference.md) - 参数参考
- [05-docker-configuration-guide.md](05-docker-configuration-guide.md) - Docker 配置
- [06-troubleshooting-and-best-practices.md](06-troubleshooting-and-best-practices.md) - 故障排除

---

**维护者**: Claude Code
**创建日期**: 2026-01-27
**状态**: ✅ 完成
