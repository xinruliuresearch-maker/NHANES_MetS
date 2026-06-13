# Phase 4 完成报告：MSI-aware 预测与个体化升级

    ## 已完成

    - 采用 nested leave-subject-out 设计：外层留一受试者，内层按受试者 5-fold 调参 alpha。
    - 模型阶梯：M0 carb-only、M1 macro/timing、M2 pre-CGM/context、M3 MSI-enhanced。
    - 输出连续结局 MAE/RMSE/R2/calibration，high-response AUC/AUPRC/sensitivity/specificity/net benefit。
    - 输出 conformal-style residual interval coverage。
    - 输出 0/1/3/5/10-shot 个体化校准表现。

    ## 总体模型表现

    | target_label | model | MAE | RMSE | calibration_slope | AUC_high_response | AUPRC_high_response | net_benefit_pt25 | n |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2h iAUC | M0_carb_only | 2295 | 3089 | 0.8874 | 0.6033 | 0.3101 | 0 | 1498 |
| 2h iAUC | M1_macro_timing | 2201 | 2948 | 0.9283 | 0.6728 | 0.4036 | 0.04473 | 1498 |
| 2h iAUC | M2_macro_precgm_context | 2166 | 2908 | 0.9015 | 0.6878 | 0.4177 | 0.05207 | 1498 |
| 2h iAUC | M3_msi_enhanced | 2011 | 2722 | 0.9306 | 0.762 | 0.5201 | 0.07966 | 1498 |
| 2h peak delta | M0_carb_only | 32.02 | 42.41 | 0.9095 | 0.5889 | 0.2977 | 0.001113 | 1498 |
| 2h peak delta | M1_macro_timing | 30.1 | 39.77 | 0.9555 | 0.6959 | 0.4272 | 0.05162 | 1498 |
| 2h peak delta | M2_macro_precgm_context | 29.83 | 39.1 | 0.9233 | 0.7025 | 0.4265 | 0.05763 | 1498 |
| 2h peak delta | M3_msi_enhanced | 27.14 | 35.85 | 0.9626 | 0.7867 | 0.5711 | 0.09413 | 1498 |

    ## 关键模型差异

    | target | comparison | MAE_delta | MAE_pct_change | AUC_delta | calibration_slope_delta |
| --- | --- | --- | --- | --- | --- |
| iauc_2h | M3_msi_enhanced minus M2_macro_precgm_context | -155 | -7.156 | 0.07414 | 0.02904 |
| iauc_2h | M3_msi_enhanced minus M0_carb_only | -283.5 | -12.36 | 0.1586 | 0.04321 |
| peak_delta_2h | M3_msi_enhanced minus M2_macro_precgm_context | -2.691 | -9.021 | 0.08421 | 0.03929 |
| peak_delta_2h | M3_msi_enhanced minus M0_carb_only | -4.881 | -15.24 | 0.1978 | 0.05302 |

    ## 投稿判断

    Phase 4 已经从简单 ridge benchmark 升级为更接近 TRIPOD+AI 思路的开发/验证框架。主文不应写成模型排行榜，而应集中回答：MSI 是否改善高风险餐食识别或校准，高 MSI 个体是否更难预测，以及 few-shot personalization 是否能补偿这种难度。
