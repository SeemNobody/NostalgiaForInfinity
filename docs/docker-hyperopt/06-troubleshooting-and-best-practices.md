# 06 - 故障排除和最佳实践

**文档编号**: 06
**创建日期**: 2026-01-27
**用途**: 常见问题解决和最佳实践指南

---

## 🔧 常见问题和解决方案

### 问题1：Docker 镜像构建失败

**症状**:
```
ERROR: failed to solve with frontend dockerfile.v0
```

**原因**:
- 网络连接问题
- 磁盘空间不足
- Dockerfile 语法错误

**解决方案**:
```bash
# 清理 Docker 系统
docker system prune -a

# 重新构建（不使用缓存）
docker compose build --no-cache

# 检查磁盘空间
df -h

# 检查网络连接
ping 8.8.8.8
```

### 问题2：容器内存不足

**症状**:
```
Killed (OOM)
Process exited with code 137
```

**原因**:
- Hyperopt 占用过多内存
- 数据集过大
- 其他进程占用内存

**解决方案**:
```bash
# 减少 epoch 数
bash scripts/docker_hyperopt.sh 1 50

# 限制时间范围
export TIMERANGE=20240601-20240901

# 限制 CPU 核心数
export FREQTRADE__HYPEROPT__HYPEROPT_JOBS=2

# 增加 Docker 内存限制
# 在 docker-compose.yml 中添加：
# mem_limit: 16g
```

### 问题3：数据下载失败

**症状**:
```
fatal: unable to access repository
```

**原因**:
- 网络连接问题
- Git 配置问题
- 磁盘空间不足

**解决方案**:
```bash
# 检查网络连接
ping github.com

# 清理旧数据
rm -rf user_data/data

# 重新下载
docker compose -f docker-compose.backtest.yml run --rm download-data

# 使用代理（如果需要）
export GIT_PROXY=http://proxy:port
```

### 问题4：Hyperopt 优化停滞

**症状**:
```
No improvement in last N epochs
```

**原因**:
- 参数空间不合适
- 数据不足
- 优化陷入局部最优

**解决方案**:
```bash
# 增加 epoch 数
bash scripts/docker_hyperopt.sh 1 500

# 扩大参数范围
# 修改 hyperopt-x7.json

# 使用不同的损失函数
# 修改 --hyperopt-loss 参数

# 重新开始优化
rm -rf user_data/hyperopt_results/phase1_results/*
```

### 问题5：容器无法连接到交易所

**症状**:
```
Connection refused
Timeout
```

**原因**:
- 网络连接问题
- 交易所 API 限制
- 防火墙阻止

**解决方案**:
```bash
# 调整速率限制
export FREQTRADE__EXCHANGE__CCXT_CONFIG__RATELIMIT=400

# 配置代理
export FREQTRADE__EXCHANGE_CONFIG__CCXT_CONFIG__AIOHTTP_PROXY=http://proxy:port

# 检查网络连接
docker compose exec freqtrade ping 8.8.8.8

# 检查 DNS
docker compose exec freqtrade nslookup api.binance.com
```

### 问题6：文件权限错误

**症状**:
```
Permission denied
```

**原因**:
- 文件权限不正确
- 用户权限不足

**解决方案**:
```bash
# 检查文件权限
ls -la user_data/

# 修改权限
chmod -R 755 user_data/
chmod -R 755 configs/

# 修改所有者
chown -R $(whoami) user_data/
chown -R $(whoami) configs/
```

### 问题7：Hyperopt 结果不一致

**症状**:
```
不同运行的结果不同
```

**原因**:
- 随机种子不同
- 数据顺序不同
- 并发问题

**解决方案**:
```bash
# 使用固定的随机种子
# 在 hyperopt-x7.json 中设置：
"hyperopt_random_state": 42

# 使用单个 CPU 核心
export FREQTRADE__HYPEROPT__HYPEROPT_JOBS=1

# 禁用缓存
--cache none
```

---

## 💡 性能优化

### 1. 快速迭代

```bash
# 使用焦点组配置
bash tests/backtests/backtesting-focus-group.sh

# 减少 epoch 数
bash scripts/docker_hyperopt.sh 1 50

# 使用更短的时间范围
export TIMERANGE=20240601-20240901
```

**预期时间**: 30分钟 - 1小时

### 2. 并行执行

```bash
# 在不同机器上运行不同阶段
# 机器1
bash scripts/docker_hyperopt.sh 1 200

# 机器2
bash scripts/docker_hyperopt.sh 2 200

# 机器3
bash scripts/docker_hyperopt.sh 3 200
```

### 3. 资源优化

```bash
# 使用 SSD 存储
# 将 user_data 移到 SSD

# 增加 RAM
# 至少 96GB 推荐

# 使用多核 CPU
# 至少 8 核推荐
```

### 4. 缓存优化

```bash
# 启用缓存
--cache default

# 禁用缓存（确保数据新鲜）
--cache none
```

---

## ✅ 最佳实践

### 1. 定期备份

```bash
# 备份 hyperopt 结果
cp -r user_data/hyperopt_results user_data/hyperopt_results.backup.$(date +%Y%m%d)

# 备份数据库
cp user_data/*.sqlite* user_data/backup/

# 备份配置
cp -r configs configs.backup.$(date +%Y%m%d)
```

### 2. 版本控制

```bash
# 跟踪优化结果
git add user_data/hyperopt_results/
git commit -m "Hyperopt phase 1 results"

# 跟踪配置变更
git add configs/
git commit -m "Update hyperopt configuration"
```

### 3. 文档记录

```bash
# 记录优化过程
echo "Phase 1: $(date)" >> HYPEROPT_LOG.txt
echo "Epochs: 200" >> HYPEROPT_LOG.txt
echo "Best Sharpe: $(docker compose run --rm freqtrade hyperopt-show --best -n 1)" >> HYPEROPT_LOG.txt
```

### 4. 监控和告警

```bash
# 监控 CPU 使用
watch -n 5 'docker stats freqtrade'

# 监控磁盘使用
watch -n 5 'du -sh user_data/'

# 监控日志
tail -f user_data/hyperopt_results/phase1_results/hyperopt_*.log
```

### 5. 定期验证

```bash
# 在样本外数据上验证
docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting \
  --strategy NostalgiaForInfinityX7 \
  --config configs/exampleconfig.json \
  --config user_data/hyperopt_results/best_params.json \
  --timerange 20250101-20260101

# 比较不同时期的结果
# 2024年（训练期）vs 2025年（测试期）
```

---

## 🎯 优化工作流

### 推荐工作流

```
1. 准备数据
   └─ docker compose -f docker-compose.backtest.yml run --rm download-data

2. 快速测试（焦点组）
   └─ bash tests/backtests/backtesting-focus-group.sh

3. 阶段1优化
   └─ bash scripts/docker_hyperopt.sh 1 200

4. 查看结果
   └─ docker compose -f docker-compose.hyperopt.yml run --rm freqtrade hyperopt-show --best -n 10

5. 后续阶段
   └─ bash scripts/docker_hyperopt.sh 2 200
   └─ bash scripts/docker_hyperopt.sh 3 200
   └─ bash scripts/docker_hyperopt.sh 4 200

6. 结果验证
   └─ docker compose -f docker-compose.backtest.yml run --rm freqtrade backtesting ...

7. 参数应用
   └─ 将最佳参数应用到策略
```

### 时间估算

| 步骤 | 时间 | 累计 |
|------|------|------|
| 1. 数据准备 | 1小时 | 1小时 |
| 2. 快速测试 | 4小时 | 5小时 |
| 3. 阶段1 | 3小时 | 8小时 |
| 4. 查看结果 | 0.5小时 | 8.5小时 |
| 5. 后续阶段 | 15小时 | 23.5小时 |
| 6. 结果验证 | 2小时 | 25.5小时 |
| 7. 参数应用 | 1小时 | 26.5小时 |

---

## 📊 质量检查清单

### 优化前

- [ ] 数据已下载
- [ ] Docker 环境就绪
- [ ] 磁盘空间充足（100GB+）
- [ ] 内存充足（96GB+）
- [ ] 网络连接稳定
- [ ] 备份已完成

### 优化中

- [ ] 监控日志
- [ ] 监控资源使用
- [ ] 记录进度
- [ ] 定期检查结果

### 优化后

- [ ] 结果已保存
- [ ] 参数已导出
- [ ] 验证已完成
- [ ] 文档已更新
- [ ] 备份已完成

---

## 🔗 相关文档

- [00-README.md](00-README.md) - 文档总览
- [01-backtesting-framework-overview.md](01-backtesting-framework-overview.md) - 回测框架
- [02-docker-hyperopt-quick-start.md](02-docker-hyperopt-quick-start.md) - 快速开始
- [03-docker-hyperopt-detailed-guide.md](03-docker-hyperopt-detailed-guide.md) - 详细指南
- [04-hyperopt-parameters-reference.md](04-hyperopt-parameters-reference.md) - 参数参考
- [05-docker-configuration-guide.md](05-docker-configuration-guide.md) - Docker 配置

---

## 📞 获取帮助

### 查看日志

```bash
# 查看 Docker 日志
docker compose logs freqtrade

# 查看 Hyperopt 日志
tail -f user_data/hyperopt_results/phase1_results/hyperopt_*.log

# 查看系统日志
dmesg | tail -20
```

### 调试命令

```bash
# 进入容器
docker compose exec freqtrade bash

# 检查环境变量
docker compose exec freqtrade env | grep FREQTRADE

# 检查文件系统
docker compose exec freqtrade ls -la /freqtrade/
```

### 获取支持

- 📖 查看相关文档
- 🔍 搜索关键词
- 💬 查看示例
- 🆘 参考故障排除

---

**维护者**: Claude Code
**创建日期**: 2026-01-27
**状态**: ✅ 完成
