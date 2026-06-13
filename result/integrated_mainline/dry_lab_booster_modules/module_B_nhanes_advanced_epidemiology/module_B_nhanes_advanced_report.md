# Module B：NHANES 高级环境流行病学补强

        日期：2026-06-10

        ## 已完成分析

        1. RCS 剂量反应代理分析：`phase2_python_rcs_spline_coefficients.csv` 与 `phase2_python_rcs_prediction_grid.csv`。
        2. DEHP 总量、oxidative profile 与 molar composition/CLR/ILR 的联合模型：`nhanes_dehp_mixture_composition_results.csv`。
        3. sex、age、obesity、diabetes history、race/ethnicity、diet-source proxy 分层：`nhanes_effect_modification_results.csv`。
        4. 排除糖尿病史、尿肌酐协变量敏感性、negative-control-like exposure/outcome：`nhanes_negative_control_and_sensitivity_results.csv`。

        ## 解释原则

        - 当前模块为 Python weighted/cluster-robust 增强版，用于确定论文主线、图表和敏感性方向。
        - 正式投稿前，建议将 RCS 与分层模型迁移到 R `survey`/`splines` 进行最终复核。
        - 对横断面 NHANES 结果只表述 association，不表述因果。

        ## 结果摘要

        RCS spline coefficients generated for 3 DEHP exposures x 5 outcomes.
Top mixture/composition terms:
outcome_label                     term  estimate  p_value
      MSI PCA         pct_oxidative_10 -0.204266 0.000318
  ln(HOMA-IR)     ln_oxidative_to_MEHP  0.936234 0.001004
     MSI-core     ln_oxidative_to_MEHP  0.657548 0.002169
      MSI PCA     ln_oxidative_to_MEHP  0.618496 0.004565
  ln(HOMA-IR) ilr_primary_vs_oxidative  0.307694 0.045490
