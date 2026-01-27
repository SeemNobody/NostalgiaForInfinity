# 04 - Hyperopt 参数参考

**文档编号**: 04
**创建日期**: 2026-01-27
**用途**: Hyperopt 优化参数的完整参考

---

## 📊 4阶段优化参数总览

| 阶段 | 参数类型 | 数量 | 时间 | 优化空间 |
|------|---------|------|------|---------|
| **1** | 保护参数 | 6个 | 2-4小时 | `protection` |
| **2** | Grinding参数 | 24个 | 8-12小时 | `grinding` |
| **3** | 入场/出场信号 | 35个 | 6-8小时 | `buy sell` |
| **4** | ROI表 | 4个 | 1-2小时 | `roi` |
| **总计** | - | **69个** | **17-26小时** | - |

---

## 🛡️ 阶段1：保护参数（6个）

### 参数列表

| 参数名 | 范围 | 默认值 | 说明 |
|--------|------|--------|------|
| `stop_threshold_spot` | 0.05-0.20 | 0.10 | 现货止损阈值 |
| `stop_threshold_futures` | 0.05-0.20 | 0.10 | 期货止损阈值 |
| `stop_threshold_rapid_spot` | 0.10-0.30 | 0.15 | 快速交易现货止损 |
| `stop_threshold_rapid_futures` | 0.10-0.30 | 0.15 | 快速交易期货止损 |
| `stop_threshold_scalp_spot` | 0.10-0.30 | 0.15 | 剥头皮现货止损 |
| `stop_threshold_scalp_futures` | 0.10-0.30 | 0.15 | 剥头皮期货止损 |

### 参数说明

**stop_threshold_spot/futures**
- 控制现货/期货交易的止损水平
- 值越小，止损越紧
- 值越大，允许更大的亏损

**stop_threshold_rapid_spot/futures**
- 用于快速交易模式的止损
- 通常比标准止损更宽松
- 适应快速市场变化

**stop_threshold_scalp_spot/futures**
- 用于剥头皮交易的止损
- 最严格的止损设置
- 保护小额利润

### 优化建议

- 从默认值开始
- 逐步调整以找到最优平衡
- 考虑市场波动性
- 在不同市场条件下测试

---

## 💰 阶段2：Grinding参数（24个）

### 参数列表

**Grind 1-6 的 stop_grinds**
- 范围: -0.80 至 -0.30
- 说明: DCA（平均成本法）的止损水平
- 值越小（更负），允许更多的亏损后才进行DCA

**Grind 1-6 的 profit_threshold**
- 范围: 0.010 至 0.050
- 说明: 利润目标阈值
- 值越大，需要更多利润才能平仓

### 参数组合示例

```
Grind 1: stop_grinds = -0.30, profit_threshold = 0.010
Grind 2: stop_grinds = -0.40, profit_threshold = 0.015
Grind 3: stop_grinds = -0.50, profit_threshold = 0.020
Grind 4: stop_grinds = -0.60, profit_threshold = 0.025
Grind 5: stop_grinds = -0.70, profit_threshold = 0.030
Grind 6: stop_grinds = -0.80, profit_threshold = 0.050
```

### 优化建议

- 平衡 DCA 激进性和利润目标
- 考虑市场趋势
- 测试不同的组合
- 监控 DCA 频率

---

## 📈 阶段3：入场/出场信号（35个）

### 多头条件开关（27个）

这些参数控制多头（看涨）交易的入场条件：

```
buy_condition_1_enable
buy_condition_2_enable
...
buy_condition_27_enable
```

**范围**: True/False（启用/禁用）

**说明**:
- 每个条件代表一个特定的技术指标或模式
- 启用多个条件可以增加信号的可靠性
- 禁用某些条件可以减少虚假信号

### 空头条件开关（8个）

这些参数控制空头（看跌）交易的入场条件：

```
sell_condition_1_enable
sell_condition_2_enable
...
sell_condition_8_enable
```

**范围**: True/False（启用/禁用）

**说明**:
- 控制出场信号
- 可以独立于入场条件
- 影响交易持续时间

### 优化建议

- 从启用所有条件开始
- 逐步禁用低效条件
- 监控信号质量
- 平衡信号频率和准确性

---

## 🎯 阶段4：ROI表（4个）

### 参数列表

| 参数 | 说明 | 范围 |
|------|------|------|
| `roi_time_1` | 第一个ROI时间点 | 0-60分钟 |
| `roi_profit_1` | 第一个ROI收益率 | 0.01-0.10 |
| `roi_time_2` | 第二个ROI时间点 | 60-300分钟 |
| `roi_profit_2` | 第二个ROI收益率 | 0.005-0.05 |

### ROI表示例

```
ROI = {
  "0": 0.10,      // 立即平仓目标：10%利润
  "10": 0.05,     // 10分钟后：5%利润
  "30": 0.01,     // 30分钟后：1%利润
  "60": 0          // 60分钟后：0%（强制平仓）
}
```

### 优化建议

- 考虑市场波动性
- 平衡利润目标和持仓时间
- 测试不同的时间点
- 监控平均持仓时间

---

## 🔄 参数优化策略

### 1. 顺序优化

```
阶段1 → 阶段2 → 阶段3 → 阶段4
```

每个阶段基于前一阶段的结果进行优化。

### 2. 独立优化

```
每个阶段独立运行，不依赖前一阶段
```

适合快速迭代和测试。

### 3. 增量优化

```
从前一次优化的最佳参数开始
```

节省时间，但可能陷入局部最优。

---

## 📊 参数范围指南

### 保守策略

```
stop_threshold: 0.05-0.10
profit_threshold: 0.010-0.020
ROI: 0.05-0.10
```

### 平衡策略

```
stop_threshold: 0.10-0.15
profit_threshold: 0.020-0.030
ROI: 0.03-0.07
```

### 激进策略

```
stop_threshold: 0.15-0.20
profit_threshold: 0.030-0.050
ROI: 0.01-0.05
```

---

## 💡 优化技巧

### 1. 参数相关性

某些参数之间存在相关性：
- 更严格的止损 → 需要更高的利润目标
- 更多的DCA → 需要更宽松的止损
- 更多的入场条件 → 需要更严格的出场条件

### 2. 市场适应性

不同市场条件需要不同的参数：
- 牛市：更激进的参数
- 熊市：更保守的参数
- 震荡市：平衡的参数

### 3. 风险管理

- 始终设置止损
- 限制最大开放交易数
- 监控最大回撤
- 定期验证结果

---

## 🎯 参数验证

### 验证步骤

1. **单参数测试**
   ```bash
   # 只改变一个参数，观察影响
   ```

2. **参数组合测试**
   ```bash
   # 测试多个参数的组合
   ```

3. **样本外验证**
   ```bash
   # 在未用于优化的数据上测试
   ```

4. **压力测试**
   ```bash
   # 在极端市场条件下测试
   ```

---

## 📈 性能指标

### 关键指标

| 指标 | 说明 | 目标 |
|------|------|------|
| Sharpe比率 | 风险调整后的收益 | > 1.0 |
| 最大回撤 | 最大亏损 | < 20% |
| 胜率 | 盈利交易比例 | > 50% |
| 利润因子 | 总利润/总亏损 | > 1.5 |

---

## 🔗 相关文档

- [00-README.md](00-README.md) - 文档总览
- [01-backtesting-framework-overview.md](01-backtesting-framework-overview.md) - 回测框架
- [02-docker-hyperopt-quick-start.md](02-docker-hyperopt-quick-start.md) - 快速开始
- [03-docker-hyperopt-detailed-guide.md](03-docker-hyperopt-detailed-guide.md) - 详细指南
- [05-docker-configuration-guide.md](05-docker-configuration-guide.md) - Docker 配置
- [06-troubleshooting-and-best-practices.md](06-troubleshooting-and-best-practices.md) - 故障排除

---

**维护者**: Claude Code
**创建日期**: 2026-01-27
**状态**: ✅ 完成
