# 高水平期刊主文图设计

建议以 8 张主图为核心，Figure 9 作为可选主图或 Extended Data。

## Main Figure 1. Integrated evidence architecture and study design
- **核心问题**：How can a population DEHP oxidative-metabolism signal be connected conservatively to CGM meal vulnerability without overclaiming causality?
- **推荐面板**：A. Graphical evidence cascade; B. Dataset flow and sample sizes; C. MSI bridge phenotype construction; D. Claim hierarchy and no-overclaim guardrails; E. Analysis module timeline.
- **数据来源**：Table1_dataset_and_phenotype_summary.csv; phase0 registry; claim guardrails; module manifest
- **核心信息**：This is a staged bridge-phenotype design: DEHP oxidative profile -> MSI in NHANES; MSI -> PPGR vulnerability in CGMacros.
- **期刊角色**：Front-door figure for Nature/Cell/Lancet-style readers; explains why the cross-dataset design is valid but cautious.
- **当前状态**：New design needed; previous schematic can be rebuilt as cleaner data-annotated graphical abstract.
- **下一步**：Rebuild as high-end graphical abstract with minimal text, dataset sizes, and a clear 'not direct causality' design note.

## Main Figure 2. DEHP oxidative-metabolism profile is associated with metabolic susceptibility in NHANES
- **核心问题**：Is the environmental exposure-profile layer statistically robust?
- **推荐面板**：A. Survey-weighted forest plot for primary and secondary exposures; B. Weighted quartile dose-response; C. spline curve; D. MSI-version robustness; E. sensitivity/negative-control panel; F. subgroup or effect-modification heatmap.
- **数据来源**：Table2_NHANES_R_survey_key_results.csv; phase2_nhanes_dose_response_quartile_summary.csv; phase2_python_rcs_prediction_grid.csv; NHANES sensitivity/composition/effect-modification files.
- **核心信息**：The DEHP oxidative profile is consistently associated with MSI and insulin-resistance/glycemic markers.
- **期刊角色**：Primary epidemiologic evidence figure.
- **当前状态**：Partly implemented in Figure1_NHANES_exposure_response_publication_v2; should be expanded for top-tier submission.
- **下一步**：Add robustness strip and subgroup heatmap; keep main forest/dose/spline as central panels.

## Main Figure 3. Construction, robustness, and transfer of the metabolic susceptibility phenotype
- **核心问题**：Is MSI a stable bridge phenotype rather than an arbitrary score?
- **推荐面板**：A. MSI component z-score architecture; B. PCA/component weights; C. MSI-version correlation matrix; D. NHANES vs CGMacros MSI distributions; E. component profiles across MSI tertiles; F. missingness/availability waterfall.
- **数据来源**：phase1_msi_version_correlations.csv; phase1_msi_pca_component_weights.csv; stage1_msi_summary_by_dataset.csv; cgmacros_subject_msi_core.csv; nhanes_2013_2018_msi_core.csv.
- **核心信息**：MSI behaves consistently across construction variants and can bridge NHANES and CGMacros.
- **期刊角色**：Defends the bridge variable, which is the manuscript's central methodological hinge.
- **当前状态**：Not yet built as a main figure; data available.
- **下一步**：Generate as a polished multi-panel figure before any top-tier submission.

## Main Figure 4. MSI identifies free-living postprandial glycemic vulnerability in CGMacros
- **核心问题**：Does the bridge phenotype manifest as dynamic meal-level vulnerability?
- **推荐面板**：A. Meal-level iAUC distribution by MSI tertile; B. peak distribution; C. subject-level MSI-response gradient; D. cluster-robust model coefficient forest; E. bootstrap estimates; F. leave-one-subject influence.
- **数据来源**：cgmacros_meal_level_with_msi_core.csv; phase3_subject_level_ppgr_msi_summary.csv; Table3_CGMacros_MSI_PPGR_results.csv; phase3_subject_bootstrap_key_terms.csv; phase3_leave_one_subject_influence.csv.
- **核心信息**：Higher MSI is a robust main-effect marker of PPGR vulnerability.
- **期刊角色**：Primary CGM physiology figure.
- **当前状态**：Partly implemented in Figure2_CGMacros_MSI_PPGR_publication_v2.
- **下一步**：Add bootstrap and leave-one-subject influence as E-F or Extended Data if main figure becomes dense.

## Main Figure 5. Person-by-food-matrix susceptibility refines carbohydrate-only interpretation
- **核心问题**：Why is the biology not just 'more carbs, more glucose'?
- **推荐面板**：A. Digestibility-risk vs iAUC meal scatter; B. iAUC and peak model forest; C. MSI x digestibility predicted response surface; D. high-risk food-matrix feature enrichment; E. counterfactual meal redesign effect; F. candidate high-risk meal matrix examples if image permissions allow.
- **数据来源**：cgmacros_food_matrix_annotation.csv; cgmacros_food_matrix_ppgr_models.csv; counterfactual_meal_redesign_effects.csv; Supplement_counterfactual_meal_redesign_summary.csv.
- **核心信息**：High-MSI individuals appear especially vulnerable to high-digestibility-risk food matrices.
- **期刊角色**：Mechanistic/nutrition novelty figure.
- **当前状态**：Partly implemented in Figure3_FoodMatrix_CurvePhenotypes_publication_v2; response surface and counterfactual panel not yet built.
- **下一步**：Add predicted interaction surface and counterfactual redesign panel; keep proxy caveat in legend.

## Main Figure 6. CGM curve phenotypes reveal prolonged and delayed response vulnerability
- **核心问题**：Does MSI/food-matrix susceptibility affect response shape, not only scalar iAUC/peak?
- **推荐面板**：A. Cluster map by iAUC/peak/time-to-peak/recovery; B. cluster composition by MSI tertile; C. delayed-peak/prolonged-elevation model forest; D. prototype response curves or reconstructed curves; E. MSI-digestibility to curve-phenotype alluvial plot.
- **数据来源**：cgmacros_ppgr_curve_features.csv; curve_shape_msi_food_matrix_models.csv; Figure4_data_curve_clusters.csv.
- **核心信息**：Susceptibility is expressed as dynamic CGM response phenotypes, especially large/prolonged responses.
- **期刊角色**：Adds physiologic depth and makes CGM dynamics visible.
- **当前状态**：Partly implemented inside Figure3 v2; should become independent figure if targeting a top-tier journal.
- **下一步**：Generate prototype curve panel if raw time-series alignment is feasible; otherwise use feature-derived clusters and model forest.

## Main Figure 7. MSI-enhanced models improve personalized high-response stratification
- **核心问题**：Does the biology improve practical meal-risk prediction?
- **推荐面板**：A. observed vs predicted iAUC; B. observed vs predicted peak; C. nested model AUC/MAE/R2; D. calibration deciles; E. conformal interval coverage/width; F. decision-curve net benefit; G. performance by MSI tertile.
- **数据来源**：phase4_nested_lso_prediction_records.csv; phase4_model_performance_overall.csv; phase4_calibration_deciles.csv; phase4_conformal_interval_coverage.csv; phase4_performance_by_msi.csv.
- **核心信息**：MSI adds incremental predictive value beyond macro/pre-CGM context models.
- **期刊角色**：Translational and AI/prediction standards figure.
- **当前状态**：Partly implemented in Figure4_Prediction_Calibration_publication_v2.
- **下一步**：Add conformal interval and decision-curve panels; present prediction as research stratification, not clinical tool.

## Main Figure 8. External CGM datasets define transportability boundaries
- **核心问题**：Where does the framework generalize, and where does it not?
- **推荐面板**：A. response-scale comparison across datasets; B. response ratio vs CGMacros; C. T1D macro directionality; D. Stanford same-food heterogeneity; E. Jaeb healthy-adult time-above-threshold reference; F. transportability evidence map.
- **数据来源**：external_transportability_map.csv; external_domain_shift_metrics.csv; phase5 external validation tables.
- **核心信息**：External data support heterogeneity and macro-response directionality while clarifying non-replication boundaries.
- **期刊角色**：Preempts overgeneralization and frames boundary conditions honestly.
- **当前状态**：Partly implemented in Figure5_ExternalBoundary_publication_v2.
- **下一步**：Add Stanford same-food heterogeneity and Jaeb healthy reference if space allows.

## Main Figure 9. Mechanistic plausibility map linking DEHP oxidative metabolism, MSI, and PPGR vulnerability
- **核心问题**：Is there a biologically plausible pathway, even without wet-lab data?
- **推荐面板**：A. curated mechanism knowledge graph; B. pathway enrichment bar plot; C. literature evidence-map matrix; D. current evidence vs missing causal tests.
- **数据来源**：dehp_msi_mechanism_knowledge_graph_edges.csv; dehp_msi_pathway_enrichment.csv; module_A evidence map.
- **核心信息**：The integrated observational/CGM signal is biologically plausible but not mechanistically proven.
- **期刊角色**：Useful for discussion or graphical abstract; may be Extended Data depending on journal length.
- **当前状态**：Not yet built as a main figure; data available from Module E and literature module.
- **下一步**：Keep conservative; do not make causal arrows beyond evidence level.
