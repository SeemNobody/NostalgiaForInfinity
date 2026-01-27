#!/bin/bash

################################################################################
# NostalgiaForInfinity 数据下载管理脚本
#
# 用途：根据 Freqtrade 和 NFI 最佳实践智能下载必要的币对数据
#
# 用法：
#   bash scripts/download-data-smart.sh [MODE] [OPTIONS]
#
# 模式 (MODE):
#   core       - 核心币对 (10个) - 快速测试 (~5GB, 10-15分钟)
#   extended   - 扩展币对 (30个) - 标准回测 (~15GB, 30-45分钟)
#   full       - 全部币对 (1000+) - 完整分析 (~100GB, 1-2小时)
#   custom     - 自定义币对列表
#
# 选项 (OPTIONS):
#   --timerange START-END  - 时间范围 (默认: 20210101-20260115)
#   --erase               - 下载前清除旧数据
#   --verify              - 下载后验证数据完整性
#   --dry-run             - 显示将要执行的命令但不执行
#
# 示例：
#   bash scripts/download-data-smart.sh core
#   bash scripts/download-data-smart.sh extended --erase
#   bash scripts/download-data-smart.sh full --timerange 20240101-20250101
#   bash scripts/download-data-smart.sh custom --config configs/my-pairs.json
#
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
MODE="${1:-extended}"
TIMERANGE="20210101-20260115"
ERASE_FLAG=""
VERIFY_FLAG=""
DRY_RUN=false
CUSTOM_CONFIG=""

# 解析选项
shift || true
while [[ $# -gt 0 ]]; do
  case $1 in
    --timerange)
      TIMERANGE="$2"
      shift 2
      ;;
    --erase)
      ERASE_FLAG="--erase"
      shift
      ;;
    --verify)
      VERIFY_FLAG="true"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --config)
      CUSTOM_CONFIG="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}未知选项: $1${NC}"
      exit 1
      ;;
  esac
done

# 打印帮助信息
print_help() {
  cat << 'EOF'
NostalgiaForInfinity 数据下载管理脚本

用法: bash scripts/download-data-smart.sh [MODE] [OPTIONS]

模式:
  core       - 核心币对 (10个) - 快速测试
  extended   - 扩展币对 (30个) - 标准回测 (推荐)
  full       - 全部币对 (1000+) - 完整分析
  custom     - 自定义币对列表

选项:
  --timerange START-END  - 时间范围 (默认: 20210101-20260115)
  --erase               - 下载前清除旧数据
  --verify              - 下载后验证数据完整性
  --dry-run             - 显示将要执行的命令但不执行
  --config FILE         - 自定义配置文件路径

示例:
  bash scripts/download-data-smart.sh core
  bash scripts/download-data-smart.sh extended --erase
  bash scripts/download-data-smart.sh full --timerange 20240101-20250101

EOF
}

# 验证 Docker 环境
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装${NC}"
    exit 1
  fi

  if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装${NC}"
    exit 1
  fi

  echo -e "${GREEN}✅ Docker 环境检查通过${NC}"
}

# 获取配置文件路径
get_config_file() {
  local mode=$1

  case $mode in
    core)
      echo "configs/pairlist-backtest-core-binance-futures-usdt.json"
      ;;
    extended)
      echo "configs/pairlist-backtest-extended-binance-futures-usdt.json"
      ;;
    full)
      echo "configs/pairlist-backtest-static-binance-futures-usdt.json"
      ;;
    custom)
      if [ -z "$CUSTOM_CONFIG" ]; then
        echo -e "${RED}❌ 自定义模式需要指定 --config 选项${NC}"
        exit 1
      fi
      echo "$CUSTOM_CONFIG"
      ;;
    *)
      echo -e "${RED}❌ 未知模式: $mode${NC}"
      print_help
      exit 1
      ;;
  esac
}

# 获取模式描述
get_mode_description() {
  local mode=$1

  case $mode in
    core)
      echo "核心币对 (10个) - 快速测试"
      ;;
    extended)
      echo "扩展币对 (30个) - 标准回测"
      ;;
    full)
      echo "全部币对 (1000+) - 完整分析"
      ;;
    custom)
      echo "自定义币对列表"
      ;;
  esac
}

# 获取预期的存储需求
get_storage_estimate() {
  local mode=$1

  case $mode in
    core)
      echo "~5GB"
      ;;
    extended)
      echo "~15GB"
      ;;
    full)
      echo "~100GB"
      ;;
    custom)
      echo "取决于币对数量"
      ;;
  esac
}

# 获取预期的下载时间
get_time_estimate() {
  local mode=$1

  case $mode in
    core)
      echo "10-15 分钟"
      ;;
    extended)
      echo "30-45 分钟"
      ;;
    full)
      echo "1-2 小时"
      ;;
    custom)
      echo "取决于币对数量"
      ;;
  esac
}

# 验证配置文件存在
verify_config_file() {
  local config_file=$1

  if [ ! -f "$config_file" ]; then
    echo -e "${RED}❌ 配置文件不存在: $config_file${NC}"
    exit 1
  fi

  echo -e "${GREEN}✅ 配置文件验证通过${NC}"
}

# 计算币对数量
count_pairs() {
  local config_file=$1

  # 使用 grep 和 wc 计算 pair_whitelist 中的币对数量
  grep -o '"[A-Z0-9]*\/USDT:USDT"' "$config_file" | wc -l
}

# 显示下载信息
show_download_info() {
  local mode=$1
  local config_file=$2
  local pair_count=$3

  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}📊 数据下载配置信息${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "模式:           ${YELLOW}$mode${NC} - $(get_mode_description "$mode")"
  echo -e "币对数量:       ${YELLOW}$pair_count${NC}"
  echo -e "时间范围:       ${YELLOW}$TIMERANGE${NC}"
  echo -e "配置文件:       ${YELLOW}$config_file${NC}"
  echo -e "存储需求:       ${YELLOW}$(get_storage_estimate "$mode")${NC}"
  echo -e "预期时间:       ${YELLOW}$(get_time_estimate "$mode")${NC}"
  echo -e "清除旧数据:     ${YELLOW}${ERASE_FLAG:-否}${NC}"
  echo -e "验证数据:       ${YELLOW}${VERIFY_FLAG:-否}${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# 构建 Docker 命令
build_docker_command() {
  local config_file=$1
  local service_name="download-data-$MODE"

  local cmd="docker compose -f docker-compose.backtest.yml run --rm $service_name"

  # 如果是自定义模式，需要直接构建命令
  if [ "$MODE" = "custom" ]; then
    cmd="docker compose -f docker-compose.backtest.yml run --rm freqtrade download-data"
    cmd="$cmd --exchange binance"
    cmd="$cmd --trading-mode futures"
    cmd="$cmd --config $config_file"
    cmd="$cmd --timeframes 5m 15m 1h 4h 1d"
    cmd="$cmd --timerange $TIMERANGE"
    cmd="$cmd --data-format-ohlcv feather"

    if [ -n "$ERASE_FLAG" ]; then
      cmd="$cmd $ERASE_FLAG"
    fi
  fi

  echo "$cmd"
}

# 执行下载
execute_download() {
  local cmd=$1

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 Dry-run 模式 - 将执行以下命令:${NC}"
    echo -e "${BLUE}$cmd${NC}\n"
    return 0
  fi

  echo -e "${BLUE}🚀 开始下载数据...${NC}\n"

  # 执行命令
  eval "$cmd"

  if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ 数据下载完成${NC}"
  else
    echo -e "\n${RED}❌ 数据下载失败${NC}"
    exit 1
  fi
}

# 验证数据完整性
verify_data() {
  local config_file=$1

  echo -e "\n${BLUE}🔍 验证数据完整性...${NC}"

  # 检查数据目录
  if [ ! -d "user_data/data/binance/futures" ]; then
    echo -e "${RED}❌ 数据目录不存在${NC}"
    return 1
  fi

  # 计算下载的币对数量
  local downloaded_pairs=$(find user_data/data/binance/futures -maxdepth 1 -type d | wc -l)
  downloaded_pairs=$((downloaded_pairs - 1)) # 减去父目录

  echo -e "${GREEN}✅ 已下载 $downloaded_pairs 个币对的数据${NC}"

  # 检查数据文件
  local feather_files=$(find user_data/data/binance/futures -name "*.feather" | wc -l)
  echo -e "${GREEN}✅ 找到 $feather_files 个数据文件${NC}"

  if [ "$feather_files" -gt 0 ]; then
    echo -e "${GREEN}✅ 数据验证通过${NC}"
    return 0
  else
    echo -e "${RED}❌ 未找到数据文件${NC}"
    return 1
  fi
}

# 显示使用建议
show_recommendations() {
  local mode=$1

  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}💡 使用建议${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

  case $mode in
    core)
      echo -e "✓ 适合快速测试和开发"
      echo -e "✓ 适合验证策略逻辑"
      echo -e "✓ 下一步: 运行 backtest-lite 进行回测"
      echo -e "  ${YELLOW}docker compose -f docker-compose.backtest.yml run --rm backtest-lite${NC}"
      ;;
    extended)
      echo -e "✓ 推荐用于标准回测和优化"
      echo -e "✓ 平衡了数据量和执行时间"
      echo -e "✓ 下一步: 运行 backtest-top40 进行回测"
      echo -e "  ${YELLOW}docker compose -f docker-compose.backtest.yml run --rm backtest-top40${NC}"
      ;;
    full)
      echo -e "✓ 用于完整的市场分析"
      echo -e "✓ 需要充足的存储空间和时间"
      echo -e "✓ 下一步: 运行完整回测"
      echo -e "  ${YELLOW}docker compose -f docker-compose.backtest.yml run --rm backtest${NC}"
      ;;
    custom)
      echo -e "✓ 使用自定义币对列表"
      echo -e "✓ 适合特定的交易策略"
      ;;
  esac

  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# 主函数
main() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  NostalgiaForInfinity 数据下载管理脚本                 ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}\n"

  # 检查 Docker
  check_docker

  # 获取配置文件
  local config_file=$(get_config_file "$MODE")

  # 验证配置文件
  verify_config_file "$config_file"

  # 计算币对数量
  local pair_count=$(count_pairs "$config_file")

  # 显示下载信息
  show_download_info "$MODE" "$config_file" "$pair_count"

  # 确认继续
  if [ "$DRY_RUN" = false ]; then
    read -p "确认继续下载? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}已取消${NC}"
      exit 0
    fi
  fi

  # 构建 Docker 命令
  local cmd=$(build_docker_command "$config_file")

  # 执行下载
  execute_download "$cmd"

  # 验证数据
  if [ "$VERIFY_FLAG" = "true" ]; then
    verify_data "$config_file"
  fi

  # 显示建议
  show_recommendations "$MODE"
}

# 如果没有参数，显示帮助
if [ "$MODE" = "-h" ] || [ "$MODE" = "--help" ]; then
  print_help
  exit 0
fi

# 运行主函数
main
