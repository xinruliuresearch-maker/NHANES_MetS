# No-digestion Phase 0-4 Master Report

    日期：2026-06-10

    ## 完成范围

    本次完成的是不考虑消化实验版本的 Phase 0-4，聚焦已经完成的计算分析、干实验补强、外部边界和预测模型。所有湿实验、仿生消化实验设计和未产生的实验数据均未纳入主线。

    ## 完成状态

    - Phase 0: scope, registry, and overclaim guardrails completed
- Phase 1: dataset inventory, evidence grades, and source crosswalk completed
- Phase 2: manuscript tables, figure data, and draft figures completed
- Phase 3: title options, claims table, abstract, outline, and storyboard completed
- Phase 4: submission readiness, limitations, reporting checklist, journal positioning, and next actions completed

    ## 当前论文主线

    > DEHP oxidative profile -> metabolic susceptibility phenotype -> postprandial glycemic vulnerability and personalized meal-risk prediction

    ## 可直接使用的主结果

    1. NHANES R survey：ln(Oxidative/MEHP) 与 MSI-core、ln(HOMA-IR)、HbA1c 显著相关。
    2. CGMacros：MSI 稳定预测 iAUC、peak 和 high-response risk。
    3. Food matrix proxy：MSI x digestibility-risk 对 iAUC 和 peak 显著。
    4. Curve phenotype：large_prolonged_response cluster 具有最高 MSI、最高 digestibility-risk 和最高 PPGR。
    5. Prediction：M3 MSI-enhanced 相比 M2 改善 MAE、AUC 和 calibration slope。

    ## 最重要的限制

    1. DEHP 和 PPGR 不在同一人群中直接观测。
    2. Food matrix/digestibility-risk 仍是 proxy。
    3. CGMacros subject-level 样本量有限。
    4. 外部数据是 boundary，不是直接 replication。
    5. 无消化实验版本缺少机制/干预闭环。

    ## 输出目录

    - CGMacros: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\no_digestion_phase0_to_phase4`
    - NHANES mirror: `C:\Users\liu12\OneDrive\Desktop\NHANES_MetS_Project\result\integrated_mainline\no_digestion_phase0_to_phase4`
