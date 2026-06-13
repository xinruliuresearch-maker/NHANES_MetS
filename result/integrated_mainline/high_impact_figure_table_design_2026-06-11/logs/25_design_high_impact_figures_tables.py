from __future__ import annotations

import csv
import json
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, Iterable, List, Sequence

import pandas as pd


DATE_TAG = "2026-06-11"
ROOT = Path(__file__).resolve().parents[1]
INTEGRATED = ROOT / "outputs" / "integrated_mainline"
OUT = INTEGRATED / f"high_impact_figure_table_design_{DATE_TAG}"
NHANES_MIRROR = (
    Path(r"C:\Users\liu12\OneDrive\Desktop\NHANES_MetS_Project")
    / "result"
    / "integrated_mainline"
    / f"high_impact_figure_table_design_{DATE_TAG}"
)

SUBDIRS = [
    "main_figures",
    "extended_figures",
    "tables",
    "source_mapping",
    "reviewer_strategy",
    "workbook_source",
    "logs",
]

PATHS = {
    "manuscript": INTEGRATED
    / "ajcn_no_wetlab_manuscript_package_2026-06-10"
    / "manuscript"
    / "AJCN_main_manuscript_no_wetlab_2026-06-10.md",
    "publication_figures_v2": INTEGRATED / "ajcn_publication_figures_v2_2026-06-10",
    "figure_v2_manifest": INTEGRATED
    / "ajcn_publication_figures_v2_2026-06-10"
    / "logs"
    / "publication_figure_manifest_v2.csv",
    "figure_v2_legends": INTEGRATED
    / "ajcn_publication_figures_v2_2026-06-10"
    / "legends"
    / "publication_figure_legends_v2.md",
    "table1_dataset": INTEGRATED
    / "no_digestion_phase0_to_phase4"
    / "phase2_manuscript_tables_and_figures"
    / "Table1_dataset_and_phenotype_summary.csv",
    "table2_nhanes": INTEGRATED
    / "no_digestion_phase0_to_phase4"
    / "phase2_manuscript_tables_and_figures"
    / "Table2_NHANES_R_survey_key_results.csv",
    "table3_cgmacros": INTEGRATED
    / "no_digestion_phase0_to_phase4"
    / "phase2_manuscript_tables_and_figures"
    / "Table3_CGMacros_MSI_PPGR_results.csv",
    "table4_food_curve": INTEGRATED
    / "no_digestion_phase0_to_phase4"
    / "phase2_manuscript_tables_and_figures"
    / "Table4_FoodMatrix_CurvePhenotype_results.csv",
    "table5_perf": INTEGRATED
    / "no_digestion_phase0_to_phase4"
    / "phase2_manuscript_tables_and_figures"
    / "Table5A_prediction_model_performance.csv",
    "table5_gain": INTEGRATED
    / "no_digestion_phase0_to_phase4"
    / "phase2_manuscript_tables_and_figures"
    / "Table5B_prediction_incremental_gain.csv",
    "external_boundary": INTEGRATED
    / "no_digestion_phase0_to_phase4"
    / "phase2_manuscript_tables_and_figures"
    / "Table5C_external_boundary_summary.csv",
    "nhanes_quartile": INTEGRATED
    / "phase2_nhanes_survey_ready"
    / "phase2_nhanes_dose_response_quartile_summary.csv",
    "nhanes_rcs": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_B_nhanes_advanced_epidemiology"
    / "phase2_python_rcs_prediction_grid.csv",
    "nhanes_effect_mod": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_B_nhanes_advanced_epidemiology"
    / "nhanes_effect_modification_results.csv",
    "nhanes_sensitivity": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_B_nhanes_advanced_epidemiology"
    / "nhanes_negative_control_and_sensitivity_results.csv",
    "nhanes_composition": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_B_nhanes_advanced_epidemiology"
    / "nhanes_dehp_mixture_composition_results.csv",
    "msi_correlations": INTEGRATED
    / "phase1_qc_msi_sensitivity"
    / "phase1_msi_version_correlations.csv",
    "msi_pca_weights": INTEGRATED
    / "phase1_qc_msi_sensitivity"
    / "phase1_msi_pca_component_weights.csv",
    "cg_meals": INTEGRATED / "stage1_msi" / "cgmacros_meal_level_with_msi_core.csv",
    "cg_subject": INTEGRATED
    / "phase3_cgmacros_robust_inference"
    / "phase3_subject_level_ppgr_msi_summary.csv",
    "cg_bootstrap": INTEGRATED
    / "phase3_cgmacros_robust_inference"
    / "phase3_subject_bootstrap_key_terms.csv",
    "cg_influence": INTEGRATED
    / "phase3_cgmacros_robust_inference"
    / "phase3_leave_one_subject_influence.csv",
    "food_annotation": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_C_cgmacros_food_matrix"
    / "cgmacros_food_matrix_annotation.csv",
    "food_models": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_C_cgmacros_food_matrix"
    / "cgmacros_food_matrix_ppgr_models.csv",
    "curve_features": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_D_cgm_curve_phenotypes"
    / "cgmacros_ppgr_curve_features.csv",
    "curve_models": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_D_cgm_curve_phenotypes"
    / "curve_shape_msi_food_matrix_models.csv",
    "prediction_records": INTEGRATED
    / "phase4_prediction_upgrade"
    / "phase4_nested_lso_prediction_records.csv",
    "prediction_perf": INTEGRATED
    / "phase4_prediction_upgrade"
    / "phase4_model_performance_overall.csv",
    "prediction_calibration": INTEGRATED
    / "phase4_prediction_upgrade"
    / "phase4_calibration_deciles.csv",
    "prediction_conformal": INTEGRATED
    / "phase4_prediction_upgrade"
    / "phase4_conformal_interval_coverage.csv",
    "prediction_by_msi": INTEGRATED
    / "phase4_prediction_upgrade"
    / "phase4_performance_by_msi.csv",
    "counterfactual": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_G_counterfactual_meal_redesign"
    / "counterfactual_meal_redesign_effects.csv",
    "external_transport": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_F_external_transportability"
    / "external_transportability_map.csv",
    "external_shift": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_F_external_transportability"
    / "external_domain_shift_metrics.csv",
    "mechanism_edges": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_E_mechanism_knowledge_graph"
    / "dehp_msi_mechanism_knowledge_graph_edges.csv",
    "mechanism_enrichment": INTEGRATED
    / "dry_lab_booster_modules"
    / "module_E_mechanism_knowledge_graph"
    / "dehp_msi_pathway_enrichment.csv",
}


def ensure_dirs() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for subdir in SUBDIRS:
        (OUT / subdir).mkdir(parents=True, exist_ok=True)


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


def write_csv(path: Path, rows: Sequence[Dict[str, object]], fields: Sequence[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def read_if_exists(path: Path) -> pd.DataFrame:
    if not path.exists():
        return pd.DataFrame()
    return pd.read_csv(path)


def load_context() -> Dict[str, object]:
    ctx: Dict[str, object] = {}
    for key, path in PATHS.items():
        if path.suffix.lower() == ".csv":
            ctx[key] = read_if_exists(path)
        elif path.is_dir():
            ctx[key] = str(path)
        elif path.exists():
            ctx[key] = path.read_text(encoding="utf-8", errors="replace")
        else:
            ctx[key] = ""
    return ctx


def fmt_ci(row: pd.Series, est: str = "estimate", low: str = "ci_low", high: str = "ci_high") -> str:
    try:
        return f"{float(row[est]):.3f} ({float(row[low]):.3f}, {float(row[high]):.3f})"
    except Exception:
        return ""


def main_figures() -> List[Dict[str, object]]:
    return [
        {
            "display_id": "Main Figure 1",
            "title": "Integrated evidence architecture and study design",
            "short_title": "Evidence architecture",
            "core_question": "How can a population DEHP oxidative-metabolism signal be connected conservatively to CGM meal vulnerability without overclaiming causality?",
            "recommended_panels": "A. Graphical evidence cascade; B. Dataset flow and sample sizes; C. MSI bridge phenotype construction; D. Claim hierarchy and no-overclaim guardrails; E. Analysis module timeline.",
            "current_status": "New design needed; previous schematic can be rebuilt as cleaner data-annotated graphical abstract.",
            "source_data": "Table1_dataset_and_phenotype_summary.csv; phase0 registry; claim guardrails; module manifest",
            "key_message": "This is a staged bridge-phenotype design: DEHP oxidative profile -> MSI in NHANES; MSI -> PPGR vulnerability in CGMacros.",
            "journal_role": "Front-door figure for Nature/Cell/Lancet-style readers; explains why the cross-dataset design is valid but cautious.",
            "priority": "Essential",
            "risk_if_missing": "Reviewers may misread the work as a direct DEHP-to-CGM causal claim or as disconnected datasets.",
            "needed_work": "Rebuild as high-end graphical abstract with minimal text, dataset sizes, and a clear 'not direct causality' design note.",
        },
        {
            "display_id": "Main Figure 2",
            "title": "DEHP oxidative-metabolism profile is associated with metabolic susceptibility in NHANES",
            "short_title": "NHANES exposure-response",
            "core_question": "Is the environmental exposure-profile layer statistically robust?",
            "recommended_panels": "A. Survey-weighted forest plot for primary and secondary exposures; B. Weighted quartile dose-response; C. spline curve; D. MSI-version robustness; E. sensitivity/negative-control panel; F. subgroup or effect-modification heatmap.",
            "current_status": "Partly implemented in Figure1_NHANES_exposure_response_publication_v2; should be expanded for top-tier submission.",
            "source_data": "Table2_NHANES_R_survey_key_results.csv; phase2_nhanes_dose_response_quartile_summary.csv; phase2_python_rcs_prediction_grid.csv; NHANES sensitivity/composition/effect-modification files.",
            "key_message": "The DEHP oxidative profile is consistently associated with MSI and insulin-resistance/glycemic markers.",
            "journal_role": "Primary epidemiologic evidence figure.",
            "priority": "Essential",
            "risk_if_missing": "The environmental component appears underpowered or merely decorative.",
            "needed_work": "Add robustness strip and subgroup heatmap; keep main forest/dose/spline as central panels.",
        },
        {
            "display_id": "Main Figure 3",
            "title": "Construction, robustness, and transfer of the metabolic susceptibility phenotype",
            "short_title": "MSI validation",
            "core_question": "Is MSI a stable bridge phenotype rather than an arbitrary score?",
            "recommended_panels": "A. MSI component z-score architecture; B. PCA/component weights; C. MSI-version correlation matrix; D. NHANES vs CGMacros MSI distributions; E. component profiles across MSI tertiles; F. missingness/availability waterfall.",
            "current_status": "Not yet built as a main figure; data available.",
            "source_data": "phase1_msi_version_correlations.csv; phase1_msi_pca_component_weights.csv; stage1_msi_summary_by_dataset.csv; cgmacros_subject_msi_core.csv; nhanes_2013_2018_msi_core.csv.",
            "key_message": "MSI behaves consistently across construction variants and can bridge NHANES and CGMacros.",
            "journal_role": "Defends the bridge variable, which is the manuscript's central methodological hinge.",
            "priority": "Essential",
            "risk_if_missing": "Reviewers may attack MSI as post hoc or unstable.",
            "needed_work": "Generate as a polished multi-panel figure before any top-tier submission.",
        },
        {
            "display_id": "Main Figure 4",
            "title": "MSI identifies free-living postprandial glycemic vulnerability in CGMacros",
            "short_title": "CGMacros PPGR vulnerability",
            "core_question": "Does the bridge phenotype manifest as dynamic meal-level vulnerability?",
            "recommended_panels": "A. Meal-level iAUC distribution by MSI tertile; B. peak distribution; C. subject-level MSI-response gradient; D. cluster-robust model coefficient forest; E. bootstrap estimates; F. leave-one-subject influence.",
            "current_status": "Partly implemented in Figure2_CGMacros_MSI_PPGR_publication_v2.",
            "source_data": "cgmacros_meal_level_with_msi_core.csv; phase3_subject_level_ppgr_msi_summary.csv; Table3_CGMacros_MSI_PPGR_results.csv; phase3_subject_bootstrap_key_terms.csv; phase3_leave_one_subject_influence.csv.",
            "key_message": "Higher MSI is a robust main-effect marker of PPGR vulnerability.",
            "journal_role": "Primary CGM physiology figure.",
            "priority": "Essential",
            "risk_if_missing": "The CGM evidence looks like summary-only association rather than true meal-level biology.",
            "needed_work": "Add bootstrap and leave-one-subject influence as E-F or Extended Data if main figure becomes dense.",
        },
        {
            "display_id": "Main Figure 5",
            "title": "Person-by-food-matrix susceptibility refines carbohydrate-only interpretation",
            "short_title": "Food matrix interaction",
            "core_question": "Why is the biology not just 'more carbs, more glucose'?",
            "recommended_panels": "A. Digestibility-risk vs iAUC meal scatter; B. iAUC and peak model forest; C. MSI x digestibility predicted response surface; D. high-risk food-matrix feature enrichment; E. counterfactual meal redesign effect; F. candidate high-risk meal matrix examples if image permissions allow.",
            "current_status": "Partly implemented in Figure3_FoodMatrix_CurvePhenotypes_publication_v2; response surface and counterfactual panel not yet built.",
            "source_data": "cgmacros_food_matrix_annotation.csv; cgmacros_food_matrix_ppgr_models.csv; counterfactual_meal_redesign_effects.csv; Supplement_counterfactual_meal_redesign_summary.csv.",
            "key_message": "High-MSI individuals appear especially vulnerable to high-digestibility-risk food matrices.",
            "journal_role": "Mechanistic/nutrition novelty figure.",
            "priority": "Essential",
            "risk_if_missing": "The manuscript may look like another CGM prediction paper rather than a nutrition-mechanism paper.",
            "needed_work": "Add predicted interaction surface and counterfactual redesign panel; keep proxy caveat in legend.",
        },
        {
            "display_id": "Main Figure 6",
            "title": "CGM curve phenotypes reveal prolonged and delayed response vulnerability",
            "short_title": "Dynamic CGM phenotypes",
            "core_question": "Does MSI/food-matrix susceptibility affect response shape, not only scalar iAUC/peak?",
            "recommended_panels": "A. Cluster map by iAUC/peak/time-to-peak/recovery; B. cluster composition by MSI tertile; C. delayed-peak/prolonged-elevation model forest; D. prototype response curves or reconstructed curves; E. MSI-digestibility to curve-phenotype alluvial plot.",
            "current_status": "Partly implemented inside Figure3 v2; should become independent figure if targeting a top-tier journal.",
            "source_data": "cgmacros_ppgr_curve_features.csv; curve_shape_msi_food_matrix_models.csv; Figure4_data_curve_clusters.csv.",
            "key_message": "Susceptibility is expressed as dynamic CGM response phenotypes, especially large/prolonged responses.",
            "journal_role": "Adds physiologic depth and makes CGM dynamics visible.",
            "priority": "High",
            "risk_if_missing": "Dynamic CGM data are underused; reviewers may see only static iAUC/peak outcomes.",
            "needed_work": "Generate prototype curve panel if raw time-series alignment is feasible; otherwise use feature-derived clusters and model forest.",
        },
        {
            "display_id": "Main Figure 7",
            "title": "MSI-enhanced models improve personalized high-response stratification",
            "short_title": "Prediction and calibration",
            "core_question": "Does the biology improve practical meal-risk prediction?",
            "recommended_panels": "A. observed vs predicted iAUC; B. observed vs predicted peak; C. nested model AUC/MAE/R2; D. calibration deciles; E. conformal interval coverage/width; F. decision-curve net benefit; G. performance by MSI tertile.",
            "current_status": "Partly implemented in Figure4_Prediction_Calibration_publication_v2.",
            "source_data": "phase4_nested_lso_prediction_records.csv; phase4_model_performance_overall.csv; phase4_calibration_deciles.csv; phase4_conformal_interval_coverage.csv; phase4_performance_by_msi.csv.",
            "key_message": "MSI adds incremental predictive value beyond macro/pre-CGM context models.",
            "journal_role": "Translational and AI/prediction standards figure.",
            "priority": "Essential",
            "risk_if_missing": "Prediction claims may look unsupported or not TRIPOD/PROBAST-aligned.",
            "needed_work": "Add conformal interval and decision-curve panels; present prediction as research stratification, not clinical tool.",
        },
        {
            "display_id": "Main Figure 8",
            "title": "External CGM datasets define transportability boundaries",
            "short_title": "External boundaries",
            "core_question": "Where does the framework generalize, and where does it not?",
            "recommended_panels": "A. response-scale comparison across datasets; B. response ratio vs CGMacros; C. T1D macro directionality; D. Stanford same-food heterogeneity; E. Jaeb healthy-adult time-above-threshold reference; F. transportability evidence map.",
            "current_status": "Partly implemented in Figure5_ExternalBoundary_publication_v2.",
            "source_data": "external_transportability_map.csv; external_domain_shift_metrics.csv; phase5 external validation tables.",
            "key_message": "External data support heterogeneity and macro-response directionality while clarifying non-replication boundaries.",
            "journal_role": "Preempts overgeneralization and frames boundary conditions honestly.",
            "priority": "High",
            "risk_if_missing": "Reviewers may demand external validation or criticize generalizability.",
            "needed_work": "Add Stanford same-food heterogeneity and Jaeb healthy reference if space allows.",
        },
        {
            "display_id": "Main Figure 9",
            "title": "Mechanistic plausibility map linking DEHP oxidative metabolism, MSI, and PPGR vulnerability",
            "short_title": "Mechanism map",
            "core_question": "Is there a biologically plausible pathway, even without wet-lab data?",
            "recommended_panels": "A. curated mechanism knowledge graph; B. pathway enrichment bar plot; C. literature evidence-map matrix; D. current evidence vs missing causal tests.",
            "current_status": "Not yet built as a main figure; data available from Module E and literature module.",
            "source_data": "dehp_msi_mechanism_knowledge_graph_edges.csv; dehp_msi_pathway_enrichment.csv; module_A evidence map.",
            "key_message": "The integrated observational/CGM signal is biologically plausible but not mechanistically proven.",
            "journal_role": "Useful for discussion or graphical abstract; may be Extended Data depending on journal length.",
            "priority": "Optional-main / Strong Extended",
            "risk_if_missing": "Mechanistic novelty may feel thin for top-tier translational journals.",
            "needed_work": "Keep conservative; do not make causal arrows beyond evidence level.",
        },
    ]


def extended_figures() -> List[Dict[str, object]]:
    items = [
        ("ED Figure 1", "Dataset flow, exclusions, and analytic sample construction", "participant/meal/event inclusion flow across NHANES, CGMacros, Stanford, T1D-UOM, Jaeb", "Table1; analysis manifests; dataset inventories", "Supports transparency."),
        ("ED Figure 2", "NHANES weighted Table 1 by DEHP oxidative quartile", "demographic/metabolic balance by exposure quartile", "phase2_weighted_table1_by_oxidative_quartile.csv", "Addresses confounding and exposure distribution."),
        ("ED Figure 3", "NHANES R survey vs Python reproducibility", "paired estimates and differences", "phase2_R_survey_vs_python_comparison.csv", "Shows formal R survey confirmation."),
        ("ED Figure 4", "NHANES subgroup/effect-modification heatmap", "sex, age, obesity, diabetes history, race/ethnicity, diet-source proxy", "nhanes_effect_modification_results.csv", "Addresses heterogeneity."),
        ("ED Figure 5", "NHANES sensitivity and negative-control-like analyses", "exclude diabetes, no creatinine adjustment, height outcome, negative-control-like exposure", "nhanes_negative_control_and_sensitivity_results.csv", "Addresses residual confounding."),
        ("ED Figure 6", "DEHP mixture/composition proxy analysis", "composition coefficients and clr/ilr terms", "nhanes_dehp_mixture_composition_results.csv", "Addresses exposure mixture concern."),
        ("ED Figure 7", "MSI component missingness and version correlations", "missingness heatmap, correlations across MSI variants", "phase1_msi_component_missingness.csv; phase1_msi_version_correlations.csv", "Defends MSI construction."),
        ("ED Figure 8", "CGMacros high-response threshold sensitivity", "top quartile, alternative definitions, iAUC/peak agreement", "phase3_high_response_definition_sensitivity.csv", "Addresses endpoint arbitrariness."),
        ("ED Figure 9", "Subject bootstrap and leave-one-subject influence", "bootstrap distributions and influence diagnostics", "phase3_subject_bootstrap_key_terms.csv; phase3_leave_one_subject_influence.csv", "Addresses small n=40 concern."),
        ("ED Figure 10", "Food-matrix annotation audit and feature dictionary", "NOVA/GI/GL/digestibility proxy feature distributions", "cgmacros_food_matrix_annotation.csv; food_matrix_annotation_codebook.md", "Addresses proxy validity."),
        ("ED Figure 11", "Counterfactual meal redesign scenario results", "predicted risk reductions by redesign scenario and subgroup", "counterfactual_meal_redesign_effects.csv", "Shows translational nutrition utility."),
        ("ED Figure 12", "Prediction leakage audit and predictor dictionary", "forbidden predictors, allowed predictors, model card summary", "prediction_leakage_audit.csv; prediction_predictor_dictionary.csv", "TRIPOD/PROBAST defense."),
        ("ED Figure 13", "Prediction conformal interval and net benefit details", "coverage/width by target/model, net benefit curves", "phase4_conformal_interval_coverage.csv; prediction_model_performance_summary.csv", "Calibration/uncertainty evidence."),
        ("ED Figure 14", "External dataset domain shift diagnostics", "event scale, subject scale, macro direction, healthy time-above-threshold reference", "external_domain_shift_metrics.csv; external_transportability_map.csv", "Generalizability boundary."),
        ("ED Figure 15", "Mechanism knowledge graph and pathway enrichment", "curated edges, evidence type, pathway enrichment", "dehp_msi_mechanism_knowledge_graph_edges.csv; dehp_msi_pathway_enrichment.csv", "Mechanistic plausibility."),
        ("ED Figure 16", "Full source-data lineage and reproducibility map", "which script generated every claim/table/figure", "analysis_manifest.csv; phase0_to_phase4_file_manifest.csv", "Reproducibility asset."),
    ]
    return [
        {
            "display_id": i,
            "title": title,
            "recommended_panels": panels,
            "source_data": source,
            "reviewer_value": value,
            "priority": "High" if idx < 10 else "Medium",
            "build_status": "Design specified; build from listed source data.",
        }
        for idx, (i, title, panels, source, value) in enumerate(items, 1)
    ]


def main_tables() -> List[Dict[str, object]]:
    return [
        {
            "table_id": "Main Table 1",
            "title": "Datasets, phenotypes, and analytic roles",
            "columns": "Dataset; role; participants; meals/events/readings; MSI available; key exposure/outcome; main limitation",
            "source_data": "Table1_dataset_and_phenotype_summary.csv; external_transportability_map.csv",
            "journal_role": "One-page transparent overview of all evidence layers.",
            "priority": "Essential",
        },
        {
            "table_id": "Main Table 2",
            "title": "Primary NHANES exposure-susceptibility estimates",
            "columns": "Exposure; outcome; beta; 95% CI; P; q; model/covariates; analytic n",
            "source_data": "Table2_NHANES_R_survey_key_results.csv",
            "journal_role": "Main epidemiology results table, complements Figure 2.",
            "priority": "Essential",
        },
        {
            "table_id": "Main Table 3",
            "title": "Primary CGMacros MSI-PPGR and food-matrix models",
            "columns": "Outcome; model block; term; estimate; 95% CI; q; meals; participants; interpretation",
            "source_data": "Table3_CGMacros_MSI_PPGR_results.csv; Table4_FoodMatrix_CurvePhenotype_results.csv",
            "journal_role": "Compact table for main CGM and food-matrix estimates.",
            "priority": "Essential",
        },
        {
            "table_id": "Main Table 4",
            "title": "Prediction performance and incremental value of MSI",
            "columns": "Target; model; MAE; R2; AUC; AUPRC; calibration slope; net benefit; delta vs M2",
            "source_data": "Table5A_prediction_model_performance.csv; Table5B_prediction_incremental_gain.csv",
            "journal_role": "Prediction/translational table aligned with TRIPOD+AI expectations.",
            "priority": "Essential",
        },
        {
            "table_id": "Main Table 5",
            "title": "Claim-level evidence strength and guardrails",
            "columns": "Claim; supporting figure/table; dataset; inference type; causal status; limitation; required wording",
            "source_data": "phase3_main_claims_table_no_digestion.csv; claim_guardrails_for_reviewers.md",
            "journal_role": "May be main or supplement; extremely useful for top-tier cautious framing.",
            "priority": "High",
        },
    ]


def supplementary_tables() -> List[Dict[str, object]]:
    titles = [
        ("Supplementary Table 1", "Full data dictionary and variable definitions", "data_dictionary.csv/xlsx"),
        ("Supplementary Table 2", "Analysis registry and prespecified claim boundaries", "phase0_no_digestion_analysis_registry.csv; phase0_overclaim_guardrails.csv"),
        ("Supplementary Table 3", "NHANES weighted descriptive table by oxidative quartile", "phase2_weighted_table1_by_oxidative_quartile.csv"),
        ("Supplementary Table 4", "Full NHANES R survey model results", "phase2_R_survey_main_results.csv"),
        ("Supplementary Table 5", "R survey vs Python comparison", "phase2_R_survey_vs_python_comparison.csv"),
        ("Supplementary Table 6", "NHANES dose-response quartile summary", "phase2_nhanes_dose_response_quartile_summary.csv"),
        ("Supplementary Table 7", "NHANES spline coefficients and prediction grid", "phase2_python_rcs_spline_coefficients.csv; phase2_python_rcs_prediction_grid.csv"),
        ("Supplementary Table 8", "NHANES effect modification", "nhanes_effect_modification_results.csv"),
        ("Supplementary Table 9", "NHANES sensitivity and negative-control-like analyses", "nhanes_negative_control_and_sensitivity_results.csv"),
        ("Supplementary Table 10", "DEHP mixture/composition proxy results", "nhanes_dehp_mixture_composition_results.csv"),
        ("Supplementary Table 11", "MSI component scaler, missingness, PCA weights, correlations", "stage1_msi_component_scaler.csv; phase1_msi_pca_component_weights.csv; phase1_msi_version_correlations.csv"),
        ("Supplementary Table 12", "CGMacros subject-level PPGR by MSI", "phase3_subject_level_ppgr_msi_summary.csv"),
        ("Supplementary Table 13", "CGMacros full cluster-robust meal-level models", "stage3_cgmacros_msi_ppgr_model_results.csv; Table3_CGMacros_MSI_PPGR_results.csv"),
        ("Supplementary Table 14", "CGMacros bootstrap and influence diagnostics", "phase3_subject_bootstrap_key_terms.csv; phase3_leave_one_subject_influence.csv"),
        ("Supplementary Table 15", "High-response definition sensitivity", "phase3_high_response_definition_sensitivity.csv"),
        ("Supplementary Table 16", "Food-matrix annotation codebook and features", "cgmacros_food_matrix_annotation.csv; food_matrix_annotation_codebook.md"),
        ("Supplementary Table 17", "Food-matrix PPGR models", "cgmacros_food_matrix_ppgr_models.csv"),
        ("Supplementary Table 18", "CGM curve phenotype features and models", "cgmacros_ppgr_curve_features.csv; curve_shape_msi_food_matrix_models.csv"),
        ("Supplementary Table 19", "Prediction model performance, calibration, conformal intervals", "phase4_model_performance_overall.csv; phase4_calibration_deciles.csv; phase4_conformal_interval_coverage.csv"),
        ("Supplementary Table 20", "Prediction leakage audit and predictor dictionary", "prediction_leakage_audit.csv; prediction_predictor_dictionary.csv"),
        ("Supplementary Table 21", "Prediction performance by MSI subgroup", "phase4_performance_by_msi.csv"),
        ("Supplementary Table 22", "Counterfactual meal redesign results", "counterfactual_meal_redesign_effects.csv; counterfactual_subject_level_heterogeneity.csv"),
        ("Supplementary Table 23", "External CGM transportability map", "external_transportability_map.csv"),
        ("Supplementary Table 24", "External domain shift and macro directionality", "external_domain_shift_metrics.csv; external_macro_direction_consistency.csv"),
        ("Supplementary Table 25", "Mechanism knowledge graph edges and pathway enrichment", "dehp_msi_mechanism_knowledge_graph_edges.csv; dehp_msi_pathway_enrichment.csv"),
        ("Supplementary Table 26", "Literature evidence map and evidence gaps", "dry_lab_evidence_map_seed.csv; dry_lab_evidence_gap_table.csv"),
        ("Supplementary Table 27", "Reproducibility manifest and run order", "analysis_manifest.csv; run_order.md"),
        ("Supplementary Table 28", "Source-data mapping for all display items", "display_source_data_map.csv"),
        ("Supplementary Table 29", "Reviewer concern-response matrix", "reviewer_concern_response_matrix.csv"),
        ("Supplementary Table 30", "Figure and table production priority tracker", "figure_build_priority_and_gap_audit.csv"),
    ]
    return [
        {
            "table_id": table_id,
            "title": title,
            "source_data": source,
            "role": "Supplementary evidence / reproducibility / reviewer defense",
            "priority": "High" if idx <= 20 else "Medium",
        }
        for idx, (table_id, title, source) in enumerate(titles, 1)
    ]


def claim_crosswalk() -> List[Dict[str, object]]:
    return [
        {
            "claim_id": "C1",
            "claim": "DEHP oxidative-metabolism profile is associated with metabolic susceptibility in NHANES.",
            "primary_display": "Main Figure 2; Main Table 2",
            "supporting_displays": "ED Figures 2-6; Supplementary Tables 3-10",
            "evidence_type": "Survey-weighted observational association",
            "allowed_wording": "associated with; consistent across sensitivity analyses",
            "avoid_wording": "causes; mediates; predicts CGM response directly",
        },
        {
            "claim_id": "C2",
            "claim": "MSI is a robust bridge phenotype across construction variants.",
            "primary_display": "Main Figure 3",
            "supporting_displays": "ED Figure 7; Supplementary Table 11",
            "evidence_type": "Construct validation / sensitivity analysis",
            "allowed_wording": "stable, concordant, transferable phenotype",
            "avoid_wording": "validated clinical biomarker",
        },
        {
            "claim_id": "C3",
            "claim": "MSI identifies higher free-living meal-level PPGR vulnerability in CGMacros.",
            "primary_display": "Main Figure 4; Main Table 3",
            "supporting_displays": "ED Figures 8-9; Supplementary Tables 12-15",
            "evidence_type": "Subject-clustered meal-level association",
            "allowed_wording": "higher vulnerability; robust main effect",
            "avoid_wording": "DEHP directly predicts CGMacros PPGR",
        },
        {
            "claim_id": "C4",
            "claim": "High-digestibility-risk food matrices amplify MSI-related PPGR vulnerability.",
            "primary_display": "Main Figure 5; Main Table 3",
            "supporting_displays": "ED Figures 10-11; Supplementary Tables 16-18, 22",
            "evidence_type": "Exploratory dry-lab proxy interaction",
            "allowed_wording": "food-matrix proxy; hypothesis-generating interaction",
            "avoid_wording": "measured digestion kinetics",
        },
        {
            "claim_id": "C5",
            "claim": "CGM curve phenotypes reveal delayed/prolonged vulnerability beyond iAUC and peak.",
            "primary_display": "Main Figure 6",
            "supporting_displays": "Supplementary Table 18",
            "evidence_type": "Feature engineering / unsupervised or rule-based dynamic phenotype",
            "allowed_wording": "dynamic phenotype; response-shape pattern",
            "avoid_wording": "pathophysiologic subtype proven",
        },
        {
            "claim_id": "C6",
            "claim": "MSI improves high-response meal-risk stratification within CGMacros.",
            "primary_display": "Main Figure 7; Main Table 4",
            "supporting_displays": "ED Figures 12-13; Supplementary Tables 19-21",
            "evidence_type": "Leave-subject-out prediction and calibration",
            "allowed_wording": "research-use stratification; incremental improvement",
            "avoid_wording": "clinical deployment; diagnostic model",
        },
        {
            "claim_id": "C7",
            "claim": "External CGM datasets define boundary conditions rather than direct replication.",
            "primary_display": "Main Figure 8",
            "supporting_displays": "ED Figure 14; Supplementary Tables 23-24",
            "evidence_type": "External boundary and domain shift evidence",
            "allowed_wording": "boundary evidence; supports heterogeneity and directionality",
            "avoid_wording": "external validation of DEHP-MSI-PPGR pathway",
        },
        {
            "claim_id": "C8",
            "claim": "Mechanistic literature supports biological plausibility but not causal proof.",
            "primary_display": "Main Figure 9 or ED Figure 15",
            "supporting_displays": "Supplementary Tables 25-26",
            "evidence_type": "Curated knowledge graph and literature map",
            "allowed_wording": "biologically plausible; convergent prior evidence",
            "avoid_wording": "mechanistically proven",
        },
    ]


def reviewer_matrix() -> List[Dict[str, object]]:
    concerns = [
        ("Datasets are disconnected", "Main Figure 1; claim crosswalk", "Bridge-phenotype design shown explicitly; no direct DEHP-to-CGM claim."),
        ("MSI is arbitrary", "Main Figure 3; ED Figure 7", "Show component construction, PCA weights, version correlations, no-BMI sensitivity."),
        ("NHANES residual confounding", "Main Figure 2; ED Figures 2-6", "Include weighted covariate table, sensitivity, negative-control-like analyses, composition models."),
        ("CGMacros n=40 is small", "Main Figure 4; ED Figure 9", "Show meal-level n=1498, subject-level gradient, bootstrap and leave-one-subject influence."),
        ("Food-matrix score is proxy", "Main Figure 5; ED Figure 10", "Explicitly label as dry-lab proxy; provide codebook and feature distributions."),
        ("Prediction model may leak outcomes", "Main Figure 7; ED Figure 12", "Show leakage audit and predictor dictionary."),
        ("Prediction not externally validated", "Main Figure 8; ED Figure 14", "Frame external data as boundary evidence; avoid deployment claims."),
        ("Mechanism is underdeveloped", "Main Figure 9; ED Figure 15", "Mechanism graph and pathway enrichment, conservative language."),
        ("Too many claims", "Main Table 5; claim guardrails", "Separate primary, secondary, exploratory and boundary claims."),
        ("Journal fit unclear", "README and display hierarchy", "Put nutrition mechanism and CGM precision nutrition at center, exposure as upstream susceptibility context."),
    ]
    return [
        {
            "reviewer_concern": c,
            "display_response": d,
            "textual_response_strategy": s,
            "priority": "High",
        }
        for c, d, s in concerns
    ]


def source_map(
    figs: Sequence[Dict[str, object]],
    eds: Sequence[Dict[str, object]],
    tabs: Sequence[Dict[str, object]],
    supp_tabs: Sequence[Dict[str, object]],
) -> List[Dict[str, object]]:
    rows: List[Dict[str, object]] = []
    for item in list(figs) + list(eds):
        rows.append(
            {
                "display_id": item.get("display_id"),
                "display_type": "Figure",
                "title": item.get("title"),
                "source_data": item.get("source_data"),
                "current_status": item.get("current_status", item.get("build_status", "")),
                "priority": item.get("priority"),
            }
        )
    for item in list(tabs) + list(supp_tabs):
        rows.append(
            {
                "display_id": item.get("table_id"),
                "display_type": "Table",
                "title": item.get("title"),
                "source_data": item.get("source_data"),
                "current_status": "Design specified; build as manuscript table/supplement.",
                "priority": item.get("priority"),
            }
        )
    return rows


def priority_audit(figs: Sequence[Dict[str, object]], eds: Sequence[Dict[str, object]]) -> List[Dict[str, object]]:
    rows = []
    for item in figs:
        status = item["current_status"]
        if "Partly implemented" in str(status):
            action = "Upgrade current v2 figure with additional panels."
        elif "Not yet built" in str(status) or "New design" in str(status):
            action = "Build new multi-panel figure from listed source data."
        else:
            action = "Review and polish."
        rows.append(
            {
                "display_id": item["display_id"],
                "priority": item["priority"],
                "current_status": status,
                "next_action": action,
                "blocking_issue": "None for design; implementation requires final journal target and figure count limits.",
            }
        )
    for item in eds:
        rows.append(
            {
                "display_id": item["display_id"],
                "priority": item["priority"],
                "current_status": item["build_status"],
                "next_action": "Build after main figure set is frozen.",
                "blocking_issue": "Only needed if space/reviewer pressure requires it.",
            }
        )
    return rows


def write_markdown_reports(
    figs: Sequence[Dict[str, object]],
    eds: Sequence[Dict[str, object]],
    tabs: Sequence[Dict[str, object]],
    supp_tabs: Sequence[Dict[str, object]],
    claims: Sequence[Dict[str, object]],
    reviewers: Sequence[Dict[str, object]],
) -> None:
    fig_lines = ["# 高水平期刊主文图设计", "", "建议以 8 张主图为核心，Figure 9 作为可选主图或 Extended Data。"]
    for fig in figs:
        fig_lines.extend(
            [
                "",
                f"## {fig['display_id']}. {fig['title']}",
                f"- **核心问题**：{fig['core_question']}",
                f"- **推荐面板**：{fig['recommended_panels']}",
                f"- **数据来源**：{fig['source_data']}",
                f"- **核心信息**：{fig['key_message']}",
                f"- **期刊角色**：{fig['journal_role']}",
                f"- **当前状态**：{fig['current_status']}",
                f"- **下一步**：{fig['needed_work']}",
            ]
        )
    write_text(OUT / "main_figures" / "main_figure_design_high_impact.md", "\n".join(fig_lines))

    ed_lines = ["# Extended Data / Supplementary Figure Design", ""]
    for item in eds:
        ed_lines.extend(
            [
                "",
                f"## {item['display_id']}. {item['title']}",
                f"- **推荐面板**：{item['recommended_panels']}",
                f"- **数据来源**：{item['source_data']}",
                f"- **审稿价值**：{item['reviewer_value']}",
                f"- **优先级**：{item['priority']}",
            ]
        )
    write_text(OUT / "extended_figures" / "extended_figure_design_high_impact.md", "\n".join(ed_lines))

    table_lines = ["# 主表与补充表设计", "", "顶刊主文建议保留 3-5 张主表；其余完整结果进入 Supplementary Tables。", ""]
    table_lines.append("## Main Tables")
    for tab in tabs:
        table_lines.extend(
            [
                "",
                f"### {tab['table_id']}. {tab['title']}",
                f"- **列设计**：{tab['columns']}",
                f"- **数据来源**：{tab['source_data']}",
                f"- **期刊角色**：{tab['journal_role']}",
            ]
        )
    table_lines.append("\n## Supplementary Tables")
    for tab in supp_tabs:
        table_lines.append(f"- **{tab['table_id']}**：{tab['title']}；来源：{tab['source_data']}")
    write_text(OUT / "tables" / "table_design_high_impact.md", "\n".join(table_lines))

    master = f"""
# 冲击高水平期刊的图表体系总设计

生成日期：{DATE_TAG}

## 1. 总体策略

当前文章的主线应收束为：

**DEHP oxidative-metabolism profile -> metabolic susceptibility phenotype (MSI) -> CGM-measured postprandial glycemic vulnerability -> personalized meal-risk stratification**

高水平期刊的图表不能只是结果堆叠，而要完成四件事：

1. 建立跨数据集证据链的可信结构。
2. 证明 MSI 不是任意构造，而是稳健桥接表型。
3. 展示真实 meal-level CGM 生理异质性，而不是只给模型系数。
4. 主动处理审稿人会攻击的点：混杂、样本量、proxy 食物基质、外部可迁移性、预测泄漏、过度因果。

## 2. 推荐主文图表数量

- **主图**：8 张必备图 + 1 张机制/图形摘要候选图。
- **Extended Data / Supplementary Figures**：16 张。
- **主表**：4 张必备表 + 1 张 claim guardrail 表。
- **Supplementary Tables**：30 张，主要用于完整结果、敏感性分析、数据字典和 reproducibility。

## 3. 当前已有图如何使用

`ajcn_publication_figures_v2_2026-06-10` 中的 5 张图可以作为基础，但不是最终冲顶版本：

- Figure 1 v2 -> 升级为主文 Figure 2。
- Figure 2 v2 -> 升级为主文 Figure 4。
- Figure 3 v2 -> 拆分/升级为主文 Figure 5 和 Figure 6。
- Figure 4 v2 -> 升级为主文 Figure 7。
- Figure 5 v2 -> 升级为主文 Figure 8。

缺失的关键图是：主文 Figure 1 研究架构图、Figure 3 MSI 构建/验证图、Figure 9 机制 plausibility 图。

## 4. 最关键的取舍

如果目标是 AJCN/Clinical Nutrition 等高水平专科期刊，可保留 5-6 张主图。  
如果目标是 Nature Medicine / Cell Metabolism / Nature Food / Lancet 系列，需要 7-9 张主图，并将 Extended Data 体系补齐。

## 5. 设计文件

- `main_figures/main_figure_design_high_impact.md`
- `extended_figures/extended_figure_design_high_impact.md`
- `tables/table_design_high_impact.md`
- `source_mapping/display_source_data_map.csv`
- `reviewer_strategy/reviewer_concern_response_matrix.csv`
- `workbook_source/*.csv`
"""
    write_text(OUT / "README_high_impact_figure_table_design.md", master)

    journal = """
# Journal-Style Alignment Notes

This design follows common expectations from high-impact biomedical/nutrition journals:

- Multi-panel figures should be self-contained but not overfilled with legend text.
- Figure legends should carry interpretation, while panels should carry data.
- Main figures should each answer one scientific question.
- Source data should be available for every panel.
- Prediction figures should show discrimination, calibration, uncertainty, and leakage safeguards.
- Observational exposure figures should show robustness, sensitivity, and noncausal language.

Current external references used while designing this package:

- Nature Portfolio figure preparation guidance.
- Cell Press figure/final artwork guidance.
- The Lancet author guidance for figures/tables.
- AJCN/ASN guide for authors, already used in the manuscript package.

Before final submission, check the specific journal's current file type, resolution, figure count, and source-data requirements.
"""
    write_text(OUT / "journal_style_alignment_notes.md", journal)


def export_workbook_source(sheets: Dict[str, Sequence[Dict[str, object]]]) -> Path:
    workbook_json = OUT / "workbook_source" / "high_impact_display_workbook_data.json"
    serializable = {name: list(rows) for name, rows in sheets.items()}
    write_text(workbook_json, json.dumps(serializable, ensure_ascii=False, indent=2))
    return workbook_json


def mirror() -> None:
    if NHANES_MIRROR.exists():
        shutil.rmtree(NHANES_MIRROR)
    shutil.copytree(OUT, NHANES_MIRROR)


def main() -> None:
    ensure_dirs()
    ctx = load_context()
    figs = main_figures()
    eds = extended_figures()
    tabs = main_tables()
    supp_tabs = supplementary_tables()
    claims = claim_crosswalk()
    reviewers = reviewer_matrix()
    sources = source_map(figs, eds, tabs, supp_tabs)
    audit = priority_audit(figs, eds)

    write_csv(OUT / "main_figures" / "main_figure_catalog_high_impact.csv", figs, list(figs[0].keys()))
    write_csv(OUT / "extended_figures" / "extended_figure_catalog_high_impact.csv", eds, list(eds[0].keys()))
    write_csv(OUT / "tables" / "main_table_catalog_high_impact.csv", tabs, list(tabs[0].keys()))
    write_csv(OUT / "tables" / "supplementary_table_catalog_high_impact.csv", supp_tabs, list(supp_tabs[0].keys()))
    write_csv(OUT / "source_mapping" / "display_source_data_map.csv", sources, list(sources[0].keys()))
    write_csv(OUT / "source_mapping" / "claim_to_display_crosswalk.csv", claims, list(claims[0].keys()))
    write_csv(OUT / "reviewer_strategy" / "reviewer_concern_response_matrix.csv", reviewers, list(reviewers[0].keys()))
    write_csv(OUT / "logs" / "figure_build_priority_and_gap_audit.csv", audit, list(audit[0].keys()))

    sheets = {
        "Main_Figures": figs,
        "Extended_Figures": eds,
        "Main_Tables": tabs,
        "Supp_Tables": supp_tabs,
        "Claims_Crosswalk": claims,
        "Reviewer_Strategy": reviewers,
        "Source_Map": sources,
        "Build_Audit": audit,
    }
    for name, rows in sheets.items():
        if rows:
            write_csv(OUT / "workbook_source" / f"{name}.csv", rows, list(rows[0].keys()))
    export_workbook_source(sheets)

    write_markdown_reports(figs, eds, tabs, supp_tabs, claims, reviewers)
    manifest = []
    for path in sorted(OUT.rglob("*")):
        if path.is_file():
            manifest.append(
                {
                    "relative_path": str(path.relative_to(OUT)),
                    "bytes": path.stat().st_size,
                    "modified": datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds"),
                }
            )
    write_csv(OUT / "logs" / "design_package_manifest.csv", manifest, ["relative_path", "bytes", "modified"])
    shutil.copy2(Path(__file__), OUT / "logs" / Path(__file__).name)
    mirror()
    print(f"Generated high-impact figure/table design package: {OUT}")
    print(f"Mirrored to: {NHANES_MIRROR}")


if __name__ == "__main__":
    main()
