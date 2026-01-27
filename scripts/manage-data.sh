#!/bin/bash

################################################################################
# NostalgiaForInfinity 数据管理脚本
#
# 用途：管理、清理和优化下载的历史数据
#
# 用法：
#   bash scripts/manage-data.sh [COMMAND] [OPTIONS]
#
# 命令 (COMMAND):
#   status     - 显示数据统计信息
#   cleanup    - 清理不必要的数据
#   optimize   - 优化数据存储
#   validate   - 验证数据完整性
#   remove     - 删除指定币对的数据
#   list       - 列出已下载的币对
#
# 选项 (OPTIONS):
#   --pair PAIR            - 指定币对 (如: BTC/USDT:USDT)
#   --timeframe TIMEFRAME  - 指定时间框架 (5m, 15m, 1h, 4h, 1d)
#   --before DATE          - 删除指定日期前的数据 (YYYYMMDD)
#   --dry-run              - 显示将要执行的操作但不执行
#
# 示例：
#   bash scripts/manage-data.sh status
#   bash scripts/manage-data.sh list
#   bash scripts/manage-data.sh cleanup --dry-run
#   bash scripts/manage-data.sh remove --pair BTC/USDT:USDT
#   bash scripts/manage-data.sh validate
#
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认值
COMMAND="${1:-status}"
PAIR=""
TIMEFRAME=""
BEFORE_DATE=""
DRY_RUN=false
DATA_DIR="user_data/data/binance/futures"

# 解析选项
shift || true
while [[ $# -gt 0 ]]; do
  case $1 in
    --pair)
      PAIR="$2"
      shift 2
      ;;
    --timeframe)
      TIMEFRAME="$2"
      shift 2
      ;;
    --before)
      BEFORE_DATE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
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
NostalgiaForInfinity 数据管理脚本

用法: bash scripts/manage-data.sh [COMMAND] [OPTIONS]

命令:
  status     - 显示数据统计信息
  cleanup    - 清理不必要的数据
  optimize   - 优化数据存储
  validate   - 验证数据完整性
  remove     - 删除指定币对的数据
  list       - 列出已下载的币对

选项:
  --pair PAIR            - 指定币对 (如: BTC/USDT:USDT)
  --timeframe TIMEFRAME  - 指定时间框架 (5m, 15m, 1h, 4h, 1d)
  --before DATE          - 删除指定日期前的数据 (YYYYMMDD)
  --dry-run              - 显示将要执行的操作但不执行

示例:
  bash scripts/manage-data.sh status
  bash scripts/manage-data.sh list
  bash scripts/manage-data.sh cleanup --dry-run
  bash scripts/manage-data.sh remove --pair BTC/USDT:USDT

EOF
}

# 检查数据目录
check_data_dir() {
  if [ ! -d "$DATA_DIR" ]; then
    echo -e "${YELLOW}⚠️  数据目录不存在: $DATA_DIR${NC}"
    echo -e "${YELLOW}请先运行: bash scripts/download-data-smart.sh${NC}"
    exit 1
  fi
}

# 显示数据统计信息
show_status() {
  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}📊 数据统计信息${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

  check_data_dir

  # 计算总大小
  local total_size=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)
  echo -e "总存储大小:     ${YELLOW}$total_size${NC}"

  # 计算币对数量
  local pair_count=$(find "$DATA_DIR" -maxdepth 1 -type d ! -name "futures" | wc -l)
  echo -e "币对数量:       ${YELLOW}$pair_count${NC}"

  # 计算数据文件数量
  local file_count=$(find "$DATA_DIR" -name "*.feather" | wc -l)
  echo -e "数据文件数量:   ${YELLOW}$file_count${NC}"

  # 计算时间框架
  local timeframes=$(find "$DATA_DIR" -maxdepth 2 -type d -name "[0-9]*m" -o -name "[0-9]*h" -o -name "[0-9]*d" | sed 's/.*\///' | sort -u | tr '\n' ' ')
  echo -e "时间框架:       ${YELLOW}${timeframes:-未找到}${NC}"

  # 显示最大的币对
  echo -e "\n${CYAN}最大的 5 个币对:${NC}"
  du -sh "$DATA_DIR"/*/ 2>/dev/null | sort -rh | head -5 | awk '{printf "  %-40s %s\n", $2, $1}' | sed "s|$DATA_DIR/||g"

  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# 列出已下载的币对
list_pairs() {
  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}📋 已下载的币对列表${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

  check_data_dir

  local pairs=$(find "$DATA_DIR" -maxdepth 1 -type d ! -name "futures" | sed 's|.*/||' | sort)
  local count=0

  for pair in $pairs; do
    count=$((count + 1))
    local size=$(du -sh "$DATA_DIR/$pair" 2>/dev/null | cut -f1)
    local files=$(find "$DATA_DIR/$pair" -name "*.feather" | wc -l)
    printf "  %-30s %8s  (%3d 个文件)\n" "$pair" "$size" "$files"
  done

  echo -e "\n总计: ${YELLOW}$count${NC} 个币对\n"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# 验证数据完整性
validate_data() {
  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}🔍 验证数据完整性${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

  check_data_dir

  local total_pairs=0
  local valid_pairs=0
  local invalid_pairs=0

  for pair_dir in "$DATA_DIR"/*; do
    if [ -d "$pair_dir" ] && [ "$(basename "$pair_dir")" != "futures" ]; then
      total_pairs=$((total_pairs + 1))
      local pair=$(basename "$pair_dir")

      # 检查是否有数据文件
      local file_count=$(find "$pair_dir" -name "*.feather" | wc -l)

      if [ "$file_count" -gt 0 ]; then
        valid_pairs=$((valid_pairs + 1))
        echo -e "  ${GREEN}✓${NC} $pair ($file_count 个文件)"
      else
        invalid_pairs=$((invalid_pairs + 1))
        echo -e "  ${RED}✗${NC} $pair (无数据文件)"
      fi
    fi
  done

  echo -e "\n${CYAN}验证结果:${NC}"
  echo -e "  总币对数:     ${YELLOW}$total_pairs${NC}"
  echo -e "  有效币对:     ${GREEN}$valid_pairs${NC}"
  echo -e "  无效币对:     ${RED}$invalid_pairs${NC}"

  if [ "$invalid_pairs" -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  发现 $invalid_pairs 个无效币对，建议重新下载${NC}"
  else
    echo -e "\n${GREEN}✅ 所有数据验证通过${NC}"
  fi

  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# 清理不必要的数据
cleanup_data() {
  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}🧹 清理不必要的数据${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

  check_data_dir

  local cleaned_size=0
  local cleaned_files=0

  # 清理空目录
  echo -e "${CYAN}清理空目录...${NC}"
  for pair_dir in "$DATA_DIR"/*; do
    if [ -d "$pair_dir" ] && [ "$(basename "$pair_dir")" != "futures" ]; then
      local file_count=$(find "$pair_dir" -type f | wc -l)

      if [ "$file_count" -eq 0 ]; then
        local pair=$(basename "$pair_dir")
        echo -e "  发现空目录: $pair"

        if [ "$DRY_RUN" = false ]; then
          rm -rf "$pair_dir"
          echo -e "  ${GREEN}✓ 已删除${NC}"
        else
          echo -e "  ${YELLOW}[DRY-RUN]${NC} 将删除"
        fi
      fi
    fi
  done

  # 清理损坏的文件
  echo -e "\n${CYAN}检查损坏的文件...${NC}"
  for feather_file in $(find "$DATA_DIR" -name "*.feather" 2>/dev/null); do
    if [ ! -s "$feather_file" ]; then
      local size=$(du -h "$feather_file" | cut -f1)
      echo -e "  发现空文件: $feather_file ($size)"

      if [ "$DRY_RUN" = false ]; then
        rm -f "$feather_file"
        cleaned_files=$((cleaned_files + 1))
        echo -e "  ${GREEN}✓ 已删除${NC}"
      else
        echo -e "  ${YELLOW}[DRY-RUN]${NC} 将删除"
      fi
    fi
  done

  if [ "$DRY_RUN" = true ]; then
    echo -e "\n${YELLOW}[DRY-RUN 模式] 未执行实际删除操作${NC}"
  else
    echo -e "\n${GREEN}✅ 清理完成${NC}"
  fi

  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# 优化数据存储
optimize_data() {
  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}⚡ 优化数据存储${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

  check_data_dir

  echo -e "${CYAN}优化前:${NC}"
  local before_size=$(du -sh "$DATA_DIR" | cut -f1)
  echo -e "  总大小: $before_size"

  # 先清理
  echo -e "\n${CYAN}执行清理...${NC}"
  cleanup_data

  echo -e "${CYAN}优化后:${NC}"
  local after_size=$(du -sh "$DATA_DIR" | cut -f1)
  echo -e "  总大小: $after_size"

  echo -e "\n${GREEN}✅ 优化完成${NC}"
  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# 删除指定币对的数据
remove_pair() {
  if [ -z "$PAIR" ]; then
    echo -e "${RED}❌ 请指定币对: --pair PAIR${NC}"
    exit 1
  fi

  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}🗑️  删除币对数据${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

  check_data_dir

  local pair_dir="$DATA_DIR/$PAIR"

  if [ ! -d "$pair_dir" ]; then
    echo -e "${RED}❌ 币对目录不存在: $pair_dir${NC}"
    exit 1
  fi

  local size=$(du -sh "$pair_dir" | cut -f1)
  local file_count=$(find "$pair_dir" -name "*.feather" | wc -l)

  echo -e "币对:           ${YELLOW}$PAIR${NC}"
  echo -e "大小:           ${YELLOW}$size${NC}"
  echo -e "文件数:         ${YELLOW}$file_count${NC}"

  if [ "$DRY_RUN" = false ]; then
    read -p "确认删除? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}已取消${NC}"
      exit 0
    fi

    rm -rf "$pair_dir"
    echo -e "\n${GREEN}✅ 已删除${NC}"
  else
    echo -e "\n${YELLOW}[DRY-RUN 模式] 将删除 $size 的数据${NC}"
  fi

  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# 主函数
main() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  NostalgiaForInfinity 数据管理脚本                     ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"

  case $COMMAND in
    status)
      show_status
      ;;
    list)
      list_pairs
      ;;
    validate)
      validate_data
      ;;
    cleanup)
      cleanup_data
      ;;
    optimize)
      optimize_data
      ;;
    remove)
      remove_pair
      ;;
    -h|--help)
      print_help
      ;;
    *)
      echo -e "${RED}❌ 未知命令: $COMMAND${NC}"
      print_help
      exit 1
      ;;
  esac
}

# 运行主函数
main
