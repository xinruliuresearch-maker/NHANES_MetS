# -*- coding: utf-8 -*-
"""
Build Phase 0-4 package for the no-digestion-experiment version of the
integrated CGMacros + NHANES manuscript.

Outputs:
    outputs/integrated_mainline/no_digestion_phase0_to_phase4

The package intentionally excludes bionic digestion experiment design and wet
experiment data. It repackages completed computational/dry-lab results into
manuscript-ready claims, tables, figure data, abstract/outline, and submission
readiness files.
"""

from __future__ import annotations

from datetime import datetime
from pathlib import Path
import hashlib
import json
import shutil
import textwrap

import numpy as np
import pandas as pd

try:
    import matplotlib.pyplot as plt

    HAS_MPL = True
except Exception:  # pragma: no cover
    HAS_MPL = False


ROOT = Path(__file__).resolve().parents[1]
NHANES_ROOT = ROOT.parent / "NHANES_MetS_Project"
OUT_ROOT = ROOT / "outputs" / "integrated_mainline"
OUT = OUT_ROOT / "no_digestion_phase0_to_phase4"
MIRROR = NHANES_ROOT / "result" / "integrated_mainline" / "no_digestion_phase0_to_phase4"
TODAY = "2026-06-10"


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def mirror_file(path: Path) -> None:
    if not path.exists():
        return
    rel = path.relative_to(OUT)
    dest = MIRROR / rel
    ensure_dir(dest.parent)
    shutil.copy2(path, dest)


def write_text(path: Path, content: str) -> Path:
    ensure_dir(path.parent)
    path.write_text(textwrap.dedent(content).strip() + "\n", encoding="utf-8")
    mirror_file(path)
    return path


def write_csv(path: Path, df: pd.DataFrame) -> Path:
    ensure_dir(path.parent)
    df.to_csv(path, index=False, encoding="utf-8-sig")
    mirror_file(path)
    return path


def write_json(path: Path, payload: dict | list) -> Path:
    ensure_dir(path.parent)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    mirror_file(path)
    return path


def save_fig(path: Path) -> Path | None:
    if not HAS_MPL:
        return None
    ensure_dir(path.parent)
    plt.tight_layout()
    plt.savefig(path, dpi=220)
    plt.close()
    mirror_file(path)
    return path


def read_csv(path: Path) -> pd.DataFrame:
    if not path.exists():
        return pd.DataFrame()
    return pd.read_csv(path)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def estimate_ci(row: pd.Series) -> str:
    for est in ["estimate", "R_beta", "MAE_delta", "mean_delta_pred"]:
        if est in row and pd.notna(row[est]):
            val = float(row[est])
            break
    else:
        return ""
    if "ci_low" in row and "ci_high" in row and pd.notna(row["ci_low"]) and pd.notna(row["ci_high"]):
        return f"{val:.3f} ({float(row['ci_low']):.3f}, {float(row['ci_high']):.3f})"
    if "R_ci_low" in row and "R_ci_high" in row and pd.notna(row["R_ci_low"]) and pd.notna(row["R_ci_high"]):
        return f"{val:.3f} ({float(row['R_ci_low']):.3f}, {float(row['R_ci_high']):.3f})"
    return f"{val:.3f}"


def load_sources() -> dict[str, pd.DataFrame]:
    return {
        "stage1_summary": read_csv(OUT_ROOT / "stage1_msi" / "stage1_msi_summary_by_dataset.csv"),
        "phase1_corr": read_csv(OUT_ROOT / "phase1_qc_msi_sensitivity" / "phase1_msi_version_correlations.csv"),
        "phase1_nhanes_sens": read_csv(OUT_ROOT / "phase1_qc_msi_sensitivity" / "phase1_nhanes_msi_exposure_sensitivity_models.csv"),
        "phase1_ppgr_sens": read_csv(OUT_ROOT / "phase1_qc_msi_sensitivity" / "phase1_msi_ppgr_sensitivity_models.csv"),
        "phase2_r_key": read_csv(OUT_ROOT / "phase2_nhanes_survey_ready" / "phase2_R_survey_key_results.csv"),
        "phase2_quartile": read_csv(OUT_ROOT / "phase2_nhanes_survey_ready" / "phase2_nhanes_dose_response_quartile_summary.csv"),
        "stage3_key": read_csv(OUT_ROOT / "stage3_cgmacros_msi_ppgr" / "stage3_cgmacros_msi_ppgr_key_results.csv"),
        "stage3_tertile": read_csv(OUT_ROOT / "stage3_cgmacros_msi_ppgr" / "stage3_msi_tertile_ppgr_summary.csv"),
        "phase3_boot": read_csv(OUT_ROOT / "phase3_cgmacros_robust_inference" / "phase3_subject_bootstrap_key_terms.csv"),
        "module_c_models": read_csv(OUT_ROOT / "dry_lab_booster_modules" / "module_C_cgmacros_food_matrix" / "cgmacros_food_matrix_ppgr_models.csv"),
        "module_d_clusters": read_csv(OUT_ROOT / "dry_lab_booster_modules" / "module_D_cgm_curve_phenotypes" / "cgmacros_ppgr_shape_clusters.csv"),
        "module_d_models": read_csv(OUT_ROOT / "dry_lab_booster_modules" / "module_D_cgm_curve_phenotypes" / "curve_shape_msi_food_matrix_models.csv"),
        "phase4_perf": read_csv(OUT_ROOT / "phase4_prediction_upgrade" / "phase4_model_performance_overall.csv"),
        "phase4_delta": read_csv(OUT_ROOT / "phase4_prediction_upgrade" / "phase4_model_comparison_key_deltas.csv"),
        "phase4_conformal": read_csv(OUT_ROOT / "phase4_prediction_upgrade" / "phase4_conformal_interval_coverage.csv"),
        "phase5_boundary": read_csv(OUT_ROOT / "phase5_external_validation" / "phase5_external_boundary_summary.csv"),
        "phase5_stanford": read_csv(OUT_ROOT / "phase5_external_validation" / "phase5_stanford_msi_proxy_models.csv"),
        "phase5_t1d": read_csv(OUT_ROOT / "phase5_external_validation" / "phase5_t1d_uom_macro_ppgr_models.csv"),
        "module_g_counterfactual": read_csv(OUT_ROOT / "dry_lab_booster_modules" / "module_G_counterfactual_meal_redesign" / "counterfactual_meal_redesign_effects.csv"),
        "module_e_pathway": read_csv(OUT_ROOT / "dry_lab_booster_modules" / "module_E_mechanism_knowledge_graph" / "dehp_msi_pathway_enrichment.csv"),
        "module_a_evidence": read_csv(OUT_ROOT / "dry_lab_booster_modules" / "module_A_literature_evidence_map" / "dry_lab_evidence_map_seed.csv"),
    }


def phase0_scope_claims(src: dict[str, pd.DataFrame]) -> dict:
    out = OUT / "phase0_scope_and_claims"
    ensure_dir(out)
    registry = pd.DataFrame(
        [
            {
                "phase": "0",
                "analysis_unit": "scope",
                "question": "What is the no-digestion manuscript claim space?",
                "input": "completed Phase 0-5 and dry-lab booster outputs",
                "output": "scope, analysis registry, overclaim guardrails",
                "status": "completed",
            },
            {
                "phase": "1",
                "analysis_unit": "evidence audit",
                "question": "Which current results are main, supplementary, or exploratory?",
                "input": "all key result CSV files",
                "output": "evidence grade and crosswalk",
                "status": "completed",
            },
            {
                "phase": "2",
                "analysis_unit": "tables/figures",
                "question": "What are the manuscript-ready tables and figure datasets?",
                "input": "NHANES, CGMacros, prediction, external boundary result tables",
                "output": "main tables, figure data, draft figures",
                "status": "completed",
            },
            {
                "phase": "3",
                "analysis_unit": "manuscript skeleton",
                "question": "How should the no-digestion paper be written?",
                "input": "evidence grade and tables",
                "output": "abstract, title options, outline, figure storyboard",
                "status": "completed",
            },
            {
                "phase": "4",
                "analysis_unit": "submission readiness",
                "question": "What remains before submission if digestion experiments are excluded?",
                "input": "all Phase 0-3 outputs",
                "output": "readiness audit, limitations, checklists, next actions",
                "status": "completed",
            },
        ]
    )
    write_csv(out / "phase0_no_digestion_analysis_registry.csv", registry)
    guardrails = pd.DataFrame(
        [
            {
                "risk": "Cross-dataset causal overclaim",
                "do_not_write": "DEHP causes higher PPGR in CGMacros.",
                "preferred_language": "DEHP oxidative profile is associated with MSI in NHANES; MSI is expressed as PPGR vulnerability in CGMacros.",
                "severity": "high",
            },
            {
                "risk": "Mediator overclaim",
                "do_not_write": "MSI mediates the causal effect of DEHP on PPGR.",
                "preferred_language": "MSI is a bridge phenotype linking population exposure signals with dynamic CGM phenotypes.",
                "severity": "high",
            },
            {
                "risk": "Food matrix overclaim",
                "do_not_write": "Digestibility-risk is experimentally validated digestion kinetics.",
                "preferred_language": "Digestibility-risk is a dry-lab food matrix proxy requiring expert/photo/database validation.",
                "severity": "high",
            },
            {
                "risk": "Prediction overclaim",
                "do_not_write": "The model precisely predicts individual glucose excursions for clinical use.",
                "preferred_language": "The MSI-enhanced model improves high-response meal risk stratification and calibration.",
                "severity": "medium",
            },
            {
                "risk": "External validation overclaim",
                "do_not_write": "Stanford/T1D-UOM externally validate the CGMacros MSI model.",
                "preferred_language": "External datasets provide transportability boundaries and directional macro-response support.",
                "severity": "medium",
            },
        ]
    )
    write_csv(out / "phase0_overclaim_guardrails.csv", guardrails)
    write_text(
        out / "phase0_scope_and_claims_report.md",
        f"""
        # Phase 0：无消化实验版本研究范围与主张冻结

        日期：{TODAY}

        ## 论文主线

        > DEHP oxidative profile -> metabolic susceptibility phenotype -> postprandial glycemic vulnerability and personalized meal-risk prediction

        ## 主问题

        1. NHANES 中 DEHP oxidative metabolic profile 是否与 MSI/HOMA-IR/HbA1c 相关？
        2. CGMacros 中 MSI 是否表现为自由生活 PPGR vulnerability？
        3. MSI 是否能改善 high-response meal prediction？
        4. food matrix/digestibility-risk proxy 和 CGM curve phenotypes 是否能深化 PPGR vulnerability 的动态解释？
        5. 外部 CGM 数据是否提供边界和方向支持？

        ## 明确排除

        本版本不纳入仿生消化实验、体外释放曲线、original/redesigned 湿实验验证或任何尚未完成的实验数据。

        ## 最高层主张

        当前结果支持一篇整合型计算/观察性论文：环境暴露相关 metabolic susceptibility phenotype 在独立 CGM 餐食数据中表现为 PPGR vulnerability，并可用于 high-response meal risk stratification。
        """,
    )
    return {"phase": "0", "files": 3, "summary": "scope, registry, and overclaim guardrails completed"}


def phase1_evidence_audit(src: dict[str, pd.DataFrame]) -> dict:
    out = OUT / "phase1_evidence_audit"
    ensure_dir(out)
    dataset_inventory = pd.DataFrame(
        [
            {"dataset": "NHANES_2013_2018", "role": "population exposure-metabolic susceptibility", "n_subjects": 5267, "n_events": np.nan, "key_output": "phase2_R_survey_key_results.csv"},
            {"dataset": "CGMacros", "role": "development CGM free-living meal cohort", "n_subjects": 40, "n_events": 1498, "key_output": "stage3_cgmacros_msi_ppgr_key_results.csv"},
            {"dataset": "Stanford_CGMDB", "role": "standardized food challenge boundary", "n_subjects": 38, "n_events": 588, "key_output": "phase5_stanford_food_challenge_metrics.csv"},
            {"dataset": "T1D_UOM", "role": "T1D free-living meal boundary", "n_subjects": 15, "n_events": 3820, "key_output": "phase5_t1d_uom_macro_ppgr_models.csv"},
            {"dataset": "Jaeb_CGMND_HealthyAdults", "role": "healthy CGM reference boundary", "n_subjects": 169, "n_events": 383117, "key_output": "phase5_jaeb_healthy_adults_cgm_summary.csv"},
        ]
    )
    write_csv(out / "phase1_dataset_inventory.csv", dataset_inventory)

    evidence_rows = [
        {
            "claim_id": "C1",
            "claim": "DEHP oxidative profile is associated with MSI and insulin-resistance/glycemic markers in NHANES.",
            "primary_evidence": "R survey: ln(Oxidative/MEHP) -> MSI-core beta 0.183, q 0.003421; ln(HOMA-IR) beta 0.218, q 0.003421; HbA1c beta 0.135, q 0.003421.",
            "evidence_grade": "main_text_strong",
            "main_or_supplement": "main",
            "main_limitation": "cross-sectional NHANES association",
        },
        {
            "claim_id": "C2",
            "claim": "MSI is robustly associated with free-living PPGR vulnerability in CGMacros.",
            "primary_evidence": "Cluster-robust models and subject bootstrap: MSI -> iAUC/1000 beta 1.070; bootstrap CI 0.587 to 1.667; MSI -> peak beta 17.356; bootstrap CI 9.831 to 26.145.",
            "evidence_grade": "main_text_strong",
            "main_or_supplement": "main",
            "main_limitation": "40 subjects, many meals but subject-level sample modest",
        },
        {
            "claim_id": "C3",
            "claim": "MSI-enhanced prediction improves high-response discrimination and calibration.",
            "primary_evidence": "M3 vs M2: iAUC MAE -7.16%, AUC +0.074; peak MAE -9.02%, AUC +0.084.",
            "evidence_grade": "main_text_moderate_strong",
            "main_or_supplement": "main",
            "main_limitation": "risk stratification better than precise individual quantitative prediction",
        },
        {
            "claim_id": "C4",
            "claim": "Food matrix/digestibility-risk proxy interacts with MSI for PPGR vulnerability.",
            "primary_evidence": "MSI x digestibility-risk: iAUC/1000 beta 0.410, q 0.000118; peak beta 4.988, q 0.000104.",
            "evidence_grade": "main_text_exploratory_high_interest",
            "main_or_supplement": "main_or_extended",
            "main_limitation": "proxy annotation, not expert-coded or experimentally validated",
        },
        {
            "claim_id": "C5",
            "claim": "High-risk CGM curve phenotypes show higher MSI and digestibility-risk.",
            "primary_evidence": "large_prolonged_response cluster: n=215, mean iAUC 8963.3, mean peak 129.8, mean MSI 0.601, mean digestibility 0.857.",
            "evidence_grade": "main_text_moderate",
            "main_or_supplement": "main_or_extended",
            "main_limitation": "trajectory features derived from meal-level summaries, not full FPCA yet",
        },
        {
            "claim_id": "C6",
            "claim": "External datasets support boundaries and macro-response direction, not direct MSI replication.",
            "primary_evidence": "T1D-UOM carbs positive and fiber negative; Stanford MSI proxy not significant; Jaeb healthy time above 140 around 2.1%.",
            "evidence_grade": "supplementary_support",
            "main_or_supplement": "supplement",
            "main_limitation": "heterogeneous populations and variables",
        },
    ]
    evidence = pd.DataFrame(evidence_rows)
    write_csv(out / "phase1_key_findings_evidence_grade.csv", evidence)
    crosswalk = []
    for name, df in src.items():
        if df.empty:
            continue
        crosswalk.append({"source_key": name, "n_rows": len(df), "n_columns": len(df.columns), "columns": "; ".join(map(str, df.columns[:20]))})
    write_csv(out / "phase1_result_source_crosswalk.csv", pd.DataFrame(crosswalk))
    write_text(
        out / "phase1_evidence_audit_report.md",
        f"""
        # Phase 1：当前证据审计

        日期：{TODAY}

        ## 判断

        当前证据足以支撑无消化实验版本论文，但定位应是整合型计算/观察性研究，而不是机制干预闭环研究。

        ## 主文核心

        - C1：NHANES DEHP oxidative profile -> MSI/HOMA/HbA1c。
        - C2：CGMacros MSI -> PPGR vulnerability。
        - C3：MSI-enhanced high-response prediction。
        - C4：MSI x digestibility-risk proxy 是深化亮点，但需谨慎写作。
        - C5：CGM curve phenotype 可增强 dynamic vulnerability 叙事。

        ## 补充/边界

        - C6：外部数据主要用于 boundary/transportability，不作为直接 replication。
        - 机制知识图谱用于 Discussion/Supplementary，不作为机制发现。
        """,
    )
    return {"phase": "1", "files": 3, "summary": "dataset inventory, evidence grades, and source crosswalk completed"}


def phase2_tables_figures(src: dict[str, pd.DataFrame]) -> dict:
    out = OUT / "phase2_manuscript_tables_and_figures"
    ensure_dir(out)

    # Table 1
    stage1 = src["stage1_summary"].copy()
    external = src["phase5_boundary"].copy()
    table1_rows = []
    if not stage1.empty:
        for _, r in stage1.iterrows():
            table1_rows.append(
                {
                    "dataset": r["dataset"],
                    "role": "MSI construction / internal analysis",
                    "n_subjects_or_participants": int(r["n"]),
                    "n_meals_or_events": 1498 if r["dataset"] == "CGMacros_subjects" else np.nan,
                    "n_msi_partial": r.get("n_msi_partial", np.nan),
                    "median_msi": r.get("median_msi_partial", np.nan),
                    "high_tertile_n": r.get("n_high_tertile", np.nan),
                }
            )
    if not external.empty:
        for _, r in external.iterrows():
            if r["dataset"] == "CGMacros":
                continue
            table1_rows.append(
                {
                    "dataset": r["dataset"],
                    "role": r.get("event_type", "external boundary"),
                    "n_subjects_or_participants": r.get("n_subjects", np.nan),
                    "n_meals_or_events": r.get("n_events", np.nan),
                    "n_msi_partial": np.nan,
                    "median_msi": np.nan,
                    "high_tertile_n": np.nan,
                }
            )
    table1 = pd.DataFrame(table1_rows)
    write_csv(out / "Table1_dataset_and_phenotype_summary.csv", table1)

    # Table 2 NHANES
    nhanes = src["phase2_r_key"].copy()
    if not nhanes.empty:
        nhanes["estimate_CI_for_table"] = nhanes.apply(lambda r: f"{r['R_beta']:.3f} ({r['R_ci_low']:.3f}, {r['R_ci_high']:.3f})", axis=1)
        table2 = nhanes[
            [
                "outcome",
                "exposure",
                "R_beta",
                "R_ci_low",
                "R_ci_high",
                "R_p",
                "R_q",
                "estimate_CI_for_table",
                "R_significant_q05",
            ]
        ].copy()
    else:
        table2 = pd.DataFrame()
    write_csv(out / "Table2_NHANES_R_survey_key_results.csv", table2)

    # Table 3 CGMacros
    stage3 = src["stage3_key"].copy()
    terms = ["carbs_10g", "msi_core_centered", "carbs_x_msi"]
    table3 = stage3.loc[
        stage3.get("term", pd.Series(dtype=str)).isin(terms)
        & stage3.get("model", pd.Series(dtype=str)).isin(["base_interaction", "macro_context_interaction"])
    ].copy()
    if not table3.empty:
        table3["estimate_CI_for_table"] = table3.apply(estimate_ci, axis=1)
    write_csv(out / "Table3_CGMacros_MSI_PPGR_results.csv", table3)

    # Table 4 food matrix and curve phenotypes
    c = src["module_c_models"].copy()
    d = src["module_d_models"].copy()
    table4_parts = []
    if not c.empty:
        tc = c.loc[c["term"].isin(["msi_centered", "digestibility_centered", "msi_x_digestibility"])].copy()
        tc["analysis_block"] = "food_matrix_ppgr"
        tc["outcome"] = tc["outcome_label"]
        table4_parts.append(tc)
    if not d.empty:
        td = d.loc[
            d["term"].isin(["msi_centered", "digestibility_centered", "msi_x_digestibility"])
            & d["outcome"].isin(["delayed_peak_flag", "prolonged_elevation_flag", "low_stable_response_flag", "early_slope_proxy_0_to_peak"])
        ].copy()
        td["analysis_block"] = "curve_phenotype"
        td["outcome_label"] = td["outcome"]
        table4_parts.append(td)
    table4 = pd.concat(table4_parts, ignore_index=True, sort=False) if table4_parts else pd.DataFrame()
    if not table4.empty:
        table4["estimate_CI_for_table"] = table4.apply(estimate_ci, axis=1)
        keep = [c for c in ["analysis_block", "outcome", "outcome_label", "term", "estimate", "ci_low", "ci_high", "p_value", "q_value", "n", "estimate_CI_for_table"] if c in table4.columns]
        table4 = table4[keep]
    write_csv(out / "Table4_FoodMatrix_CurvePhenotype_results.csv", table4)

    # Table 5 prediction and external boundary
    perf = src["phase4_perf"].copy()
    delta = src["phase4_delta"].copy()
    boundary = src["phase5_boundary"].copy()
    if not perf.empty:
        write_csv(out / "Table5A_prediction_model_performance.csv", perf)
    if not delta.empty:
        write_csv(out / "Table5B_prediction_incremental_gain.csv", delta)
    if not boundary.empty:
        write_csv(out / "Table5C_external_boundary_summary.csv", boundary)

    # Supplemental counterfactual and mechanism
    counter = src["module_g_counterfactual"].copy()
    if not counter.empty:
        counter_focus = counter.loc[counter["target"].eq("iauc_2h")].sort_values("mean_delta_pred")
        write_csv(out / "Supplement_counterfactual_meal_redesign_summary.csv", counter_focus)
    pathway = src["module_e_pathway"].copy()
    if not pathway.empty:
        write_csv(out / "Supplement_mechanism_pathway_bridge_summary.csv", pathway)

    # Figure data
    if not table2.empty:
        fig2 = table2.loc[table2["exposure"].isin(["ln_oxidative_to_MEHP", "pct_oxidative_10"])].copy()
        write_csv(out / "Figure2_data_NHANES_forest.csv", fig2)
    tertile = src["stage3_tertile"].copy()
    if not tertile.empty:
        write_csv(out / "Figure3_data_MSI_tertile_PPGR.csv", tertile)
    clusters = src["module_d_clusters"].copy()
    if not clusters.empty:
        write_csv(out / "Figure4_data_curve_clusters.csv", clusters)
    if not perf.empty:
        write_csv(out / "Figure5_data_prediction_performance.csv", perf)

    if HAS_MPL:
        if not table2.empty:
            focus = table2.loc[table2["exposure"].eq("ln_oxidative_to_MEHP")].copy()
            focus = focus.sort_values("R_beta")
            plt.figure(figsize=(7, 4))
            y = np.arange(len(focus))
            plt.errorbar(
                focus["R_beta"],
                y,
                xerr=[focus["R_beta"] - focus["R_ci_low"], focus["R_ci_high"] - focus["R_beta"]],
                fmt="o",
                color="#1F4E79",
            )
            plt.axvline(0, color="black", linewidth=0.8)
            plt.yticks(y, focus["outcome"])
            plt.xlabel("R survey beta")
            plt.title("Figure 2 draft: ln(Oxidative/MEHP) associations")
            save_fig(out / "Figure2_draft_NHANES_forest.png")
        if not tertile.empty:
            plt.figure(figsize=(6, 4))
            x = np.arange(len(tertile))
            width = 0.35
            plt.bar(x - width / 2, tertile["mean_iauc_2h"], width, label="mean iAUC", color="#386641")
            ax2 = plt.gca().twinx()
            ax2.bar(x + width / 2, tertile["mean_peak_delta_2h"], width, label="mean peak", color="#BC4749")
            plt.gca().set_xticks(x)
            plt.gca().set_xticklabels(tertile["msi_tertile"].astype(str))
            plt.gca().set_ylabel("Mean iAUC")
            ax2.set_ylabel("Mean peak")
            plt.title("Figure 3 draft: PPGR by MSI tertile")
            save_fig(out / "Figure3_draft_MSI_tertile_PPGR.png")
        if not clusters.empty:
            plt.figure(figsize=(7, 4))
            plt.scatter(clusters["mean_peak_delta_2h"], clusters["mean_iauc_2h"], s=clusters["n_meals"] * 1.5, color="#6A4C93", alpha=0.75)
            for _, r in clusters.iterrows():
                plt.text(r["mean_peak_delta_2h"], r["mean_iauc_2h"], str(r["shape_cluster_id"]))
            plt.xlabel("Mean peak delta")
            plt.ylabel("Mean iAUC")
            plt.title("Figure 4 draft: CGM curve phenotype clusters")
            save_fig(out / "Figure4_draft_curve_clusters.png")
        if not perf.empty:
            focus = perf.loc[perf["model"].isin(["M0_carb_only", "M2_macro_precgm_context", "M3_msi_enhanced"])].copy()
            plt.figure(figsize=(7, 4))
            for target, g in focus.groupby("target"):
                plt.plot(g["model"], g["AUC_high_response"], marker="o", label=target)
            plt.ylim(0.5, 0.85)
            plt.ylabel("AUC high response")
            plt.xticks(rotation=15, ha="right")
            plt.title("Figure 5 draft: MSI-enhanced prediction")
            plt.legend()
            save_fig(out / "Figure5_draft_prediction_AUC.png")

    write_text(
        out / "phase2_tables_and_figures_report.md",
        f"""
        # Phase 2：主表、主图数据与草图

        日期：{TODAY}

        ## 已完成

        - Table 1：数据集与核心表型概览。
        - Table 2：NHANES R survey 主结果。
        - Table 3：CGMacros MSI -> PPGR 主模型。
        - Table 4：food matrix/digestibility-risk 和 CGM curve phenotype。
        - Table 5A-C：预测模型、增益和外部边界。
        - Figure 2-5 数据文件和 draft PNG（若 matplotlib 可用）。

        ## 重要取舍

        无消化实验版本中，Figure 5 应展示 prediction + counterfactual + external boundary，而不是体外消化曲线。
        """,
    )
    return {"phase": "2", "files": len(list(out.glob("*"))), "summary": "manuscript tables, figure data, and draft figures completed"}


def phase3_manuscript_skeleton(src: dict[str, pd.DataFrame]) -> dict:
    out = OUT / "phase3_manuscript_skeleton"
    ensure_dir(out)
    titles = pd.DataFrame(
        [
            {"rank": 1, "title": "A metabolic susceptibility phenotype links phthalate oxidative metabolism with real-world postprandial glycemic vulnerability", "positioning": "best integrated observational/computational framing"},
            {"rank": 2, "title": "Metabolic susceptibility-aware prediction of postprandial glycemic vulnerability in free-living meals", "positioning": "precision nutrition / CGM emphasis"},
            {"rank": 3, "title": "DEHP oxidative metabolic profile, metabolic susceptibility, and personalized postprandial glucose risk", "positioning": "environment plus digital nutrition"},
            {"rank": 4, "title": "Food matrix risk and metabolic susceptibility shape postprandial glucose dynamics", "positioning": "food matrix / nutrition science emphasis"},
        ]
    )
    write_csv(out / "phase3_title_options.csv", titles)
    claims = pd.DataFrame(
        [
            {"claim_order": 1, "claim": "DEHP oxidative metabolic profile is associated with MSI/HOMA/HbA1c in NHANES.", "figure": "Figure 2", "strength": "strong association", "caution": "cross-sectional"},
            {"claim_order": 2, "claim": "MSI predicts free-living PPGR vulnerability in CGMacros.", "figure": "Figure 3", "strength": "strong internal evidence", "caution": "40 subjects"},
            {"claim_order": 3, "claim": "Food matrix/digestibility-risk proxy and MSI interact for PPGR outcomes.", "figure": "Figure 4", "strength": "high-interest exploratory", "caution": "proxy annotation"},
            {"claim_order": 4, "claim": "MSI-enhanced models improve high-response meal prediction.", "figure": "Figure 5", "strength": "moderate-strong prediction evidence", "caution": "risk stratification, not clinical deployment"},
            {"claim_order": 5, "claim": "External CGM datasets define transportability boundaries.", "figure": "Figure 5 / Supplement", "strength": "supportive", "caution": "not direct MSI validation"},
        ]
    )
    write_csv(out / "phase3_main_claims_table_no_digestion.csv", claims)
    write_text(
        out / "phase3_structured_abstract_draft.md",
        """
        # Structured Abstract Draft

        ## Background

        Postprandial glycemic responses vary substantially across individuals and meals, but the environmental and metabolic susceptibility axes underlying this vulnerability remain incompletely characterized.

        ## Objective

        To test whether a DEHP oxidative metabolic profile is associated with a metabolic susceptibility phenotype in NHANES, and whether this phenotype stratifies free-living postprandial glycemic vulnerability and high-response meal prediction in CGMacros.

        ## Methods

        We integrated NHANES 2013-2018 urinary DEHP metabolite data with CGMacros continuous glucose monitoring meals. A metabolic susceptibility index (MSI) was constructed from BMI, HbA1c, fasting glucose, HOMA-IR and TG/HDL-C using NHANES reference scaling. Survey-weighted NHANES models evaluated DEHP oxidative profile associations with MSI and metabolic markers. Subject-clustered CGMacros models tested MSI associations with 2-hour iAUC, peak glucose excursion, high-response risk, food matrix proxies, and CGM curve phenotypes. Nested leave-subject-out models evaluated MSI-enhanced prediction, calibration and high-response discrimination. External CGM datasets were used to define transportability boundaries.

        ## Results

        In NHANES, ln(Oxidative/MEHP) was associated with higher MSI-core, ln(HOMA-IR), and HbA1c after survey-design adjustment. In CGMacros, higher MSI was associated with higher 2-hour iAUC, peak excursion, and high-response risk, with subject bootstrap support. A dry-lab digestibility-risk proxy and MSI-by-digestibility-risk terms were associated with iAUC and peak responses. MSI-enhanced prediction improved high-response AUC and calibration relative to macro/pre-CGM/context models. External datasets supported meal-response heterogeneity and expected carbohydrate/fiber directions while defining limits to transportability.

        ## Conclusions

        A DEHP oxidative metabolic profile is associated with metabolic susceptibility in NHANES, and the same susceptibility phenotype stratifies real-world postprandial glycemic vulnerability and personalized meal-risk prediction in CGMacros. These findings support metabolic susceptibility-aware precision nutrition while requiring prospective and mechanistic validation.
        """,
    )
    write_text(
        out / "phase3_manuscript_outline_no_digestion_v1.md",
        """
        # Manuscript Outline: No-digestion Version

        ## Introduction

        1. PPGR is highly individualized and clinically relevant.
        2. Environmental metabolic disruptors, including DEHP/phthalates, associate with insulin resistance and metabolic syndrome, but rarely connect to dynamic CGM phenotypes.
        3. A bridge phenotype is needed to connect population exposure biology and free-living meal responses.
        4. Study objective: integrate NHANES and CGMacros to test a susceptibility-aware PPGR framework.

        ## Methods

        - Study design and data sources.
        - MSI construction and scaling.
        - NHANES survey-weighted DEHP/MSI analyses.
        - CGMacros meal-level PPGR outcomes.
        - Robust subject-clustered and bootstrap inference.
        - Food matrix/digestibility-risk proxy annotation.
        - Curve phenotype analysis.
        - Prediction models and nested leave-subject-out validation.
        - External boundary datasets.
        - Reporting standards and reproducibility.

        ## Results

        1. Dataset overview and MSI robustness.
        2. DEHP oxidative profile is associated with MSI and metabolic markers in NHANES.
        3. MSI stratifies CGMacros PPGR vulnerability.
        4. Food matrix proxy and CGM curve phenotypes deepen dynamic vulnerability.
        5. MSI-enhanced prediction improves high-response risk stratification.
        6. External datasets define boundaries and support macro-response direction.

        ## Discussion

        - Main contribution: environmental-metabolic susceptibility phenotype expressed as dynamic PPGR vulnerability.
        - Implications for precision nutrition and exposure-informed risk stratification.
        - Why MSI x digestibility-risk is stronger than simple carbs x MSI.
        - Limitations: cross-dataset bridge, proxy food matrix, modest CGMacros subjects, no mechanistic/intervention proof.
        - Next step: expert-coded food matrix and prospective/mechanistic validation.
        """,
    )
    write_text(
        out / "phase3_figure_storyboard_no_digestion_v1.md",
        """
        # Figure Storyboard: No-digestion Version

        ## Figure 1

        Study framework and dataset map: NHANES -> MSI bridge -> CGMacros PPGR vulnerability -> prediction and external boundary.

        ## Figure 2

        NHANES R survey forest plot and quartile trend for ln(Oxidative/MEHP) and %Oxidative against MSI, ln(HOMA-IR), HbA1c.

        ## Figure 3

        CGMacros MSI tertiles, PPGR distributions, cluster-robust models and subject bootstrap.

        ## Figure 4

        Food matrix/digestibility-risk proxy, MSI x digestibility-risk, and CGM curve phenotype clusters.

        ## Figure 5

        Prediction and personalization: M0-M3 performance, AUC/AUPRC/calibration, conformal coverage, counterfactual meal-risk scenarios and external boundary map.
        """,
    )
    return {"phase": "3", "files": 4, "summary": "title options, claims table, abstract, outline, and storyboard completed"}


def phase4_submission_readiness(src: dict[str, pd.DataFrame]) -> dict:
    out = OUT / "phase4_submission_readiness"
    ensure_dir(out)
    readiness = pd.DataFrame(
        [
            {"item": "Main analysis results", "status": "complete", "evidence": "Phase 2/3/4 key CSVs available", "next_action": "convert draft figures to journal style"},
            {"item": "R survey NHANES main models", "status": "complete", "evidence": "phase2_R_survey_key_results.csv", "next_action": "migrate selected RCS/subgroup models to R survey if used in main text"},
            {"item": "MSI robustness", "status": "complete", "evidence": "phase1_msi_version_correlations.csv", "next_action": "summarize in supplement"},
            {"item": "Food matrix annotation", "status": "partial", "evidence": "dry-lab proxy available", "next_action": "manual photo/database validation before strong claims"},
            {"item": "Prediction reporting", "status": "mostly complete", "evidence": "TRIPOD+AI draft, model card, leakage audit", "next_action": "complete final checklist with manuscript line references"},
            {"item": "External validation", "status": "boundary complete", "evidence": "Stanford/T1D/Jaeb summaries", "next_action": "write as boundary analysis, not direct validation"},
            {"item": "Mechanistic validation", "status": "not included", "evidence": "mechanism graph only", "next_action": "state as limitation in no-digestion version"},
            {"item": "Manuscript text", "status": "draft skeleton complete", "evidence": "phase3 outline and abstract", "next_action": "write full English manuscript"},
        ]
    )
    write_csv(out / "phase4_submission_readiness_audit.csv", readiness)
    write_text(
        out / "phase4_limitations_and_reviewer_response_plan.md",
        """
        # Limitations and Reviewer Response Plan

        ## Likely reviewer concern 1: NHANES and CGMacros are different cohorts.

        Response: The manuscript does not claim individual-level mediation. MSI is framed as a bridge phenotype. NHANES tests exposure-to-susceptibility association; CGMacros tests susceptibility-to-dynamic-PPGR expression.

        ## Likely reviewer concern 2: Food matrix variables are proxies.

        Response: Label digestibility-risk as dry-lab food matrix proxy. Place strongest claims on MSI main effects and prediction; present food matrix as exploratory mechanistic-prioritization layer.

        ## Likely reviewer concern 3: CGMacros has only 40 subjects.

        Response: Use subject-clustered inference, leave-subject-out prediction, subject bootstrap, leave-one-subject influence, and clear subject-level limitations.

        ## Likely reviewer concern 4: Prediction error is still large.

        Response: Frame model as high-response risk stratification and prioritization, not precise clinical glucose forecasting.

        ## Likely reviewer concern 5: External datasets do not replicate MSI.

        Response: Present external datasets as boundary/transportability analyses. Stanford lacks full MSI variables and T1D-UOM is a disease-state boundary.
        """,
    )
    write_text(
        out / "phase4_reporting_checklist_readiness.md",
        """
        # Reporting Checklist Readiness

        ## STROBE / STROBE-ME

        - NHANES study population, cycles, weights and covariates: ready.
        - Urinary biomarker handling and creatinine adjustment: ready.
        - Cross-sectional limitation: must be explicit.
        - RCS/subgroup survey finalization: needed if included in main figures.

        ## STROBE-nut

        - CGMacros meal variables and food matrix proxy: ready as dry-lab proxy.
        - Manual food annotation: still recommended before strong food-structure claims.

        ## TRIPOD+AI

        - Prediction objective, predictors, outcomes and nested leave-subject-out validation: ready.
        - Calibration, AUC/AUPRC, conformal intervals, leakage audit: ready.
        - Final checklist must include manuscript line references.

        ## PROBAST+AI

        - Self-assessment exists.
        - Overall risk should be described as moderate due to sample size and proxy annotation.
        """,
    )
    write_text(
        out / "phase4_target_journal_positioning.md",
        """
        # Target Journal Positioning Without Digestion Experiments

        ## Stronger fit

        - American Journal of Clinical Nutrition
        - Clinical Nutrition
        - npj Science of Food
        - Nutrition & Diabetes
        - Environment International / Environmental Health, if split toward NHANES

        ## Possible but harder

        - Nature Food: possible only if food matrix annotation and story are very polished, but lack of mechanistic validation is a weakness.
        - Cell Metabolism / Nature Metabolism: currently less suitable without mechanistic or intervention evidence.

        ## Best no-digestion framing

        This is not a wet-mechanism paper. It is an integrated environmental epidemiology + CGM precision nutrition + risk prediction paper.
        """,
    )
    write_text(
        out / "phase4_next_actions_without_digestion.md",
        """
        # Next Actions Without Digestion Experiments

        1. Convert Phase 2 draft figures into publication-quality Figure 2-5.
        2. Complete manual/photo/database validation for food matrix annotation.
        3. Rerun selected RCS/subgroup analyses in R survey if they remain in main figures.
        4. Write full English manuscript from the Phase 3 outline.
        5. Move few-shot personalization, mechanism graph, and external boundary details to supplement.
        6. Finalize TRIPOD+AI, PROBAST+AI, STROBE-ME and STROBE-nut checklists with line references.
        7. Prepare cover letter emphasizing bridge phenotype and PPGR vulnerability, while acknowledging absence of direct mechanistic validation.
        """,
    )
    return {"phase": "4", "files": 5, "summary": "submission readiness, limitations, reporting checklist, journal positioning, and next actions completed"}


def build_manifest(results: list[dict]) -> None:
    files = []
    script_archive = OUT / "scripts" / Path(__file__).name
    ensure_dir(script_archive.parent)
    shutil.copy2(Path(__file__), script_archive)
    mirror_file(script_archive)
    for p in sorted(OUT.rglob("*")):
        if p.is_file():
            files.append(
                {
                    "relative_path": str(p.relative_to(OUT)),
                    "bytes": p.stat().st_size,
                    "sha256": sha256_file(p),
                    "last_write_time": datetime.fromtimestamp(p.stat().st_mtime).isoformat(timespec="seconds"),
                }
            )
    write_csv(OUT / "phase0_to_phase4_file_manifest.csv", pd.DataFrame(files))
    write_json(OUT / "phase0_to_phase4_completion_summary.json", results)


def write_master_report(results: list[dict]) -> None:
    lines = [f"- Phase {r['phase']}: {r['summary']}" for r in results]
    report = f"""
    # No-digestion Phase 0-4 Master Report

    日期：{TODAY}

    ## 完成范围

    本次完成的是不考虑消化实验版本的 Phase 0-4，聚焦已经完成的计算分析、干实验补强、外部边界和预测模型。所有湿实验、仿生消化实验设计和未产生的实验数据均未纳入主线。

    ## 完成状态

    {chr(10).join(lines)}

    ## 当前论文主线

    > DEHP oxidative profile -> metabolic susceptibility phenotype -> postprandial glycemic vulnerability and personalized meal-risk prediction

    ## 可直接使用的主结果

    1. NHANES R survey：ln(Oxidative/MEHP) 与 MSI-core、ln(HOMA-IR)、HbA1c 显著相关。
    2. CGMacros：MSI 稳定预测 iAUC、peak 和 high-response risk。
    3. Food matrix proxy：MSI x digestibility-risk 对 iAUC 和 peak 显著。
    4. Curve phenotype：large_prolonged_response cluster 具有最高 MSI、最高 digestibility-risk 和最高 PPGR。
    5. Prediction：M3 MSI-enhanced 相比 M2 改善 MAE、AUC 和 calibration slope。

    ## 最重要的限制

    1. DEHP 和 PPGR 不在同一人群中直接观测。
    2. Food matrix/digestibility-risk 仍是 proxy。
    3. CGMacros subject-level 样本量有限。
    4. 外部数据是 boundary，不是直接 replication。
    5. 无消化实验版本缺少机制/干预闭环。

    ## 输出目录

    - CGMacros: `{OUT}`
    - NHANES mirror: `{MIRROR}`
    """
    write_text(OUT / f"no_digestion_phase0_to_phase4_master_report_{TODAY}.md", report)


def main() -> None:
    ensure_dir(OUT)
    ensure_dir(MIRROR)
    src = load_sources()
    results = []
    for fn in [phase0_scope_claims, phase1_evidence_audit, phase2_tables_figures, phase3_manuscript_skeleton, phase4_submission_readiness]:
        print(f"Running {fn.__name__} ...")
        results.append(fn(src))
    build_manifest(results)
    write_master_report(results)
    print(f"Completed no-digestion Phase 0-4 package: {OUT}")


if __name__ == "__main__":
    main()
