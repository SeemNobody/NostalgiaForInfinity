"""
NostalgiaForInfinityX7 Hyperopt优化策略

继承X7所有功能,添加参数优化空间定义,支持4阶段渐进式优化:
- 阶段1: 保护参数(止损阈值)
- 阶段2: Grinding参数(DCA分层加仓)
- 阶段3: 入场信号开关
- 阶段4: ROI表优化

使用方法:
freqtrade hyperopt --strategy NostalgiaForInfinityX7Hyperopt \
    --hyperopt-loss SharpeHyperOptLossDaily \
    --spaces protection \
    --epochs 200 \
    --timerange 20240101-20250101
"""

from NostalgiaForInfinityX7 import NostalgiaForInfinityX7
from freqtrade.optimize.space import Real, Categorical
from typing import Dict, Any


class NostalgiaForInfinityX7Hyperopt(NostalgiaForInfinityX7):
    """
    X7策略的Hyperopt优化版本

    继承X7所有功能,添加参数空间定义用于Hyperopt优化
    """

    # ============================================================
    # 阶段1: 保护参数优化空间 (6个参数)
    # ============================================================
    # 优化目标: 最大化Sharpe比率,建立风险控制基线
    # 预计Epochs: 200
    # 预计时间: 2-4小时

    # 止损阈值 - 现货
    stop_threshold_spot = Real(0.05, 0.20, default=0.10, space='protection')
    stop_threshold_rapid_spot = Real(0.10, 0.30, default=0.20, space='protection')
    stop_threshold_scalp_spot = Real(0.10, 0.30, default=0.20, space='protection')

    # 止损阈值 - 期货
    stop_threshold_futures = Real(0.05, 0.20, default=0.10, space='protection')
    stop_threshold_rapid_futures = Real(0.10, 0.30, default=0.20, space='protection')
    stop_threshold_scalp_futures = Real(0.10, 0.30, default=0.20, space='protection')

    # ============================================================
    # 阶段2: Grinding参数优化空间 (24个核心参数)
    # ============================================================
    # 优化目标: 最大化总收益,优化DCA分层加仓机制
    # 预计Epochs: 500
    # 预计时间: 8-12小时

    # Grind 1 - Spot
    grind_1_stop_grinds_spot = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_1_profit_threshold_spot = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 1 - Futures
    grind_1_stop_grinds_futures = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_1_profit_threshold_futures = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 2 - Spot
    grind_2_stop_grinds_spot = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_2_profit_threshold_spot = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 2 - Futures
    grind_2_stop_grinds_futures = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_2_profit_threshold_futures = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 3 - Spot
    grind_3_stop_grinds_spot = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_3_profit_threshold_spot = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 3 - Futures
    grind_3_stop_grinds_futures = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_3_profit_threshold_futures = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 4 - Spot
    grind_4_stop_grinds_spot = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_4_profit_threshold_spot = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 4 - Futures
    grind_4_stop_grinds_futures = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_4_profit_threshold_futures = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 5 - Spot
    grind_5_stop_grinds_spot = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_5_profit_threshold_spot = Real(0.010, 0.050, default=0.048, space='grinding')

    # Grind 5 - Futures
    grind_5_stop_grinds_futures = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_5_profit_threshold_futures = Real(0.010, 0.050, default=0.048, space='grinding')

    # Grind 6 - Spot
    grind_6_stop_grinds_spot = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_6_profit_threshold_spot = Real(0.010, 0.030, default=0.018, space='grinding')

    # Grind 6 - Futures
    grind_6_stop_grinds_futures = Real(-0.80, -0.30, default=-0.50, space='grinding')
    grind_6_profit_threshold_futures = Real(0.010, 0.030, default=0.018, space='grinding')

    # ============================================================
    # 阶段3: 入场信号开关优化空间 (35个参数)
    # ============================================================
    # 优化目标: 优化信号组合,提升胜率
    # 预计Epochs: 300
    # 预计时间: 6-8小时

    # 多头信号开关 (27个)
    long_entry_condition_1_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_2_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_3_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_4_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_5_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_6_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_21_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_41_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_42_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_43_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_44_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_45_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_46_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_61_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_62_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_63_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_101_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_102_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_103_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_104_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_120_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_121_enable = Categorical([True, False], default=False, space='buy')
    long_entry_condition_141_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_142_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_143_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_144_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_145_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_161_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_162_enable = Categorical([True, False], default=True, space='buy')
    long_entry_condition_163_enable = Categorical([True, False], default=True, space='buy')

    # 空头信号开关 (8个)
    short_entry_condition_501_enable = Categorical([True, False], default=True, space='sell')
    short_entry_condition_502_enable = Categorical([True, False], default=True, space='sell')
    short_entry_condition_541_enable = Categorical([True, False], default=True, space='sell')
    short_entry_condition_542_enable = Categorical([True, False], default=True, space='sell')
    short_entry_condition_543_enable = Categorical([True, False], default=True, space='sell')
    short_entry_condition_544_enable = Categorical([True, False], default=True, space='sell')
    short_entry_condition_545_enable = Categorical([True, False], default=True, space='sell')
    short_entry_condition_546_enable = Categorical([True, False], default=True, space='sell')

    # ============================================================
    # 阶段4: ROI表优化空间
    # ============================================================
    # 优化目标: 微调退出时机
    # 预计Epochs: 100
    # 预计时间: 1-2小时
    # 注意: Freqtrade会自动处理ROI参数,无需手动定义

    def __init__(self, config: Dict[str, Any]) -> None:
        """
        初始化Hyperopt策略

        应用Hyperopt参数到父类属性
        """
        super().__init__(config)

        # 应用多头信号开关到long_entry_signal_params
        long_conditions = [
            1, 2, 3, 4, 5, 6, 21, 41, 42, 43, 44, 45, 46,
            61, 62, 63, 101, 102, 103, 104, 120, 121,
            141, 142, 143, 144, 145, 161, 162, 163
        ]

        for condition_id in long_conditions:
            param_name = f"long_entry_condition_{condition_id}_enable"
            if hasattr(self, param_name):
                self.long_entry_signal_params[param_name] = getattr(self, param_name)

        # 应用空头信号开关到short_entry_signal_params
        short_conditions = [501, 502, 541, 542, 543, 544, 545, 546]

        for condition_id in short_conditions:
            param_name = f"short_entry_condition_{condition_id}_enable"
            if hasattr(self, param_name):
                self.short_entry_signal_params[param_name] = getattr(self, param_name)
