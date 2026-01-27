# 02 - Docker Hyperopt 快速开始

**文档编号**: 02
**创建日期**: 2026-01-27
**用途**: 快速上手 Docker Hyperopt 优化

---

## 🚀 30秒快速开始

```bash
# 1. 准备数据（首次运行）
docker compose -f docker-compose.backtest.yml run --rm download-data

# 2. 运行阶段1优化
bash scripts/docker_hyperopt.sh 1 200

# 3. 查看结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10
```

---

## ✅ 前置条件检查

在开始之前，请确保以下条件满足：

### 系统要求

- [ ] Docker 已安装：`docker --version`
- [ ] Docker Compose 已安装：`docker compose --version`
- [ ] 磁盘空间充足（至少 100GB 可用）
- [ ] 网络连接稳定
- [ ] 系统冷却（避免热启动）

### 项目文件

- [ ] `docker-compose.hyperopt.yml` 存在
- [ ] `scripts/docker_hyperopt.sh` 存在
- [ ] `configs/hyperopt-x7.json` 存在
- [ ] `NostalgiaForInfinityX7Hyperopt.py` 存在

### 备份

- [ ] 备份现有的 hyperopt 结果：
  ```bash
  cp -r user_data/hyperopt_results user_data/hyperopt_results.backup
  ```

---

## 📋 4步快速执行

### 第一步：准备数据（30-60分钟）

```bash
cd /Users/colin/IdeaProjects/NostalgiaForInfinity

# 下载必要的历史数据
docker compose -f docker-compose.backtest.yml run --rm download-data
```

**预期输出**:
- 下载 Binance Futures 2021-2026 的 5 分钟数据
- 数据大小：50-100GB
- 完成后显示数据大小信息

### 第二步：运行阶段1优化（2-4小时）

```bash
# 运行保护参数优化
bash scripts/docker_hyperopt.sh 1 200
```

**参数说明**:
- `1` - 阶段1（保护参数）
- `200` - 200个epoch

**预期输出**:
- Docker 镜像构建
- Hyperopt 优化进度
- 日志保存到 `user_data/hyperopt_results/phase1_results/`

### 第三步：查看结果（5分钟）

```bash
# 查看最佳结果（前10个）
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10

# 导出最佳参数为JSON
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json > user_data/hyperopt_results/phase1_best_params.json
```

### 第四步：继续后续阶段（可选）

```bash
# 阶段2：Grinding参数 (8-12小时)
bash scripts/docker_hyperopt.sh 2 200

# 阶段3：入场信号 (6-8小时)
bash scripts/docker_hyperopt.sh 3 200

# 阶段4：ROI表 (1-2小时)
bash scripts/docker_hyperopt.sh 4 200
```

---

## ⏱️ 时间估算

| 步骤 | 任务 | 时间 | 累计 |
|------|------|------|------|
| 1 | 数据准备 | 30-60分钟 | 30-60分钟 |
| 2 | 阶段1优化 | 2-4小时 | 2.5-5小时 |
| 3 | 查看结果 | 5分钟 | 2.5-5小时 |
| 4 | 后续阶段 | 15-22小时 | 17-27小时 |

---

## 🎯 常见问题解答

### Q1: 我可以跳过数据下载吗？

**A**: 如果你已经有历史数据，可以跳过。检查：
```bash
ls -lh user_data/data/binance/futures/5m/
```

### Q2: 我可以只运行一个阶段吗？

**A**: 可以。每个阶段是独立的：
```bash
bash scripts/docker_hyperopt.sh 1 200  # 只运行阶段1
```

### Q3: 我可以加快优化速度吗？

**A**: 可以，减少 epoch 数：
```bash
bash scripts/docker_hyperopt.sh 1 50   # 50个epoch而不是200个
```

### Q4: 我可以在后台运行吗？

**A**: 可以，使用 `nohup` 或 `screen`：
```bash
nohup bash scripts/docker_hyperopt.sh 1 200 > hyperopt.log 2>&1 &
```

### Q5: 我如何监控进度？

**A**: 在另一个终端查看日志：
```bash
tail -f user_data/hyperopt_results/phase1_results/hyperopt_*.log
```

---

## 🔧 快速命令参考

### 数据管理

```bash
# 下载数据
docker compose -f docker-compose.backtest.yml run --rm download-data

# 检查数据
ls -lh user_data/data/binance/futures/5m/
```

### Hyperopt 执行

```bash
# 运行阶段1
bash scripts/docker_hyperopt.sh 1 200

# 运行阶段2
bash scripts/docker_hyperopt.sh 2 200

# 运行阶段3
bash scripts/docker_hyperopt.sh 3 200

# 运行阶段4
bash scripts/docker_hyperopt.sh 4 200
```

### 结果查看

```bash
# 查看最佳结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10

# 查看所有结果
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-list

# 导出参数
docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best --print-json > best_params.json
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

## 📊 4阶段优化概览

| 阶段 | 参数类型 | 数量 | 时间 | 说明 |
|------|---------|------|------|------|
| 1 | 保护参数 | 6个 | 2-4小时 | 止损阈值 |
| 2 | Grinding参数 | 24个 | 8-12小时 | DCA和利润 |
| 3 | 入场/出场 | 35个 | 6-8小时 | 交易信号 |
| 4 | ROI表 | 4个 | 1-2小时 | 收益目标 |

---

## 🎓 下一步建议

### 立即可做

1. ✅ 检查前置条件
2. ✅ 准备数据
3. ✅ 运行阶段1优化

### 短期（1-2周）

1. 完成所有 4 阶段优化
2. 分析优化结果
3. 进行 Walk-Forward 验证

### 长期（1-3个月）

1. 优化策略参数
2. 进行实盘测试
3. 持续监控和改进

---

## 📚 相关文档

- [00-README.md](00-README.md) - 文档总览
- [01-backtesting-framework-overview.md](01-backtesting-framework-overview.md) - 回测框架
- [03-docker-hyperopt-detailed-guide.md](03-docker-hyperopt-detailed-guide.md) - 详细指南
- [04-hyperopt-parameters-reference.md](04-hyperopt-parameters-reference.md) - 参数参考
- [05-docker-configuration-guide.md](05-docker-configuration-guide.md) - Docker 配置
- [06-troubleshooting-and-best-practices.md](06-troubleshooting-and-best-practices.md) - 故障排除

---

## 💡 提示

- 💾 **定期备份**: 优化结果很宝贵，定期备份
- 📊 **监控进度**: 使用 `tail -f` 监控日志
- 🔄 **增量优化**: 可以在前一阶段的基础上继续优化
- 📈 **验证结果**: 始终在样本外数据上验证

---

**维护者**: Claude Code
**创建日期**: 2026-01-27
**状态**: ✅ 完成
