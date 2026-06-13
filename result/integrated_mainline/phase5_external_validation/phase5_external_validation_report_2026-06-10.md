# Phase 5 完成报告：外部 CGM 验证与边界分析

    ## 已完成

    - Stanford CGMDB：从标准化食物挑战 CGM 曲线计算 baseline、2h iAUC、3h iAUC、2h peak delta，并构建 Stanford MSI proxy。
    - T1D-UOM：从营养日志和 CGM 文件自动配对餐食事件，计算 T1D 自由生活餐食 PPGR。
    - Jaeb healthy adults：提取健康成人 CGM phenotype 参考。
    - 生成跨数据集边界表，明确外部数据只用于边界验证，不作为同分布重复验证。

    ## 外部边界概览

    | dataset | n_subjects | n_events | event_type | median_iauc_2h | median_peak_delta_2h | time_above_140_or_high_rate |
| --- | --- | --- | --- | --- | --- | --- |
| CGMacros | 40 | 1498 | free-living meals | 2146 | 42.6 |  |
| Stanford_CGMDB | 38 | 588 | standardized food challenges | 2441 | 49.76 | 0.25 |
| T1D_UOM | 15 | 3820 | T1D logged meals | 1326 | 42.34 | 0.25 |
| Jaeb_CGMND_HealthyAdults | 169 | 383117 | healthy adult CGM readings |  |  | 0.02069 |

    ## Stanford 标准化食物挑战最高反应食物

    | food | n_challenges | n_subjects | median_iauc_2h | median_peak_delta_2h | cv_iauc_2h |
| --- | --- | --- | --- | --- | --- |
| Glucose | 2 | 1 | 5517 | 92.67 | 0.02482 |
| Rice | 209 | 38 | 3123 | 60 | 0.6872 |
| Pasta | 52 | 27 | 2511 | 46.74 | 0.8072 |
| Potatoes | 73 | 36 | 2441 | 51.35 | 0.8197 |
| Bread | 105 | 38 | 2372 | 47.08 | 0.8849 |
| Grapes | 69 | 38 | 1931 | 53.49 | 0.8459 |
| Quinoa | 5 | 4 | 1828 | 49.31 | 1.109 |
| Beans | 34 | 21 | 1239 | 29.01 | 1.128 |

    ## Stanford MSI proxy 模型

    | outcome | term | estimate_CI | p_value | n | n_clusters |
| --- | --- | --- | --- | --- | --- |
| iauc_2h | stanford_msi_proxy | 0.552 (-0.385, 1.490) | 0.2482 | 581 | 37 |
| peak_delta_2h | stanford_msi_proxy | 2.850 (-8.604, 14.304) | 0.6258 | 581 | 37 |

    ## 投稿判断

    Stanford CGMDB 适合作为主文外部边界图，因为它是标准化食物挑战，能够展示相同食物下的个体异质性。T1D-UOM 提供疾病状态下的自由生活餐食边界，但不应被解释为 CGMacros 的直接重复验证。Jaeb healthy adults 适合作为健康 CGM 波动范围参考。
