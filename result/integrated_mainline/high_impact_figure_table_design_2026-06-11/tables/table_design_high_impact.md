# 主表与补充表设计

顶刊主文建议保留 3-5 张主表；其余完整结果进入 Supplementary Tables。

## Main Tables

### Main Table 1. Datasets, phenotypes, and analytic roles
- **列设计**：Dataset; role; participants; meals/events/readings; MSI available; key exposure/outcome; main limitation
- **数据来源**：Table1_dataset_and_phenotype_summary.csv; external_transportability_map.csv
- **期刊角色**：One-page transparent overview of all evidence layers.

### Main Table 2. Primary NHANES exposure-susceptibility estimates
- **列设计**：Exposure; outcome; beta; 95% CI; P; q; model/covariates; analytic n
- **数据来源**：Table2_NHANES_R_survey_key_results.csv
- **期刊角色**：Main epidemiology results table, complements Figure 2.

### Main Table 3. Primary CGMacros MSI-PPGR and food-matrix models
- **列设计**：Outcome; model block; term; estimate; 95% CI; q; meals; participants; interpretation
- **数据来源**：Table3_CGMacros_MSI_PPGR_results.csv; Table4_FoodMatrix_CurvePhenotype_results.csv
- **期刊角色**：Compact table for main CGM and food-matrix estimates.

### Main Table 4. Prediction performance and incremental value of MSI
- **列设计**：Target; model; MAE; R2; AUC; AUPRC; calibration slope; net benefit; delta vs M2
- **数据来源**：Table5A_prediction_model_performance.csv; Table5B_prediction_incremental_gain.csv
- **期刊角色**：Prediction/translational table aligned with TRIPOD+AI expectations.

### Main Table 5. Claim-level evidence strength and guardrails
- **列设计**：Claim; supporting figure/table; dataset; inference type; causal status; limitation; required wording
- **数据来源**：phase3_main_claims_table_no_digestion.csv; claim_guardrails_for_reviewers.md
- **期刊角色**：May be main or supplement; extremely useful for top-tier cautious framing.

## Supplementary Tables
- **Supplementary Table 1**：Full data dictionary and variable definitions；来源：data_dictionary.csv/xlsx
- **Supplementary Table 2**：Analysis registry and prespecified claim boundaries；来源：phase0_no_digestion_analysis_registry.csv; phase0_overclaim_guardrails.csv
- **Supplementary Table 3**：NHANES weighted descriptive table by oxidative quartile；来源：phase2_weighted_table1_by_oxidative_quartile.csv
- **Supplementary Table 4**：Full NHANES R survey model results；来源：phase2_R_survey_main_results.csv
- **Supplementary Table 5**：R survey vs Python comparison；来源：phase2_R_survey_vs_python_comparison.csv
- **Supplementary Table 6**：NHANES dose-response quartile summary；来源：phase2_nhanes_dose_response_quartile_summary.csv
- **Supplementary Table 7**：NHANES spline coefficients and prediction grid；来源：phase2_python_rcs_spline_coefficients.csv; phase2_python_rcs_prediction_grid.csv
- **Supplementary Table 8**：NHANES effect modification；来源：nhanes_effect_modification_results.csv
- **Supplementary Table 9**：NHANES sensitivity and negative-control-like analyses；来源：nhanes_negative_control_and_sensitivity_results.csv
- **Supplementary Table 10**：DEHP mixture/composition proxy results；来源：nhanes_dehp_mixture_composition_results.csv
- **Supplementary Table 11**：MSI component scaler, missingness, PCA weights, correlations；来源：stage1_msi_component_scaler.csv; phase1_msi_pca_component_weights.csv; phase1_msi_version_correlations.csv
- **Supplementary Table 12**：CGMacros subject-level PPGR by MSI；来源：phase3_subject_level_ppgr_msi_summary.csv
- **Supplementary Table 13**：CGMacros full cluster-robust meal-level models；来源：stage3_cgmacros_msi_ppgr_model_results.csv; Table3_CGMacros_MSI_PPGR_results.csv
- **Supplementary Table 14**：CGMacros bootstrap and influence diagnostics；来源：phase3_subject_bootstrap_key_terms.csv; phase3_leave_one_subject_influence.csv
- **Supplementary Table 15**：High-response definition sensitivity；来源：phase3_high_response_definition_sensitivity.csv
- **Supplementary Table 16**：Food-matrix annotation codebook and features；来源：cgmacros_food_matrix_annotation.csv; food_matrix_annotation_codebook.md
- **Supplementary Table 17**：Food-matrix PPGR models；来源：cgmacros_food_matrix_ppgr_models.csv
- **Supplementary Table 18**：CGM curve phenotype features and models；来源：cgmacros_ppgr_curve_features.csv; curve_shape_msi_food_matrix_models.csv
- **Supplementary Table 19**：Prediction model performance, calibration, conformal intervals；来源：phase4_model_performance_overall.csv; phase4_calibration_deciles.csv; phase4_conformal_interval_coverage.csv
- **Supplementary Table 20**：Prediction leakage audit and predictor dictionary；来源：prediction_leakage_audit.csv; prediction_predictor_dictionary.csv
- **Supplementary Table 21**：Prediction performance by MSI subgroup；来源：phase4_performance_by_msi.csv
- **Supplementary Table 22**：Counterfactual meal redesign results；来源：counterfactual_meal_redesign_effects.csv; counterfactual_subject_level_heterogeneity.csv
- **Supplementary Table 23**：External CGM transportability map；来源：external_transportability_map.csv
- **Supplementary Table 24**：External domain shift and macro directionality；来源：external_domain_shift_metrics.csv; external_macro_direction_consistency.csv
- **Supplementary Table 25**：Mechanism knowledge graph edges and pathway enrichment；来源：dehp_msi_mechanism_knowledge_graph_edges.csv; dehp_msi_pathway_enrichment.csv
- **Supplementary Table 26**：Literature evidence map and evidence gaps；来源：dry_lab_evidence_map_seed.csv; dry_lab_evidence_gap_table.csv
- **Supplementary Table 27**：Reproducibility manifest and run order；来源：analysis_manifest.csv; run_order.md
- **Supplementary Table 28**：Source-data mapping for all display items；来源：display_source_data_map.csv
- **Supplementary Table 29**：Reviewer concern-response matrix；来源：reviewer_concern_response_matrix.csv
- **Supplementary Table 30**：Figure and table production priority tracker；来源：figure_build_priority_and_gap_audit.csv
