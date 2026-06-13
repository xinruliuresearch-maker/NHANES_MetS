# Phase 0-5 计算工作流总报告

    日期：2026-06-10

    已完成 Phase 0-5 中所有当前电脑可以完成的计算部分。随后已定位本机 R 4.6.0，并成功运行 Phase 2 正式 R `survey` 复杂抽样复核脚本。

    ## 阶段输出概览

    | phase | n_files | key_files |
| --- | --- | --- |
| phase0_protocol | 4 | phase0_analysis_registry.csv; phase0_main_claims_and_no_overclaim_rules.md; phase0_report_2026-06-10.md; phase0_statistical_analysis_plan_v1.md |
| phase1_qc_msi_sensitivity | 9 | phase1_candidate_meal_qc.csv; phase1_candidate_meal_qc_summary.csv; phase1_msi_pca_component_weights.csv; phase1_msi_ppgr_sensitivity_models.csv; phase1_msi_sensitivity_nhanes.csv; phase1_msi_sensitivity_subjects_cgmacros.csv; phase1_msi_version_correlations.csv; phase1_nhanes_msi_exposure_sensitivity_models.csv |
| phase2_nhanes_survey_ready | 7 | phase2_formal_R_survey_script.R; phase2_nhanes_dose_response_quartile_summary.csv; phase2_nhanes_python_sensitivity_results.csv; phase2_nhanes_python_weighted_cluster_main_results.csv; phase2_nhanes_survey_ready_report_2026-06-10.md; phase2_python_analysis_dataset.csv; phase2_weighted_table1_by_oxidative_quartile.csv |
| phase3_cgmacros_robust_inference | 6 | phase3_cgmacros_robust_inference_report_2026-06-10.md; phase3_high_response_definition_sensitivity.csv; phase3_leave_one_subject_influence.csv; phase3_load_variant_cluster_models.csv; phase3_subject_bootstrap_key_terms.csv; phase3_subject_level_ppgr_msi_summary.csv |
| phase4_prediction_upgrade | 8 | phase4_calibration_deciles.csv; phase4_conformal_interval_coverage.csv; phase4_fewshot_recalibration_performance.csv; phase4_model_comparison_key_deltas.csv; phase4_model_performance_overall.csv; phase4_nested_lso_prediction_records.csv; phase4_performance_by_msi.csv; phase4_prediction_upgrade_report_2026-06-10.md |
| phase5_external_validation | 8 | phase5_external_boundary_summary.csv; phase5_external_validation_report_2026-06-10.md; phase5_jaeb_healthy_adults_cgm_summary.csv; phase5_stanford_food_challenge_metrics.csv; phase5_stanford_food_summary.csv; phase5_stanford_msi_proxy_models.csv; phase5_t1d_uom_macro_ppgr_models.csv; phase5_t1d_uom_meal_ppgr_metrics.csv |

    ## 当前投稿级判断

    - Phase 0 已冻结主线和禁止过度解释规则。
    - Phase 1 已完成 MSI 稳健性和候选餐食 QC。
    - Phase 2 已完成 Python survey-like 近似和 R survey-ready 脚本。
    - Phase 3 已完成 CGMacros subject-cluster、subject bootstrap、leave-one-subject-out 稳健推断。
    - Phase 4 已完成 nested leave-subject-out 预测、校准、high-response detection、conformal coverage 和 few-shot personalization。
    - Phase 5 已完成 Stanford/T1D-UOM/Jaeb 的外部边界分析。

    下一步最关键的非计算任务是：对 Stage 5 候选餐食做人工图片/配方复核后开展仿生消化 pilot。R `survey` 正式复核已经完成。
