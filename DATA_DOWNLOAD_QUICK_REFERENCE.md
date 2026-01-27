# 数据下载快速参考卡片

## 🚀 快速命令

### 推荐方案 (30个币对, ~15GB, 30-45分钟)
```bash
bash scripts/download-data-smart.sh extended
```

### 快速测试 (10个币对, ~5GB, 10-15分钟)
```bash
bash scripts/download-data-smart.sh core
```

### 完整分析 (1000+个币对, ~100GB, 1-2小时)
```bash
bash scripts/download-data-smart.sh full
```

---

## 📊 数据管理

### 查看统计信息
```bash
bash scripts/manage-data.sh status
```

### 列出已下载的币对
```bash
bash scripts/manage-data.sh list
```

### 验证数据完整性
```bash
bash scripts/manage-data.sh validate
```

### 清理不必要的数据
```bash
bash scripts/manage-data.sh cleanup
```

### 删除特定币对
```bash
bash scripts/manage-data.sh remove --pair BTC/USDT:USDT
```

---

## 🔧 高级选项

### 指定时间范围
```bash
bash scripts/download-data-smart.sh extended --timerange 20240101-20241231
```

### 清除旧数据后下载
```bash
bash scripts/download-data-smart.sh extended --erase
```

### 下载并验证
```bash
bash scripts/download-data-smart.sh extended --verify
```

### Dry-run 模式 (预览)
```bash
bash scripts/download-data-smart.sh extended --dry-run
```

### 自定义币对列表
```bash
bash scripts/download-data-smart.sh custom --config configs/my-pairs.json
```

---

## 📋 完整工作流

### 1️⃣ 下载数据
```bash
bash scripts/download-data-smart.sh extended
```

### 2️⃣ 验证数据
```bash
bash scripts/manage-data.sh validate
```

### 3️⃣ 运行回测
```bash
docker compose -f docker-compose.backtest.yml run --rm backtest-top40
```

### 4️⃣ 查看结果
```bash
cat user_data/backtest_results/backtest-top40-futures-2025.json
```

---

## 💡 选择指南

| 场景 | 推荐方案 | 命令 |
|------|--------|------|
| 快速测试 | Core | `bash scripts/download-data-smart.sh core` |
| 标准回测 | Extended ⭐ | `bash scripts/download-data-smart.sh extended` |
| 完整分析 | Full | `bash scripts/download-data-smart.sh full` |
| 自定义 | Custom | `bash scripts/download-data-smart.sh custom --config ...` |

---

## ⚠️ 常见问题

**Q: 应该选择哪个方案?**
A: 大多数用户应该选择 **Extended** (30个币对)

**Q: 下载需要多长时间?**
A: Extended 方案需要 30-45 分钟

**Q: 需要多少存储空间?**
A: Extended 方案需要 ~15GB

**Q: 如何更新数据?**
A: 使用 `--erase` 选项: `bash scripts/download-data-smart.sh extended --erase`

---

## 📚 详细文档

- [数据下载最佳实践](docs/data-download-best-practices.md) - 完整指南
- [优化总结](DATA_DOWNLOAD_OPTIMIZATION_SUMMARY.md) - 优化详情
- [Docker Hyperopt 指南](docs/docker-hyperopt/00-README.md) - Hyperopt 使用

---

**最后更新**: 2026-01-27
**版本**: 1.0
