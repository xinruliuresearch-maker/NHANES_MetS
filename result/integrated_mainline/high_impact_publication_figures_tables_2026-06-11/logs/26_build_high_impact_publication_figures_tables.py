from __future__ import annotations

import csv
import json
import math
import shutil
import textwrap
from datetime import datetime
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from PIL import Image
from scipy import stats


DATE_TAG = "2026-06-11"
ROOT = Path(__file__).resolve().parents[1]
INTEGRATED = ROOT / "outputs" / "integrated_mainline"
PACKAGE_NAME = f"high_impact_publication_figures_tables_{DATE_TAG}"
OUT = INTEGRATED / PACKAGE_NAME

FIG_MAIN = OUT / "figures" / "main"
FIG_EXT = OUT / "figures" / "extended"
TABLE_MAIN = OUT / "tables" / "main"
TABLE_SUPP = OUT / "tables" / "supplementary"
SRC = OUT / "source_data"
LEGENDS = OUT / "legends"
LOGS = OUT / "logs"
WORKBOOK_SRC = OUT / "workbook_source"

NHANES_MIRROR = (
    Path(r"C:\Users\liu12\OneDrive\Desktop\NHANES_MetS_Project")
    / "result"
    / "integrated_mainline"
    / PACKAGE_NAME
)

DESIGN = INTEGRATED / f"high_impact_figure_table_design_{DATE_TAG}"
PHASE2 = INTEGRATED / "no_digestion_phase0_to_phase4" / "phase2_manuscript_tables_and_figures"
PHASE0 = INTEGRATED / "no_digestion_phase0_to_phase4" / "phase0_scope_and_claims"
PHASE3_SKEL = INTEGRATED / "no_digestion_phase0_to_phase4" / "phase3_manuscript_skeleton"
STAGE1 = INTEGRATED / "stage1_msi"
PHASE1 = INTEGRATED / "phase1_qc_msi_sensitivity"
PHASE2_NHANES = INTEGRATED / "phase2_nhanes_survey_ready"
PHASE3_CGM = INTEGRATED / "phase3_cgmacros_robust_inference"
PHASE4 = INTEGRATED / "phase4_prediction_upgrade"
PHASE5 = INTEGRATED / "phase5_external_validation"
BOOST = INTEGRATED / "dry_lab_booster_modules"

PATHS = {
    "table1": PHASE2 / "Table1_dataset_and_phenotype_summary.csv",
    "nhanes_key": PHASE2 / "Table2_NHANES_R_survey_key_results.csv",
    "nhanes_quartile": PHASE2_NHANES / "phase2_nhanes_dose_response_quartile_summary.csv",
    "nhanes_rcs": BOOST / "module_B_nhanes_advanced_epidemiology" / "phase2_python_rcs_prediction_grid.csv",
    "nhanes_rcs_coef": BOOST / "module_B_nhanes_advanced_epidemiology" / "phase2_python_rcs_spline_coefficients.csv",
    "nhanes_effect_mod": BOOST / "module_B_nhanes_advanced_epidemiology" / "nhanes_effect_modification_results.csv",
    "nhanes_sensitivity": BOOST
    / "module_B_nhanes_advanced_epidemiology"
    / "nhanes_negative_control_and_sensitivity_results.csv",
    "nhanes_mixture": BOOST / "module_B_nhanes_advanced_epidemiology" / "nhanes_dehp_mixture_composition_results.csv",
    "weighted_table1": PHASE2_NHANES / "phase2_weighted_table1_by_oxidative_quartile.csv",
    "r_vs_python": PHASE2_NHANES / "phase2_R_survey_vs_python_comparison.csv",
    "r_main": PHASE2_NHANES / "phase2_R_survey_main_results.csv",
    "python_sensitivity": PHASE2_NHANES / "phase2_nhanes_python_sensitivity_results.csv",
    "python_cluster": PHASE2_NHANES / "phase2_nhanes_python_weighted_cluster_main_results.csv",
    "nhanes_dataset": PHASE2_NHANES / "phase2_python_analysis_dataset.csv",
    "msi_corr": PHASE1 / "phase1_msi_version_correlations.csv",
    "msi_weights": PHASE1 / "phase1_msi_pca_component_weights.csv",
    "msi_ppgr_sensitivity": PHASE1 / "phase1_msi_ppgr_sensitivity_models.csv",
    "nhanes_msi_sensitivity": PHASE1 / "phase1_nhanes_msi_exposure_sensitivity_models.csv",
    "msi_missing": STAGE1 / "stage1_msi_component_missingness.csv",
    "msi_scaler": STAGE1 / "stage1_msi_component_scaler.csv",
    "msi_summary": STAGE1 / "stage1_msi_summary_by_dataset.csv",
    "nhanes_msi": STAGE1 / "nhanes_2013_2018_msi_core.csv",
    "cg_subject_msi": STAGE1 / "cgmacros_subject_msi_core.csv",
    "cg_meals": STAGE1 / "cgmacros_meal_level_with_msi_core.csv",
    "cg_subject_ppgr": PHASE3_CGM / "phase3_subject_level_ppgr_msi_summary.csv",
    "cg_models": PHASE2 / "Table3_CGMacros_MSI_PPGR_results.csv",
    "cg_bootstrap": PHASE3_CGM / "phase3_subject_bootstrap_key_terms.csv",
    "cg_influence": PHASE3_CGM / "phase3_leave_one_subject_influence.csv",
    "cg_threshold": PHASE3_CGM / "phase3_high_response_definition_sensitivity.csv",
    "cg_load_variants": PHASE3_CGM / "phase3_load_variant_cluster_models.csv",
    "food_annotation": BOOST / "module_C_cgmacros_food_matrix" / "cgmacros_food_matrix_annotation.csv",
    "food_codebook": BOOST / "module_C_cgmacros_food_matrix" / "food_matrix_annotation_codebook.md",
    "food_models": BOOST / "module_C_cgmacros_food_matrix" / "cgmacros_food_matrix_ppgr_models.csv",
    "gi_gl": BOOST / "module_C_cgmacros_food_matrix" / "cgmacros_gi_gl_digestibility_features.csv",
    "food_error": BOOST / "module_C_cgmacros_food_matrix" / "food_matrix_prediction_error_explanation.csv",
    "curve_features": BOOST / "module_D_cgm_curve_phenotypes" / "cgmacros_ppgr_curve_features.csv",
    "curve_clusters": BOOST / "module_D_cgm_curve_phenotypes" / "cgmacros_ppgr_shape_clusters.csv",
    "curve_models": BOOST / "module_D_cgm_curve_phenotypes" / "curve_shape_msi_food_matrix_models.csv",
    "counterfactual": BOOST / "module_G_counterfactual_meal_redesign" / "counterfactual_meal_redesign_effects.csv",
    "counter_subject": BOOST / "module_G_counterfactual_meal_redesign" / "counterfactual_subject_level_heterogeneity.csv",
    "counter_subgroup": BOOST
    / "module_G_counterfactual_meal_redesign"
    / "counterfactual_subgroup_net_benefit_existing_subgroups.csv",
    "prediction_records": PHASE4 / "phase4_nested_lso_prediction_records.csv",
    "prediction_perf": PHASE4 / "phase4_model_performance_overall.csv",
    "prediction_delta": PHASE4 / "phase4_model_comparison_key_deltas.csv",
    "calibration": PHASE4 / "phase4_calibration_deciles.csv",
    "performance_msi": PHASE4 / "phase4_performance_by_msi.csv",
    "conformal": PHASE4 / "phase4_conformal_interval_coverage.csv",
    "fewshot": PHASE4 / "phase4_fewshot_recalibration_performance.csv",
    "leakage": BOOST / "module_H_prediction_TRIPOD_PROBAST_AI" / "prediction_leakage_audit.csv",
    "predictors": BOOST / "module_H_prediction_TRIPOD_PROBAST_AI" / "prediction_predictor_dictionary.csv",
    "external_map": BOOST / "module_F_external_transportability" / "external_transportability_map.csv",
    "external_shift": BOOST / "module_F_external_transportability" / "external_domain_shift_metrics.csv",
    "external_macro": BOOST / "module_F_external_transportability" / "external_macro_direction_consistency.csv",
    "external_boundary": PHASE5 / "phase5_external_boundary_summary.csv",
    "stanford_metrics": PHASE5 / "phase5_stanford_food_challenge_metrics.csv",
    "stanford_summary": PHASE5 / "phase5_stanford_food_summary.csv",
    "jaeb": PHASE5 / "phase5_jaeb_healthy_adults_cgm_summary.csv",
    "t1d_models": PHASE5 / "phase5_t1d_uom_macro_ppgr_models.csv",
    "t1d_metrics": PHASE5 / "phase5_t1d_uom_meal_ppgr_metrics.csv",
    "mechanism_edges": BOOST / "module_E_mechanism_knowledge_graph" / "dehp_msi_mechanism_knowledge_graph_edges.csv",
    "pathway": BOOST / "module_E_mechanism_knowledge_graph" / "dehp_msi_pathway_enrichment.csv",
    "evidence_map": BOOST / "module_A_literature_evidence_map" / "dry_lab_evidence_map_seed.csv",
    "evidence_gap": BOOST / "module_A_literature_evidence_map" / "dry_lab_evidence_gap_table.csv",
    "analysis_manifest": BOOST / "module_I_reproducibility_submission_package" / "analysis_manifest.csv",
    "data_dictionary": BOOST / "module_I_reproducibility_submission_package" / "data_dictionary.csv",
    "run_order": BOOST / "module_I_reproducibility_submission_package" / "run_order.md",
    "claims": PHASE3_SKEL / "phase3_main_claims_table_no_digestion.csv",
    "registry": PHASE0 / "phase0_no_digestion_analysis_registry.csv",
    "guardrails": PHASE0 / "phase0_overclaim_guardrails.csv",
    "display_map": DESIGN / "source_mapping" / "display_source_data_map.csv",
    "reviewer_matrix": DESIGN / "reviewer_strategy" / "reviewer_concern_response_matrix.csv",
    "priority_tracker": DESIGN / "logs" / "figure_build_priority_and_gap_audit.csv",
    "main_figure_catalog": DESIGN / "main_figures" / "main_figure_catalog_high_impact.csv",
    "extended_figure_catalog": DESIGN / "extended_figures" / "extended_figure_catalog_high_impact.csv",
    "main_table_catalog": DESIGN / "tables" / "main_table_catalog_high_impact.csv",
    "supp_table_catalog": DESIGN / "tables" / "supplementary_table_catalog_high_impact.csv",
}

PALETTE = {
    "blue": "#3E6FA5",
    "cyan": "#56B4C9",
    "green": "#2E8B57",
    "yellow": "#C9A227",
    "orange": "#E17C3A",
    "red": "#C75361",
    "purple": "#8E5EA2",
    "teal": "#007C89",
    "gray": "#626D78",
    "light": "#E9EDF1",
    "dark": "#18212B",
}
TERTILE_COLORS = {"low": "#3E6FA5", "middle": "#2E8B57", "high": "#E17C3A"}
MODEL_COLORS = {
    "M0_carb_only": "#9CA3AA",
    "M1_macro_timing": "#3E6FA5",
    "M2_macro_precgm_context": "#2E8B57",
    "M3_msi_enhanced": "#E17C3A",
}


def ensure_dirs() -> None:
    for path in [FIG_MAIN, FIG_EXT, TABLE_MAIN, TABLE_SUPP, SRC, LEGENDS, LOGS, WORKBOOK_SRC]:
        path.mkdir(parents=True, exist_ok=True)


def setup_style() -> None:
    sns.set_theme(style="whitegrid", context="paper")
    mpl.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "svg.fonttype": "none",
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.edgecolor": "#1F2933",
            "axes.linewidth": 0.75,
            "axes.labelcolor": "#1F2933",
            "xtick.color": "#1F2933",
            "ytick.color": "#1F2933",
            "grid.color": "#E8EDF2",
            "grid.linewidth": 0.55,
            "legend.frameon": False,
            "savefig.dpi": 600,
            "figure.dpi": 130,
        }
    )


def load_data() -> Dict[str, pd.DataFrame]:
    data: Dict[str, pd.DataFrame] = {}
    for key, path in PATHS.items():
        if path.suffix.lower() == ".csv" and path.exists():
            data[key] = pd.read_csv(path)
        else:
            data[key] = pd.DataFrame()
    return data


def save_csv(path: Path, df: pd.DataFrame) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False, encoding="utf-8-sig")


def source(name: str, df: pd.DataFrame) -> None:
    if df is not None and not df.empty:
        save_csv(SRC / f"{name}.csv", df)


def md_table(path: Path, df: pd.DataFrame, max_rows: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = df.copy()
    if max_rows is not None:
        out = out.head(max_rows)
    cols = [str(c) for c in out.columns]
    lines = [
        "| " + " | ".join(cols) + " |",
        "| " + " | ".join(["---"] * len(cols)) + " |",
    ]
    for _, row in out.iterrows():
        vals = []
        for col in out.columns:
            val = "" if pd.isna(row[col]) else str(row[col])
            vals.append(val.replace("|", "\\|").replace("\n", " "))
        lines.append("| " + " | ".join(vals) + " |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def label(ax: plt.Axes, text: str, x: float = -0.09, y: float = 1.08) -> None:
    ax.text(
        x,
        y,
        text,
        transform=ax.transAxes,
        ha="left",
        va="top",
        fontsize=10.5,
        fontweight="bold",
        color=PALETTE["dark"],
    )


def clean(ax: plt.Axes, grid_axis: str = "y") -> None:
    ax.tick_params(labelsize=8.2, length=3)
    ax.xaxis.label.set_size(8.8)
    ax.yaxis.label.set_size(8.8)
    ax.title.set_size(9.4)
    if grid_axis == "y":
        ax.grid(True, axis="y")
        ax.grid(False, axis="x")
    elif grid_axis == "x":
        ax.grid(True, axis="x")
        ax.grid(False, axis="y")
    else:
        ax.grid(False)


def fmt_p(x: object) -> str:
    try:
        val = float(x)
    except Exception:
        return ""
    if not math.isfinite(val):
        return ""
    return f"{val:.1e}" if val < 0.001 else f"{val:.3f}"


def outcome_label(x: object) -> str:
    return {
        "msi_pca": "MSI PCA",
        "msi_core_partial": "MSI core",
        "msi_core_complete": "MSI complete",
        "msi_no_bmi": "MSI without BMI",
        "msi_ranknorm": "MSI rank-normalized",
        "ln_HOMA_IR": "ln(HOMA-IR)",
        "HbA1c": "HbA1c",
        "iauc_2h_per1000": "2-h iAUC /1000",
        "peak_delta_2h": "2-h peak delta",
        "high_iauc_top_quartile": "High iAUC",
        "high_peak_top_quartile": "High peak",
        "early_slope_proxy_0_to_peak": "Early slope",
        "delayed_peak_flag": "Delayed peak",
        "prolonged_elevation_flag": "Prolonged elevation",
        "high_iAUC_moderate_peak_flag": "High iAUC/moderate peak",
        "high_peak_fast_recovery_flag": "High peak/fast recovery",
        "low_stable_response_flag": "Low stable response",
    }.get(str(x), str(x))


def term_label(x: object) -> str:
    return {
        "carbs_10g": "Carbohydrate /10 g",
        "protein_10g": "Protein /10 g",
        "fat_10g": "Fat /10 g",
        "fiber_5g": "Fiber /5 g",
        "msi_core_centered": "MSI",
        "msi_centered": "MSI",
        "carbs_x_msi": "Carb x MSI",
        "load_x_msi": "Load x MSI",
        "digestibility_centered": "Digestibility-risk",
        "msi_x_digestibility": "MSI x digestibility-risk",
        "baseline_glucose_z": "Baseline glucose, z",
        "baseline_glucose": "Baseline glucose",
        "ln_oxidative_to_MEHP": "ln oxidative/MEHP",
        "pct_oxidative_10": "% oxidative /10 pp",
        "ln_Sigma_DEHP": "ln Sigma DEHP",
    }.get(str(x), str(x).replace("_", " "))


def model_label(x: object) -> str:
    return {
        "M0_carb_only": "M0 carb",
        "M1_macro_timing": "M1 macro+time",
        "M2_macro_precgm_context": "M2 + pre-CGM",
        "M3_msi_enhanced": "M3 + MSI",
    }.get(str(x), str(x))


def dataset_label(x: object) -> str:
    return {
        "NHANES_2013_2018": "NHANES",
        "CGMacros_subjects": "CGMacros",
        "CGMacros": "CGMacros",
        "Stanford_CGMDB": "Stanford",
        "T1D_UOM": "T1D-UOM",
        "Jaeb_healthy_adults": "Jaeb healthy",
        "Jaeb_CGMND_HealthyAdults": "Jaeb healthy",
    }.get(str(x), str(x))


def draw_forest(
    ax: plt.Axes,
    df: pd.DataFrame,
    estimate: str,
    low: str,
    high: str,
    label_col: str,
    color_col: str | None = None,
    q_col: str | None = None,
    xlab: str = "Estimate (95% CI)",
    ref: float = 0.0,
) -> None:
    if df.empty:
        ax.axis("off")
        ax.text(0.5, 0.5, "No source data", ha="center", va="center", fontsize=9)
        return
    plot = df.copy().reset_index(drop=True)
    for col in [estimate, low, high]:
        plot[col] = pd.to_numeric(plot[col], errors="coerce")
    plot = plot.dropna(subset=[estimate, low, high])
    if plot.empty:
        ax.axis("off")
        ax.text(0.5, 0.5, "No numeric estimates", ha="center", va="center", fontsize=9)
        return
    y = np.arange(len(plot))[::-1]
    colors = plot[color_col].tolist() if color_col else [PALETTE["blue"]] * len(plot)
    for i, row in plot.iterrows():
        yy = y[i]
        ax.plot([row[low], row[high]], [yy, yy], color=colors[i], lw=1.75, solid_capstyle="round")
        ax.scatter(row[estimate], yy, s=27, color=colors[i], edgecolor="white", linewidth=0.45, zorder=3)
        if q_col and q_col in plot.columns:
            ax.text(
                ax.get_xlim()[1],
                yy,
                f"q={fmt_p(row[q_col])}",
                ha="right",
                va="center",
                fontsize=6.8,
                color=PALETTE["gray"],
            )
    ax.axvline(ref, color="#AEB7C2", lw=0.85, zorder=0)
    ax.set_yticks(y)
    ax.set_yticklabels(plot[label_col], fontsize=7.4)
    ax.set_ylim(-0.7, len(plot) - 0.3)
    ax.set_xlabel(xlab)
    clean(ax, "x")


def save_figure(fig: plt.Figure, stem: str, group: str) -> List[Dict[str, object]]:
    out_dir = FIG_MAIN if group == "main" else FIG_EXT
    records: List[Dict[str, object]] = []
    for ext in ["pdf", "svg", "png", "tiff"]:
        path = out_dir / f"{stem}.{ext}"
        kwargs = {"bbox_inches": "tight"}
        if ext in ["png", "tiff"]:
            kwargs["dpi"] = 600
        if ext == "tiff":
            kwargs["pil_kwargs"] = {"compression": "tiff_lzw"}
        fig.savefig(path, **kwargs)
        rec = {
            "figure": stem,
            "group": group,
            "format": ext,
            "path": str(path),
            "bytes": path.stat().st_size,
        }
        if ext in ["png", "tiff"]:
            with Image.open(path) as im:
                rec["width_px"] = im.width
                rec["height_px"] = im.height
                rec["mode"] = im.mode
        records.append(rec)
    plt.close(fig)
    return records


def zscore_series(s: pd.Series) -> pd.Series:
    vals = pd.to_numeric(s, errors="coerce")
    sd = vals.std(ddof=0)
    if pd.isna(sd) or sd == 0:
        return vals * 0
    return (vals - vals.mean()) / sd


def compact_name(x: object, max_len: int = 34) -> str:
    text = str(x)
    return text if len(text) <= max_len else text[: max_len - 1] + "."


def draw_mini_table(ax: plt.Axes, df: pd.DataFrame, title: str | None = None, font_size: float = 7.1) -> None:
    ax.axis("off")
    if title:
        ax.set_title(title, loc="left", fontsize=9.4, pad=4)
    table = ax.table(
        cellText=df.astype(str).values,
        colLabels=df.columns.tolist(),
        cellLoc="left",
        colLoc="left",
        loc="center",
        bbox=[0, 0, 1, 0.95],
    )
    table.auto_set_font_size(False)
    table.set_fontsize(font_size)
    for (row, col), cell in table.get_celld().items():
        cell.set_edgecolor("#D9DEE5")
        cell.set_linewidth(0.45)
        if row == 0:
            cell.set_facecolor("#EEF2F6")
            cell.set_text_props(weight="bold", color=PALETTE["dark"])
        else:
            cell.set_facecolor("white" if row % 2 else "#F8FAFC")


def figure1_architecture(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    table1 = data["table1"].copy()
    registry = data["registry"].copy()
    guardrails = data["guardrails"].copy()
    claims = data["claims"].copy()
    source("MainFigure1_Table1_dataset_roles", table1)
    source("MainFigure1_Analysis_registry", registry)
    source("MainFigure1_Claim_guardrails", guardrails)

    fig = plt.figure(figsize=(13.0, 7.8), constrained_layout=True)
    gs = fig.add_gridspec(2, 2, width_ratios=[1.25, 1.0], height_ratios=[1.2, 1.0])
    ax_a = fig.add_subplot(gs[0, :])
    ax_b = fig.add_subplot(gs[1, 0])
    ax_c = fig.add_subplot(gs[1, 1])

    ax_a.axis("off")
    nodes = [
        ("NHANES\n2013-2018", "DEHP oxidative profile\nsurvey-weighted associations", PALETTE["blue"]),
        ("MSI bridge", "Metabolic susceptibility\nphenotype construction", PALETTE["teal"]),
        ("CGMacros", "Free-living meal-level\nCGM vulnerability", PALETTE["orange"]),
        ("Food matrix", "Digestibility-risk proxy\ncurve phenotypes", PALETTE["green"]),
        ("Prediction\nboundaries", "MSI stratification\nexternal limits", PALETTE["purple"]),
    ]
    x_positions = np.linspace(0.09, 0.91, len(nodes))
    for i, (head, body, color) in enumerate(nodes):
        x = x_positions[i]
        rect = mpl.patches.FancyBboxPatch(
            (x - 0.075, 0.48),
            0.15,
            0.28,
            boxstyle="round,pad=0.018,rounding_size=0.015",
            fc="white",
            ec=color,
            lw=1.8,
            transform=ax_a.transAxes,
        )
        ax_a.add_patch(rect)
        ax_a.text(x, 0.70, head, ha="center", va="center", fontsize=9.2, fontweight="bold", color=color, transform=ax_a.transAxes)
        ax_a.text(x, 0.58, body, ha="center", va="center", fontsize=7.1, color=PALETTE["dark"], transform=ax_a.transAxes)
        if i < len(nodes) - 1:
            ax_a.annotate(
                "",
                xy=(x_positions[i + 1] - 0.095, 0.62),
                xytext=(x + 0.095, 0.62),
                xycoords=ax_a.transAxes,
                arrowprops=dict(arrowstyle="->", color="#7C8794", lw=1.4),
            )
    ax_a.text(
        0.5,
        0.28,
        "Design principle: cross-dataset bridge phenotype, not a direct DEHP-to-PPGR causal mediation test",
        ha="center",
        va="center",
        fontsize=9,
        color=PALETTE["dark"],
        bbox=dict(boxstyle="round,pad=0.35", fc="#F4F7FA", ec="#D5DDE6", lw=0.8),
        transform=ax_a.transAxes,
    )
    label(ax_a, "A", x=0.0, y=1.0)

    plot = table1.copy()
    plot["dataset_label"] = plot["dataset"].map(dataset_label)
    plot["n_subjects_or_participants"] = pd.to_numeric(plot["n_subjects_or_participants"], errors="coerce")
    plot["n_meals_or_events"] = pd.to_numeric(plot["n_meals_or_events"], errors="coerce").fillna(0)
    y = np.arange(len(plot))
    ax_b.barh(y + 0.18, plot["n_subjects_or_participants"], height=0.32, color=PALETTE["blue"], alpha=0.88, label="participants")
    ax_b.barh(y - 0.18, plot["n_meals_or_events"], height=0.32, color=PALETTE["orange"], alpha=0.86, label="meals/events")
    ax_b.set_yticks(y)
    ax_b.set_yticklabels(plot["dataset_label"], fontsize=7.6)
    ax_b.set_xscale("symlog", linthresh=10)
    ax_b.set_xlabel("Count, symlog scale")
    ax_b.set_title("Analytic sample layers")
    ax_b.legend(fontsize=7.2, loc="lower right")
    clean(ax_b, "x")
    label(ax_b, "B")

    ax_c.axis("off")
    ax_c.set_title("No-overclaim guardrails", loc="left", fontsize=9.4, pad=4)
    guard = guardrails[["risk", "preferred_language", "severity"]].head(4).copy()
    for i, row in guard.iterrows():
        y0 = 0.78 - i * 0.22
        severity = str(row["severity"]).lower()
        color = PALETTE["red"] if severity == "high" else PALETTE["orange"]
        rect = mpl.patches.FancyBboxPatch(
            (0.02, y0),
            0.96,
            0.18,
            boxstyle="round,pad=0.012,rounding_size=0.012",
            fc="#F8FAFC",
            ec="#D7DEE7",
            lw=0.8,
            transform=ax_c.transAxes,
        )
        ax_c.add_patch(rect)
        ax_c.text(0.04, y0 + 0.13, str(row["risk"]), ha="left", va="center", fontsize=7.7, fontweight="bold", color=PALETTE["dark"], transform=ax_c.transAxes)
        ax_c.text(
            0.04,
            y0 + 0.062,
            "Use: " + textwrap.fill(str(row["preferred_language"]), width=58),
            ha="left",
            va="center",
            fontsize=6.25,
            color=PALETTE["gray"],
            transform=ax_c.transAxes,
        )
        ax_c.text(
            0.93,
            y0 + 0.13,
            severity,
            ha="right",
            va="center",
            fontsize=7.0,
            color="white",
            bbox=dict(boxstyle="round,pad=0.18", fc=color, ec="none"),
            transform=ax_c.transAxes,
        )
    label(ax_c, "C")

    outputs = save_figure(fig, "MainFigure1_EvidenceArchitecture", "main")

    if not claims.empty:
        claim_short = claims[["claim_order", "claim", "strength", "caution"]].copy()
        claim_short["claim"] = claim_short["claim"].map(lambda x: compact_name(x, 90))
        source("MainFigure1_Claim_ladder", claim_short)
    return outputs


def figure2_nhanes(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    survey = data["nhanes_key"].copy()
    survey = survey[survey["outcome"].isin(["msi_core_partial", "msi_pca", "msi_no_bmi", "ln_HOMA_IR", "HbA1c"])]
    survey = survey[survey["exposure"].isin(["ln_oxidative_to_MEHP", "pct_oxidative_10"])]
    survey["label"] = survey["exposure"].map(term_label) + " | " + survey["outcome"].map(outcome_label)
    survey["color"] = survey["exposure"].map({"ln_oxidative_to_MEHP": PALETTE["blue"], "pct_oxidative_10": PALETTE["orange"]})
    survey = survey.sort_values(["exposure", "outcome"])
    source("MainFigure2A_NHANES_survey_forest", survey)

    quart = data["nhanes_quartile"].copy()
    quart = quart[quart["quartile"].notna() & quart["exposure"].eq("ln_oxidative_to_MEHP")]
    quart = quart[quart["outcome"].isin(["msi_core_partial", "ln_HOMA_IR", "HbA1c"])]
    quart["outcome_label"] = quart["outcome"].map(outcome_label)
    quart["z_weighted_mean"] = quart.groupby("outcome")["weighted_mean_outcome"].transform(zscore_series)
    source("MainFigure2B_NHANES_quartile_dose_response", quart)

    rcs = data["nhanes_rcs"].copy()
    rcs = rcs[(rcs["exposure"].eq("ln_oxidative_to_MEHP")) & (rcs["outcome"].eq("msi_core_partial"))]
    source("MainFigure2C_NHANES_RCS_grid", rcs)

    sens = data["nhanes_sensitivity"].copy()
    sens = sens[sens["outcome"].isin(["msi_core_partial", "msi_no_bmi", "ln_HOMA_IR", "HbA1c"])]
    sens = sens[sens["term"].isin(["ln_oxidative_to_MEHP", "pct_oxidative_10", "ln_Sigma_DEHP"])]
    sens = sens.head(14).copy()
    sens["label"] = sens["model"].astype(str) + " | " + sens["outcome"].map(outcome_label) + " | " + sens["term"].map(term_label)
    sens["color"] = sens["model"].map({"primary": PALETTE["blue"], "negative_control_like": PALETTE["gray"]}).fillna(PALETTE["teal"])
    source("MainFigure2D_NHANES_sensitivity", sens)

    em = data["nhanes_effect_mod"].copy()
    em = em[(em["outcome"].eq("msi_core_partial")) & (em["exposure"].eq("ln_oxidative_to_MEHP"))]
    em["subgroup"] = em["subgroup_variable"].astype(str) + ": " + em["subgroup_level"].astype(str)
    em_plot = em.pivot_table(index="subgroup", columns="term", values="estimate", aggfunc="mean")
    source("MainFigure2E_NHANES_effect_modification", em)

    mix = data["nhanes_mixture"].copy()
    mix = mix[mix["outcome"].isin(["msi_core_partial", "ln_HOMA_IR", "HbA1c"])]
    mix = mix[mix["term"].isin(["ln_Sigma_DEHP", "pct_oxidative_10", "ln_oxidative_to_MEHP"])]
    mix["label"] = mix["outcome"].map(outcome_label) + " | " + mix["term"].map(term_label)
    mix["color"] = mix["term"].map(
        {"ln_Sigma_DEHP": PALETTE["gray"], "pct_oxidative_10": PALETTE["orange"], "ln_oxidative_to_MEHP": PALETTE["blue"]}
    )
    source("MainFigure2F_NHANES_mixture_proxy", mix)

    fig = plt.figure(figsize=(12.2, 9.6), constrained_layout=True)
    gs = fig.add_gridspec(3, 2, height_ratios=[1.35, 1.0, 1.1])
    axes = [fig.add_subplot(gs[i, j]) for i in range(3) for j in range(2)]

    axes[0].set_xlim(-0.09, max(0.38, survey["R_ci_high"].max() * 1.12))
    draw_forest(axes[0], survey, "R_beta", "R_ci_low", "R_ci_high", "label", "color", "R_q", "Survey-weighted beta")
    axes[0].set_title("Primary survey-weighted associations")
    label(axes[0], "A")

    sns.lineplot(
        data=quart,
        x="quartile",
        y="z_weighted_mean",
        hue="outcome_label",
        style="outcome_label",
        markers=True,
        dashes=False,
        palette=[PALETTE["blue"], PALETTE["green"], PALETTE["red"]],
        ax=axes[1],
        linewidth=1.7,
        markersize=5,
    )
    axes[1].set_xticks([1, 2, 3, 4])
    axes[1].set_xlabel("Quartile of ln(oxidative/MEHP)")
    axes[1].set_ylabel("Weighted mean outcome, z-scaled")
    axes[1].set_title("Dose-response pattern")
    axes[1].legend(title="", fontsize=7.2, loc="upper left")
    clean(axes[1])
    label(axes[1], "B")

    axes[2].plot(rcs["x"], rcs["delta_vs_median"], color=PALETTE["blue"], lw=2.0)
    axes[2].fill_between(rcs["x"], rcs["delta_vs_median"], 0, color=PALETTE["blue"], alpha=0.08)
    axes[2].axhline(0, color="#AEB7C2", lw=0.8)
    if not rcs.empty and rcs["reference_median"].notna().any():
        med = rcs["reference_median"].dropna().iloc[0]
        axes[2].axvline(med, color=PALETTE["gray"], lw=0.9, ls="--")
    axes[2].set_xlabel("ln(oxidative/MEHP)")
    axes[2].set_ylabel("Predicted MSI-core difference vs median")
    axes[2].set_title("Restricted cubic spline sensitivity")
    clean(axes[2])
    label(axes[2], "C")

    draw_forest(axes[3], sens, "estimate", "ci_low", "ci_high", "label", "color", "q_value", "Sensitivity estimate")
    axes[3].set_title("Sensitivity and negative-control-like checks")
    label(axes[3], "D")

    if not em_plot.empty:
        sns.heatmap(em_plot, cmap="vlag", center=0, annot=True, fmt=".2f", linewidths=0.3, cbar_kws={"label": "beta"}, ax=axes[4])
    axes[4].set_title("Subgroup/effect-modification screen")
    axes[4].set_xlabel("")
    axes[4].set_ylabel("")
    axes[4].tick_params(labelsize=6.7)
    label(axes[4], "E")

    draw_forest(axes[5], mix, "estimate", "ci_low", "ci_high", "label", "color", "q_value", "Joint proxy model beta")
    axes[5].set_title("DEHP composition/mixture proxy")
    label(axes[5], "F")

    return save_figure(fig, "MainFigure2_NHANES_ExposureResponse", "main")


def figure3_msi_validation(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    weights = data["msi_weights"].copy()
    corr = data["msi_corr"].copy()
    summary = data["msi_summary"].copy()
    nhanes = data["nhanes_msi"].copy()
    cg = data["cg_subject_msi"].copy()
    missing = data["msi_missing"].copy()
    scaler = data["msi_scaler"].copy()
    source("MainFigure3A_MSI_weights", weights)
    source("MainFigure3B_MSI_correlations", corr)
    source("MainFigure3C_MSI_distributions", pd.concat([nhanes.assign(source_dataset="NHANES"), cg.assign(source_dataset="CGMacros")], sort=False))
    source("MainFigure3D_MSI_missingness", missing)
    source("MainFigure3E_MSI_scaler", scaler)

    fig = plt.figure(figsize=(11.4, 9.3), constrained_layout=True)
    gs = fig.add_gridspec(3, 2, height_ratios=[1.0, 1.2, 1.0])
    axes = [fig.add_subplot(gs[i, j]) for i in range(3) for j in range(2)]

    weights["component_label"] = weights["component"].str.replace("_z_nhanes_ref", "", regex=False).str.replace("_", " ")
    sns.barplot(data=weights, x="weight", y="component_label", color=PALETTE["teal"], ax=axes[0])
    axes[0].axvline(0, color="#AEB7C2", lw=0.8)
    axes[0].set_xlabel("PCA loading")
    axes[0].set_ylabel("")
    axes[0].set_title("MSI component architecture")
    clean(axes[0], "x")
    label(axes[0], "A")

    if not corr.empty:
        chosen = corr[corr["dataset"].astype(str).str.contains("NHANES", case=False, na=False)].copy()
        if chosen.empty:
            chosen = corr.copy()
        pivot = chosen.pivot_table(index="msi_a", columns="msi_b", values="spearman", aggfunc="mean")
        names = sorted(set(pivot.index).union(set(pivot.columns)))
        pivot = pivot.reindex(index=names, columns=names)
        for name in names:
            pivot.loc[name, name] = 1.0
        sns.heatmap(pivot, vmin=0.75, vmax=1.0, cmap="YlGnBu", annot=True, fmt=".2f", cbar_kws={"label": "Spearman r"}, ax=axes[1])
    axes[1].set_title("MSI version robustness")
    axes[1].set_xlabel("")
    axes[1].set_ylabel("")
    axes[1].tick_params(labelsize=6.2)
    label(axes[1], "B")

    dist = pd.concat(
        [
            nhanes[["msi_core_partial_nhanes_ref"]].rename(columns={"msi_core_partial_nhanes_ref": "MSI"}).assign(dataset="NHANES"),
            cg[["msi_core_partial_nhanes_ref"]].rename(columns={"msi_core_partial_nhanes_ref": "MSI"}).assign(dataset="CGMacros"),
        ],
        ignore_index=True,
    ).dropna()
    sns.kdeplot(data=dist, x="MSI", hue="dataset", common_norm=False, fill=True, alpha=0.16, linewidth=1.7, ax=axes[2], palette=[PALETTE["blue"], PALETTE["orange"]])
    axes[2].axvline(0, color="#AEB7C2", lw=0.8)
    axes[2].set_title("Bridge phenotype distributions")
    clean(axes[2])
    label(axes[2], "C")

    comp_cols = [
        "bmi_z_nhanes_ref",
        "hba1c_z_nhanes_ref",
        "fasting_glucose_mgdl_z_nhanes_ref",
        "ln_homa_ir_z_nhanes_ref",
        "ln_tg_hdl_z_nhanes_ref",
    ]
    prof = nhanes.dropna(subset=["msi_core_tertile_within_dataset"]).groupby("msi_core_tertile_within_dataset")[comp_cols].mean()
    prof = prof.reindex(["low", "middle", "high"])
    prof.columns = [c.replace("_z_nhanes_ref", "").replace("_", " ") for c in prof.columns]
    sns.heatmap(prof, cmap="vlag", center=0, annot=True, fmt=".2f", linewidths=0.35, cbar_kws={"label": "z"}, ax=axes[3])
    axes[3].set_title("Component profiles across MSI tertiles")
    axes[3].set_xlabel("")
    axes[3].set_ylabel("MSI tertile")
    axes[3].tick_params(labelsize=7.0)
    label(axes[3], "D")

    miss = missing.copy()
    miss["component_label"] = miss["component"].str.replace("_", " ")
    sns.barplot(data=miss, x="pct_nonmissing", y="component_label", hue="dataset", ax=axes[4], palette=[PALETTE["blue"], PALETTE["orange"]])
    axes[4].set_xlim(0, 105)
    axes[4].set_xlabel("Nonmissing (%)")
    axes[4].set_ylabel("")
    axes[4].set_title("Component availability")
    axes[4].legend(title="", fontsize=7.0, loc="lower right")
    clean(axes[4], "x")
    label(axes[4], "E")

    summ = summary.copy()
    summ["dataset"] = summ["dataset"].map(dataset_label)
    table = summ[["dataset", "n", "n_msi_partial", "median_msi_partial", "p25_msi_partial", "p75_msi_partial", "n_high_tertile"]].copy()
    table.columns = ["Dataset", "N", "MSI N", "Median", "P25", "P75", "High tertile N"]
    for col in ["Median", "P25", "P75"]:
        table[col] = pd.to_numeric(table[col], errors="coerce").map(lambda x: f"{x:.2f}")
    draw_mini_table(axes[5], table, "Dataset-level MSI summary", font_size=7.0)
    label(axes[5], "F")

    return save_figure(fig, "MainFigure3_MSI_Validation", "main")


def figure4_cgmacros(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    meals = data["cg_meals"].copy()
    meals = meals.rename(columns={"msi_core_tertile_within_dataset": "msi_tertile", "msi_core_partial_nhanes_ref": "msi"})
    meals = meals[meals["msi_tertile"].isin(["low", "middle", "high"])]
    subj = data["cg_subject_ppgr"].copy()
    models = data["cg_models"].copy()
    boot = data["cg_bootstrap"].copy()
    influence = data["cg_influence"].copy()
    source("MainFigure4AB_Meal_distributions", meals[["subject_id", "meal_time", "msi", "msi_tertile", "iauc_2h", "peak_delta_2h", "carbs", "meal_type"]])
    source("MainFigure4C_Subject_gradient", subj)
    source("MainFigure4E_Bootstrap_terms", boot)
    source("MainFigure4F_Leave_one_subject", influence)

    keep = (
        models["model"].eq("base_interaction")
        & models["outcome"].isin(["iauc_2h_per1000", "peak_delta_2h", "high_iauc_top_quartile", "high_peak_top_quartile"])
        & models["term"].isin(["carbs_10g", "msi_core_centered", "carbs_x_msi"])
    )
    forest = models[keep].copy()
    forest["label"] = forest["outcome"].map(outcome_label) + " | " + forest["term"].map(term_label)
    forest["color"] = forest["term"].map({"carbs_10g": PALETTE["gray"], "msi_core_centered": PALETTE["orange"], "carbs_x_msi": PALETTE["purple"]})
    source("MainFigure4D_CGMacros_model_forest", forest)

    fig = plt.figure(figsize=(12.0, 9.4), constrained_layout=True)
    gs = fig.add_gridspec(3, 2)
    axes = [fig.add_subplot(gs[i, j]) for i in range(3) for j in range(2)]
    order = ["low", "middle", "high"]

    sns.violinplot(data=meals, x="msi_tertile", y="iauc_2h", order=order, palette=TERTILE_COLORS, inner=None, cut=0, linewidth=0.7, ax=axes[0])
    sns.boxplot(
        data=meals,
        x="msi_tertile",
        y="iauc_2h",
        order=order,
        width=0.22,
        showfliers=False,
        boxprops={"facecolor": "white", "edgecolor": PALETTE["dark"], "linewidth": 0.8},
        medianprops={"color": PALETTE["dark"], "linewidth": 1.0},
        ax=axes[0],
    )
    axes[0].set_ylim(0, meals["iauc_2h"].quantile(0.99) * 1.05)
    axes[0].set_xlabel("MSI tertile")
    axes[0].set_ylabel("2-h iAUC (mg/dL*min)")
    axes[0].set_title("Meal-level iAUC distribution")
    clean(axes[0])
    label(axes[0], "A")

    sns.violinplot(data=meals, x="msi_tertile", y="peak_delta_2h", order=order, palette=TERTILE_COLORS, inner=None, cut=0, linewidth=0.7, ax=axes[1])
    sns.boxplot(
        data=meals,
        x="msi_tertile",
        y="peak_delta_2h",
        order=order,
        width=0.22,
        showfliers=False,
        boxprops={"facecolor": "white", "edgecolor": PALETTE["dark"], "linewidth": 0.8},
        medianprops={"color": PALETTE["dark"], "linewidth": 1.0},
        ax=axes[1],
    )
    axes[1].set_ylim(meals["peak_delta_2h"].quantile(0.01) - 8, meals["peak_delta_2h"].quantile(0.99) * 1.05)
    axes[1].set_xlabel("MSI tertile")
    axes[1].set_ylabel("Peak delta (mg/dL)")
    axes[1].set_title("Meal-level peak distribution")
    clean(axes[1])
    label(axes[1], "B")

    subj = subj.rename(columns={"msi_core_tertile_within_dataset": "msi_tertile", "msi_core_partial_nhanes_ref": "msi"})
    if "msi" not in subj.columns:
        subj = subj.rename(columns={"msi_core": "msi"})
    for tert, group in subj.groupby("msi_tertile"):
        axes[2].scatter(
            group["msi"],
            group["mean_iauc_2h"],
            s=24 + pd.to_numeric(group.get("n_meals", 20), errors="coerce").fillna(20) * 0.55,
            color=TERTILE_COLORS.get(tert, PALETTE["gray"]),
            edgecolor="white",
            linewidth=0.45,
            alpha=0.9,
            label=tert,
        )
    sns.regplot(data=subj, x="msi", y="mean_iauc_2h", scatter=False, color=PALETTE["dark"], line_kws={"lw": 1.1}, ax=axes[2])
    mask = subj["msi"].notna() & subj["mean_iauc_2h"].notna()
    if mask.sum() > 2:
        rho, p = stats.spearmanr(subj.loc[mask, "msi"], subj.loc[mask, "mean_iauc_2h"])
        axes[2].text(0.04, 0.94, f"Spearman r={rho:.2f}\np={fmt_p(p)}", transform=axes[2].transAxes, va="top", fontsize=7.5)
    axes[2].set_xlabel("Participant MSI")
    axes[2].set_ylabel("Mean 2-h iAUC")
    axes[2].set_title("Subject-level susceptibility gradient")
    axes[2].legend(title="MSI", fontsize=7.0, title_fontsize=7.0)
    clean(axes[2])
    label(axes[2], "C")

    display = forest[forest["outcome"].isin(["iauc_2h_per1000", "high_iauc_top_quartile", "high_peak_top_quartile"])].copy()
    draw_forest(axes[3], display, "estimate", "ci_low", "ci_high", "label", "color", "q_value", "Model coefficient")
    axes[3].set_title("Cluster-robust meal-level models")
    label(axes[3], "D")

    boot_plot = boot[boot["term"].isin(["carbs_10g", "msi_centered", "load_x_msi"])].copy()
    boot_plot["label"] = boot_plot["outcome"].map(outcome_label) + " | " + boot_plot["term"].map(term_label)
    boot_plot["color"] = boot_plot["term"].map({"carbs_10g": PALETTE["gray"], "msi_centered": PALETTE["orange"], "load_x_msi": PALETTE["purple"]})
    draw_forest(axes[4], boot_plot, "boot_mean", "boot_ci_low", "boot_ci_high", "label", "color", None, "Bootstrap mean (95% interval)")
    axes[4].set_title("Subject bootstrap stability")
    label(axes[4], "E")

    inf = influence[influence["term"].eq("msi_centered") & influence["outcome"].isin(["iauc_2h_per1000", "peak_delta_2h"])].copy()
    sns.boxplot(data=inf, x="outcome", y="estimate", color="#DCE7F2", fliersize=2, ax=axes[5])
    sns.stripplot(data=inf, x="outcome", y="estimate", color=PALETTE["blue"], size=2.7, alpha=0.65, ax=axes[5])
    axes[5].set_xticklabels([outcome_label(t.get_text()) for t in axes[5].get_xticklabels()], rotation=0)
    axes[5].axhline(0, color="#AEB7C2", lw=0.8)
    axes[5].set_xlabel("")
    axes[5].set_ylabel("Leave-one-subject estimate")
    axes[5].set_title("Influence diagnostics")
    clean(axes[5])
    label(axes[5], "F")

    return save_figure(fig, "MainFigure4_CGMacros_PPGR_Vulnerability", "main")


def figure5_food_matrix(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    ann = data["food_annotation"].copy()
    ann = ann[ann["msi_core_tertile_within_dataset"].isin(["low", "middle", "high"])]
    models = data["food_models"].copy()
    counter = data["counterfactual"].copy()
    source("MainFigure5A_FoodMatrix_meal_data", ann)
    source("MainFigure5B_FoodMatrix_models", models)
    source("MainFigure5E_Counterfactual_meal_redesign", counter)

    fig = plt.figure(figsize=(12.0, 9.5), constrained_layout=True)
    gs = fig.add_gridspec(3, 2)
    axes = [fig.add_subplot(gs[i, j]) for i in range(3) for j in range(2)]

    sns.scatterplot(
        data=ann,
        x="digestibility_risk_score",
        y="iauc_2h",
        hue="msi_core_tertile_within_dataset",
        palette=TERTILE_COLORS,
        s=18,
        alpha=0.6,
        linewidth=0,
        ax=axes[0],
    )
    sns.regplot(data=ann, x="digestibility_risk_score", y="iauc_2h", scatter=False, color=PALETTE["dark"], line_kws={"lw": 1.1}, ax=axes[0])
    axes[0].set_ylim(0, ann["iauc_2h"].quantile(0.99) * 1.05)
    axes[0].set_xlabel("Digestibility-risk proxy")
    axes[0].set_ylabel("2-h iAUC")
    axes[0].set_title("Meal-level food-matrix gradient")
    axes[0].legend(title="MSI", fontsize=6.8, title_fontsize=6.8)
    clean(axes[0])
    label(axes[0], "A")

    forest = models[models["term"].isin(["carbs_10g", "protein_10g", "fat_10g", "fiber_5g", "msi_centered", "digestibility_centered", "msi_x_digestibility"])].copy()
    forest = forest[forest["outcome"].eq("iauc_2h_per1000")]
    forest["label"] = forest["term"].map(term_label)
    forest["color"] = forest["term"].map(
        {
            "msi_centered": PALETTE["orange"],
            "digestibility_centered": PALETTE["teal"],
            "msi_x_digestibility": PALETTE["purple"],
            "carbs_10g": PALETTE["gray"],
            "protein_10g": PALETTE["green"],
            "fat_10g": PALETTE["yellow"],
            "fiber_5g": PALETTE["blue"],
        }
    )
    draw_forest(axes[1], forest, "estimate", "ci_low", "ci_high", "label", "color", "q_value", "iAUC coefficient")
    axes[1].set_title("Food-matrix model estimates")
    label(axes[1], "B")

    coef = {r["term"]: r["estimate"] for _, r in models[models["outcome"].eq("iauc_2h_per1000")].iterrows()}
    msi_grid = np.linspace(ann["msi_core_partial_nhanes_ref"].quantile(0.05), ann["msi_core_partial_nhanes_ref"].quantile(0.95), 40)
    dig_grid = np.linspace(ann["digestibility_risk_score"].quantile(0.05), ann["digestibility_risk_score"].quantile(0.95), 40)
    zz = np.zeros((len(dig_grid), len(msi_grid)))
    for i, dig in enumerate(dig_grid):
        for j, msi in enumerate(msi_grid):
            zz[i, j] = (
                coef.get("Intercept", 0)
                + coef.get("msi_centered", 0) * msi
                + coef.get("digestibility_centered", 0) * dig
                + coef.get("msi_x_digestibility", 0) * msi * dig
            )
    im = axes[2].imshow(
        zz,
        origin="lower",
        aspect="auto",
        extent=[msi_grid.min(), msi_grid.max(), dig_grid.min(), dig_grid.max()],
        cmap="YlOrRd",
    )
    fig.colorbar(im, ax=axes[2], label="Predicted iAUC /1000")
    axes[2].set_xlabel("MSI")
    axes[2].set_ylabel("Digestibility-risk")
    axes[2].set_title("MSI x food-matrix response surface")
    label(axes[2], "C")
    source(
        "MainFigure5C_Response_surface",
        pd.DataFrame(
            [{"msi": m, "digestibility": d, "pred_iauc_per1000": zz[i, j]} for i, d in enumerate(dig_grid) for j, m in enumerate(msi_grid)]
        ),
    )

    feature_cols = [
        "refined_starch_proxy",
        "liquid_carb_proxy",
        "dessert_sweetened_proxy",
        "high_fat_high_carb_matrix",
        "visible_fiber_proxy",
        "protein_coingestion_proxy",
        "fried_processed_packaged_proxy",
        "whole_intact_grain_or_vegetable_proxy",
    ]
    feat = []
    high_cut = ann["digestibility_risk_score"].quantile(0.75)
    low_cut = ann["digestibility_risk_score"].quantile(0.25)
    for col in feature_cols:
        feat.append(
            {
                "feature": col.replace("_proxy", "").replace("_", " "),
                "high_digestibility": ann.loc[ann["digestibility_risk_score"] >= high_cut, col].mean(),
                "low_digestibility": ann.loc[ann["digestibility_risk_score"] <= low_cut, col].mean(),
            }
        )
    feat_df = pd.DataFrame(feat)
    source("MainFigure5D_FoodMatrix_feature_enrichment", feat_df)
    feat_long = feat_df.melt("feature", var_name="digestibility_group", value_name="prevalence")
    sns.barplot(data=feat_long, y="feature", x="prevalence", hue="digestibility_group", palette=[PALETTE["red"], PALETTE["blue"]], ax=axes[3])
    axes[3].set_xlabel("Feature prevalence")
    axes[3].set_ylabel("")
    axes[3].set_title("High-risk matrix feature enrichment")
    axes[3].legend(title="", fontsize=6.8)
    axes[3].tick_params(axis="y", labelsize=6.5)
    clean(axes[3], "x")
    label(axes[3], "D")

    cf = counter[counter["target"].eq("iauc_2h")].copy().sort_values("mean_predicted_reduction", ascending=False).head(8)
    sns.barplot(data=cf, y="scenario_label", x="mean_predicted_reduction", color=PALETTE["green"], ax=axes[4])
    axes[4].set_xlabel("Mean predicted reduction (mg/dL*min)")
    axes[4].set_ylabel("")
    axes[4].set_title("Counterfactual meal redesign")
    axes[4].tick_params(axis="y", labelsize=6.6)
    clean(axes[4], "x")
    label(axes[4], "E")

    matrix = ann.assign(
        high_iAUC=pd.qcut(ann["iauc_2h"], 4, labels=["Q1", "Q2", "Q3", "Q4"], duplicates="drop"),
        high_digest=pd.qcut(ann["digestibility_risk_score"], 4, labels=["Q1", "Q2", "Q3", "Q4"], duplicates="drop"),
    )
    cross = pd.crosstab(matrix["high_digest"], matrix["msi_core_tertile_within_dataset"], values=matrix["iauc_2h"], aggfunc="median")
    cross = cross.reindex(columns=["low", "middle", "high"])
    sns.heatmap(cross, cmap="YlGnBu", annot=True, fmt=".0f", linewidths=0.35, cbar_kws={"label": "Median iAUC"}, ax=axes[5])
    axes[5].set_xlabel("MSI tertile")
    axes[5].set_ylabel("Digestibility-risk quartile")
    axes[5].set_title("Person-by-matrix risk strata")
    label(axes[5], "F")

    return save_figure(fig, "MainFigure5_FoodMatrix_Interaction", "main")


def figure6_curve_phenotypes(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    features = data["curve_features"].copy()
    clusters = data["curve_clusters"].copy()
    models = data["curve_models"].copy()
    source("MainFigure6A_Curve_features", features)
    source("MainFigure6B_Curve_clusters", clusters)
    source("MainFigure6C_Curve_models", models)

    fig = plt.figure(figsize=(11.7, 8.8), constrained_layout=True)
    gs = fig.add_gridspec(2, 3, width_ratios=[1.05, 1.0, 1.1], height_ratios=[1.0, 1.05])
    ax_a = fig.add_subplot(gs[0, 0])
    ax_b = fig.add_subplot(gs[0, 1])
    ax_c = fig.add_subplot(gs[0, 2])
    ax_d = fig.add_subplot(gs[1, :2])
    ax_e = fig.add_subplot(gs[1, 2])

    cl = clusters.copy()
    cl["cluster"] = cl["shape_cluster_label"].astype(str) + " (" + cl["shape_cluster_id"].astype(str) + ")"
    feat_cols = ["mean_iauc_2h", "mean_peak_delta_2h", "mean_time_to_peak", "mean_recovery_time", "mean_msi", "mean_digestibility"]
    heat = cl.set_index("cluster")[feat_cols].apply(zscore_series, axis=0)
    heat.columns = ["iAUC", "Peak", "Time to peak", "Recovery", "MSI", "Digestibility"]
    sns.heatmap(heat, cmap="vlag", center=0, annot=True, fmt=".1f", linewidths=0.35, cbar_kws={"label": "z"}, ax=ax_a)
    ax_a.set_title("Feature-derived curve clusters")
    ax_a.set_xlabel("")
    ax_a.set_ylabel("")
    ax_a.tick_params(labelsize=6.4)
    label(ax_a, "A")

    comp = pd.crosstab(features["shape_cluster_label"], features["msi_core_tertile_within_dataset"], normalize="index").reindex(columns=["low", "middle", "high"])
    comp.plot(kind="bar", stacked=True, color=[TERTILE_COLORS["low"], TERTILE_COLORS["middle"], TERTILE_COLORS["high"]], ax=ax_b, width=0.78)
    ax_b.set_ylabel("Meal share")
    ax_b.set_xlabel("")
    ax_b.set_title("Cluster composition by MSI")
    ax_b.legend(title="MSI", fontsize=6.8, title_fontsize=6.8)
    ax_b.tick_params(axis="x", labelrotation=35, labelsize=6.5)
    clean(ax_b)
    label(ax_b, "B")

    mf = models[models["term"].isin(["msi_centered", "digestibility_centered", "msi_x_digestibility"])].copy()
    mf = mf[mf["outcome"].isin(["delayed_peak_flag", "prolonged_elevation_flag", "high_iAUC_moderate_peak_flag", "high_peak_fast_recovery_flag"])]
    mf["label"] = mf["outcome"].map(outcome_label) + " | " + mf["term"].map(term_label)
    mf["color"] = mf["term"].map({"msi_centered": PALETTE["orange"], "digestibility_centered": PALETTE["teal"], "msi_x_digestibility": PALETTE["purple"]})
    draw_forest(ax_c, mf, "estimate", "ci_low", "ci_high", "label", "color", "q_value", "Coefficient")
    ax_c.set_title("Dynamic phenotype models")
    label(ax_c, "C")

    t = np.linspace(0, 180, 181)
    source_rows = []
    for _, row in cl.iterrows():
        peak = max(float(row.get("mean_peak_delta_2h", 1)), 1)
        tpeak = max(float(row.get("mean_time_to_peak", 45)), 5)
        recovery = max(float(row.get("mean_recovery_time", 90)), tpeak + 5)
        curve = peak * (t / tpeak) * np.exp(1 - t / tpeak)
        curve[t > recovery] *= np.exp(-(t[t > recovery] - recovery) / 35)
        ax_d.plot(t, curve, lw=1.8, label=row["cluster"])
        source_rows.extend([{"cluster": row["cluster"], "minute": minute, "feature_derived_delta": val} for minute, val in zip(t, curve)])
    source("MainFigure6D_Feature_derived_prototype_curves", pd.DataFrame(source_rows))
    ax_d.set_xlabel("Minutes after meal")
    ax_d.set_ylabel("Feature-derived glucose delta")
    ax_d.set_title("Prototype response curves from cluster summaries")
    ax_d.legend(fontsize=6.4, ncol=2)
    clean(ax_d)
    label(ax_d, "D")

    risk = features.assign(
        digest_q=pd.qcut(features["digestibility_risk_score"], 3, labels=["low", "mid", "high"], duplicates="drop")
    )
    risk_tab = pd.crosstab(risk["digest_q"], risk["shape_cluster_label"], normalize="index")
    sns.heatmap(risk_tab, cmap="YlOrRd", annot=True, fmt=".2f", linewidths=0.35, cbar_kws={"label": "Meal share"}, ax=ax_e)
    ax_e.set_xlabel("Curve cluster")
    ax_e.set_ylabel("Digestibility tertile")
    ax_e.set_title("Food-matrix to curve phenotype")
    ax_e.tick_params(axis="x", labelrotation=45, labelsize=6.2)
    label(ax_e, "E")

    return save_figure(fig, "MainFigure6_Dynamic_CGM_Phenotypes", "main")


def figure7_prediction(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    records = data["prediction_records"].copy()
    perf = data["prediction_perf"].copy()
    delta = data["prediction_delta"].copy()
    cal = data["calibration"].copy()
    conf = data["conformal"].copy()
    by_msi = data["performance_msi"].copy()
    source("MainFigure7A_Prediction_records", records)
    source("MainFigure7C_Model_performance", perf)
    source("MainFigure7D_Calibration", cal)
    source("MainFigure7E_Conformal", conf)
    source("MainFigure7F_Performance_by_MSI", by_msi)

    fig = plt.figure(figsize=(12.0, 9.4), constrained_layout=True)
    gs = fig.add_gridspec(3, 2)
    axes = [fig.add_subplot(gs[i, j]) for i in range(3) for j in range(2)]

    for ax, target, lab in [(axes[0], "iauc_2h", "A"), (axes[1], "peak_delta_2h", "B")]:
        df = records[(records["model"].eq("M3_msi_enhanced")) & (records["target"].eq(target))].copy()
        sample = df.sample(min(len(df), 2500), random_state=26) if len(df) > 2500 else df
        ax.scatter(sample["y_pred"], sample["y_true"], s=9, alpha=0.28, color=PALETTE["blue"], edgecolor="none")
        lim = [min(df["y_pred"].min(), df["y_true"].min()), max(df["y_pred"].max(), df["y_true"].max())]
        ax.plot(lim, lim, color="#AEB7C2", lw=1.0, ls="--")
        ax.set_xlim(lim)
        ax.set_ylim(lim)
        ax.set_xlabel("Predicted")
        ax.set_ylabel("Observed")
        ax.set_title(f"Observed vs predicted {target.replace('_', ' ')}")
        clean(ax)
        label(ax, lab)

    perf_i = perf[perf["target"].eq("iauc_2h")].copy()
    perf_i["Model"] = perf_i["model"].map(model_label)
    x = np.arange(len(perf_i))
    axes[2].bar(x, perf_i["MAE"], color=PALETTE["gray"], width=0.58, alpha=0.88, label="MAE")
    axes[2].set_xticks(x)
    axes[2].set_xticklabels(perf_i["Model"], rotation=20, ha="right")
    axes[2].set_xlabel("")
    axes[2].set_ylabel("MAE (mg/dL*min)")
    axes[2].set_title("Nested model performance")
    ax2 = axes[2].twinx()
    ax2.plot(x, perf_i["AUC_high_response"], color=PALETTE["orange"], marker="o", lw=1.7, label="AUC")
    ax2.plot(x, perf_i["R2"], color=PALETTE["green"], marker="s", lw=1.5, label="R2")
    ax2.set_ylim(0, max(0.8, float(perf_i[["AUC_high_response", "R2"]].max().max()) * 1.15))
    ax2.set_ylabel("AUC / R2")
    handles1, labels1 = axes[2].get_legend_handles_labels()
    handles2, labels2 = ax2.get_legend_handles_labels()
    axes[2].legend(handles1 + handles2, labels1 + labels2, title="", fontsize=6.8, loc="upper right")
    clean(axes[2])
    label(axes[2], "C")

    cal_plot = cal[(cal["target"].eq("iauc_2h")) & (cal["model"].isin(["M2_macro_precgm_context", "M3_msi_enhanced"]))].copy()
    for model, group in cal_plot.groupby("model"):
        axes[3].plot(group["mean_pred"], group["mean_observed"], marker="o", lw=1.7, ms=4, label=model_label(model), color=MODEL_COLORS.get(model, PALETTE["blue"]))
    lim = [
        min(cal_plot["mean_pred"].min(), cal_plot["mean_observed"].min()),
        max(cal_plot["mean_pred"].max(), cal_plot["mean_observed"].max()),
    ]
    axes[3].plot(lim, lim, color="#AEB7C2", lw=1.0, ls="--")
    axes[3].set_xlabel("Mean predicted by decile")
    axes[3].set_ylabel("Mean observed by decile")
    axes[3].set_title("Calibration by prediction decile")
    axes[3].legend(fontsize=7.0)
    clean(axes[3])
    label(axes[3], "D")

    conf_plot = conf[conf["target"].eq("iauc_2h")].copy()
    x = np.arange(len(conf_plot))
    axes[4].bar(x - 0.18, conf_plot["coverage_q90"], width=0.36, color=PALETTE["blue"], label="q90 coverage")
    ax2 = axes[4].twinx()
    ax2.plot(x + 0.18, conf_plot["median_q90_width"], color=PALETTE["orange"], marker="o", lw=1.5, label="q90 width")
    axes[4].axhline(0.90, color="#AEB7C2", lw=0.9, ls="--")
    axes[4].set_xticks(x)
    axes[4].set_xticklabels([model_label(m) for m in conf_plot["model"]], rotation=25, ha="right")
    axes[4].set_ylim(0.75, 1.0)
    axes[4].set_ylabel("Coverage")
    ax2.set_ylabel("Median interval width")
    axes[4].set_title("Conformal interval behavior")
    clean(axes[4])
    label(axes[4], "E")

    msi_plot = by_msi[(by_msi["target"].eq("iauc_2h")) & (by_msi["model"].isin(["M2_macro_precgm_context", "M3_msi_enhanced"]))].copy()
    pivot = msi_plot.pivot_table(index="msi_tertile", columns="model", values="MAE", aggfunc="mean").reindex(["low", "middle", "high"])
    sns.heatmap(pivot, cmap="YlOrRd_r", annot=True, fmt=".0f", linewidths=0.35, cbar_kws={"label": "MAE"}, ax=axes[5])
    axes[5].set_xlabel("Model")
    axes[5].set_ylabel("MSI tertile")
    axes[5].set_xticklabels([model_label(t.get_text()) for t in axes[5].get_xticklabels()], rotation=20, ha="right")
    axes[5].set_title("Performance by susceptibility stratum")
    label(axes[5], "F")

    source("MainFigure7_Deltas", delta)
    return save_figure(fig, "MainFigure7_Prediction_Calibration", "main")


def figure8_external(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    ext = data["external_boundary"].copy()
    shift = data["external_shift"].copy()
    t1d = data["t1d_models"].copy()
    stan = data["stanford_summary"].copy()
    jaeb = data["jaeb"].copy()
    emap = data["external_map"].copy()
    source("MainFigure8A_External_boundary", ext)
    source("MainFigure8B_Domain_shift", shift)
    source("MainFigure8C_T1D_macro_models", t1d)
    source("MainFigure8D_Stanford_food_summary", stan)
    source("MainFigure8E_Jaeb_summary", jaeb)
    source("MainFigure8F_Transportability_map", emap)

    fig = plt.figure(figsize=(12.0, 9.2), constrained_layout=True)
    gs = fig.add_gridspec(3, 2)
    axes = [fig.add_subplot(gs[i, j]) for i in range(3) for j in range(2)]

    ext["dataset_label"] = ext["dataset"].map(dataset_label)
    sns.barplot(data=ext, x="dataset_label", y="median_iauc_2h", color=PALETTE["blue"], ax=axes[0])
    axes[0].set_ylabel("Median 2-h iAUC")
    axes[0].set_xlabel("")
    axes[0].set_title("Response scale across CGM datasets")
    axes[0].tick_params(axis="x", rotation=20)
    clean(axes[0])
    label(axes[0], "A")

    shift_plot = shift.copy()
    shift_plot["dataset_label"] = shift_plot["dataset"].map(dataset_label)
    sns.barplot(data=shift_plot, x="dataset_label", y="ratio_median_iauc_vs_CGMacros", color=PALETTE["orange"], ax=axes[1])
    axes[1].axhline(1, color="#AEB7C2", lw=0.9, ls="--")
    axes[1].set_ylabel("Median iAUC ratio vs CGMacros")
    axes[1].set_xlabel("")
    axes[1].set_title("Transportability response ratio")
    axes[1].tick_params(axis="x", rotation=20)
    clean(axes[1])
    label(axes[1], "B")

    tf = t1d[t1d["term"].isin(["carbs_10g", "protein_10g", "fat_10g", "fiber_5g"]) & t1d["outcome"].eq("iauc_2h_per1000")].copy()
    tf["label"] = tf["term"].map(term_label)
    tf["color"] = tf["term"].map({"carbs_10g": PALETTE["gray"], "protein_10g": PALETTE["green"], "fat_10g": PALETTE["yellow"], "fiber_5g": PALETTE["blue"]})
    draw_forest(axes[2], tf, "estimate", "ci_low", "ci_high", "label", "color", None, "T1D coefficient")
    axes[2].set_title("T1D macro directionality boundary")
    label(axes[2], "C")

    st = stan.sort_values("cv_iauc_2h", ascending=False).head(8)
    sns.barplot(data=st, y="food", x="cv_iauc_2h", color=PALETTE["purple"], ax=axes[3])
    axes[3].set_xlabel("Coefficient of variation, iAUC")
    axes[3].set_ylabel("")
    axes[3].set_title("Stanford same-food heterogeneity")
    clean(axes[3], "x")
    label(axes[3], "D")

    axes[4].hist(jaeb["time_above_140"], bins=25, color=PALETTE["teal"], alpha=0.88, edgecolor="white")
    axes[4].axvline(jaeb["time_above_140"].median(), color=PALETTE["dark"], lw=1.1)
    axes[4].set_xlabel("Time above 140 mg/dL")
    axes[4].set_ylabel("Healthy adults")
    axes[4].set_title("Jaeb healthy-adult reference boundary")
    clean(axes[4])
    label(axes[4], "E")

    evidence = emap[["dataset", "role", "paper_interpretation"]].copy()
    evidence["dataset"] = evidence["dataset"].map(dataset_label)
    evidence["role"] = evidence["role"].map(lambda x: compact_name(x, 40))
    evidence["paper_interpretation"] = evidence["paper_interpretation"].map(lambda x: compact_name(x, 38))
    draw_mini_table(axes[5], evidence, "Evidence map for generalization", font_size=6.3)
    label(axes[5], "F")

    return save_figure(fig, "MainFigure8_External_Transportability", "main")


def figure9_mechanism(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    edges = data["mechanism_edges"].copy()
    pathway = data["pathway"].copy()
    ev = data["evidence_map"].copy()
    gap = data["evidence_gap"].copy()
    source("MainFigure9A_Mechanism_edges", edges)
    source("MainFigure9B_Pathway_enrichment", pathway)
    source("MainFigure9C_Evidence_map", ev)
    source("MainFigure9D_Evidence_gaps", gap)

    fig = plt.figure(figsize=(11.6, 8.2), constrained_layout=True)
    gs = fig.add_gridspec(2, 2, width_ratios=[1.25, 1.0])
    ax_a = fig.add_subplot(gs[:, 0])
    ax_b = fig.add_subplot(gs[0, 1])
    ax_c = fig.add_subplot(gs[1, 1])

    ax_a.axis("off")
    top_edges = edges.groupby(["source_node", "target_node", "target_pathway", "confidence_tier"]).size().reset_index(name="n").head(28)
    pathways = pathway.sort_values("n_edges", ascending=False)["target_pathway"].head(6).tolist()
    pathway_pos = {p: (0.78, 0.15 + i * 0.14) for i, p in enumerate(pathways)}
    gene_nodes = top_edges["target_node"].drop_duplicates().head(16).tolist()
    gene_pos = {g: (0.38 + 0.2 * (i % 2), 0.12 + 0.1 * (i // 2)) for i, g in enumerate(gene_nodes)}
    ax_a.text(0.08, 0.52, "DEHP", ha="center", va="center", fontsize=12, fontweight="bold", color="white", bbox=dict(boxstyle="round,pad=0.45", fc=PALETTE["red"], ec="none"), transform=ax_a.transAxes)
    for g, (x, y) in gene_pos.items():
        ax_a.text(x, y, g, ha="center", va="center", fontsize=7.4, bbox=dict(boxstyle="round,pad=0.2", fc="white", ec=PALETTE["blue"], lw=1.0), transform=ax_a.transAxes)
        ax_a.annotate("", xy=(x - 0.055, y), xytext=(0.14, 0.52), xycoords=ax_a.transAxes, arrowprops=dict(arrowstyle="-", color="#B5BDC7", lw=0.7, alpha=0.8))
    for p, (x, y) in pathway_pos.items():
        ax_a.text(x, y, p.replace("_", " "), ha="center", va="center", fontsize=7.8, bbox=dict(boxstyle="round,pad=0.25", fc="#F6F8FB", ec=PALETTE["green"], lw=1.0), transform=ax_a.transAxes)
    for _, row in top_edges.iterrows():
        if row["target_node"] in gene_pos and row["target_pathway"] in pathway_pos:
            gx, gy = gene_pos[row["target_node"]]
            px, py = pathway_pos[row["target_pathway"]]
            ax_a.annotate("", xy=(px - 0.08, py), xytext=(gx + 0.055, gy), xycoords=ax_a.transAxes, arrowprops=dict(arrowstyle="-", color="#C9CED6", lw=0.6, alpha=0.75))
    ax_a.set_title("Curated mechanism knowledge graph", loc="left", fontsize=9.5)
    label(ax_a, "A", x=0.0, y=1.0)

    py = pathway.sort_values("n_edges", ascending=True)
    ax_b.barh(py["target_pathway"].str.replace("_", " "), py["n_edges"], color=PALETTE["green"], alpha=0.88, label="all edges")
    ax_b.scatter(py["higher_confidence_edges"], py["target_pathway"].str.replace("_", " "), color=PALETTE["orange"], s=34, label="higher confidence")
    ax_b.set_xlabel("Curated edges")
    ax_b.set_ylabel("")
    ax_b.set_title("Pathway support")
    ax_b.legend(fontsize=6.8)
    clean(ax_b, "x")
    label(ax_b, "B")

    ev_counts = ev["domain"].value_counts().sort_values().reset_index()
    ev_counts.columns = ["domain", "records"]
    ev_counts["domain"] = ev_counts["domain"].str.replace("_", " ", regex=False)
    sns.barplot(data=ev_counts, y="domain", x="records", color=PALETTE["blue"], ax=ax_c)
    ax_c.set_title("Literature evidence domains")
    ax_c.set_xlabel("Curated records")
    ax_c.set_ylabel("")
    ax_c.tick_params(axis="y", labelsize=7.0)
    clean(ax_c, "x")
    label(ax_c, "C")

    return save_figure(fig, "MainFigure9_Mechanistic_Plausibility", "main")


def extended_figures(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    records: List[Dict[str, object]] = []
    records += extended_1_dataset_flow(data)
    records += extended_2_weighted_table1(data)
    records += extended_3_reproducibility(data)
    records += extended_4_effect_mod(data)
    records += extended_5_sensitivity(data)
    records += extended_6_mixture(data)
    records += extended_7_msi(data)
    records += extended_8_threshold(data)
    records += extended_9_bootstrap_influence(data)
    records += extended_10_food_annotation(data)
    records += extended_11_counterfactual(data)
    records += extended_12_prediction_audit(data)
    records += extended_13_conformal(data)
    records += extended_14_external_shift(data)
    records += extended_15_mechanism(data)
    records += extended_16_reproducibility_map(data)
    return records


def extended_1_dataset_flow(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    table1 = data["table1"].copy()
    manifest = data["analysis_manifest"].copy()
    source("EDFigure1_Dataset_flow", table1)
    fig, axes = plt.subplots(1, 2, figsize=(10.2, 4.6), constrained_layout=True)
    table1["dataset_label"] = table1["dataset"].map(dataset_label)
    y = np.arange(len(table1))
    axes[0].barh(y, table1["n_subjects_or_participants"], color=PALETTE["blue"])
    axes[0].set_yticks(y)
    axes[0].set_yticklabels(table1["dataset_label"], fontsize=7.5)
    axes[0].set_xscale("symlog", linthresh=10)
    axes[0].set_title("Participants")
    clean(axes[0], "x")
    label(axes[0], "A")
    mod = manifest["module"].value_counts().head(12).reset_index()
    mod.columns = ["module", "files"]
    sns.barplot(data=mod, y="module", x="files", color=PALETTE["teal"], ax=axes[1])
    axes[1].set_ylabel("")
    axes[1].set_title("Reproducible module outputs")
    axes[1].tick_params(axis="y", labelsize=6.2)
    clean(axes[1], "x")
    label(axes[1], "B")
    return save_figure(fig, "EDFigure1_DatasetFlow", "extended")


def extended_2_weighted_table1(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    df = data["weighted_table1"].copy()
    source("EDFigure2_Weighted_Table1", df)
    plot = df[df["statistic"].eq("weighted_mean")].pivot_table(index="variable", columns="quartile", values="value", aggfunc="mean")
    plot_z = plot.apply(zscore_series, axis=1)
    fig, ax = plt.subplots(figsize=(7.2, 5.8), constrained_layout=True)
    sns.heatmap(plot_z, cmap="vlag", center=0, annot=plot.round(2), fmt="", linewidths=0.35, cbar_kws={"label": "row z"}, ax=ax)
    ax.set_title("NHANES weighted descriptive profile by oxidative quartile")
    ax.set_xlabel("Oxidative quartile")
    ax.set_ylabel("")
    ax.tick_params(labelsize=7.2)
    label(ax, "A", x=-0.08)
    return save_figure(fig, "EDFigure2_NHANES_Table1_by_Quartile", "extended")


def extended_3_reproducibility(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    df = data["r_vs_python"].copy()
    source("EDFigure3_R_vs_Python", df)
    fig, axes = plt.subplots(1, 2, figsize=(9.6, 4.5), constrained_layout=True)
    axes[0].scatter(df["python_beta"], df["R_beta"], s=28, color=PALETTE["blue"], alpha=0.8, edgecolor="white", linewidth=0.4)
    lim = [min(df["python_beta"].min(), df["R_beta"].min()), max(df["python_beta"].max(), df["R_beta"].max())]
    axes[0].plot(lim, lim, color="#AEB7C2", ls="--", lw=1)
    axes[0].set_xlabel("Python beta")
    axes[0].set_ylabel("R survey beta")
    axes[0].set_title("R vs Python estimate agreement")
    clean(axes[0])
    label(axes[0], "A")
    axes[1].hist(df["beta_delta_R_minus_python"], bins=16, color=PALETTE["orange"], edgecolor="white")
    axes[1].axvline(0, color="#AEB7C2", lw=1)
    axes[1].set_xlabel("R beta minus Python beta")
    axes[1].set_ylabel("Models")
    axes[1].set_title("Numerical delta distribution")
    clean(axes[1])
    label(axes[1], "B")
    return save_figure(fig, "EDFigure3_NHANES_Reproducibility", "extended")


def extended_4_effect_mod(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    df = data["nhanes_effect_mod"].copy()
    source("EDFigure4_Effect_Modification", df)
    df = df[df["term"].eq("ln_oxidative_to_MEHP")]
    df["row"] = df["subgroup_variable"].astype(str) + ": " + df["subgroup_level"].astype(str)
    pivot = df.pivot_table(index="row", columns="outcome_label", values="estimate", aggfunc="mean")
    fig, ax = plt.subplots(figsize=(8.8, 7.4), constrained_layout=True)
    sns.heatmap(pivot, cmap="vlag", center=0, annot=True, fmt=".2f", linewidths=0.35, cbar_kws={"label": "beta"}, ax=ax)
    ax.set_title("NHANES effect-modification screen")
    ax.set_xlabel("")
    ax.set_ylabel("")
    ax.tick_params(labelsize=6.8)
    label(ax, "A", x=-0.08)
    return save_figure(fig, "EDFigure4_NHANES_EffectModification", "extended")


def extended_5_sensitivity(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    df = data["nhanes_sensitivity"].copy()
    source("EDFigure5_NHANES_Sensitivity", df)
    df["label"] = df["model"].astype(str) + " | " + df["outcome_label"].astype(str) + " | " + df["term"].map(term_label)
    df["color"] = df["model"].map({"primary": PALETTE["blue"], "negative_control_like": PALETTE["gray"]}).fillna(PALETTE["teal"])
    fig, ax = plt.subplots(figsize=(8.5, 7.5), constrained_layout=True)
    draw_forest(ax, df.head(22), "estimate", "ci_low", "ci_high", "label", "color", "q_value", "Sensitivity beta")
    ax.set_title("Sensitivity and negative-control-like analyses")
    label(ax, "A", x=-0.08)
    return save_figure(fig, "EDFigure5_NHANES_Sensitivity", "extended")


def extended_6_mixture(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    df = data["nhanes_mixture"].copy()
    source("EDFigure6_DEHP_Mixture", df)
    df = df[df["term"].isin(["ln_Sigma_DEHP", "pct_oxidative_10", "ln_oxidative_to_MEHP"])].copy()
    df["label"] = df["outcome_label"].astype(str) + " | " + df["term"].map(term_label)
    df["color"] = df["term"].map({"ln_Sigma_DEHP": PALETTE["gray"], "pct_oxidative_10": PALETTE["orange"], "ln_oxidative_to_MEHP": PALETTE["blue"]})
    fig, ax = plt.subplots(figsize=(8.0, 7.5), constrained_layout=True)
    draw_forest(ax, df, "estimate", "ci_low", "ci_high", "label", "color", "q_value", "Joint proxy beta")
    ax.set_title("DEHP mixture/composition proxy results")
    label(ax, "A", x=-0.08)
    return save_figure(fig, "EDFigure6_DEHP_MixtureProxy", "extended")


def extended_7_msi(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    missing = data["msi_missing"].copy()
    corr = data["msi_corr"].copy()
    source("EDFigure7_MSI_Missingness", missing)
    source("EDFigure7_MSI_Correlations", corr)
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 5.0), constrained_layout=True)
    missing["component_label"] = missing["component"].str.replace("_", " ")
    sns.barplot(data=missing, y="component_label", x="pct_nonmissing", hue="dataset", palette=[PALETTE["blue"], PALETTE["orange"]], ax=axes[0])
    axes[0].set_xlim(0, 105)
    axes[0].set_xlabel("Nonmissing (%)")
    axes[0].set_ylabel("")
    axes[0].set_title("Component availability")
    axes[0].legend(title="", fontsize=6.8)
    clean(axes[0], "x")
    label(axes[0], "A")
    c = corr.pivot_table(index="msi_a", columns="msi_b", values="spearman", aggfunc="mean")
    names = sorted(set(c.index).union(c.columns))
    c = c.reindex(index=names, columns=names)
    for name in names:
        c.loc[name, name] = 1
    sns.heatmap(c, vmin=0.75, vmax=1.0, cmap="YlGnBu", annot=True, fmt=".2f", ax=axes[1], cbar_kws={"label": "Spearman r"})
    axes[1].set_title("MSI version correlations")
    axes[1].tick_params(labelsize=6.1)
    label(axes[1], "B")
    return save_figure(fig, "EDFigure7_MSI_Robustness", "extended")


def extended_8_threshold(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    df = data["cg_threshold"].copy()
    source("EDFigure8_High_Response_Sensitivity", df)
    fig, ax = plt.subplots(figsize=(8.0, 4.8), constrained_layout=True)
    sns.barplot(data=df, x="definition", y="high_rate", hue="msi_tertile", palette=TERTILE_COLORS, ax=ax)
    ax.set_ylabel("High-response rate")
    ax.set_xlabel("")
    ax.set_title("High-response threshold sensitivity")
    ax.tick_params(axis="x", rotation=25, labelsize=6.8)
    ax.legend(title="MSI", fontsize=7.0)
    clean(ax)
    label(ax, "A", x=-0.08)
    return save_figure(fig, "EDFigure8_HighResponse_Sensitivity", "extended")


def extended_9_bootstrap_influence(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    boot = data["cg_bootstrap"].copy()
    influence = data["cg_influence"].copy()
    source("EDFigure9_Bootstrap", boot)
    source("EDFigure9_Influence", influence)
    fig, axes = plt.subplots(1, 2, figsize=(10.8, 5.0), constrained_layout=True)
    b = boot[boot["term"].isin(["msi_centered", "load_x_msi"])].copy()
    b["label"] = b["outcome"].map(outcome_label) + " | " + b["term"].map(term_label)
    b["color"] = b["term"].map({"msi_centered": PALETTE["orange"], "load_x_msi": PALETTE["purple"]})
    draw_forest(axes[0], b, "boot_mean", "boot_ci_low", "boot_ci_high", "label", "color", None, "Bootstrap mean")
    axes[0].set_title("Bootstrap intervals")
    label(axes[0], "A")
    inf = influence[influence["term"].isin(["msi_centered", "load_x_msi"])].copy()
    sns.boxplot(data=inf, x="term", y="estimate", hue="outcome", ax=axes[1], fliersize=1.8)
    axes[1].axhline(0, color="#AEB7C2", lw=0.8)
    axes[1].set_xlabel("")
    axes[1].set_ylabel("Leave-one-subject estimate")
    axes[1].set_title("Leave-one-subject influence")
    axes[1].tick_params(axis="x", labelrotation=20)
    axes[1].legend(fontsize=6.8)
    clean(axes[1])
    label(axes[1], "B")
    return save_figure(fig, "EDFigure9_Bootstrap_Influence", "extended")


def extended_10_food_annotation(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    ann = data["food_annotation"].copy()
    source("EDFigure10_Food_Annotation", ann)
    fig, axes = plt.subplots(1, 2, figsize=(10.4, 5.0), constrained_layout=True)
    feature_cols = [c for c in ann.columns if c.endswith("_proxy") or c.endswith("_matrix")]
    prevalence = ann[feature_cols].mean(numeric_only=True).sort_values(ascending=False).head(12).reset_index()
    prevalence.columns = ["feature", "prevalence"]
    prevalence["feature"] = prevalence["feature"].str.replace("_proxy", "", regex=False).str.replace("_matrix", "", regex=False).str.replace("_", " ")
    sns.barplot(data=prevalence, y="feature", x="prevalence", color=PALETTE["teal"], ax=axes[0])
    axes[0].set_xlabel("Prevalence")
    axes[0].set_ylabel("")
    axes[0].set_title("Food-matrix feature prevalence")
    clean(axes[0], "x")
    label(axes[0], "A")
    sns.scatterplot(data=ann, x="glycemic_load_proxy", y="digestibility_risk_score", hue="estimated_NOVA_proxy", palette="viridis", s=17, alpha=0.65, ax=axes[1])
    axes[1].set_title("Annotation consistency screen")
    axes[1].set_xlabel("Glycemic load proxy")
    axes[1].set_ylabel("Digestibility-risk proxy")
    axes[1].legend(title="NOVA proxy", fontsize=6.5, title_fontsize=6.5)
    clean(axes[1])
    label(axes[1], "B")
    return save_figure(fig, "EDFigure10_FoodMatrix_Annotation", "extended")


def extended_11_counterfactual(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    df = data["counterfactual"].copy()
    subj = data["counter_subject"].copy()
    source("EDFigure11_Counterfactual", df)
    source("EDFigure11_Counterfactual_Subjects", subj)
    fig, axes = plt.subplots(1, 2, figsize=(10.8, 5.0), constrained_layout=True)
    plot = df[df["target"].eq("iauc_2h")].sort_values("mean_predicted_reduction", ascending=False)
    sns.barplot(data=plot, y="scenario_label", x="mean_predicted_reduction", color=PALETTE["green"], ax=axes[0])
    axes[0].set_xlabel("Mean predicted reduction")
    axes[0].set_ylabel("")
    axes[0].set_title("Scenario-level mean effect")
    axes[0].tick_params(axis="y", labelsize=6.8)
    clean(axes[0], "x")
    label(axes[0], "A")
    s = subj[subj["target"].eq("iauc_2h")]
    sns.boxplot(data=s, y="scenario_label", x="mean_predicted_reduction", color="#DCE7F2", fliersize=1.5, ax=axes[1])
    axes[1].set_xlabel("Subject mean predicted reduction")
    axes[1].set_ylabel("")
    axes[1].set_title("Subject-level heterogeneity")
    axes[1].tick_params(axis="y", labelsize=6.5)
    clean(axes[1], "x")
    label(axes[1], "B")
    return save_figure(fig, "EDFigure11_Counterfactual_Meal_Redesign", "extended")


def extended_12_prediction_audit(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    leak = data["leakage"].copy()
    pred = data["predictors"].copy()
    source("EDFigure12_Leakage_Audit", leak)
    source("EDFigure12_Predictor_Dictionary", pred)
    fig, axes = plt.subplots(1, 2, figsize=(10.2, 4.8), constrained_layout=True)
    counts = leak["reason"].value_counts().reset_index()
    counts.columns = ["reason", "columns"]
    sns.barplot(data=counts, y="reason", x="columns", color=PALETTE["red"], ax=axes[0])
    axes[0].set_xlabel("Columns flagged")
    axes[0].set_ylabel("")
    axes[0].set_title("Leakage audit")
    clean(axes[0], "x")
    label(axes[0], "A")
    pcount = pred.groupby(["feature_set", "type"]).size().reset_index(name="n")
    pivot = pcount.pivot_table(index="feature_set", columns="type", values="n", fill_value=0)
    pivot.plot(kind="bar", stacked=True, ax=axes[1], color=[PALETTE["blue"], PALETTE["orange"], PALETTE["green"], PALETTE["purple"]])
    axes[1].set_xlabel("")
    axes[1].set_ylabel("Predictor count")
    axes[1].set_title("Predictor dictionary composition")
    axes[1].tick_params(axis="x", labelrotation=25, labelsize=6.6)
    axes[1].legend(fontsize=6.6)
    clean(axes[1])
    label(axes[1], "B")
    return save_figure(fig, "EDFigure12_Prediction_Audit", "extended")


def extended_13_conformal(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    conf = data["conformal"].copy()
    perf = data["prediction_perf"].copy()
    source("EDFigure13_Conformal", conf)
    source("EDFigure13_Performance", perf)
    fig, axes = plt.subplots(1, 2, figsize=(10.6, 4.9), constrained_layout=True)
    sns.barplot(data=conf, x="model", y="coverage_q95", hue="target_label", palette=[PALETTE["blue"], PALETTE["orange"]], ax=axes[0])
    axes[0].axhline(0.95, color="#AEB7C2", lw=0.9, ls="--")
    axes[0].set_ylim(0.8, 1.0)
    axes[0].set_xlabel("")
    axes[0].set_ylabel("q95 coverage")
    axes[0].set_title("Conformal coverage")
    axes[0].tick_params(axis="x", rotation=25, labelsize=6.3)
    axes[0].legend(fontsize=6.8)
    clean(axes[0])
    label(axes[0], "A")
    sns.scatterplot(data=perf, x="AUC_high_response", y="net_benefit_pt25", hue="model", style="target_label", palette=MODEL_COLORS, s=45, ax=axes[1])
    axes[1].set_xlabel("AUC high response")
    axes[1].set_ylabel("Net benefit, pt=0.25")
    axes[1].set_title("Decision-oriented performance")
    axes[1].legend(fontsize=6.3, bbox_to_anchor=(1.01, 1), loc="upper left")
    clean(axes[1])
    label(axes[1], "B")
    return save_figure(fig, "EDFigure13_Prediction_Conformal_NetBenefit", "extended")


def extended_14_external_shift(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    shift = data["external_shift"].copy()
    ext = data["external_boundary"].copy()
    source("EDFigure14_Domain_Shift", shift)
    source("EDFigure14_External_Boundary", ext)
    fig, axes = plt.subplots(1, 2, figsize=(10.6, 4.9), constrained_layout=True)
    shift["dataset"] = shift["dataset"].map(dataset_label)
    metrics = shift.set_index("dataset")[["ratio_median_iauc_vs_CGMacros", "ratio_median_peak_vs_CGMacros", "feature_response_corr_iauc", "feature_response_corr_peak"]]
    sns.heatmap(metrics, cmap="vlag", center=1, annot=True, fmt=".2f", linewidths=0.35, cbar_kws={"label": "metric"}, ax=axes[0])
    axes[0].set_title("External domain-shift diagnostics")
    axes[0].set_xlabel("")
    axes[0].set_ylabel("")
    axes[0].tick_params(labelsize=6.6)
    label(axes[0], "A")
    ext["dataset"] = ext["dataset"].map(dataset_label)
    sns.scatterplot(data=ext, x="median_iauc_2h", y="median_peak_delta_2h", size="n_events", hue="dataset", s=80, ax=axes[1])
    axes[1].set_xlabel("Median iAUC")
    axes[1].set_ylabel("Median peak delta")
    axes[1].set_title("Response-scale map")
    axes[1].legend(fontsize=6.3)
    clean(axes[1])
    label(axes[1], "B")
    return save_figure(fig, "EDFigure14_External_DomainShift", "extended")


def extended_15_mechanism(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    edges = data["mechanism_edges"].copy()
    pathway = data["pathway"].copy()
    source("EDFigure15_Mechanism_Edges", edges)
    source("EDFigure15_Pathways", pathway)
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 5.0), constrained_layout=True)
    counts = edges["target_pathway"].value_counts().reset_index()
    counts.columns = ["pathway", "edges"]
    sns.barplot(data=counts, y="pathway", x="edges", color=PALETTE["green"], ax=axes[0])
    axes[0].set_xlabel("Curated edges")
    axes[0].set_ylabel("")
    axes[0].set_title("Mechanism edge distribution")
    clean(axes[0], "x")
    label(axes[0], "A")
    conf = pd.crosstab(edges["target_pathway"], edges["confidence_tier"])
    sns.heatmap(conf, cmap="YlGnBu", annot=True, fmt="d", linewidths=0.35, cbar=False, ax=axes[1])
    axes[1].set_title("Confidence tier by pathway")
    axes[1].set_xlabel("")
    axes[1].set_ylabel("")
    axes[1].tick_params(labelsize=6.8)
    label(axes[1], "B")
    return save_figure(fig, "EDFigure15_Mechanism_KG_Pathways", "extended")


def extended_16_reproducibility_map(data: Dict[str, pd.DataFrame]) -> List[Dict[str, object]]:
    manifest = data["analysis_manifest"].copy()
    display_map = data["display_map"].copy()
    source("EDFigure16_Analysis_Manifest", manifest)
    source("EDFigure16_Display_Source_Map", display_map)
    fig, axes = plt.subplots(1, 2, figsize=(11.0, 5.2), constrained_layout=True)
    modules = manifest["module"].value_counts().head(15).reset_index()
    modules.columns = ["module", "files"]
    sns.barplot(data=modules, y="module", x="files", color=PALETTE["blue"], ax=axes[0])
    axes[0].set_xlabel("Files")
    axes[0].set_ylabel("")
    axes[0].set_title("Reproducibility manifest")
    axes[0].tick_params(axis="y", labelsize=6.2)
    clean(axes[0], "x")
    label(axes[0], "A")
    if not display_map.empty:
        source_col = next(
            (col for col in ["source_file", "source_data", "relative_path", "source_table"] if col in display_map.columns),
            None,
        )
        if source_col:
            count = display_map[source_col].value_counts().head(14).reset_index()
            count.columns = ["source_file", "display_links"]
        else:
            count = pd.DataFrame({"source_file": [], "display_links": []})
    else:
        count = pd.DataFrame({"source_file": [], "display_links": []})
    sns.barplot(data=count, y="source_file", x="display_links", color=PALETTE["orange"], ax=axes[1])
    axes[1].set_xlabel("Display links")
    axes[1].set_ylabel("")
    axes[1].set_title("Source-data linkage density")
    axes[1].tick_params(axis="y", labelsize=5.8)
    clean(axes[1], "x")
    label(axes[1], "B")
    return save_figure(fig, "EDFigure16_SourceData_Reproducibility", "extended")


def build_tables(data: Dict[str, pd.DataFrame]) -> Tuple[List[Dict[str, object]], List[Dict[str, object]]]:
    main_records: List[Dict[str, object]] = []
    supp_records: List[Dict[str, object]] = []

    table1 = data["table1"].copy()
    ext = data["external_boundary"].copy()
    main1 = table1.rename(
        columns={
            "dataset": "Dataset",
            "role": "Analytic role",
            "n_subjects_or_participants": "Participants",
            "n_meals_or_events": "Meals/events",
            "n_msi_partial": "MSI available",
            "median_msi": "Median MSI",
            "high_tertile_n": "High MSI tertile N",
        }
    )
    for col in ["Median MSI"]:
        if col in main1.columns:
            main1[col] = pd.to_numeric(main1[col], errors="coerce").map(lambda x: f"{x:.3f}" if pd.notna(x) else "")
    write_table_pair("MainTable1_Datasets_Phenotypes", main1, TABLE_MAIN, main_records)

    main2 = data["nhanes_key"].copy()
    main2["Outcome"] = main2["outcome"].map(outcome_label)
    main2["Exposure"] = main2["exposure"].map(term_label)
    main2 = main2[["Exposure", "Outcome", "R_beta", "R_ci_low", "R_ci_high", "R_p", "R_q", "estimate_CI_for_table", "R_significant_q05"]]
    main2.columns = ["Exposure", "Outcome", "Beta", "CI low", "CI high", "P", "q", "Estimate (95% CI)", "q<0.05"]
    write_table_pair("MainTable2_NHANES_Primary_Estimates", main2, TABLE_MAIN, main_records)

    cg = data["cg_models"].copy()
    food = data["food_models"].copy()
    cg = cg[cg["term"].isin(["carbs_10g", "msi_core_centered", "carbs_x_msi"])].assign(block="CGMacros MSI-PPGR")
    food = food[food["term"].isin(["carbs_10g", "protein_10g", "fat_10g", "fiber_5g", "msi_centered", "digestibility_centered", "msi_x_digestibility"])].assign(block="Food-matrix model")
    main3 = pd.concat([cg, food], ignore_index=True, sort=False)
    main3["Outcome"] = main3["outcome"].map(outcome_label)
    main3["Term"] = main3["term"].map(term_label)
    main3 = main3[["block", "Outcome", "Term", "estimate", "ci_low", "ci_high", "p_value", "q_value", "n", "n_clusters"]]
    main3.columns = ["Model block", "Outcome", "Term", "Estimate", "CI low", "CI high", "P", "q", "Meals", "Participants/clusters"]
    write_table_pair("MainTable3_CGMacros_FoodMatrix_Models", main3, TABLE_MAIN, main_records)

    perf = data["prediction_perf"].copy()
    delta = data["prediction_delta"].copy()
    perf["Model"] = perf["model"].map(model_label)
    main4 = perf[["target_label", "Model", "n", "n_subjects", "MAE", "RMSE", "R2", "AUC_high_response", "AUPRC_high_response", "calibration_slope", "net_benefit_pt25"]].copy()
    main4.columns = ["Target", "Model", "N", "Participants", "MAE", "RMSE", "R2", "AUC", "AUPRC", "Calibration slope", "Net benefit pt25"]
    write_table_pair("MainTable4_Prediction_Performance", main4, TABLE_MAIN, main_records)

    claims = data["claims"].copy()
    guard = data["guardrails"].copy()
    guard_summary = guard[["risk", "preferred_language", "severity"]].rename(columns={"risk": "Claim", "preferred_language": "Required wording", "severity": "Caution level"})
    claims_summary = claims.rename(columns={"claim": "Claim", "figure": "Supporting display", "strength": "Evidence strength", "caution": "Caution level"})
    main5 = pd.concat(
        [
            claims_summary[["Claim", "Supporting display", "Evidence strength", "Caution level"]],
            guard_summary.assign(**{"Supporting display": "Guardrail", "Evidence strength": "wording constraint"})[
                ["Claim", "Supporting display", "Evidence strength", "Caution level"]
            ],
        ],
        ignore_index=True,
        sort=False,
    )
    write_table_pair("MainTable5_Claims_Guardrails", main5, TABLE_MAIN, main_records)

    supp_specs = [
        ("SupplementaryTable01_DataDictionary", ["data_dictionary"]),
        ("SupplementaryTable02_AnalysisRegistry_Guardrails", ["registry", "guardrails"]),
        ("SupplementaryTable03_NHANES_Weighted_Table1", ["weighted_table1"]),
        ("SupplementaryTable04_NHANES_R_Survey_Main", ["r_main"]),
        ("SupplementaryTable05_R_vs_Python", ["r_vs_python"]),
        ("SupplementaryTable06_NHANES_DoseResponse_Quartile", ["nhanes_quartile"]),
        ("SupplementaryTable07_NHANES_RCS", ["nhanes_rcs_coef", "nhanes_rcs"]),
        ("SupplementaryTable08_NHANES_EffectModification", ["nhanes_effect_mod"]),
        ("SupplementaryTable09_NHANES_Sensitivity", ["nhanes_sensitivity"]),
        ("SupplementaryTable10_DEHP_MixtureProxy", ["nhanes_mixture"]),
        ("SupplementaryTable11_MSI_Scaler_Weights_Correlations", ["msi_scaler", "msi_missing", "msi_weights", "msi_corr"]),
        ("SupplementaryTable12_CGMacros_Subject_PPGR", ["cg_subject_ppgr"]),
        ("SupplementaryTable13_CGMacros_MealLevel_Models", ["cg_models", "cg_load_variants"]),
        ("SupplementaryTable14_CGMacros_Bootstrap_Influence", ["cg_bootstrap", "cg_influence"]),
        ("SupplementaryTable15_HighResponse_Definition", ["cg_threshold"]),
        ("SupplementaryTable16_FoodMatrix_Annotation_Features", ["food_annotation"]),
        ("SupplementaryTable17_FoodMatrix_PPGR_Models", ["food_models"]),
        ("SupplementaryTable18_CGM_Curve_Features_Models", ["curve_features", "curve_models"]),
        ("SupplementaryTable19_Prediction_Performance_Calibration_Conformal", ["prediction_perf", "calibration", "conformal"]),
        ("SupplementaryTable20_Prediction_Leakage_Predictors", ["leakage", "predictors"]),
        ("SupplementaryTable21_Prediction_By_MSI", ["performance_msi"]),
        ("SupplementaryTable22_Counterfactual_Meal_Redesign", ["counterfactual", "counter_subject", "counter_subgroup"]),
        ("SupplementaryTable23_External_Transportability_Map", ["external_map", "external_boundary"]),
        ("SupplementaryTable24_External_DomainShift_Macro", ["external_shift", "external_macro", "t1d_models"]),
        ("SupplementaryTable25_Mechanism_KG_Pathways", ["mechanism_edges", "pathway"]),
        ("SupplementaryTable26_Literature_Evidence_Gaps", ["evidence_map", "evidence_gap"]),
        ("SupplementaryTable27_Reproducibility_Manifest", ["analysis_manifest"]),
        ("SupplementaryTable28_Display_SourceData_Map", ["display_map"]),
        ("SupplementaryTable29_Reviewer_Response_Matrix", ["reviewer_matrix"]),
        ("SupplementaryTable30_Production_Priority_Tracker", ["priority_tracker"]),
    ]
    for stem, keys in supp_specs:
        frames = []
        for key in keys:
            df = data.get(key, pd.DataFrame()).copy()
            if not df.empty:
                df.insert(0, "source_table", key)
                frames.append(df)
        out = pd.concat(frames, ignore_index=True, sort=False) if frames else pd.DataFrame({"source_table": keys, "note": "source not found"})
        write_table_pair(stem, out, TABLE_SUPP, supp_records, md_preview_rows=60)

    main_catalog = pd.DataFrame(main_records)
    supp_catalog = pd.DataFrame(supp_records)
    save_csv(TABLE_MAIN / "main_table_manifest.csv", main_catalog)
    save_csv(TABLE_SUPP / "supplementary_table_manifest.csv", supp_catalog)
    return main_records, supp_records


def write_table_pair(
    stem: str,
    df: pd.DataFrame,
    directory: Path,
    records: List[Dict[str, object]],
    md_preview_rows: int | None = None,
) -> None:
    csv_path = directory / f"{stem}.csv"
    md_path = directory / f"{stem}.md"
    save_csv(csv_path, df)
    md_table(md_path, df, max_rows=md_preview_rows)
    records.append(
        {
            "table": stem,
            "rows": len(df),
            "columns": len(df.columns),
            "csv_path": str(csv_path),
            "md_path": str(md_path),
            "csv_bytes": csv_path.stat().st_size,
        }
    )


def write_legends_and_readme(figure_manifest: pd.DataFrame, main_tables: List[Dict[str, object]], supp_tables: List[Dict[str, object]]) -> None:
    main_legends = [
        ("Main Figure 1", "Integrated evidence architecture and study design."),
        ("Main Figure 2", "NHANES DEHP oxidative-metabolism profile and metabolic susceptibility."),
        ("Main Figure 3", "Construction, robustness, and transfer of the metabolic susceptibility phenotype."),
        ("Main Figure 4", "MSI identifies free-living postprandial glycemic vulnerability in CGMacros."),
        ("Main Figure 5", "Person-by-food-matrix susceptibility refines carbohydrate-only interpretation."),
        ("Main Figure 6", "CGM curve phenotypes reveal prolonged and delayed response vulnerability."),
        ("Main Figure 7", "MSI-enhanced models improve personalized high-response stratification."),
        ("Main Figure 8", "External CGM datasets define transportability boundaries."),
        ("Main Figure 9", "Mechanistic plausibility map linking DEHP oxidative metabolism, MSI, and PPGR vulnerability."),
    ]
    ext_legends = [
        (f"Extended Data Figure {i}", title)
        for i, title in enumerate(
            [
                "Dataset flow, exclusions, and analytic sample construction.",
                "NHANES weighted Table 1 by DEHP oxidative quartile.",
                "NHANES R survey vs Python reproducibility.",
                "NHANES subgroup/effect-modification heatmap.",
                "NHANES sensitivity and negative-control-like analyses.",
                "DEHP mixture/composition proxy analysis.",
                "MSI component missingness and version correlations.",
                "CGMacros high-response threshold sensitivity.",
                "Subject bootstrap and leave-one-subject influence.",
                "Food-matrix annotation audit and feature dictionary.",
                "Counterfactual meal redesign scenario results.",
                "Prediction leakage audit and predictor dictionary.",
                "Prediction conformal interval and net benefit details.",
                "External dataset domain shift diagnostics.",
                "Mechanism knowledge graph and pathway enrichment.",
                "Full source-data lineage and reproducibility map.",
            ],
            start=1,
        )
    ]
    legend_text = ["# High-impact publication figure legends", ""]
    for name, text in main_legends + ext_legends:
        legend_text.append(f"## {name}")
        legend_text.append(text)
        legend_text.append("Source data are provided as CSV files under `source_data/`; all panels are generated from current project outputs.")
        legend_text.append("")
    (LEGENDS / "figure_legends_high_impact.md").write_text("\n".join(legend_text), encoding="utf-8")

    main_png = figure_manifest[(figure_manifest["group"] == "main") & (figure_manifest["format"] == "png")]
    ext_png = figure_manifest[(figure_manifest["group"] == "extended") & (figure_manifest["format"] == "png")]
    readme = f"""# High-impact publication figures and tables

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

This package upgrades the current no-wet-lab manuscript into a full display-item set for high-level journal targeting.

## Contents

- Main figures: {main_png['figure'].nunique()}
- Extended figures: {ext_png['figure'].nunique()}
- Main tables: {len(main_tables)}
- Supplementary tables: {len(supp_tables)}
- Figure formats: PDF, SVG, PNG, TIFF
- Source-data tables: {len(list(SRC.glob('*.csv')))}

## Evidence line

NHANES DEHP oxidative profile -> MSI bridge phenotype -> CGMacros PPGR vulnerability -> food-matrix and curve phenotypes -> prediction value and external boundaries -> conservative mechanism plausibility.

## Guardrail

The figures intentionally frame the design as a cross-dataset bridge-phenotype study. They do not claim direct DEHP-to-PPGR causality or formal mediation.
"""
    (OUT / "README_high_impact_publication_figures_tables.md").write_text(readme, encoding="utf-8")


def quality_check(figure_manifest: pd.DataFrame) -> pd.DataFrame:
    checks = []
    for _, row in figure_manifest.iterrows():
        path = Path(row["path"])
        check = {
            "figure": row["figure"],
            "group": row["group"],
            "format": row["format"],
            "path": row["path"],
            "exists": path.exists(),
            "bytes": path.stat().st_size if path.exists() else 0,
            "status": "ok",
        }
        if path.exists() and row["format"] in {"png", "tiff"}:
            with Image.open(path) as im:
                check["width_px"] = im.width
                check["height_px"] = im.height
                arr = np.asarray(im.convert("L").resize((64, 64)))
                check["pixel_sd_64"] = float(arr.std())
                if im.width < 1800 or im.height < 1200:
                    check["status"] = "low_resolution"
                if arr.std() < 2:
                    check["status"] = "likely_blank"
        if check["bytes"] < 10000:
            check["status"] = "small_file_review"
        checks.append(check)
    return pd.DataFrame(checks)


def mirror_package() -> None:
    NHANES_MIRROR.mkdir(parents=True, exist_ok=True)
    shutil.copytree(OUT, NHANES_MIRROR, dirs_exist_ok=True)


def main() -> None:
    ensure_dirs()
    setup_style()
    data = load_data()

    figure_records: List[Dict[str, object]] = []
    figure_records += figure1_architecture(data)
    figure_records += figure2_nhanes(data)
    figure_records += figure3_msi_validation(data)
    figure_records += figure4_cgmacros(data)
    figure_records += figure5_food_matrix(data)
    figure_records += figure6_curve_phenotypes(data)
    figure_records += figure7_prediction(data)
    figure_records += figure8_external(data)
    figure_records += figure9_mechanism(data)
    figure_records += extended_figures(data)

    figure_manifest = pd.DataFrame(figure_records)
    save_csv(LOGS / "figure_manifest_high_impact.csv", figure_manifest)
    qc = quality_check(figure_manifest)
    save_csv(LOGS / "figure_quality_check_high_impact.csv", qc)

    main_tables, supp_tables = build_tables(data)
    write_legends_and_readme(figure_manifest, main_tables, supp_tables)

    package_manifest = []
    for path in OUT.rglob("*"):
        if path.is_file():
            package_manifest.append(
                {
                    "relative_path": str(path.relative_to(OUT)),
                    "bytes": path.stat().st_size,
                    "last_write_time": datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds"),
                }
            )
    save_csv(LOGS / "package_manifest_high_impact.csv", pd.DataFrame(package_manifest))
    shutil.copy2(__file__, LOGS / Path(__file__).name)
    mirror_package()
    print(f"Generated: {OUT}")
    print(f"Mirrored: {NHANES_MIRROR}")
    print(f"Main figures: {figure_manifest[figure_manifest['group'].eq('main')]['figure'].nunique()}")
    print(f"Extended figures: {figure_manifest[figure_manifest['group'].eq('extended')]['figure'].nunique()}")
    print(f"Main tables: {len(main_tables)}")
    print(f"Supplementary tables: {len(supp_tables)}")
    print(f"QC statuses: {qc['status'].value_counts().to_dict()}")


if __name__ == "__main__":
    main()
