# Extended Data / Supplementary Figure Design


## ED Figure 1. Dataset flow, exclusions, and analytic sample construction
- **推荐面板**：participant/meal/event inclusion flow across NHANES, CGMacros, Stanford, T1D-UOM, Jaeb
- **数据来源**：Table1; analysis manifests; dataset inventories
- **审稿价值**：Supports transparency.
- **优先级**：High

## ED Figure 2. NHANES weighted Table 1 by DEHP oxidative quartile
- **推荐面板**：demographic/metabolic balance by exposure quartile
- **数据来源**：phase2_weighted_table1_by_oxidative_quartile.csv
- **审稿价值**：Addresses confounding and exposure distribution.
- **优先级**：High

## ED Figure 3. NHANES R survey vs Python reproducibility
- **推荐面板**：paired estimates and differences
- **数据来源**：phase2_R_survey_vs_python_comparison.csv
- **审稿价值**：Shows formal R survey confirmation.
- **优先级**：High

## ED Figure 4. NHANES subgroup/effect-modification heatmap
- **推荐面板**：sex, age, obesity, diabetes history, race/ethnicity, diet-source proxy
- **数据来源**：nhanes_effect_modification_results.csv
- **审稿价值**：Addresses heterogeneity.
- **优先级**：High

## ED Figure 5. NHANES sensitivity and negative-control-like analyses
- **推荐面板**：exclude diabetes, no creatinine adjustment, height outcome, negative-control-like exposure
- **数据来源**：nhanes_negative_control_and_sensitivity_results.csv
- **审稿价值**：Addresses residual confounding.
- **优先级**：High

## ED Figure 6. DEHP mixture/composition proxy analysis
- **推荐面板**：composition coefficients and clr/ilr terms
- **数据来源**：nhanes_dehp_mixture_composition_results.csv
- **审稿价值**：Addresses exposure mixture concern.
- **优先级**：High

## ED Figure 7. MSI component missingness and version correlations
- **推荐面板**：missingness heatmap, correlations across MSI variants
- **数据来源**：phase1_msi_component_missingness.csv; phase1_msi_version_correlations.csv
- **审稿价值**：Defends MSI construction.
- **优先级**：High

## ED Figure 8. CGMacros high-response threshold sensitivity
- **推荐面板**：top quartile, alternative definitions, iAUC/peak agreement
- **数据来源**：phase3_high_response_definition_sensitivity.csv
- **审稿价值**：Addresses endpoint arbitrariness.
- **优先级**：High

## ED Figure 9. Subject bootstrap and leave-one-subject influence
- **推荐面板**：bootstrap distributions and influence diagnostics
- **数据来源**：phase3_subject_bootstrap_key_terms.csv; phase3_leave_one_subject_influence.csv
- **审稿价值**：Addresses small n=40 concern.
- **优先级**：High

## ED Figure 10. Food-matrix annotation audit and feature dictionary
- **推荐面板**：NOVA/GI/GL/digestibility proxy feature distributions
- **数据来源**：cgmacros_food_matrix_annotation.csv; food_matrix_annotation_codebook.md
- **审稿价值**：Addresses proxy validity.
- **优先级**：Medium

## ED Figure 11. Counterfactual meal redesign scenario results
- **推荐面板**：predicted risk reductions by redesign scenario and subgroup
- **数据来源**：counterfactual_meal_redesign_effects.csv
- **审稿价值**：Shows translational nutrition utility.
- **优先级**：Medium

## ED Figure 12. Prediction leakage audit and predictor dictionary
- **推荐面板**：forbidden predictors, allowed predictors, model card summary
- **数据来源**：prediction_leakage_audit.csv; prediction_predictor_dictionary.csv
- **审稿价值**：TRIPOD/PROBAST defense.
- **优先级**：Medium

## ED Figure 13. Prediction conformal interval and net benefit details
- **推荐面板**：coverage/width by target/model, net benefit curves
- **数据来源**：phase4_conformal_interval_coverage.csv; prediction_model_performance_summary.csv
- **审稿价值**：Calibration/uncertainty evidence.
- **优先级**：Medium

## ED Figure 14. External dataset domain shift diagnostics
- **推荐面板**：event scale, subject scale, macro direction, healthy time-above-threshold reference
- **数据来源**：external_domain_shift_metrics.csv; external_transportability_map.csv
- **审稿价值**：Generalizability boundary.
- **优先级**：Medium

## ED Figure 15. Mechanism knowledge graph and pathway enrichment
- **推荐面板**：curated edges, evidence type, pathway enrichment
- **数据来源**：dehp_msi_mechanism_knowledge_graph_edges.csv; dehp_msi_pathway_enrichment.csv
- **审稿价值**：Mechanistic plausibility.
- **优先级**：Medium

## ED Figure 16. Full source-data lineage and reproducibility map
- **推荐面板**：which script generated every claim/table/figure
- **数据来源**：analysis_manifest.csv; phase0_to_phase4_file_manifest.csv
- **审稿价值**：Reproducibility asset.
- **优先级**：Medium
