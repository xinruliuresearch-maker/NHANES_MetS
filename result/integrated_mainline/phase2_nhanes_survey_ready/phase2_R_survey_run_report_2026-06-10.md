# Phase 2 R survey 正式复核运行报告

日期：2026-06-10  
运行脚本：`phase2_formal_R_survey_script.R`  
Rscript：`C:\Program Files\R\R-4.6.0\bin\Rscript.exe`  
R 版本：R 4.6.0  
核心包：`survey`

## 1. 运行状态

已成功运行正式 NHANES complex survey design 脚本：

```r
des <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTSB6YR_MAIN,
  nest = TRUE,
  data = nh
)
```

输出文件：

- `phase2_R_survey_main_results.csv`
- `phase2_R_survey_key_results.csv`
- `phase2_R_survey_vs_python_comparison.csv`

同一批文件已同步到：

`C:\Users\liu12\OneDrive\Desktop\NHANES_MetS_Project\result\integrated_mainline\phase2_nhanes_survey_ready`

## 2. R survey 关键结果

| Outcome | Exposure | R survey estimate |
|---|---|---:|
| MSI PCA | ln(Oxidative/MEHP) | 0.157 (0.100, 0.213), q=0.003421 |
| MSI-core | ln(Oxidative/MEHP) | 0.183 (0.109, 0.257), q=0.003421 |
| ln(HOMA-IR) | ln(Oxidative/MEHP) | 0.218 (0.129, 0.308), q=0.003421 |
| MSI no BMI | ln(Oxidative/MEHP) | 0.172 (0.100, 0.244), q=0.003421 |
| HbA1c | ln(Oxidative/MEHP) | 0.135 (0.079, 0.190), q=0.003421 |
| MSI-core | %Oxidative per 10 pp | 0.168 (0.072, 0.265), q=0.016124 |
| MSI no BMI | %Oxidative per 10 pp | 0.168 (0.070, 0.267), q=0.016124 |
| ln(HOMA-IR) | %Oxidative per 10 pp | 0.182 (0.074, 0.290), q=0.016124 |
| MSI PCA | %Oxidative per 10 pp | 0.105 (0.038, 0.173), q=0.022804 |
| HbA1c | %Oxidative per 10 pp | 0.110 (0.033, 0.186), q=0.030217 |

## 3. 与 Python 近似结果的关系

R `survey` 结果与之前 Python weighted + cluster-robust 近似结果的 beta 几乎完全一致，说明前期计算没有方向性错误。主要差异来自：

- R 使用 NHANES complex survey design 的 t 检验和设计自由度。
- Python 近似使用正态近似的 cluster-robust sandwich。

这一步完成后，Phase 2 已从“探索性近似”升级为“正式复杂抽样复核结果”。

## 4. 投稿解释

Phase 2 现在可以作为主文人群级证据：

> DEHP oxidative metabolic profile is associated with metabolic susceptibility, particularly MSI-core and insulin-resistance phenotypes, under a formal NHANES complex survey design.

需要保持的谨慎边界：

- 这些结果仍是横断面关联，不应写成因果证明。
- 它们支持 “DEHP oxidative profile -> metabolic susceptibility” 这一上游证据，不直接证明 “DEHP -> CGMacros PPGR”。

## 5. 下一步

主文 Figure 2 可以基于 `phase2_R_survey_key_results.csv` 绘制。后续若继续加强，可以在 R 中进一步补充：

- restricted cubic spline 剂量反应；
- 排除糖尿病/用药者；
- creatinine 处理敏感性；
- obesity/sex/age 分层；
- source-oriented dietary covariate adjustment。
