# 📚 Backtesting & Hyperopt 文档索引

**创建日期**: 2026-01-27
**项目**: NostalgiaForInfinity X7
**目的**: 统一管理 Backtesting 和 Hyperopt 相关文档

---

## 📖 文档导航

### 🎯 快速导航

| 文档 | 大小 | 行数 | 用途 | 适合人群 |
|------|------|------|------|---------|
| [BACKTESTING_DOCUMENTATION_SUMMARY.md](#backtesting_documentation_summarymd) | 13KB | 588 | 回测文档完整总结 | 想了解回测框架的开发者 |
| [DOCKER_HYPEROPT_EXECUTION_GUIDE.md](#docker_hyperopt_execution_guidemd) | 16KB | 551 | Docker Hyperopt 执行指南 | 想运行 Hyperopt 优化的开发者 |

---

## 📄 BACKTESTING_DOCUMENTATION_SUMMARY.md

### 📋 内容概览

本文档是对 `docs/backtesting/` 下三个核心文档的完整总结：

1. **backtesting.md** - 回测基础设施
2. **backtesting-execution.md** - 回测执行流程
3. **backtesting-data-and-configuration.md** - 数据和配置管理

### 🔑 关键章节

#### 📖 文档1：backtesting.md
- 回测基础设施概览
- 主要回测脚本详解
- 数据下载流程
- 环境变量配置
- 年份特定的配对可用性
- Hyperopt 优化基础

#### 📖 文档2：backtesting-execution.md
- 回测工作流程
- backtesting-all.sh 脚本详解
- backtesting-all-years-all-pairs.sh 脚本详解
- backtesting-for-hunting-bad-buys.sh 脚本详解
- 数据准备和管理
- 常见问题和故障排除
- 性能优化建议

#### 📖 文档3：backtesting-data-and-configuration.md
- 静态配对列表
- 焦点组测试配置
- 年份特定的配对可用性文件
- 与 Freqtrade 的集成
- 自定义配对列表
- 验证过程
- 数据准确性最佳实践
- 常见配置错误

### 💡 核心要点

**支持的交易所**：
- Binance（现货和期货）
- Kucoin（现货）
- OKX（现货和期货）
- Gate.io（现货和期货）

**资源需求**：
- 最小 96GB RAM
- 多核 CPU
- 至少 100GB 可用存储
- 完整执行可能需要 4 天

**关键脚本**：
- `backtesting-all.sh` - 主编排脚本
- `backtesting-all-years-all-pairs.sh` - 年度全对回测
- `backtesting-focus-group.sh` - 焦点组测试
- `backtesting-for-hunting-bad-buys.sh` - 坏买信号检测
- `download-necessary-exchange-market-data-for-backtests.sh` - 数据下载

### 🎯 使用场景

**快速回测**（开发阶段）：
```bash
export TIMERANGE=20230601-20230901
bash tests/backtests/backtesting-focus-group.sh
```

**完整回测**（验证阶段）：
```bash
bash tests/backtests/backtesting-all.sh
```

**坏买信号检测**（优化阶段）：
```bash
bash tests/backtests/backtesting-for-hunting-bad-buys.sh
```

---

## 📄 DOCKER_HYPEROPT_EXECUTION_GUIDE.md

### 📋 内容概览

本文档提供了在 Docker 环境中运行 Hyperopt 优化的完整指南。

### 🔑 关键章节

#### 🚀 快速开始
- 前置条件检查
- 数据准备步骤
- 4阶段优化执行
- 结果查看和验证

#### ⚙️ 配置详解
- hyperopt-x7.json 配置说明
- Docker Compose 配置结构
- docker_hyperopt.sh 脚本功能

#### 💡 最佳实践
- 执行前检查清单
- 性能优化建议
- 结果分析方法
- 故障排除指南

#### 📊 参数概览
- 4阶段优化结构（69个参数）
- 阶段1：保护参数（6个）
- 阶段2：Grinding参数（24个）
- 阶段3：入场/出场信号（35个）
- 阶段4：ROI表（4个）

### 🎯 执行流程

**第一步：准备数据**
```bash
docker compose -f docker-compose.backtest.yml run --rm download-data
```

**第二步：运行 Hyperopt 优化**
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

**第三步：查看结果**
```bash
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10
```

**第四步：验证结果**
```bash
docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/best_params.json \
  --timerange 20250101-20260101 \
  --breakdown month
```

### ⏱️ 时间估算

| 阶段 | 执行时间 | 累计时间 |
|------|---------|---------|
| 1 | 2-4小时 | 2-4小时 |
| 2 | 8-12小时 | 10-16小时 |
| 3 | 6-8小时 | 16-24小时 |
| 4 | 1-2小时 | 17-26小时 |

---

## 🔗 文档关系图

```
docs/backtesting/
├── backtesting.md
├── backtesting-execution.md
└── backtesting-data-and-configuration.md
        ↓
        ↓ (总结)
        ↓
BACKTESTING_DOCUMENTATION_SUMMARY.md
        ↓
        ├─→ 理解回测框架
        ├─→ 学习脚本使用
        └─→ 掌握数据管理

        ↓
        ↓ (应用)
        ↓
DOCKER_HYPEROPT_EXECUTION_GUIDE.md
        ↓
        ├─→ 准备数据
        ├─→ 运行优化
        ├─→ 分析结果
        └─→ 验证参数
```

---

## 📚 相关文档

### 项目内文档

| 文档 | 位置 | 用途 |
|------|------|------|
| HYPEROPT_GUIDE.md | 项目根目录 | 详细的 Hyperopt 指南 |
| HYPEROPT_QUICK_START.md | 项目根目录 | Hyperopt 快速参考 |
| HYPEROPT_IMPLEMENTATION_REPORT.md | 项目根目录 | Hyperopt 实现报告 |
| HYPEROPT_EXECUTION_REPORT.md | 项目根目录 | Hyperopt 执行报告 |
| HYPEROPT_LIVE_REPORT.md | 项目根目录 | Hyperopt 实时报告 |
| CLAUDE.md | 项目根目录 | 项目指导文档 |

### 官方文档

| 资源 | 链接 | 用途 |
|------|------|------|
| Freqtrade 文档 | https://www.freqtrade.io/ | 官方文档 |
| Hyperopt 指南 | https://www.freqtrade.io/en/latest/hyperopt/ | Hyperopt 详解 |
| Docker 支持 | https://www.freqtrade.io/en/latest/docker/ | Docker 集成 |

---

## 🎯 学习路径

### 初学者路径

1. **了解基础** → 阅读 `BACKTESTING_DOCUMENTATION_SUMMARY.md` 的第一部分
2. **理解框架** → 学习回测脚本和数据管理
3. **实践操作** → 运行焦点组回测
4. **深入学习** → 阅读完整的 `docs/backtesting/` 文档

### 优化者路径

1. **快速入门** → 阅读 `DOCKER_HYPEROPT_EXECUTION_GUIDE.md` 的快速开始部分
2. **准备环境** → 检查前置条件和数据
3. **运行优化** → 执行 4 阶段优化
4. **分析结果** → 查看和验证优化结果
5. **深入优化** → 阅读 `HYPEROPT_GUIDE.md` 了解高级技巧

### 完整学习路径

1. **理论基础** → `BACKTESTING_DOCUMENTATION_SUMMARY.md`
2. **实践操作** → `DOCKER_HYPEROPT_EXECUTION_GUIDE.md`
3. **深入研究** → 原始 `docs/backtesting/` 文档
4. **高级应用** → `HYPEROPT_GUIDE.md` 和相关报告

---

## 🔧 常用命令速查

### 数据管理

```bash
# 下载数据
docker compose -f docker-compose.backtest.yml run --rm download-data

# 检查数据
ls -lh user_data/data/
```

### 回测执行

```bash
# 焦点组回测
bash tests/backtests/backtesting-focus-group.sh

# 完整回测
bash tests/backtests/backtesting-all.sh

# 坏买信号检测
bash tests/backtests/backtesting-for-hunting-bad-buys.sh
```

### Hyperopt 优化

```bash
# 阶段1
bash scripts/docker_hyperopt.sh 1 200

# 查看结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10

# 导出参数
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json > user_data/hyperopt_results/best_params.json
```

### 结果验证

```bash
# 使用优化参数回测
docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/best_params.json \
  --timerange 20250101-20260101
```

---

## 📊 文档统计

| 指标 | 值 |
|------|-----|
| 总文档数 | 2 |
| 总行数 | 1,139 |
| 总大小 | 29KB |
| 创建日期 | 2026-01-27 |
| 最后更新 | 2026-01-27 |

---

## ✅ 文档检查清单

- [x] BACKTESTING_DOCUMENTATION_SUMMARY.md 已创建
- [x] DOCKER_HYPEROPT_EXECUTION_GUIDE.md 已创建
- [x] 文档内容完整
- [x] 代码示例正确
- [x] 链接有效
- [x] 格式规范

---

## 📝 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|---------|
| 2026-01-27 | 1.0 | 创建文档索引，链接两个新文档 |

---

## 🎯 下一步建议

### 立即可做

1. ✅ 阅读 `BACKTESTING_DOCUMENTATION_SUMMARY.md` 了解框架
2. ✅ 检查 Docker 环境是否就绪
3. ✅ 准备数据（如果还没有）

### 短期计划

1. 运行焦点组回测进行快速测试
2. 执行第一阶段 Hyperopt 优化
3. 分析优化结果

### 长期计划

1. 完成所有 4 阶段 Hyperopt 优化
2. 进行 Walk-Forward 验证
3. 优化策略参数

---

**文档维护者**: Claude Code
**最后更新**: 2026-01-27
**状态**: ✅ 完成

---

## 📞 获取帮助

- 📖 查看相关文档
- 🔍 搜索关键词
- 💬 查看常见问题
- 🆘 参考故障排除部分
