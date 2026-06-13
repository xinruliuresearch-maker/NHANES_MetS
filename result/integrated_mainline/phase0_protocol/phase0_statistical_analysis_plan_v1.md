# Phase 0: Integrated Statistical Analysis Plan v1

日期：2026-06-10

## 冻结后的主线

DEHP oxidative profile -> MSI-core metabolic susceptibility -> PPGR vulnerability -> digestion-informed meal redesign.

这条主线使用 MSI-core 作为跨项目桥梁。NHANES 负责上游人群暴露-代谢易感性证据；CGMacros 负责餐食级动态血糖脆弱性；外部 CGM 数据只作为边界验证；陈晓东教授体外消化仿生系统负责后续机制和干预验证。

## Primary hypotheses

1. NHANES 中 `%Oxidative` 或 `ln(Oxidative/MEHP)` 与 MSI-core、ln(HOMA-IR)、HbA1c 等 insulin-resistant metabolic susceptibility 表型正相关。
2. CGMacros 中 MSI-core 与更高 2h iAUC、2h peak delta 和 high-response risk 相关。
3. MSI-aware prediction 至少在 high-response detection、calibration 或 few-shot personalization 中体现增益。

## Secondary hypotheses

1. `meal load x MSI` 的方向应为正，但若不显著，主张降级为 susceptibility stratification。
2. 外部 CGM 数据不要求复制 MSI 机制，只用于证明 PPGR heterogeneity 和疾病状态边界。
3. 仿生消化实验的正式湿实验不在本计算阶段内；本阶段只完成候选餐食 QC、方案和数据结构准备。

## Main analysis sets

- NHANES: 2013-2018 with phthalate subsample weights; current workstation lacks R, so Phase 2 produces a Python weighted/clustered approximation and a formal R `survey` script for final rerun.
- CGMacros: meal-level dataset with 40 subjects and repeated meals; all inference must respect subject clustering or subject bootstrap.
- External CGM: Stanford CGMDB food challenge as the main boundary dataset; T1D-UOM as disease-state meal-CGM boundary; Jaeb CGMND as healthy-CGM phenotype reference.

## Primary outcomes

- NHANES: MSI-core, ln(HOMA-IR), HbA1c, TyG, ln(TG/HDL-C).
- CGMacros: 2h iAUC, 2h peak delta, high-response meals.
- Prediction: MAE/RMSE, calibration slope/intercept, high-response AUC/AUPRC, conformal interval coverage.
- External: challenge/meal iAUC, peak delta, within-food/within-disease heterogeneity.

## Multiplicity and sensitivity

Main results prioritize direction, effect size, confidence interval, and FDR q-values. Sensitivity analyses include alternative MSI definitions, exclusion of diabetes history, load-variable alternatives, subject bootstrap, and leave-one-subject-out influence.
