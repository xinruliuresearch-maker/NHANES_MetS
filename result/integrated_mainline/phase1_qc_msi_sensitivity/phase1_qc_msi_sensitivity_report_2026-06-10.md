# Phase 1 完成报告：数据质量与 MSI 稳健性

    ## 已完成

    - 构建 9 个 MSI 敏感性版本：partial、complete、ranknorm、without BMI、glycemia/IR、IR/lipid、PCA、HOMA 单指标、TG/HDL 单指标。
    - 计算 NHANES 与 CGMacros 中 MSI 版本之间的 Pearson/Spearman 相关。
    - 在 CGMacros 中复核各 MSI 版本与 PPGR 的关联。
    - 在 NHANES 中复核各 MSI 版本与 DEHP oxidative profile 的关联。
    - 对 Stage 5 体外消化候选餐食做图片存在性、宏量营养合理性、0 纤维、重复宏量指纹 QC。

    ## 关键发现

    - PCA MSI 权重已保存到 `phase1_msi_pca_component_weights.csv`。
    - CGMacros/NHANES 的 MSI 版本高度相关性与模型结果见 `phase1_msi_version_correlations.csv`、`phase1_msi_ppgr_sensitivity_models.csv`、`phase1_nhanes_msi_exposure_sensitivity_models.csv`。
    - 体外消化候选餐食中，需要人工复核的候选数：12/12；图片找到 12/12；0 纤维候选 12/12。

    ## NHANES MSI 敏感性中最强的 5 个关联

    | outcome_msi_version | exposure | estimate_CI | p_value | q_value | n |
| --- | --- | --- | --- | --- | --- |
| msi_pca | ln_oxidative_to_MEHP | 0.157 (0.099, 0.214) | 9.783e-08 | 1.761e-06 | 2741 |
| msi_no_bmi | ln_oxidative_to_MEHP | 0.172 (0.102, 0.242) | 1.471e-06 | 1.028e-05 | 1306 |
| msi_glycemia_ir | ln_oxidative_to_MEHP | 0.182 (0.107, 0.257) | 1.721e-06 | 1.028e-05 | 1313 |
| homa_ir_single | ln_oxidative_to_MEHP | 0.253 (0.148, 0.358) | 2.351e-06 | 1.028e-05 | 1292 |
| msi_core_partial | ln_oxidative_to_MEHP | 0.183 (0.106, 0.259) | 2.874e-06 | 1.028e-05 | 1313 |

    ## CGMacros MSI-PPGR 敏感性中最强的 5 个关联

    | msi_version | outcome_label | term | estimate_CI | p_value | q_value | n |
| --- | --- | --- | --- | --- | --- | --- |
| msi_glycemia_ir | 2h peak delta | msi_centered | 22.005 (15.656, 28.354) | 1.097e-11 | 3.948e-10 | 1498 |
| msi_glycemia_ir | 2h iAUC / 1000 | msi_centered | 1.401 (0.935, 1.867) | 3.872e-09 | 6.97e-08 | 1498 |
| msi_pca | 2h peak delta | msi_centered | 18.773 (11.404, 26.141) | 5.932e-07 | 7.119e-06 | 1498 |
| msi_no_bmi | 2h peak delta | msi_centered | 17.820 (10.181, 25.458) | 4.822e-06 | 4.34e-05 | 1498 |
| msi_pca | 2h iAUC / 1000 | msi_centered | 1.166 (0.654, 1.679) | 8.237e-06 | 5.306e-05 | 1498 |

    ## 投稿含义

    MSI 桥梁变量不是只依赖单一构造方式；后续主文可以用 `MSI-core partial NHANES-ref` 作为主版本，并把 PCA、without-BMI、ranknorm、单指标版本放入补充材料。Stage 5 候选餐食必须先做人工图片/配方复核，尤其是 0 纤维和重复宏量指纹候选。
