# Module G：反事实餐食重构与 target-trial-style 决策分析

日期：2026-06-10

## Target Trial Emulation Table

| Element | Specification |
|---|---|
| Eligibility | CGMacros meals with valid macros, pre-meal CGM context and 2h PPGR outcomes |
| Time zero | Logged meal start time |
| Treatment strategies | S1 carb -20% energy reduced; S2 carb -20% to protein isocaloric; S3 carb -20% to fat isocaloric; S4 fiber +5 g; S5 protein +10 g; S6 cap carbs at 60 g; S7 cap carbs at 45 g; S8 late meal to noon exploratory |
| Assignment | Hypothetical deterministic strategy applied to observed meals |
| Follow-up | 0-120 min postprandial CGM |
| Outcomes | 2h iAUC and 2h peak glucose excursion |
| Estimand | Mean model-predicted contrast between observed meal and redesigned meal |
| Analysis | Existing model-based g-computation/counterfactual prediction with subject-level heterogeneity and bootstrap summaries |
| Causal language | Exploratory decision analysis; not a randomized intervention effect |

## 核心结论

既有反事实结果显示，限制 available carbohydrates 到 45 g、将部分碳水等热量替换为蛋白、增加纤维，是平均收益最稳定的策略。该模块把这些结果转化为仿生消化实验选择逻辑：优先选择高 MSI、高 digestibility-risk、高 predicted reduction 的餐食原型，比较 original vs redesigned 的 glucose release iAUC/Cmax/early slope。

## 输出

- `meal_redesign_target_trial_protocol.md`
- `counterfactual_meal_redesign_effects.csv`
- `counterfactual_subgroup_net_benefit_existing_subgroups.csv`
- `counterfactual_subject_level_heterogeneity.csv`
