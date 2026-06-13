from __future__ import annotations

import csv
import json
import math
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, Iterable, List, Sequence

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy import stats


DATE_TAG = "2026-06-10"
ROOT = Path(__file__).resolve().parents[1]
INTEGRATED = ROOT / "outputs" / "integrated_mainline"
PACKAGE_NAME = f"ajcn_publication_figures_v2_{DATE_TAG}"
OUT = INTEGRATED / PACKAGE_NAME
FIG_DIR = OUT / "figures"
SRC_DIR = OUT / "source_data"
LOG_DIR = OUT / "logs"
LEGEND_DIR = OUT / "legends"

AJCN_PACKAGE = INTEGRATED / f"ajcn_no_wetlab_manuscript_package_{DATE_TAG}"
AJCN_FIG_V2 = AJCN_PACKAGE / "figures_publication_v2"
NHANES_PACKAGE = (
    Path(r"C:\Users\liu12\OneDrive\Desktop\NHANES_MetS_Project")
    / "result"
    / "integrated_mainline"
    / PACKAGE_NAME
)
NHANES_AJCN_FIG_V2 = (
    Path(r"C:\Users\liu12\OneDrive\Desktop\NHANES_MetS_Project")
    / "result"
    / "integrated_mainline"
    / f"ajcn_no_wetlab_manuscript_package_{DATE_TAG}"
    / "figures_publication_v2"
)

PHASE2 = INTEGRATED / "no_digestion_phase0_to_phase4" / "phase2_manuscript_tables_and_figures"

PATHS = {
    "nhanes_survey": PHASE2 / "Table2_NHANES_R_survey_key_results.csv",
    "nhanes_quartile": INTEGRATED / "phase2_nhanes_survey_ready" / "phase2_nhanes_dose_response_quartile_summary.csv",
    "nhanes_rcs": INTEGRATED / "dry_lab_booster_modules" / "module_B_nhanes_advanced_epidemiology" / "phase2_python_rcs_prediction_grid.csv",
    "cgmacros_meals": INTEGRATED / "stage1_msi" / "cgmacros_meal_level_with_msi_core.csv",
    "cgmacros_subject": INTEGRATED / "phase3_cgmacros_robust_inference" / "phase3_subject_level_ppgr_msi_summary.csv",
    "cgmacros_models": PHASE2 / "Table3_CGMacros_MSI_PPGR_results.csv",
    "food_models": PHASE2 / "Table4_FoodMatrix_CurvePhenotype_results.csv",
    "food_annotation": INTEGRATED / "dry_lab_booster_modules" / "module_C_cgmacros_food_matrix" / "cgmacros_food_matrix_annotation.csv",
    "curve_features": INTEGRATED / "dry_lab_booster_modules" / "module_D_cgm_curve_phenotypes" / "cgmacros_ppgr_curve_features.csv",
    "curve_clusters": PHASE2 / "Figure4_data_curve_clusters.csv",
    "prediction_records": INTEGRATED / "phase4_prediction_upgrade" / "phase4_nested_lso_prediction_records.csv",
    "prediction_perf": INTEGRATED / "phase4_prediction_upgrade" / "phase4_model_performance_overall.csv",
    "prediction_delta": INTEGRATED / "phase4_prediction_upgrade" / "phase4_model_comparison_key_deltas.csv",
    "calibration": INTEGRATED / "phase4_prediction_upgrade" / "phase4_calibration_deciles.csv",
    "external_map": INTEGRATED / "dry_lab_booster_modules" / "module_F_external_transportability" / "external_transportability_map.csv",
    "external_shift": INTEGRATED / "dry_lab_booster_modules" / "module_F_external_transportability" / "external_domain_shift_metrics.csv",
}

PALETTE = {
    "blue": "#4477AA",
    "cyan": "#66CCEE",
    "green": "#228833",
    "yellow": "#CCBB44",
    "red": "#CC6677",
    "purple": "#AA3377",
    "gray": "#5F6670",
    "light_gray": "#D7DBDF",
    "dark": "#1B1F24",
    "orange": "#EE7733",
    "teal": "#009988",
}
TERTILE_COLORS = {"low": PALETTE["blue"], "middle": PALETTE["teal"], "high": PALETTE["orange"]}
MODEL_COLORS = {
    "M0_carb_only": "#B8BEC4",
    "M1_macro_timing": PALETTE["blue"],
    "M2_macro_precgm_context": PALETTE["green"],
    "M3_msi_enhanced": PALETTE["orange"],
}


def ensure_dirs() -> None:
    for path in [OUT, FIG_DIR, SRC_DIR, LOG_DIR, LEGEND_DIR]:
        path.mkdir(parents=True, exist_ok=True)


def setup_style() -> None:
    sns.set_theme(style="whitegrid", context="paper")
    mpl.rcParams.update(
        {
            "font.family": "Arial",
            "font.sans-serif": ["Arial", "DejaVu Sans", "Liberation Sans"],
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.linewidth": 0.8,
            "axes.edgecolor": "#222222",
            "axes.labelcolor": "#222222",
            "xtick.color": "#222222",
            "ytick.color": "#222222",
            "grid.color": "#E8ECEF",
            "grid.linewidth": 0.55,
            "legend.frameon": False,
            "savefig.dpi": 600,
            "savefig.bbox": "tight",
            "figure.dpi": 120,
        }
    )


def label_panel(ax: plt.Axes, label: str, x: float = -0.12, y: float = 1.06) -> None:
    ax.text(
        x,
        y,
        label,
        transform=ax.transAxes,
        fontsize=10.5,
        fontweight="bold",
        va="top",
        ha="left",
        color=PALETTE["dark"],
    )


def clean_axis(ax: plt.Axes) -> None:
    ax.grid(True, axis="y", color="#E8ECEF", linewidth=0.55)
    ax.grid(False, axis="x")
    ax.tick_params(labelsize=8.5, length=3)
    ax.xaxis.label.set_size(9)
    ax.yaxis.label.set_size(9)
    ax.title.set_size(9.5)


def save_figure(fig: plt.Figure, stem: str) -> Dict[str, str]:
    outputs = {}
    for ext in ["pdf", "png", "tiff"]:
        path = FIG_DIR / f"{stem}.{ext}"
        if ext == "tiff":
            fig.savefig(path, dpi=600, pil_kwargs={"compression": "tiff_lzw"})
        else:
            fig.savefig(path, dpi=600)
        outputs[ext] = str(path)
    plt.close(fig)
    return outputs


def write_csv(path: Path, rows: Sequence[Dict[str, object]], fieldnames: Sequence[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


def copy_source(name: str, df: pd.DataFrame) -> None:
    df.to_csv(SRC_DIR / f"{name}.csv", index=False, encoding="utf-8")


def fmt_p(x: float) -> str:
    if pd.isna(x):
        return ""
    return f"{x:.1e}" if x < 0.001 else f"{x:.3f}"


def outcome_label(x: str) -> str:
    return {
        "msi_pca": "MSI PCA",
        "msi_core_partial": "MSI core",
        "msi_no_bmi": "MSI without BMI",
        "ln_HOMA_IR": "ln(HOMA-IR)",
        "HbA1c": "HbA1c",
        "iauc_2h_per1000": "2-h iAUC /1000",
        "peak_delta_2h": "2-h peak delta",
        "high_iauc_top_quartile": "High iAUC",
        "high_peak_top_quartile": "High peak",
    }.get(x, x)


def term_label(x: str) -> str:
    return {
        "carbs_10g": "Carbohydrate /10 g",
        "msi_core_centered": "MSI",
        "carbs_x_msi": "Carb x MSI",
        "msi_centered": "MSI",
        "digestibility_centered": "Digestibility-risk",
        "msi_x_digestibility": "MSI x digestibility-risk",
    }.get(x, x)


def add_reference_line(ax: plt.Axes, axis: str = "x", value: float = 0.0) -> None:
    if axis == "x":
        ax.axvline(value, color="#B7BDC5", lw=0.8, zorder=0)
    else:
        ax.axhline(value, color="#B7BDC5", lw=0.8, zorder=0)


def add_spearman(ax: plt.Axes, x: pd.Series, y: pd.Series, loc: tuple[float, float] = (0.05, 0.92)) -> None:
    mask = x.notna() & y.notna()
    rho, p = stats.spearmanr(x[mask], y[mask])
    ax.text(
        loc[0],
        loc[1],
        f"Spearman rho={rho:.2f}\np={fmt_p(p)}",
        transform=ax.transAxes,
        fontsize=8.3,
        va="top",
        bbox=dict(boxstyle="round,pad=0.25", fc="white", ec="#D8DDE3", lw=0.6),
    )


def draw_forest(
    ax: plt.Axes,
    df: pd.DataFrame,
    est_col: str,
    low_col: str,
    high_col: str,
    label_col: str,
    color_col: str | None = None,
    q_col: str | None = None,
    x_label: str = "Estimate (95% CI)",
) -> None:
    df = df.reset_index(drop=True)
    y = np.arange(len(df))[::-1]
    colors = df[color_col].tolist() if color_col else [PALETTE["blue"]] * len(df)
    for i, row in df.iterrows():
        yy = y[i]
        ax.plot([row[low_col], row[high_col]], [yy, yy], color=colors[i], lw=1.8, solid_capstyle="round")
        ax.scatter(row[est_col], yy, color=colors[i], s=28, zorder=3, edgecolor="white", linewidth=0.4)
        if q_col:
            ax.text(
                ax.get_xlim()[1],
                yy,
                f"q={fmt_p(row[q_col])}",
                fontsize=7.6,
                va="center",
                ha="right",
                color=PALETTE["gray"],
            )
    ax.set_yticks(y)
    ax.set_yticklabels(df[label_col], fontsize=8.2)
    add_reference_line(ax, "x", 0)
    ax.set_xlabel(x_label)
    ax.set_ylim(-0.7, len(df) - 0.3)
    clean_axis(ax)


def load_data() -> Dict[str, pd.DataFrame]:
    data: Dict[str, pd.DataFrame] = {}
    for key, path in PATHS.items():
        data[key] = pd.read_csv(path)
    return data


def figure1_nhanes(data: Dict[str, pd.DataFrame]) -> Dict[str, str]:
    survey = data["nhanes_survey"].copy()
    survey["label"] = survey["outcome"].map(outcome_label)
    survey["exposure_label"] = survey["exposure"].map(
        {
            "ln_oxidative_to_MEHP": "ln oxidative/MEHP",
            "pct_oxidative_10": "% oxidative /10 pp",
        }
    )
    survey = survey[survey["outcome"].isin(["msi_core_partial", "ln_HOMA_IR", "HbA1c", "msi_no_bmi", "msi_pca"])]
    survey = survey[survey["exposure"].isin(["ln_oxidative_to_MEHP", "pct_oxidative_10"])]
    order = ["msi_core_partial", "msi_pca", "msi_no_bmi", "ln_HOMA_IR", "HbA1c"]
    survey["outcome_order"] = survey["outcome"].map({v: i for i, v in enumerate(order)})
    survey = survey.sort_values(["exposure", "outcome_order"], ascending=[True, True])
    survey["forest_label"] = survey["exposure_label"] + " | " + survey["label"]
    survey["color"] = survey["exposure"].map(
        {"ln_oxidative_to_MEHP": PALETTE["blue"], "pct_oxidative_10": PALETTE["orange"]}
    )
    copy_source("Figure1A_NHANES_survey_forest", survey)

    quart = data["nhanes_quartile"].copy()
    quart = quart[quart["quartile"].notna() & quart["exposure"].eq("ln_oxidative_to_MEHP")]
    quart["outcome_label"] = quart["outcome"].map({"msi_core_partial": "MSI core", "ln_HOMA_IR": "ln(HOMA-IR)", "HbA1c": "HbA1c"})
    quart["z_weighted_mean"] = quart.groupby("outcome")["weighted_mean_outcome"].transform(
        lambda s: (s - s.mean()) / s.std(ddof=0)
    )
    copy_source("Figure1B_NHANES_quartile_dose_response", quart)

    rcs = data["nhanes_rcs"].copy()
    rcs = rcs[(rcs["exposure"] == "ln_oxidative_to_MEHP") & (rcs["outcome"] == "msi_core_partial")]
    copy_source("Figure1C_NHANES_RCS_grid", rcs)

    fig = plt.figure(figsize=(7.2, 8.4), constrained_layout=True)
    gs = fig.add_gridspec(2, 2, height_ratios=[1.3, 1.0], width_ratios=[1.05, 1.0])
    ax_a = fig.add_subplot(gs[0, :])
    ax_b = fig.add_subplot(gs[1, 0])
    ax_c = fig.add_subplot(gs[1, 1])

    ax_a.set_xlim(-0.08, 0.39)
    draw_forest(
        ax_a,
        survey,
        "R_beta",
        "R_ci_low",
        "R_ci_high",
        "forest_label",
        color_col="color",
        q_col="R_q",
        x_label="Survey-weighted beta (95% CI)",
    )
    ax_a.set_title("NHANES survey-weighted associations")
    label_panel(ax_a, "A")

    sns.lineplot(
        data=quart,
        x="quartile",
        y="z_weighted_mean",
        hue="outcome_label",
        style="outcome_label",
        markers=True,
        dashes=False,
        palette=[PALETTE["blue"], PALETTE["green"], PALETTE["red"]],
        ax=ax_b,
        linewidth=1.6,
        markersize=5,
    )
    ax_b.set_xlabel("Quartile of ln(oxidative/MEHP)")
    ax_b.set_ylabel("Weighted mean outcome, z-scaled")
    ax_b.set_xticks([1, 2, 3, 4])
    ax_b.set_title("Dose-response pattern")
    ax_b.legend(title="", fontsize=7.7, loc="upper left")
    clean_axis(ax_b)
    label_panel(ax_b, "B")

    ax_c.plot(rcs["x"], rcs["delta_vs_median"], color=PALETTE["blue"], lw=2.0)
    ax_c.scatter(rcs["x"].iloc[::8], rcs["delta_vs_median"].iloc[::8], color=PALETTE["blue"], s=14, zorder=3)
    ax_c.axhline(0, color="#B7BDC5", lw=0.8)
    ref = rcs["reference_median"].dropna().iloc[0] if rcs["reference_median"].notna().any() else None
    if ref is not None:
        ax_c.axvline(ref, color=PALETTE["gray"], lw=0.8, ls="--")
        ax_c.text(ref, ax_c.get_ylim()[0], "median", fontsize=7.2, va="bottom", ha="right", rotation=90, color=PALETTE["gray"])
    knot_text = str(rcs["knots"].dropna().iloc[0]) if rcs["knots"].notna().any() else ""
    for knot in [float(k) for k in knot_text.split(";") if k]:
        ax_c.axvline(knot, color="#D6DADE", lw=0.6, zorder=0)
    ax_c.set_xlabel("ln(oxidative/MEHP)")
    ax_c.set_ylabel("Predicted MSI-core difference vs median")
    ax_c.set_title("Spline sensitivity curve")
    clean_axis(ax_c)
    label_panel(ax_c, "C")

    return save_figure(fig, "Figure1_NHANES_exposure_response_publication_v2")


def figure2_cgmacros(data: Dict[str, pd.DataFrame]) -> Dict[str, str]:
    meals = data["cgmacros_meals"].copy()
    meals = meals.rename(
        columns={
            "msi_core_tertile_within_dataset": "msi_tertile",
            "msi_core_partial_nhanes_ref": "msi",
        }
    )
    meals = meals[meals["msi_tertile"].isin(["low", "middle", "high"])]
    tertile_order = ["low", "middle", "high"]
    copy_source("Figure2AB_CGMacros_meal_level_distributions", meals[
        ["subject_id", "meal_time", "msi", "msi_tertile", "iauc_2h", "peak_delta_2h", "carbs", "meal_type"]
    ])

    subj = data["cgmacros_subject"].copy()
    copy_source("Figure2C_CGMacros_subject_level_MSI_PPGR", subj)

    model = data["cgmacros_models"].copy()
    keep = model["model"].eq("base_interaction") & model["outcome"].isin(
        ["iauc_2h_per1000", "peak_delta_2h", "high_iauc_top_quartile", "high_peak_top_quartile"]
    ) & model["term"].isin(["carbs_10g", "msi_core_centered", "carbs_x_msi"])
    forest = model[keep].copy()
    forest["label"] = forest["outcome"].map(outcome_label) + " | " + forest["term"].map(term_label)
    forest["color"] = forest["term"].map(
        {"carbs_10g": PALETTE["gray"], "msi_core_centered": PALETTE["orange"], "carbs_x_msi": PALETTE["purple"]}
    )
    forest = forest.sort_values(["outcome", "term"])
    copy_source("Figure2D_CGMacros_model_coefficients", forest)

    fig = plt.figure(figsize=(7.2, 8.8), constrained_layout=True)
    gs = fig.add_gridspec(2, 2, height_ratios=[1.05, 1.0])
    ax_a = fig.add_subplot(gs[0, 0])
    ax_b = fig.add_subplot(gs[0, 1])
    ax_c = fig.add_subplot(gs[1, 0])
    ax_d = fig.add_subplot(gs[1, 1])

    sns.violinplot(
        data=meals,
        x="msi_tertile",
        y="iauc_2h",
        order=tertile_order,
        palette=TERTILE_COLORS,
        inner=None,
        linewidth=0.7,
        cut=0,
        ax=ax_a,
        saturation=0.85,
    )
    sns.boxplot(
        data=meals,
        x="msi_tertile",
        y="iauc_2h",
        order=tertile_order,
        width=0.22,
        showcaps=True,
        showfliers=False,
        boxprops={"facecolor": "white", "edgecolor": PALETTE["dark"], "linewidth": 0.8},
        medianprops={"color": PALETTE["dark"], "linewidth": 1.1},
        whiskerprops={"color": PALETTE["dark"], "linewidth": 0.8},
        ax=ax_a,
    )
    ax_a.set_ylim(0, meals["iauc_2h"].quantile(0.99) * 1.05)
    ax_a.set_xlabel("MSI tertile")
    ax_a.set_ylabel("2-h iAUC (mg/dL x min)")
    ax_a.set_title("Meal-level iAUC distribution")
    clean_axis(ax_a)
    label_panel(ax_a, "A")

    sns.violinplot(
        data=meals,
        x="msi_tertile",
        y="peak_delta_2h",
        order=tertile_order,
        palette=TERTILE_COLORS,
        inner=None,
        linewidth=0.7,
        cut=0,
        ax=ax_b,
        saturation=0.85,
    )
    sns.boxplot(
        data=meals,
        x="msi_tertile",
        y="peak_delta_2h",
        order=tertile_order,
        width=0.22,
        showfliers=False,
        boxprops={"facecolor": "white", "edgecolor": PALETTE["dark"], "linewidth": 0.8},
        medianprops={"color": PALETTE["dark"], "linewidth": 1.1},
        whiskerprops={"color": PALETTE["dark"], "linewidth": 0.8},
        ax=ax_b,
    )
    ax_b.set_ylim(meals["peak_delta_2h"].quantile(0.01) - 8, meals["peak_delta_2h"].quantile(0.99) * 1.05)
    ax_b.set_xlabel("MSI tertile")
    ax_b.set_ylabel("2-h peak delta (mg/dL)")
    ax_b.set_title("Meal-level peak distribution")
    clean_axis(ax_b)
    label_panel(ax_b, "B")

    for tertile, group in subj.groupby("msi_tertile"):
        ax_c.scatter(
            group["msi"],
            group["mean_iauc_2h"],
            s=18 + group["n_meals"] * 0.55,
            color=TERTILE_COLORS.get(tertile, PALETTE["gray"]),
            alpha=0.88,
            edgecolor="white",
            linewidth=0.5,
            label=tertile,
        )
    sns.regplot(data=subj, x="msi", y="mean_iauc_2h", scatter=False, ax=ax_c, color=PALETTE["dark"], line_kws={"lw": 1.1})
    add_spearman(ax_c, subj["msi"], subj["mean_iauc_2h"])
    ax_c.set_xlabel("Participant MSI")
    ax_c.set_ylabel("Mean 2-h iAUC")
    ax_c.set_title("Subject-level susceptibility gradient")
    ax_c.legend(title="MSI tertile", fontsize=7.5, title_fontsize=7.5, loc="lower right")
    clean_axis(ax_c)
    label_panel(ax_c, "C")

    ax_d.set_xlim(-0.45, 2.05)
    # Keep iAUC and binary-risk rows; peak term is on a larger unit scale and remains in source table.
    display = forest[forest["outcome"].isin(["iauc_2h_per1000", "high_iauc_top_quartile", "high_peak_top_quartile"])].copy()
    draw_forest(
        ax_d,
        display,
        "estimate",
        "ci_low",
        "ci_high",
        "label",
        color_col="color",
        q_col="q_value",
        x_label="Coefficient (95% CI)",
    )
    ax_d.set_title("Meal-level model estimates")
    label_panel(ax_d, "D")

    return save_figure(fig, "Figure2_CGMacros_MSI_PPGR_publication_v2")


def figure3_food_curve(data: Dict[str, pd.DataFrame]) -> Dict[str, str]:
    ann = data["food_annotation"].copy()
    ann = ann[ann["msi_core_tertile_within_dataset"].isin(["low", "middle", "high"])]
    copy_source(
        "Figure3A_food_matrix_meal_level_scatter",
        ann[
            [
                "subject_id",
                "meal_time",
                "digestibility_risk_score",
                "msi_core_partial_nhanes_ref",
                "msi_core_tertile_within_dataset",
                "iauc_2h",
                "peak_delta_2h",
                "available_carbs_g",
                "glycemic_load_proxy",
            ]
        ],
    )

    food = data["food_models"].copy()
    inter = food[
        (food["analysis_block"] == "food_matrix_ppgr")
        & (food["term"].isin(["msi_centered", "digestibility_centered", "msi_x_digestibility"]))
    ].copy()
    inter["label"] = inter["outcome_label"] + " | " + inter["term"].map(term_label)
    inter["color"] = inter["term"].map(
        {
            "msi_centered": PALETTE["blue"],
            "digestibility_centered": PALETTE["green"],
            "msi_x_digestibility": PALETTE["orange"],
        }
    )
    copy_source("Figure3B_food_matrix_model_coefficients", inter)

    clusters_raw = data["curve_clusters"].copy()
    copy_source("Figure3C_curve_cluster_summary_raw", clusters_raw)
    clusters = (
        clusters_raw.assign(weight=clusters_raw["n_meals"])
        .groupby("shape_cluster_label", as_index=False)
        .apply(
            lambda g: pd.Series(
                {
                    "n_meals": g["n_meals"].sum(),
                    "n_subjects": g["n_subjects"].max(),
                    "mean_iauc_2h": np.average(g["mean_iauc_2h"], weights=g["weight"]),
                    "mean_peak_delta_2h": np.average(g["mean_peak_delta_2h"], weights=g["weight"]),
                    "mean_msi": np.average(g["mean_msi"], weights=g["weight"]),
                    "mean_digestibility": np.average(g["mean_digestibility"], weights=g["weight"]),
                }
            )
        )
        .reset_index(drop=True)
    )
    copy_source("Figure3C_curve_cluster_summary_collapsed", clusters)

    curve = data["curve_features"].copy()
    comp = (
        curve.groupby(["msi_core_tertile_within_dataset", "shape_cluster_label"])
        .size()
        .reset_index(name="n")
    )
    comp["prop"] = comp["n"] / comp.groupby("msi_core_tertile_within_dataset")["n"].transform("sum")
    copy_source("Figure3D_curve_cluster_composition_by_MSI", comp)

    fig = plt.figure(figsize=(7.2, 8.9), constrained_layout=True)
    gs = fig.add_gridspec(2, 2, height_ratios=[1.0, 1.0])
    ax_a = fig.add_subplot(gs[0, 0])
    ax_b = fig.add_subplot(gs[0, 1])
    ax_c = fig.add_subplot(gs[1, 0])
    ax_d = fig.add_subplot(gs[1, 1])

    x_clip = ann["digestibility_risk_score"].quantile(0.99)
    y_clip = ann["iauc_2h"].quantile(0.99)
    plot_ann = ann.copy()
    plot_ann["digestibility_plot"] = plot_ann["digestibility_risk_score"].clip(upper=x_clip)
    plot_ann["iauc_plot"] = plot_ann["iauc_2h"].clip(upper=y_clip)
    sns.scatterplot(
        data=plot_ann,
        x="digestibility_plot",
        y="iauc_plot",
        hue="msi_core_tertile_within_dataset",
        hue_order=["low", "middle", "high"],
        palette=TERTILE_COLORS,
        s=16,
        alpha=0.45,
        linewidth=0,
        ax=ax_a,
    )
    plot_ann["digestibility_bin"] = pd.qcut(plot_ann["digestibility_plot"], q=10, duplicates="drop")
    binned = (
        plot_ann.groupby("digestibility_bin", observed=True)
        .agg(
            x_mid=("digestibility_plot", "median"),
            y_med=("iauc_plot", "median"),
            y_q25=("iauc_plot", lambda s: np.nanquantile(s, 0.25)),
            y_q75=("iauc_plot", lambda s: np.nanquantile(s, 0.75)),
        )
        .reset_index(drop=True)
    )
    ax_a.plot(binned["x_mid"], binned["y_med"], color=PALETTE["dark"], lw=1.4)
    ax_a.fill_between(
        binned["x_mid"].to_numpy(),
        binned["y_q25"].to_numpy(),
        binned["y_q75"].to_numpy(),
        color=PALETTE["dark"],
        alpha=0.10,
        linewidth=0,
    )
    ax_a.set_xlabel("Digestibility-risk score")
    ax_a.set_ylabel("2-h iAUC (clipped at 99th percentile)")
    ax_a.set_title("Meal matrix and iAUC", pad=12)
    ax_a.legend(title="MSI tertile", fontsize=7.4, title_fontsize=7.4, loc="upper left")
    clean_axis(ax_a)
    label_panel(ax_a, "A", x=-0.16, y=1.12)

    display = inter[inter["outcome"].isin(["2h iAUC /1000"])].copy()
    display = display.sort_values("term")
    ax_b.set_xlim(-0.2, 2.15)
    draw_forest(
        ax_b,
        display,
        "estimate",
        "ci_low",
        "ci_high",
        "label",
        color_col="color",
        q_col="q_value",
        x_label="Coefficient for iAUC/1000",
    )
    ax_b.set_title("Food-matrix iAUC model", pad=12)
    label_panel(ax_b, "B", x=-0.16, y=1.12)

    ax_c.scatter(
        clusters["mean_iauc_2h"] / 1000,
        clusters["mean_peak_delta_2h"],
        s=np.sqrt(clusters["n_meals"]) * 34,
        c=clusters["mean_msi"],
        cmap="RdBu_r",
        edgecolor=PALETTE["dark"],
        linewidth=0.7,
        alpha=0.9,
    )
    label_offsets = {
        "low_stable_response": (0.35, 5.0, "low stable"),
        "delayed_peak": (0.20, 8.0, "delayed\npeak"),
        "high_peak_fast_recovery": (0.15, 9.5, "high peak\nfast recovery"),
        "large_prolonged_response": (-0.35, 8.0, "large prolonged\nresponse"),
    }
    for _, r in clusters.iterrows():
        dx, dy, txt = label_offsets.get(r["shape_cluster_label"], (0.1, 7.0, r["shape_cluster_label"].replace("_", "\n")))
        ha = "right" if dx < 0 else "left"
        ax_c.text(r["mean_iauc_2h"] / 1000 + dx, r["mean_peak_delta_2h"] + dy, txt, fontsize=7.1, ha=ha, va="bottom")
    cbar = fig.colorbar(ax_c.collections[0], ax=ax_c, fraction=0.046, pad=0.02)
    cbar.set_label("Mean MSI", fontsize=8)
    cbar.ax.tick_params(labelsize=7)
    ax_c.set_xlabel("Mean 2-h iAUC (x1000)")
    ax_c.set_ylabel("Mean peak delta (mg/dL)")
    ax_c.set_xlim(-0.35, max(clusters["mean_iauc_2h"] / 1000) + 1.1)
    ax_c.set_ylim(0, max(clusters["mean_peak_delta_2h"]) + 28)
    ax_c.set_title("CGM curve-shape clusters", pad=12)
    clean_axis(ax_c)
    label_panel(ax_c, "C", x=-0.16, y=1.12)

    cluster_order = (
        comp.groupby("shape_cluster_label")["n"].sum().sort_values(ascending=False).index.tolist()
    )
    bottoms = np.zeros(3)
    tertiles = ["low", "middle", "high"]
    cluster_palette = sns.color_palette("Set2", n_colors=len(cluster_order))
    for color, cluster in zip(cluster_palette, cluster_order):
        vals = []
        for tertile in tertiles:
            val = comp.loc[
                (comp["msi_core_tertile_within_dataset"] == tertile) & (comp["shape_cluster_label"] == cluster),
                "prop",
            ]
            vals.append(float(val.iloc[0]) if len(val) else 0.0)
        ax_d.bar(tertiles, vals, bottom=bottoms, color=color, width=0.68, label=cluster.replace("_", " "))
        bottoms += np.array(vals)
    ax_d.set_ylim(0, 1)
    ax_d.set_ylabel("Proportion of meals")
    ax_d.set_xlabel("MSI tertile")
    ax_d.set_title("Curve phenotype composition", pad=12)
    ax_d.legend(fontsize=6.1, loc="center left", bbox_to_anchor=(1.02, 0.5))
    clean_axis(ax_d)
    label_panel(ax_d, "D", x=-0.16, y=1.12)

    return save_figure(fig, "Figure3_FoodMatrix_CurvePhenotypes_publication_v2")


def figure4_prediction(data: Dict[str, pd.DataFrame]) -> Dict[str, str]:
    rec = data["prediction_records"].copy()
    perf = data["prediction_perf"].copy()
    cal = data["calibration"].copy()
    delta = data["prediction_delta"].copy()
    copy_source("Figure4_prediction_records_M3", rec[rec["model"] == "M3_msi_enhanced"])
    copy_source("Figure4_prediction_performance", perf)
    copy_source("Figure4_calibration_deciles", cal)
    copy_source("Figure4_prediction_incremental_deltas", delta)

    fig = plt.figure(figsize=(7.2, 8.9), constrained_layout=True)
    gs = fig.add_gridspec(2, 2, height_ratios=[1.05, 1.0])
    ax_a = fig.add_subplot(gs[0, 0])
    ax_b = fig.add_subplot(gs[0, 1])
    ax_c = fig.add_subplot(gs[1, 0])
    ax_d = fig.add_subplot(gs[1, 1])

    def observed_predicted_panel(ax: plt.Axes, target: str, title: str, lim: tuple[float, float]) -> None:
        df = rec[(rec["model"] == "M3_msi_enhanced") & (rec["target"] == target)].copy()
        hb = ax.hexbin(
            df["y_pred"],
            df["y_true"],
            gridsize=34,
            cmap="Blues",
            mincnt=1,
            linewidths=0,
            extent=(lim[0], lim[1], lim[0], lim[1]),
        )
        ax.plot(lim, lim, color=PALETTE["red"], lw=1.0, ls="--")
        perf_row = perf[(perf["target"] == target) & (perf["model"] == "M3_msi_enhanced")].iloc[0]
        ax.text(
            0.05,
            0.94,
            f"R2={perf_row['R2']:.2f}\nAUC={perf_row['AUC_high_response']:.2f}\nMAE={perf_row['MAE']:.1f}",
            transform=ax.transAxes,
            fontsize=7.8,
            va="top",
            bbox=dict(boxstyle="round,pad=0.25", fc="white", ec="#D8DDE3", lw=0.6),
        )
        ax.set_xlim(lim)
        ax.set_ylim(lim)
        ax.set_xlabel("Predicted")
        ax.set_ylabel("Observed")
        ax.set_title(title)
        clean_axis(ax)
        return hb

    hb1 = observed_predicted_panel(ax_a, "iauc_2h", "M3: iAUC observed vs predicted", (0, 13000))
    cbar1 = fig.colorbar(hb1, ax=ax_a, fraction=0.046, pad=0.02)
    cbar1.set_label("Meals/bin", fontsize=7.5)
    cbar1.ax.tick_params(labelsize=7)
    label_panel(ax_a, "A")
    hb2 = observed_predicted_panel(ax_b, "peak_delta_2h", "M3: peak observed vs predicted", (-60, 230))
    cbar2 = fig.colorbar(hb2, ax=ax_b, fraction=0.046, pad=0.02)
    cbar2.set_label("Meals/bin", fontsize=7.5)
    cbar2.ax.tick_params(labelsize=7)
    label_panel(ax_b, "B")

    auc_perf = perf.pivot_table(index="model", columns="target", values="AUC_high_response").loc[
        ["M0_carb_only", "M1_macro_timing", "M2_macro_precgm_context", "M3_msi_enhanced"]
    ]
    x = np.arange(len(auc_perf))
    ax_c.plot(x, auc_perf["iauc_2h"], marker="o", color=PALETTE["blue"], lw=1.8, label="iAUC high-response AUC")
    ax_c.plot(x, auc_perf["peak_delta_2h"], marker="o", color=PALETTE["orange"], lw=1.8, label="Peak high-response AUC")
    ax_c.set_xticks(x)
    ax_c.set_xticklabels(["M0", "M1", "M2", "M3"])
    ax_c.set_ylim(0.55, 0.84)
    ax_c.set_ylabel("AUC")
    ax_c.set_xlabel("Nested model")
    ax_c.set_title("Discrimination improves with MSI")
    ax_c.legend(fontsize=7.4, loc="lower right")
    clean_axis(ax_c)
    label_panel(ax_c, "C")

    cal_m3 = cal[cal["model"] == "M3_msi_enhanced"].copy()
    for target, color, label in [
        ("iauc_2h", PALETTE["blue"], "iAUC"),
        ("peak_delta_2h", PALETTE["orange"], "Peak"),
    ]:
        df = cal_m3[cal_m3["target"] == target]
        xvals = (df["mean_pred"] - df["mean_pred"].min()) / (df["mean_pred"].max() - df["mean_pred"].min())
        yvals = (df["mean_observed"] - df["mean_observed"].min()) / (df["mean_observed"].max() - df["mean_observed"].min())
        ax_d.plot(xvals, yvals, marker="o", color=color, lw=1.7, label=label)
    ax_d.plot([0, 1], [0, 1], color=PALETTE["gray"], lw=0.9, ls="--")
    ax_d.set_xlabel("Predicted decile mean, normalized")
    ax_d.set_ylabel("Observed decile mean, normalized")
    ax_d.set_title("Calibration by prediction decile")
    ax_d.legend(fontsize=7.5, loc="upper left")
    clean_axis(ax_d)
    label_panel(ax_d, "D")

    return save_figure(fig, "Figure4_Prediction_Calibration_publication_v2")


def figure5_external(data: Dict[str, pd.DataFrame]) -> Dict[str, str]:
    ext = data["external_map"].copy()
    shift = data["external_shift"].copy()
    copy_source("Figure5A_external_transportability_map", ext)
    copy_source("Figure5B_external_domain_shift", shift)

    fig = plt.figure(figsize=(7.2, 7.6), constrained_layout=True)
    gs = fig.add_gridspec(2, 2)
    ax_a = fig.add_subplot(gs[0, 0])
    ax_b = fig.add_subplot(gs[0, 1])
    ax_c = fig.add_subplot(gs[1, 0])
    ax_d = fig.add_subplot(gs[1, 1])

    ext_plot = ext[ext["dataset"].isin(["CGMacros", "Stanford_CGMDB", "T1D_UOM"])].copy()
    ext_long = ext_plot.melt(
        id_vars=["dataset", "n_subjects", "n_events"],
        value_vars=["median_iauc_2h", "median_peak_delta_2h"],
        var_name="metric",
        value_name="value",
    )
    ext_long["metric_label"] = ext_long["metric"].map({"median_iauc_2h": "Median iAUC", "median_peak_delta_2h": "Median peak"})
    sns.barplot(
        data=ext_long,
        x="dataset",
        y="value",
        hue="metric_label",
        palette=[PALETTE["blue"], PALETTE["orange"]],
        ax=ax_a,
    )
    ax_a.set_yscale("symlog", linthresh=100)
    ax_a.set_xlabel("")
    ax_a.set_ylabel("Median response (symlog scale)")
    ax_a.set_title("External response scale")
    ax_a.tick_params(axis="x", rotation=25)
    ax_a.legend(title="", fontsize=7.2)
    clean_axis(ax_a)
    label_panel(ax_a, "A")

    ratio = shift[shift["dataset"].isin(["CGMacros", "Stanford_CGMDB", "T1D_UOM"])].copy()
    ratio_long = ratio.melt(
        id_vars=["dataset"],
        value_vars=["ratio_median_iauc_vs_CGMacros", "ratio_median_peak_vs_CGMacros"],
        var_name="ratio_metric",
        value_name="ratio",
    )
    ratio_long["metric_label"] = ratio_long["ratio_metric"].map(
        {
            "ratio_median_iauc_vs_CGMacros": "iAUC ratio",
            "ratio_median_peak_vs_CGMacros": "Peak ratio",
        }
    )
    sns.pointplot(
        data=ratio_long,
        x="ratio",
        y="dataset",
        hue="metric_label",
        dodge=0.38,
        join=False,
        palette=[PALETTE["blue"], PALETTE["orange"]],
        ax=ax_b,
        errorbar=None,
        markers="o",
    )
    ax_b.axvline(1.0, color=PALETTE["gray"], lw=0.9, ls="--")
    ax_b.set_xlabel("Ratio vs CGMacros")
    ax_b.set_ylabel("")
    ax_b.set_title("Domain-shift magnitude")
    ax_b.legend(title="", fontsize=7.4, loc="upper right")
    clean_axis(ax_b)
    label_panel(ax_b, "B")

    corr = shift[shift["dataset"].str.startswith("T1D_UOM_")].copy()
    corr["feature"] = corr["dataset"].str.replace("T1D_UOM_", "", regex=False).str.replace("_direction", "", regex=False)
    corr_long = corr.melt(
        id_vars=["feature"],
        value_vars=["feature_response_corr_iauc", "feature_response_corr_peak"],
        var_name="outcome",
        value_name="correlation",
    )
    corr_long["outcome"] = corr_long["outcome"].map(
        {"feature_response_corr_iauc": "iAUC", "feature_response_corr_peak": "Peak"}
    )
    sns.barplot(
        data=corr_long,
        x="correlation",
        y="feature",
        hue="outcome",
        palette=[PALETTE["blue"], PALETTE["orange"]],
        ax=ax_c,
    )
    ax_c.axvline(0, color=PALETTE["gray"], lw=0.8)
    ax_c.set_xlabel("Feature-response correlation")
    ax_c.set_ylabel("")
    ax_c.set_title("T1D-UOM macro directionality")
    ax_c.legend(title="", fontsize=7.4)
    clean_axis(ax_c)
    label_panel(ax_c, "C")

    role = ext.copy()
    role = role[role["dataset"].isin(["CGMacros", "Stanford_CGMDB", "T1D_UOM", "Jaeb_CGMND_HealthyAdults"])].copy()
    ax_d.axis("off")
    ax_d.text(0.00, 1.04, "D", transform=ax_d.transAxes, fontsize=10.5, fontweight="bold", va="top", ha="left", color=PALETTE["dark"])
    ax_d.text(0.09, 1.04, "Boundary-evidence map", transform=ax_d.transAxes, fontsize=9.5, va="top", ha="left", color=PALETTE["dark"])
    y = 0.92
    for _, r in role.iterrows():
        ax_d.scatter(
            0.04,
            y,
            s=45,
            color=PALETTE["blue"] if r["dataset"] == "CGMacros" else PALETTE["gray"],
            transform=ax_d.transAxes,
            clip_on=False,
        )
        ax_d.text(0.09, y + 0.025, r["dataset"], transform=ax_d.transAxes, fontsize=8.2, fontweight="bold", va="center")
        ax_d.text(
            0.09,
            y - 0.035,
            f"n={int(r['n_subjects'])}; events={int(r['n_events'])}; {str(r['paper_interpretation'])[:54]}",
            transform=ax_d.transAxes,
            fontsize=7.4,
            color=PALETTE["gray"],
            va="center",
        )
        y -= 0.20

    return save_figure(fig, "Figure5_ExternalBoundary_publication_v2")


def build_legends() -> None:
    legends = """
# Publication Figure Legends v2

**Figure 1. NHANES DEHP oxidative-metabolism profile and metabolic susceptibility.** Panel A shows survey-weighted beta estimates and 95% CIs for associations of ln(oxidative DEHP metabolites/MEHP) and oxidative metabolite fraction with MSI and metabolic markers. Panel B shows weighted outcome means across ln(oxidative/MEHP) quartiles after within-outcome z-scaling for visual comparison. Panel C shows the spline sensitivity curve for MSI-core relative to the median exposure level. All panels use existing NHANES survey outputs.

**Figure 2. CGMacros metabolic susceptibility and meal-level postprandial glycemic response.** Panels A and B show full meal-level distributions of 2-h iAUC and peak glucose excursions by participant MSI tertile, with violin and embedded box summaries. Panel C shows subject-level mean iAUC by MSI with point size proportional to meal count. Panel D shows subject-clustered model coefficients for selected iAUC and high-response outcomes. Full coefficient outputs are retained in source data.

**Figure 3. Food-matrix proxy and CGM curve phenotypes.** Panel A shows meal-level digestibility-risk score and iAUC colored by MSI tertile. Panel B shows food-matrix model estimates for iAUC/1000, including MSI, digestibility-risk, and their interaction. Panel C maps curve-shape clusters by mean iAUC and peak excursion, with bubble size reflecting meal count and color reflecting mean MSI. Panel D shows cluster composition across MSI tertiles. Digestibility-risk is a dry-lab proxy, not measured digestion kinetics.

**Figure 4. Prediction and calibration.** Panels A and B show leave-subject-out observed-versus-predicted plots for the MSI-enhanced model. Panel C compares high-response discrimination across nested models. Panel D shows normalized calibration across prediction deciles for the MSI-enhanced model. Prediction models are intended for research stratification, not clinical deployment.

**Figure 5. External CGM boundary evidence.** Panel A compares response scales across CGMacros, Stanford CGMDB, and T1D-UOM. Panel B shows median response ratios relative to CGMacros. Panel C summarizes T1D-UOM macro-response directionality correlations. Panel D maps each external dataset's role in the manuscript. External datasets define boundary conditions and do not directly replicate the DEHP-MSI-CGM pathway.
"""
    write_text(LEGEND_DIR / "publication_figure_legends_v2.md", legends)


def build_design_note(outputs: Dict[str, Dict[str, str]]) -> None:
    note = f"""
# Publication Figure Redesign Notes

Generated: {datetime.now().isoformat(timespec="seconds")}

## Why this version replaces the first AJCN draft figures

The previous figure set was useful as a narrative sketch but too schematic for high-level peer review. The v2 set is built from actual run outputs and meal-level/source result tables:

- NHANES survey estimates, quartile dose-response summaries, and spline grids.
- CGMacros meal-level MSI/PPGR records and subject-level summaries.
- Food-matrix annotation records and curve-phenotype outputs.
- Leave-subject-out prediction records, calibration deciles, and model performance tables.
- External CGM transportability summaries and domain-shift metrics.

## Output formats

Each figure is exported as PDF, PNG, and TIFF at 600 dpi. PDF should be used for vector-first editing/submission when accepted; TIFF/PNG are included for journal upload or review decks.

## Design decisions

- English labels and compact panel titles suitable for AJCN submission.
- Colorblind-aware palette.
- Figure legends kept in a separate file rather than long in-figure text.
- Source data for each panel exported to `source_data/`.
- Raw distributions are shown where possible; iAUC and digestibility axes are clipped only for visual readability and source data retain complete values.

## Generated figures

{chr(10).join(f"- {stem}: {paths['pdf']}" for stem, paths in outputs.items())}
"""
    write_text(OUT / "README_publication_figures_v2.md", note)


def build_manifest(outputs: Dict[str, Dict[str, str]]) -> None:
    rows = []
    for stem, paths in outputs.items():
        for fmt, path in paths.items():
            p = Path(path)
            rows.append({"figure": stem, "format": fmt, "path": str(p), "bytes": p.stat().st_size})
    write_csv(LOG_DIR / "publication_figure_manifest_v2.csv", rows, ["figure", "format", "path", "bytes"])

    qa_rows = []
    for path in FIG_DIR.glob("*"):
        if path.suffix.lower() in {".png", ".tiff", ".pdf"}:
            qa_rows.append(
                {
                    "file": path.name,
                    "bytes": path.stat().st_size,
                    "status": "generated",
                    "note": "600 dpi export for raster formats; PDF is vector-first matplotlib export.",
                }
            )
    write_csv(LOG_DIR / "publication_figure_QA_v2.csv", qa_rows, ["file", "bytes", "status", "note"])


def mirror_outputs() -> None:
    for dest in [AJCN_FIG_V2, NHANES_PACKAGE, NHANES_AJCN_FIG_V2]:
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(OUT, dest)


def main() -> None:
    ensure_dirs()
    setup_style()
    data = load_data()
    outputs: Dict[str, Dict[str, str]] = {}
    outputs["Figure1_NHANES"] = figure1_nhanes(data)
    outputs["Figure2_CGMacros"] = figure2_cgmacros(data)
    outputs["Figure3_FoodMatrix_Curve"] = figure3_food_curve(data)
    outputs["Figure4_Prediction"] = figure4_prediction(data)
    outputs["Figure5_ExternalBoundary"] = figure5_external(data)
    build_legends()
    build_design_note(outputs)
    build_manifest(outputs)
    shutil.copy2(Path(__file__), OUT / "scripts_24_build_publication_quality_ajcn_figures_v2.py")
    mirror_outputs()
    print(f"Generated publication-quality figure package: {OUT}")
    print(f"Copied into AJCN package: {AJCN_FIG_V2}")
    print(f"Mirrored to NHANES package: {NHANES_PACKAGE}")


if __name__ == "__main__":
    main()
