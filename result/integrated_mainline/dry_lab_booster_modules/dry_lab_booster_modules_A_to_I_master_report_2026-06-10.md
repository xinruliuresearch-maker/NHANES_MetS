# Dry-lab Booster Modules A-I Master Report

    日期：2026-06-10

    ## 完成状态

    - Module A: completed; records=20; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_A_literature_evidence_map`
- Module B: completed; n=5267; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_B_nhanes_advanced_epidemiology`
- Module C: completed; n_meals=1498; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_C_cgmacros_food_matrix`
- Module D: completed; n_meals=1498; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_D_cgm_curve_phenotypes`
- Module E: completed; n_edges=141; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_E_mechanism_knowledge_graph`
- Module F: completed; n_datasets=5; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_F_external_transportability`
- Module G: completed; n_scenarios=16; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_G_counterfactual_meal_redesign`
- Module H: completed; n_perf_rows=8; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_H_prediction_TRIPOD_PROBAST_AI`
- Module I: completed; n_manifest_files=43; output: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\dry_lab_booster_modules\module_I_reproducibility_submission_package`

    ## 当前可用于论文的主线

    > DEHP oxidative profile -> metabolic susceptibility -> postprandial glycemic vulnerability -> digestion-informed meal redesign

    ## 关键结果摘要

    - Module B: ln(Oxidative/MEHP) -> MSI-core = 0.183 (0.106, 0.259), q=7.54e-06.
- Module B: ln(Oxidative/MEHP) -> ln(HOMA-IR) = 0.218 (0.128, 0.309), q=6.57e-06.
- Module B: ln(Oxidative/MEHP) -> HbA1c = 0.135 (0.077, 0.193), q=1.3e-05.
- Module C: msi_centered predicts 2h iAUC /1000: beta=1.288 (0.654, 1.923), q=0.000214.
- Module C: digestibility_centered predicts 2h iAUC /1000: beta=0.388 (0.239, 0.537), q=2.88e-06.
- Module C: msi_x_digestibility predicts 2h iAUC /1000: beta=0.410 (0.216, 0.605), q=0.000118.
- Module C: msi_centered predicts 2h peak delta: beta=20.290 (11.919, 28.662), q=1.16e-05.
- Module C: digestibility_centered predicts 2h peak delta: beta=4.113 (2.168, 6.057), q=0.000118.
- Module C: msi_x_digestibility predicts 2h peak delta: beta=4.988 (2.664, 7.313), q=0.000104.
- Module D: highest-risk curve cluster is large_prolonged_response (n=215, mean iAUC=8963.3, mean peak=129.8, mean MSI=0.601).
- Module G: Cap carbs at 45 g predicted iAUC delta=-557.5; high-risk delta=-1513.4.
- Module G: Carb -20% to protein, isocaloric predicted iAUC delta=-285.6; high-risk delta=-678.0.
- Module G: Fiber +5 g predicted iAUC delta=-213.6; high-risk delta=-513.5.
- Module H: M3 MSI-enhanced iauc_2h MAE=2011.3, AUC_high_response=0.762, calibration slope=0.931.
- Module H: M3 MSI-enhanced peak_delta_2h MAE=27.1, AUC_high_response=0.787, calibration slope=0.963.

    ## 最重要的新增价值

    1. Module A 把研究空白定位为环境暴露、动态 PPGR 和食品消化结构之间的跨尺度连接。
    2. Module B 把 NHANES 从主模型扩展到 RCS、组成/混合代理、分层和负控/敏感性。
    3. Module C/D 把 CGMacros 从简单宏量营养推进到 food matrix proxy 和 CGM dynamic phenotype。
    4. Module E/F 补足机制可信度和外部边界，避免过度泛化。
    5. Module G/H/I 将预测结果转化为可解释干预逻辑，并补齐 TRIPOD+AI/PROBAST+AI 与可复现材料。

    ## 仍需人工/湿实验衔接

    - 12 个 bionic candidate meal 的图片和真实配方仍需人工 QC。
    - Module B 的 Python RCS/分层结果建议投稿前用 R `survey` 复核。
    - Food matrix proxy 若进入主文结论，建议用 USDA FoodData Central、Sydney GI 和 Open Food Facts 做二次校正。
    - 仿生消化实验应优先比较 high MSI/high digestibility-risk 餐食的 original vs redesigned glucose release kinetics。
