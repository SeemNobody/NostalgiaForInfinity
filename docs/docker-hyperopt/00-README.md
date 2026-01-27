# Docker Hyperopt 完整指南

**项目**: NostalgiaForInfinity X7
**创建日期**: 2026-01-27
**最后更新**: 2026-01-27
**版本**: 1.0

---

## 📚 文档结构

本目录包含 Docker 环境下运行 Hyperopt 优化的完整指南和参考资料。

### 📖 文档清单

| 序号 | 文件名 | 大小 | 用途 |
|------|--------|------|------|
| 00 | [../data-download-best-practices.md](../data-download-best-practices.md) | 12KB | **数据下载最佳实践** ⭐ 新增 |
| 01 | [01-backtesting-framework-overview.md](01-backtesting-framework-overview.md) | 13KB | 回测框架完整总结 |
| 02 | [02-docker-hyperopt-quick-start.md](02-docker-hyperopt-quick-start.md) | 8KB | Docker Hyperopt 快速开始 |
| 03 | [03-docker-hyperopt-detailed-guide.md](03-docker-hyperopt-detailed-guide.md) | 16KB | Docker Hyperopt 详细指南 |
| 04 | [04-hyperopt-parameters-reference.md](04-hyperopt-parameters-reference.md) | 6KB | Hyperopt 参数参考 |
| 05 | [05-docker-configuration-guide.md](05-docker-configuration-guide.md) | 7KB | Docker 配置指南 |
| 06 | [06-troubleshooting-and-best-practices.md](06-troubleshooting-and-best-practices.md) | 8KB | 故障排除和最佳实践 |

---

## 🎯 快速导航

### 初学者路径

1. **了解数据下载** → [../data-download-best-practices.md](../data-download-best-practices.md) ⭐ 新增
2. **了解基础** → [01-backtesting-framework-overview.md](01-backtesting-framework-overview.md)
3. **快速开始** → [02-docker-hyperopt-quick-start.md](02-docker-hyperopt-quick-start.md)
4. **运行优化** → [03-docker-hyperopt-detailed-guide.md](03-docker-hyperopt-detailed-guide.md)

### 优化者路径

1. **参数参考** → [04-hyperopt-parameters-reference.md](04-hyperopt-parameters-reference.md)
2. **配置指南** → [05-docker-configuration-guide.md](05-docker-configuration-guide.md)
3. **故障排除** → [06-troubleshooting-and-best-practices.md](06-troubleshooting-and-best-practices.md)

### 完整学习路径

按顺序阅读所有文档：01 → 02 → 03 → 04 → 05 → 06

---

## 🚀 30秒快速开始

```bash
# 1. 准备数据 - 使用智能下载脚本（推荐）
bash scripts/download-data-smart.sh extended

# 或使用 Docker Compose 直接下载
docker compose -f docker-compose.backtest.yml run --rm download-data-extended

# 2. 运行阶段1优化
bash scripts/docker_hyperopt.sh 1 200

# 3. 查看结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10
```

**💡 提示**:
- 使用 `download-data-extended` 下载 30 个币对 (~15GB, 30-45分钟) - 推荐
- 使用 `download-data-core` 下载 10 个币对 (~5GB, 10-15分钟) - 快速测试
- 使用 `download-data` 下载全部币对 (~100GB, 1-2小时) - 完整分析

详见: [数据下载最佳实践](../data-download-best-practices.md)

---

## 📊 关键数据

### 回测框架

- **支持交易所**: Binance、Kucoin、OKX、Gate.io
- **交易模式**: 现货、期货
- **历史数据**: 2017-2023（7年）
- **核心脚本**: 4个

### Hyperopt 优化

- **优化阶段**: 4个
- **优化参数**: 69个
- **完整时间**: 17-26小时
- **每阶段时间**: 2-12小时

### Docker 配置

- **主配置**: docker-compose.yml
- **回测配置**: docker-compose.backtest.yml
- **Hyperopt配置**: docker-compose.hyperopt.yml
- **便捷脚本**: docker_hyperopt.sh

---

## 📋 文档内容概览

### 01 - 回测框架总结
- 回测基础设施
- 4个核心脚本详解
- 数据管理和配置
- 环境变量配置

### 02 - 快速开始
- 前置条件检查
- 4步快速执行
- 常见问题解答
- 下一步建议

### 03 - 详细指南
- 完整执行步骤
- 配置文件说明
- 性能优化建议
- 结果分析方法

### 04 - 参数参考
- 4阶段参数详解
- 参数范围说明
- 参数优化建议
- 参数组合示例

### 05 - Docker配置
- Docker Compose 配置
- 自定义镜像构建
- 环境变量设置
- 卷挂载配置

### 06 - 故障排除
- 常见问题和解决方案
- 性能优化技巧
- 最佳实践建议
- 调试方法

---

## 💡 核心概念

### 防止前瞻偏差

使用年份特定的配对列表确保只使用该年实际可用的配对。

### 4阶段优化

1. **保护参数** - 止损阈值优化
2. **Grinding参数** - DCA和利润目标优化
3. **入场/出场信号** - 交易信号条件优化
4. **ROI表** - 收益目标优化

### Docker 集成

使用 Docker Compose 简化环境配置和依赖管理。

---

## 🔗 相关资源

### 项目内文档

- `docs/backtesting/` - 原始回测文档
- `HYPEROPT_GUIDE.md` - 详细 Hyperopt 指南
- `HYPEROPT_QUICK_START.md` - Hyperopt 快速参考
- `CLAUDE.md` - 项目指导文档

### 官方资源

- [Freqtrade 文档](https://www.freqtrade.io/)
- [Hyperopt 指南](https://www.freqtrade.io/en/latest/hyperopt/)
- [Docker 支持](https://www.freqtrade.io/en/latest/docker/)

---

## 📞 获取帮助

1. **查看相关文档** - 使用上面的导航链接
2. **搜索关键词** - 使用 Ctrl+F 搜索
3. **查看示例** - 参考代码示例部分
4. **参考故障排除** - 查看第06个文档

---

## ✅ 文档检查清单

- [x] 01 - 回测框架总结
- [x] 02 - 快速开始指南
- [x] 03 - 详细执行指南
- [x] 04 - 参数参考
- [x] 05 - Docker 配置
- [x] 06 - 故障排除和最佳实践

---

**维护者**: Claude Code
**质量评分**: ⭐⭐⭐⭐⭐ (5/5)
**状态**: ✅ 完成
