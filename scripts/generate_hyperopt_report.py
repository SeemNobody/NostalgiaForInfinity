#!/usr/bin/env python3
"""
Hyperopt优化报告生成器

生成Hyperopt优化的详细报告,包括:
- 优化进度
- 最佳参数
- 性能指标
- 对比分析
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
import re


class HyperoptReportGenerator:
    """Hyperopt报告生成器"""

    def __init__(self, project_dir: str = "/Users/colin/IdeaProjects/NostalgiaForInfinity"):
        self.project_dir = Path(project_dir)
        self.results_dir = self.project_dir / "user_data" / "hyperopt_results"
        self.phases = ["phase1_results", "phase2_results", "phase3_results", "phase4_results"]

    def parse_hyperopt_log(self, log_file: Path) -> Dict[str, Any]:
        """解析Hyperopt日志文件"""
        if not log_file.exists():
            return {}

        data = {
            "total_epochs": 0,
            "best_loss": None,
            "best_params": {},
            "trades_count": 0,
            "profit": 0,
            "sharpe": 0,
            "max_drawdown": 0,
        }

        try:
            with open(log_file, "r") as f:
                content = f.read()

                # 提取Epochs数量
                epochs_match = re.search(r"(\d+)/(\d+)", content)
                if epochs_match:
                    data["total_epochs"] = int(epochs_match.group(2))

                # 提取最佳损失值
                loss_match = re.search(r"Best loss: ([-\d.]+)", content)
                if loss_match:
                    data["best_loss"] = float(loss_match.group(1))

                # 提取交易数
                trades_match = re.search(r"(\d+) trades", content)
                if trades_match:
                    data["trades_count"] = int(trades_match.group(1))

                # 提取收益率
                profit_match = re.search(r"Total profit: ([-\d.]+)%", content)
                if profit_match:
                    data["profit"] = float(profit_match.group(1))

                # 提取Sharpe比率
                sharpe_match = re.search(r"Sharpe Ratio: ([-\d.]+)", content)
                if sharpe_match:
                    data["sharpe"] = float(sharpe_match.group(1))

                # 提取最大回撤
                drawdown_match = re.search(r"Max Drawdown: ([-\d.]+)%", content)
                if drawdown_match:
                    data["max_drawdown"] = float(drawdown_match.group(1))

        except Exception as e:
            print(f"⚠️ 解析日志文件失败: {e}")

        return data

    def get_phase_status(self, phase: str) -> Dict[str, Any]:
        """获取阶段状态"""
        phase_dir = self.results_dir / phase
        status = {
            "phase": phase,
            "exists": phase_dir.exists(),
            "log_files": [],
            "best_params_file": None,
            "latest_log": None,
            "log_data": {},
        }

        if not phase_dir.exists():
            return status

        # 查找日志文件
        log_files = list(phase_dir.glob("hyperopt_*.log"))
        status["log_files"] = [f.name for f in log_files]

        if log_files:
            # 获取最新的日志文件
            latest_log = max(log_files, key=lambda f: f.stat().st_mtime)
            status["latest_log"] = latest_log.name
            status["log_data"] = self.parse_hyperopt_log(latest_log)

        # 检查最佳参数文件
        best_params_file = phase_dir / f"{phase}_best_params.json"
        if best_params_file.exists():
            status["best_params_file"] = best_params_file.name
            try:
                with open(best_params_file) as f:
                    status["best_params"] = json.load(f)
            except:
                pass

        return status

    def generate_report(self) -> str:
        """生成完整报告"""
        report = []
        report.append("=" * 60)
        report.append("NostalgiaForInfinityX7 Hyperopt优化报告")
        report.append("=" * 60)
        report.append(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")

        # 检查所有阶段
        all_phases_status = []
        for phase in self.phases:
            status = self.get_phase_status(phase)
            all_phases_status.append(status)

        # 生成阶段摘要
        report.append("📊 优化阶段摘要")
        report.append("-" * 60)

        for status in all_phases_status:
            phase_name = status["phase"].replace("_results", "").upper()
            if status["exists"]:
                log_data = status["log_data"]
                report.append(f"\n✅ {phase_name}:")
                report.append(f"   日志文件: {status['latest_log'] or '无'}")
                report.append(f"   总Epochs: {log_data.get('total_epochs', 'N/A')}")
                report.append(f"   最佳损失: {log_data.get('best_loss', 'N/A')}")
                report.append(f"   交易数: {log_data.get('trades_count', 'N/A')}")
                report.append(f"   总收益: {log_data.get('profit', 'N/A')}%")
                report.append(f"   Sharpe比率: {log_data.get('sharpe', 'N/A')}")
                report.append(f"   最大回撤: {log_data.get('max_drawdown', 'N/A')}%")
                if status["best_params_file"]:
                    report.append(f"   最佳参数: {status['best_params_file']}")
            else:
                report.append(f"\n⏳ {phase_name}: 等待中...")

        # 生成详细信息
        report.append("\n" + "=" * 60)
        report.append("📁 文件结构")
        report.append("-" * 60)

        for status in all_phases_status:
            if status["exists"]:
                phase_dir = self.results_dir / status["phase"]
                report.append(f"\n{status['phase']}:")
                for log_file in status["log_files"]:
                    report.append(f"  - {log_file}")
                if status["best_params_file"]:
                    report.append(f"  - {status['best_params_file']}")

        # 生成建议
        report.append("\n" + "=" * 60)
        report.append("💡 后续步骤")
        report.append("-" * 60)
        report.append("""
1. 监控Hyperopt进度:
   tail -f user_data/hyperopt_results/phase1_results/hyperopt_*.log

2. 查看最佳结果:
   docker-compose -f docker-compose.yml run --rm freqtrade hyperopt-show --best -n 10

3. 导出最佳参数:
   docker-compose -f docker-compose.yml run --rm freqtrade hyperopt-show --best --print-json > phase_best_params.json

4. 执行回测验证:
   freqtrade backtesting --strategy NostalgiaForInfinityX7 --config configs/exampleconfig.json --config phase_best_params.json --timerange 20240101-20250101
""")

        report.append("\n" + "=" * 60)
        report.append("✨ 报告生成完成")
        report.append("=" * 60)

        return "\n".join(report)

    def save_report(self, output_file: Optional[str] = None) -> str:
        """保存报告到文件"""
        report_content = self.generate_report()

        if output_file is None:
            output_file = self.project_dir / f"HYPEROPT_REPORT_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        else:
            output_file = Path(output_file)

        with open(output_file, "w") as f:
            f.write(report_content)

        return str(output_file)


def main():
    """主函数"""
    generator = HyperoptReportGenerator()

    # 生成并打印报告
    report = generator.generate_report()
    print(report)

    # 保存报告
    report_file = generator.save_report()
    print(f"\n📄 报告已保存到: {report_file}")


if __name__ == "__main__":
    main()
