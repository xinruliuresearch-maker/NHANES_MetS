# NHANES原始单体代谢物混合物模型

生成日期: 2026-06-11

## 目的

本模块重建 NHANES 2013-2018 的原始邻苯二甲酸酯/DEHP 单体代谢物混合物模型，不再把 `ln_Sigma_DEHP`、`pct_oxidative_10` 或 `ln_oxidative_to_MEHP` 作为主混合物输入。

## 主混合物

- DEHP raw four monomers: MEHP, MEHHP, MEOHP, MECPP。
- DEHP oxidative three: MEHHP, MEOHP, MECPP。
- Broad raw phthalate monomers: 所有当前周期可用的原始单体。

## 已输出

- `01_raw_monomer_codebook.csv`: 原始单体变量说明。
- `02_raw_monomer_lod_summary.csv`: LOD 标记与周期分布。
- `03_raw_monomer_sample_flow.csv`: 样本流。
- `04_raw_monomer_analysis_dataset.csv`: 复核分析数据集。
- `05_survey_weighted_single_monomer_glm.csv`: survey-weighted 单体模型。
- `06_survey_weighted_raw_monomer_mixture_qgcomp_like.csv`: 复杂抽样加权 qgcomp-like 主结果。
- `07_survey_weighted_qgcomp_like_component_weights.csv`: 单体方向性权重。
- `08_qgcomp_glm_noboot_weighted_raw_monomer_results.csv`: qgcomp 包敏感性结果。
- `09_gwqs_positive_raw_monomer_results.csv`: gWQS 快速敏感性结果。
- `10_bkmr_run_status.csv` 和 `10_bkmr_pip_summary.csv`: BKMR 探索运行状态与 PIP。

## 解释原则

主文应优先报告复杂抽样加权 qgcomp-like 结果；qgcomp/gWQS/BKMR 作为方法学三角验证。若 qgcomp 包结果与 survey-qgcomp-like 结果方向一致，说明信号不依赖派生比例指标。
