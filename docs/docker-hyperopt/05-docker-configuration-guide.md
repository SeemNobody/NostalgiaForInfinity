# 05 - Docker 配置指南

**文档编号**: 05
**创建日期**: 2026-01-27
**用途**: Docker 和 Docker Compose 配置详解

---

## 🐳 Docker 基础

### Docker 是什么？

Docker 是一个容器化平台，允许你在隔离的环境中运行应用程序。

**优点**:
- 环境一致性
- 依赖隔离
- 易于部署
- 可重复性

### Docker Compose 是什么？

Docker Compose 是一个工具，用于定义和运行多容器 Docker 应用程序。

---

## 📋 Docker Compose 配置详解

### docker-compose.yml（主配置）

```yaml
x-common-settings:
  &common-settings
  image: freqtradeorg/freqtrade:stable
  build:
    context: .
    dockerfile: "./docker/Dockerfile.custom"
  restart: unless-stopped
  volumes:
    - "./user_data:/freqtrade/user_data"
    - "./user_data/data:/freqtrade/user_data/data"
    - "./configs:/freqtrade/configs"
    - "./${FREQTRADE__STRATEGY:-NostalgiaForInfinityX7}.py:/freqtrade/${FREQTRADE__STRATEGY:-NostalgiaForInfinityX7}.py"
  env_file:
    - path: .env
      required: false

services:
  freqtrade:
    <<: *common-settings
    container_name: ${FREQTRADE__BOT_NAME:-Example_Test_Account}_${FREQTRADE__EXCHANGE__NAME:-binance}_${FREQTRADE__TRADING_MODE:-futures}-${FREQTRADE__STRATEGY:-NostalgiaForInfinityX7}
    ports:
      - "${FREQTRADE__API_SERVER__LISTEN_PORT:-8080}:${FREQTRADE__API_SERVER__LISTEN_PORT:-8080}"
    command: >
      trade
      --db-url sqlite:////freqtrade/user_data/${FREQTRADE__BOT_NAME:-Example_Test_Account}_${FREQTRADE__EXCHANGE__NAME:-binance}_${FREQTRADE__TRADING_MODE:-futures}-tradesv3.sqlite
      --log-file user_data/logs/${FREQTRADE__BOT_NAME:-Example_Test_Account}-${FREQTRADE__EXCHANGE__NAME:-binance}-${FREQTRADE__STRATEGY:-NostalgiaForInfinityX7}-${FREQTRADE__TRADING_MODE:-futures}.log
      --strategy-path .
```

### docker-compose.backtest.yml（回测配置）

```yaml
x-common-settings: &common-settings
  image: freqtradeorg/freqtrade:stable
  volumes:
    - "./user_data:/freqtrade/user_data"
    - "./configs:/freqtrade/configs"
    - "./NostalgiaForInfinityX7.py:/freqtrade/NostalgiaForInfinityX7.py"

services:
  download-data:
    <<: *common-settings
    container_name: nfi-download-binance-futures
    command: >
      download-data
      --exchange binance
      --trading-mode futures
      --config configs/pairlist-backtest-static-binance-futures-usdt.json
      --timeframes 5m 15m 1h 4h 1d
      --timerange 20210101-20260115
      --data-format-ohlcv feather

  backtest:
    <<: *common-settings
    container_name: nfi-backtest-binance-futures-5y
    command: >
      backtesting
      --strategy NostalgiaForInfinityX7
      --timerange 20210101-20260101
      --config configs/exampleconfig.json
      --config configs/trading_mode-futures.json
      --config configs/pairlist-backtest-static-binance-futures-usdt.json
      --config configs/blacklist-binance.json
      --breakdown day
      --export signals
      --export-filename backtest-binance-futures-5y.json
      --log-file user_data/logs/backtest-binance-futures-5y.log
```

### docker-compose.hyperopt.yml（Hyperopt配置）

```yaml
x-common-settings:
  &common-settings
  image: freqtradeorg/freqtrade:stable
  build:
    context: .
    dockerfile: "./docker/Dockerfile.custom"
  restart: "no"
  volumes:
    - "./user_data:/freqtrade/user_data"
    - "./user_data/data:/freqtrade/user_data/data"
    - "./configs:/freqtrade/configs"
    - "./NostalgiaForInfinityX7.py:/freqtrade/NostalgiaForInfinityX7.py"
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

## 🔧 配置元素详解

### 镜像（Image）

```yaml
image: freqtradeorg/freqtrade:stable
```

- 使用官方 Freqtrade 镜像
- `stable` 标签表示稳定版本
- 可以使用其他标签如 `develop`、`latest`

### 构建（Build）

```yaml
build:
  context: .
  dockerfile: "./docker/Dockerfile.custom"
```

- 从本地 Dockerfile 构建自定义镜像
- 添加额外的依赖和配置

### 卷挂载（Volumes）

```yaml
volumes:
  - "./user_data:/freqtrade/user_data"      # 用户数据
  - "./configs:/freqtrade/configs"          # 配置文件
  - "./NostalgiaForInfinityX7.py:/freqtrade/NostalgiaForInfinityX7.py"  # 策略文件
```

**说明**:
- 左侧：主机路径
- 右侧：容器路径
- 允许容器访问主机文件

### 环境变量（Environment）

```yaml
environment:
  - FREQTRADE__STRATEGY=NostalgiaForInfinityX7Hyperopt
  - FREQTRADE__HYPEROPT__HYPEROPT_JOBS=4
```

### 端口映射（Ports）

```yaml
ports:
  - "${FREQTRADE__API_SERVER__LISTEN_PORT:-8080}:${FREQTRADE__API_SERVER__LISTEN_PORT:-8080}"
```

- 将容器端口映射到主机端口
- 允许外部访问容器服务

### 命令（Command）

```yaml
command: >
  hyperopt
  --strategy NostalgiaForInfinityX7Hyperopt
  --config configs/hyperopt-x7.json
  ...
```

- 容器启动时执行的命令
- 可以覆盖 Dockerfile 中的默认命令

---

## 🐳 Dockerfile 自定义

### docker/Dockerfile.custom

```dockerfile
ARG sourceimage=freqtradeorg/freqtrade
ARG sourcetag=stable

# Stage 1: Build dependencies
FROM ${sourceimage}:${sourcetag} AS builder

USER root
RUN pip install --upgrade pip

COPY --chown=1000:1000 tests/requirements.txt /freqtrade/

USER ftuser
RUN --mount=type=cache,target=/home/ftuser/.cache/pip \
    pip install --user --no-build-isolation --no-cache-dir -r /freqtrade/requirements.txt

USER root
RUN chown -R 1000:1000 /home/ftuser/.local

# Stage 2: Final image
FROM ${sourceimage}:${sourcetag}

USER root

COPY --from=builder /home/ftuser/.local /home/ftuser/.local
COPY --chown=1000:1000 tests/requirements.txt /freqtrade/

USER ftuser

ENV PATH=/home/ftuser/.local/bin:$PATH
```

**说明**:
- 多阶段构建减少镜像大小
- 安装额外的 Python 依赖
- 设置环境变量

---

## 🔑 环境变量配置

### .env 文件

```bash
# 机器人配置
FREQTRADE__BOT_NAME=Example_Test_Account
FREQTRADE__EXCHANGE__NAME=binance
FREQTRADE__TRADING_MODE=futures
FREQTRADE__STRATEGY=NostalgiaForInfinityX7

# API 服务器
FREQTRADE__API_SERVER__LISTEN_PORT=8080
FREQTRADE__API_SERVER__USERNAME=freqtrader
FREQTRADE__API_SERVER__PASSWORD=freqtrader

# Hyperopt 配置
FREQTRADE__HYPEROPT__HYPEROPT_JOBS=4
FREQTRADE__HYPEROPT__HYPEROPT_EPOCHS=200
```

### 环境变量优先级

1. 命令行参数（最高）
2. 环境变量
3. .env 文件
4. 配置文件
5. 默认值（最低）

---

## 🚀 常用 Docker Compose 命令

### 启动服务

```bash
# 启动所有服务
docker compose up -d

# 启动特定服务
docker compose up -d freqtrade

# 前台运行（查看日志）
docker compose up freqtrade
```

### 停止服务

```bash
# 停止所有服务
docker compose down

# 停止特定服务
docker compose stop freqtrade

# 停止并删除卷
docker compose down -v
```

### 查看日志

```bash
# 查看所有日志
docker compose logs

# 查看特定服务日志
docker compose logs freqtrade

# 实时查看日志
docker compose logs -f freqtrade

# 查看最后100行
docker compose logs --tail=100 freqtrade
```

### 执行命令

```bash
# 在运行中的容器中执行命令
docker compose exec freqtrade bash

# 运行一次性容器
docker compose run --rm freqtrade hyperopt-show --best
```

### 构建镜像

```bash
# 构建镜像
docker compose build

# 重新构建（不使用缓存）
docker compose build --no-cache

# 构建特定服务
docker compose build freqtrade
```

---

## 🔍 故障排除

### 问题1：容器无法启动

```bash
# 查看错误日志
docker compose logs freqtrade

# 检查镜像是否存在
docker images | grep freqtrade

# 重新构建镜像
docker compose build --no-cache
```

### 问题2：卷挂载权限错误

```bash
# 检查文件权限
ls -la user_data/

# 修改权限
chmod -R 755 user_data/

# 重启容器
docker compose restart freqtrade
```

### 问题3：内存不足

```bash
# 检查 Docker 内存限制
docker stats

# 增加 Docker 内存（在 Docker Desktop 设置中）
# 或使用 docker-compose 限制
services:
  freqtrade:
    mem_limit: 8g
```

### 问题4：网络连接问题

```bash
# 检查容器网络
docker network ls

# 检查容器 IP
docker inspect freqtrade | grep IPAddress

# 测试网络连接
docker compose exec freqtrade ping 8.8.8.8
```

---

## 💡 最佳实践

### 1. 使用 .env 文件

```bash
# 不要在 docker-compose.yml 中硬编码敏感信息
# 使用 .env 文件管理环境变量
```

### 2. 定期备份

```bash
# 备份用户数据
docker compose exec freqtrade tar czf /freqtrade/user_data/backup.tar.gz /freqtrade/user_data/

# 备份数据库
cp user_data/*.sqlite* user_data/backup/
```

### 3. 监控资源使用

```bash
# 监控 CPU 和内存
docker stats freqtrade

# 监控磁盘使用
du -sh user_data/
```

### 4. 定期更新

```bash
# 更新镜像
docker compose pull

# 重新构建
docker compose build --no-cache

# 重启服务
docker compose restart
```

---

## 🔗 相关文档

- [00-README.md](00-README.md) - 文档总览
- [01-backtesting-framework-overview.md](01-backtesting-framework-overview.md) - 回测框架
- [02-docker-hyperopt-quick-start.md](02-docker-hyperopt-quick-start.md) - 快速开始
- [03-docker-hyperopt-detailed-guide.md](03-docker-hyperopt-detailed-guide.md) - 详细指南
- [04-hyperopt-parameters-reference.md](04-hyperopt-parameters-reference.md) - 参数参考
- [06-troubleshooting-and-best-practices.md](06-troubleshooting-and-best-practices.md) - 故障排除

---

**维护者**: Claude Code
**创建日期**: 2026-01-27
**状态**: ✅ 完成
