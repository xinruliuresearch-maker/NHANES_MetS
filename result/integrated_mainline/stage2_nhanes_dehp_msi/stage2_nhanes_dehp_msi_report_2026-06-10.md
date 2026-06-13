# Stage 2 报告：NHANES DEHP oxidative profile 与 MSI-core

日期：2026-06-10

## 目的

检验 NHANES 2013-2018 中 DEHP oxidative metabolic profile 是否与 `MSI-core` 及核心糖脂代谢表型相关。这一阶段为整条主线提供人群级证据：

`DEHP oxidative profile -> metabolic susceptibility`

## 方法

当前环境无 `Rscript` 和 `statsmodels`，本阶段使用纯 Python 实现：

- 加权最小二乘回归，权重为 `WTSB6YR_MAIN`。
- 标准误按 `SDMVSTRA + SDMVPSU` 组合做 cluster-robust sandwich。
- 协变量包括 age, sex, race/ethnicity, education, PIR, energy intake, smoking, alcohol, physical activity, urinary creatinine, cycle。
- 这是主线推进版 NHANES weighted approximation。投稿前建议在 R `survey` 环境中做最终复杂抽样方差复核。

## 关键结果

### DEHP oxidative profile 与 MSI-core

- `%Oxidative per 10 pp -> MSI-core`: 0.168 (0.065, 0.272), q=0.006, n=1313
- `ln(Oxidative/MEHP) -> MSI-core`: 0.183 (0.106, 0.259), q=<0.001, n=1313
- `ln(Sigma DEHP) -> MSI-core`: 0.066 (-0.004, 0.135), q=0.080, n=1313

### 与既有代谢终点的一致性

- `%Oxidative per 10 pp -> ln(HOMA-IR)`: 19.958 (6.896, 34.617), q=0.006, n=1292
- `%Oxidative per 10 pp -> HbA1c`: 0.110 (0.031, 0.188), q=0.012, n=2671
- `%Oxidative per 10 pp -> TyG`: 0.108 (0.001, 0.216), q=0.067, n=1279
- `%Oxidative per 10 pp -> ln(TG/HDL-C)`: 10.260 (-1.927, 23.962), q=0.118, n=1279

## 解释

如果以 `MSI-core` 作为跨项目桥梁，本阶段结果支持将 DEHP oxidative profile 放在主线的上游：它与 insulin-resistance/glycemic-lipid susceptibility 表型相关。下一阶段不需要、也不能把 DEHP 直接带入 CGMacros；而应将 `MSI-core` 带入 CGMacros，检验它是否放大餐食诱导的 PPGR vulnerability。

## 输出文件

- `stage2_nhanes_dehp_msi_results.csv`
- `stage2_nhanes_dehp_msi_key_results.csv`
- `stage2_dehp_msi_forest.svg`
- `stage2_nhanes_dehp_msi_report_2026-06-10.md`
