# 01 - 回测框架完整总结

**文档编号**: 01
**创建日期**: 2026-01-27
**用途**: 理解 NostalgiaForInfinity 的回测框架

---

## 📚 概述

本文档总结了 `docs/backtesting/` 下三个核心文档的内容，提供对项目回测框架的完整理解。

---

## 🏗️ 回测框架架构

### 核心特点

- **多交易所支持**: Binance、Kucoin、OKX、Gate.io
- **多交易模式**: 现货和期货
- **历史数据**: 2017-2023（7年）
- **防前瞻偏差**: 使用年份特定的配对列表
- **完整自动化**: Shell 脚本编排

### 系统流程

```
数据准备 → 标准回测 → 坏买信号检测 → 结果分析 → 报告生成
```

---

## 🔧 核心脚本详解

### 1. backtesting-all.sh

**功能**: 主编排脚本，运行所有交易所和模式的完整回测

**执行流程**:
```
1. 设置环境变量
2. 循环遍历交易所（Binance、Kucoin、OKX、Gate.io）
3. 循环遍历交易模式（现货、期货）
4. 调用 backtesting-all-years-all-pairs.sh
5. 调用 backtesting-for-hunting-bad-buys.sh
```

**资源需求**:
- CPU: 多核处理器
- 内存: 最少 96GB RAM
- 存储: 至少 100GB 可用空间
- 时间: 最多 4 天

### 2. backtesting-all-years-all-pairs.sh

**功能**: 按年份进行全对回测

**执行流程**:
```
1. 设置默认配置
2. 循环遍历年份（2023-2017）
3. 检查配对列表文件是否存在
4. 执行 Freqtrade 回测命令
5. 运行回测分析
6. 记录结果
```

**关键参数**:
- `--cache none` - 禁用缓存
- `--breakdown day` - 按天分解结果
- `--export signals` - 导出交易信号
- `--timeframe-detail 1m` - 1分钟详细分析

### 3. backtesting-focus-group.sh

**功能**: 焦点组测试（高潜力配对的集中评估）

**特点**:
- 使用焦点组配对列表
- 快速迭代策略优化
- 减少计算开销

**执行时间**: 4-6小时

### 4. backtesting-for-hunting-bad-buys.sh

**功能**: 识别潜在的坏买信号

**关键参数**:
```bash
--timeframe-detail 1m          # 1分钟时间框架
--dry-run-wallet 100000        # 大虚拟钱包
--stake-amount 100             # 小投注金额
--max-open-trades 1000         # 最多1000笔开放交易
--eps                          # 启用入场价格模拟
```

**检测方法**:
- 运行高频交易模拟
- 捕获所有可能的入场信号
- 分析信号质量
- 识别问题模式

---

## 📊 数据管理

### 数据下载

**脚本**: `download-necessary-exchange-market-data-for-backtests.sh`

**功能**:
- 从 HistoricalDataForTradeBacktest 仓库下载数据
- 使用 Git sparse checkout 高效下载
- 支持多个交易所和交易模式

**下载的时间框架**:
- 主要: 5m（5分钟）
- 辅助: 1d、4h、1h、15m、1m

### 配对列表管理

#### 静态配对列表

**文件**: `pairlist-backtest-static-{exchange}-{mode}-usdt.json`

**用途**: 确保回测条件一致，防止动态配对选择引入偏差

**示例**:
```json
{
  "exchange": {
    "name": "binance",
    "pair_whitelist": ["BTC/USDT", "ETH/USDT", "ADA/USDT"]
  },
  "pairlists": [{"method": "StaticPairList"}]
}
```

#### 年份特定的配对可用性

**文件**: `pairs-available-{exchange}-{mode}-usdt-{year}.json`

**用途**: 防止前瞻偏差，确保只使用该年实际可用的配对

**现货市场数据**:
- 2017: 31对
- 2018: 47对
- 2019: 63对
- 2020: 85对
- 2021: 105对
- 2022: 125对
- 2023: 145对

**期货市场数据**（从2019年开始）:
- 2019: 25对
- 2020: 45对
- 2021: 65对
- 2022: 85对
- 2023: 105对

---

## 🔑 环境变量配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `EXCHANGE` | binance | 交易所 |
| `TRADING_MODE` | spot | 交易模式 |
| `STRATEGY_NAME` | NostalgiaForInfinityX6 | 策略名称 |
| `STRATEGY_VERSION` | auto-detected | 版本标识 |
| `TIMERANGE` | none | 时间范围 |

**使用示例**:
```bash
export EXCHANGE=binance
export TRADING_MODE=futures
export TIMERANGE=20230101-20231231
./tests/backtests/backtesting-all-years-all-pairs.sh
```

---

## 🎯 使用场景

### 快速回测（开发阶段）

```bash
# 使用焦点组和短时间范围
export TIMERANGE=20230601-20230901
bash tests/backtests/backtesting-focus-group.sh
```

**执行时间**: 4-6小时

### 完整回测（验证阶段）

```bash
# 使用所有交易所和完整时间范围
bash tests/backtests/backtesting-all.sh
```

**执行时间**: 4天

### 坏买信号检测（优化阶段）

```bash
# 运行坏买信号检测
bash tests/backtests/backtesting-for-hunting-bad-buys.sh
```

**执行时间**: 1-2天

---

## 🔍 常见问题和故障排除

### 问题1：缺少依赖

**症状**: Freqtrade 命令不找到
**解决方案**: 确保 Freqtrade 正确安装，检查 requirements.txt

### 问题2：路径错误

**症状**: 文件不找到错误
**解决方案**: 验证目录结构，检查相对路径是否正确

### 问题3：数据不足

**症状**: 回测失败，提示"No data found"
**解决方案**: 运行数据下载脚本，验证 feather 文件存在

### 问题4：连接错误

**症状**: 交易所连接失败
**解决方案**: 调整速率限制
```bash
export FREQTRADE__EXCHANGE__CCXT_CONFIG__RATELIMIT=400
```

### 问题5：内存耗尽

**症状**: 进程被杀死或系统冻结
**解决方案**:
- 使用 TIMERANGE 限制范围
- 在不同机器上并行运行
- 增加系统 RAM

---

## 💡 最佳实践

### 防止前瞻偏差

- ✅ 始终使用年份特定的配对列表
- ✅ 不包含未来引入的配对
- ✅ 使用历史数据匹配回测时期
- ✅ 验证配对列表不包含未来信息

### 数据管理

- ✅ 定期更新配对列表
- ✅ 交叉参考交易所历史数据
- ✅ 处理下市配对
- ✅ 在版本控制中跟踪更改

### 性能优化

- ✅ 使用 SSD 存储加速数据访问
- ✅ 在多台机器上并行运行
- ✅ 使用焦点组进行快速迭代
- ✅ 限制时间范围进行快速测试

---

## 📈 支持的交易所和模式

| 交易所 | 现货 | 期货 | 数据起始 |
|--------|------|------|---------|
| Binance | ✅ | ✅ | 2017 (现货), 2019 (期货) |
| Kucoin | ✅ | ❌ | 2017 |
| OKX | ✅ | ✅ | 2017 (现货), 2019 (期货) |
| Gate.io | ✅ | ✅ | 2017 (现货), 2019 (期货) |

---

## 🔗 相关资源

### 原始文档

- `docs/backtesting/backtesting.md` - 回测基础设施
- `docs/backtesting/backtesting-execution.md` - 执行流程
- `docs/backtesting/backtesting-data-and-configuration.md` - 数据配置

### 脚本位置

- `tests/backtests/backtesting-all.sh`
- `tests/backtests/backtesting-all-years-all-pairs.sh`
- `tests/backtests/backtesting-focus-group.sh`
- `tests/backtests/backtesting-for-hunting-bad-buys.sh`
- `tools/download-necessary-exchange-market-data-for-backtests.sh`

---

## 📝 下一步

阅读完本文档后，建议：

1. **快速开始** → 查看 [02-docker-hyperopt-quick-start.md](02-docker-hyperopt-quick-start.md)
2. **详细指南** → 查看 [03-docker-hyperopt-detailed-guide.md](03-docker-hyperopt-detailed-guide.md)
3. **参数参考** → 查看 [04-hyperopt-parameters-reference.md](04-hyperopt-parameters-reference.md)

---

**维护者**: Claude Code
**创建日期**: 2026-01-27
**状态**: ✅ 完成
