# Phase 2 完成报告：NHANES survey-ready 分析

    ## 环境状态

    当前电脑未检测到 R/Rscript：True。因此本阶段已完成 Python weighted + cluster-robust 近似分析，并生成正式 R `survey` 脚本 `phase2_formal_R_survey_script.R`，供安装 R 后作为投稿最终版复核。

    ## 已完成的计算输出

    - `phase2_python_analysis_dataset.csv`：已合并 MSI 敏感性版本和 NHANES 协变量。
    - `phase2_weighted_table1_by_oxidative_quartile.csv`：按 `%Oxidative` 四分位的加权基线表。
    - `phase2_nhanes_python_weighted_cluster_main_results.csv`：主模型。
    - `phase2_nhanes_python_sensitivity_results.csv`：minimal/full、排除糖尿病史、非肥胖子集敏感性。
    - `phase2_nhanes_dose_response_quartile_summary.csv`：四分位剂量反应描述。

    ## 最强主模型结果快照

    | outcome_label | exposure_label | estimate_CI | p_value | q_value | n | n_clusters |
| --- | --- | --- | --- | --- | --- | --- |
| MSI PCA | ln(Oxidative/MEHP) | 0.157 (0.099, 0.214) | 9.783e-08 | 2.054e-06 | 2741 | 60 |
| MSI no BMI | ln(Oxidative/MEHP) | 0.172 (0.102, 0.242) | 1.471e-06 | 1.509e-05 | 1306 | 60 |
| ln(HOMA-IR) | ln(Oxidative/MEHP) | 0.218 (0.128, 0.309) | 2.189e-06 | 1.509e-05 | 1292 | 60 |
| MSI-core | ln(Oxidative/MEHP) | 0.183 (0.106, 0.259) | 2.874e-06 | 1.509e-05 | 1313 | 60 |
| HbA1c | ln(Oxidative/MEHP) | 0.135 (0.077, 0.193) | 5.555e-06 | 2.333e-05 | 2671 | 60 |
| MSI no BMI | %Oxidative per 10 pp | 0.168 (0.070, 0.267) | 0.0007735 | 0.002707 | 1306 | 60 |
| MSI-core | %Oxidative per 10 pp | 0.168 (0.065, 0.272) | 0.001479 | 0.004361 | 1313 | 60 |
| MSI PCA | ln(Sigma DEHP) | 0.069 (0.026, 0.112) | 0.001661 | 0.004361 | 2741 | 60 |

    ## 投稿判断

    Python 结果可作为当前主线推进和结果筛选依据，但正式投稿必须用 `phase2_formal_R_survey_script.R` 在 R `survey` 环境中复核。若 R 结果与当前方向一致，NHANES 端可以作为主文 Figure 2 的核心证据。
