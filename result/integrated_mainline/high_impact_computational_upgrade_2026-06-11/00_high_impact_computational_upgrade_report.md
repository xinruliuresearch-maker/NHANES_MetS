# High-impact computational upgrade report

Generated: 2026-06-11 02:45:33

## Central Guardrail

This package strengthens the project as a triangulated cross-dataset bridge-phenotype study. It does not claim direct DEHP-to-PPGR causality or formal mediation because no same-participant dataset currently contains both urinary DEHP metabolites and meal-level CGM PPGR.

## What Was Completed

1. NHANES survey-weighted exposure models plus WQS, qgcomp, BKMR-style nonlinear mixture screen, restricted cubic splines, and E-value sensitivity tables.
2. Dual MSI reconstruction: exposure-facing MSI and response-vulnerability index in NHANES and CGMacros.
3. CGMacros prediction and inference were rerun with subject-disjoint splits and subject-cluster/hierarchical inference.
4. Food matrix score was formalized with codebook, proxy FDC linkage, and dual-rule reliability checks.
5. Stanford CGM Database was converted to standardized challenge-level PPGR phenotypes for external boundary validation.
6. Mechanism layer was rebuilt around CTD chemical-gene/disease edges, KEGG pathway overlap, Reactome pathway mapping, and CompTox reproducible query links.
7. TRIPOD+AI, PROBAST+AI, STROBE, and PRISMA supplementary checklists were generated.

## Interpretation Notes

- Loaded NHANES analysis dataset: C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\phase2_nhanes_survey_ready\phase2_python_analysis_dataset.csv with shape (5267, 30).
- Loaded CGMacros MSI meal dataset: C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\stage1_msi\cgmacros_meal_level_with_msi_core.csv with shape (1498, 101).
- NHANES mixture models use Python approximations: WQS repeated holdout, qgcomp-style quantile sum, and BKMR-style Gaussian kernel ridge.
- FDC linkage is a proxy query-level match because the available CGMacros table has image paths and nutrient fields but no full parsed meal ingredient text.
- Stanford CGM boundary validation uses standardized challenge foods rather than free-living nutrient-coded meals; it tests transportability boundaries, not one-to-one replication.
- Mechanism evidence is database-backed plausibility evidence, not direct experimental proof.

## File Manifest

- `01_msi_component_reference_parameters.csv` - Reference means/SDs for dual MSI components.
- `01_nhanes_dual_msi_dataset.csv` - NHANES analysis dataset with exposure-facing MSI and response-vulnerability index.
- `01_cgmacros_dual_msi_meal_dataset.csv` - CGMacros meal dataset with dual MSI indices.
- `01_dual_msi_construct_correlations.csv` - Construct validity correlations among dual MSI and previous MSI versions.
- `02_nhanes_survey_weighted_standardized_models.csv` - nhanes survey weighted standardized models
- `02_nhanes_e_values.csv` - nhanes e values
- `02_nhanes_qgcomp_summary.csv` - nhanes qgcomp summary
- `02_nhanes_qgcomp_component_weights.csv` - nhanes qgcomp component weights
- `02_nhanes_wqs_repeated_holdout_results.csv` - nhanes wqs repeated holdout results
- `02_nhanes_wqs_summary.csv` - nhanes wqs summary
- `02_nhanes_wqs_component_weights.csv` - nhanes wqs component weights
- `02_nhanes_rcs_tests.csv` - nhanes rcs tests
- `02_nhanes_rcs_marginal_grid.csv` - nhanes rcs marginal grid
- `02_nhanes_bkmr_kernel_summary.csv` - nhanes bkmr kernel summary
- `02_nhanes_bkmr_kernel_importance.csv` - nhanes bkmr kernel importance
- `02_nhanes_bkmr_kernel_joint_response_curve.csv` - nhanes bkmr kernel joint response curve
- `03_food_matrix_codebook.csv` - Food-matrix variable definitions and rationale.
- `03_cgmacros_food_matrix_scored_meals.csv` - CGMacros meals with food-matrix scores and dual-rule categories.
- `03_food_matrix_fdc_proxy_matches.csv` - Proxy USDA FoodData Central query links derived from food-matrix categories.
- `03_food_matrix_reliability.csv` - Algorithmic dual-rule kappa/ICC reliability stress test.
- `04_cgmacros_cluster_hierarchical_coefficients.csv` - cgmacros cluster hierarchical coefficients
- `04_cgmacros_random_intercept_variance_components.csv` - cgmacros random intercept variance components
- `04_cgmacros_subject_disjoint_prediction_records.csv` - cgmacros subject disjoint prediction records
- `04_cgmacros_subject_disjoint_performance.csv` - cgmacros subject disjoint performance
- `05_stanford_challenge_level_ppgr.csv` - stanford challenge level ppgr
- `05_stanford_boundary_coefficients.csv` - stanford boundary coefficients
- `05_stanford_subject_disjoint_prediction_records.csv` - stanford subject disjoint prediction records
- `05_stanford_subject_disjoint_performance.csv` - stanford subject disjoint performance
- `05_stanford_distribution_summary.csv` - stanford distribution summary
- `06_mechanism_ctd_target_chemicals.csv` - mechanism ctd target chemicals
- `06_mechanism_ctd_chemical_gene_edges.csv` - mechanism ctd chemical gene edges
- `06_mechanism_ctd_chemical_disease_edges.csv` - mechanism ctd chemical disease edges
- `06_mechanism_ctd_gene_summary.csv` - mechanism ctd gene summary
- `06_mechanism_kegg_download_status.csv` - mechanism kegg download status
- `06_mechanism_kegg_pathway_overlap.csv` - mechanism kegg pathway overlap
- `06_mechanism_kegg_gene_pathway_edges.csv` - mechanism kegg gene pathway edges
- `06_mechanism_reactome_download_status.csv` - mechanism reactome download status
- `06_mechanism_reactome_relevant_edges.csv` - mechanism reactome relevant edges
- `06_mechanism_reactome_pathway_summary.csv` - mechanism reactome pathway summary
- `06_mechanism_comptox_query_manifest.csv` - mechanism comptox query manifest
- `07_TRIPOD_AI_checklist.csv` - TRIPOD AI checklist
- `07_PROBAST_AI_checklist.csv` - PROBAST AI checklist
- `07_STROBE_checklist.csv` - STROBE checklist
- `07_PRISMA_checklist.csv` - PRISMA checklist

## Next Submission Step

Before journal submission, rerun the NHANES mixture module in R if a full R environment becomes available, using `survey`, `qgcomp`, `gWQS`, and `bkmr` package implementations. The current Python outputs are transparent, reproducible approximations and are suitable for deciding whether the evidence chain is strong enough to advance.
