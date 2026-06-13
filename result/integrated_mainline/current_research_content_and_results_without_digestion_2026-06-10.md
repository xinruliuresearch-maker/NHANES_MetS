# 当前全部研究内容与运行结果整理：不纳入消化实验版本

日期：2026-06-10

项目：CGMacros + NHANES DEHP/MSI + 外部 CGM + 干实验补强

范围说明：本报告只整理当前已经完成的计算分析、干实验、外部数据库整合、预测模型和文献/机制证据。暂不纳入仿生消化实验、消化实验候选餐食、original/redesigned 体外释放实验设计或任何尚未产生的湿实验数据。

## 1. 当前研究主线

在不考虑消化实验的情况下，当前研究可以收束为一条三段式主线：

> DEHP oxidative profile -> metabolic susceptibility phenotype -> postprandial glycemic vulnerability and personalized meal-risk prediction

对应的科学问题是：

1. 在 NHANES 2013-2018 中，DEHP oxidative metabolic profile 是否与 metabolic susceptibility phenotype 相关？
2. 在 CGMacros 中，同一个 susceptibility phenotype 是否表现为更高的自由生活餐后血糖脆弱性？
3. 加入 susceptibility phenotype 后，是否能更好地识别 high-response meals，并解释哪些餐食结构更危险？
4. 外部 CGM 数据是否支持餐后反应异质性、碳水/纤维方向和模型适用边界？

当前不应写成：

> DEHP directly causes higher CGM postprandial glucose.

更稳妥的主文表述应是：

> DEHP oxidative metabolic profile is associated with a metabolic susceptibility phenotype in NHANES, and the same phenotype is expressed as higher postprandial glycemic vulnerability in CGMacros.

## 2. 当前数据与分析资产

### 2.1 主要数据集

| 数据集 | 当前角色 | 样本量/事件量 | 当前用途 |
|---|---:|---:|---|
| NHANES 2013-2018 | 人群级环境暴露与代谢表型 | n=5267；MSI partial n=2491；MSI complete n=2368 | DEHP oxidative profile -> MSI/HOMA/HbA1c |
| CGMacros | 主分析 CGM 自由生活餐食队列 | 40 subjects；1498 meals | MSI -> PPGR vulnerability；prediction；food matrix proxy |
| Stanford CGMDB | 标准化食物挑战外部边界 | 38 subjects；588 food challenges | 同食物下 PPGR 异质性与外部边界 |
| T1D-UOM | T1D 自由生活餐食外部边界 | 15 subjects；3820 meals | 碳水/纤维方向外部参照 |
| Jaeb CGMND Healthy Adults | 健康 CGM 参照 | 169 subjects；383117 readings | 健康人群 CGM 波动边界 |

### 2.2 核心派生表型

#### Metabolic Susceptibility Index, MSI

MSI 基于 NHANES 参考分布构建，主要整合：

- BMI
- HbA1c
- fasting glucose
- ln(HOMA-IR)
- ln(TG/HDL-C)

Stage 1 输出显示：

| 数据集 | n | n_msi_partial | mean MSI | SD MSI | median MSI | high tertile n |
|---|---:|---:|---:|---:|---:|---:|
| NHANES 2013-2018 | 5267 | 2491 | 0.004 | 0.725 | -0.101 | 830 |
| CGMacros subjects | 40 | 40 | 0.260 | 0.698 | 0.325 | 13 |

MSI 稳健性：

- CGMacros 中 `msi_core_partial` 与 `msi_pca` Pearson=0.997，Spearman=0.993。
- NHANES 中 `msi_core_partial` 与 `msi_pca` Pearson=0.996，Spearman=0.997。
- CGMacros 中 `msi_core_partial` 与 `msi_no_bmi` Pearson=0.978。
- NHANES 中 `msi_core_partial` 与 `msi_no_bmi` Pearson=0.966。

解释：MSI 构建不是单一版本偶然结果，PCA、no-BMI、glycemia/IR 等替代版本与主版本高度一致。

## 3. Phase 0：研究方案与过度解释边界

已完成：

- `phase0_statistical_analysis_plan_v1.md`
- `phase0_main_claims_and_no_overclaim_rules.md`
- `phase0_analysis_registry.csv`

主要冻结的解释规则：

1. NHANES 结果只能表述 association。
2. CGMacros 没有 DEHP 暴露，因此不能声称 DEHP 直接预测 CGM PPGR。
3. MSI 是 bridge phenotype，不是因果中介的已证实变量。
4. 外部 T1D/Stanford/Jaeb 数据用于边界与方向参照，不用于直接复制 CGMacros 模型。
5. prediction 结果用于 risk stratification 和 personalization，不用于临床诊断。

## 4. Phase 1：MSI 稳健性与数据 QC

### 4.1 NHANES MSI 与 DEHP exposure sensitivity

在多个 MSI 版本中，DEHP oxidative profile 的方向一致：

| MSI outcome | Exposure | Estimate | 95% CI | q |
|---|---|---:|---|---:|
| MSI-core partial | ln(Oxidative/MEHP) | 0.183 | 0.106, 0.259 | 0.000010 |
| MSI-core complete | ln(Oxidative/MEHP) | 0.191 | 0.111, 0.272 | 0.000010 |
| MSI no BMI | ln(Oxidative/MEHP) | 0.172 | 0.102, 0.242 | 0.000010 |
| MSI glycemia/IR | ln(Oxidative/MEHP) | 0.182 | 0.107, 0.257 | 0.000010 |
| MSI PCA | ln(Oxidative/MEHP) | 0.157 | 0.099, 0.214 | 0.000002 |

解释：上游 NHANES 结果不是依赖某一个 MSI 定义。

### 4.2 CGMacros MSI 与 PPGR sensitivity

CGMacros 中 MSI 主效应稳定：

| MSI version | Outcome | MSI estimate | 95% CI | q |
|---|---|---:|---|---:|
| MSI-core partial | iAUC/1000 | 1.070 | 0.540, 1.599 | 0.000224 |
| MSI-core partial | peak delta | 17.356 | 9.643, 25.069 | 0.000053 |
| MSI no BMI | iAUC/1000 | 1.109 | 0.567, 1.652 | 0.000222 |
| MSI no BMI | peak delta | 17.820 | 10.181, 25.458 | 0.000043 |
| MSI glycemia/IR | iAUC/1000 | 1.401 | 0.935, 1.867 | 6.97e-08 |
| MSI glycemia/IR | peak delta | 22.005 | 15.656, 28.354 | 3.95e-10 |

`carbs x MSI` 方向多为正，但主版本中置信区间跨 0，因此当前不应把它作为主要 effect modification 结论。

## 5. Phase 2：NHANES DEHP oxidative profile 与代谢易感性

### 5.1 R survey 正式复核

已安装并运行 R 4.6.0 + `survey` 包，正式 R survey 结果如下：

| Outcome | Exposure | R beta | 95% CI | R q | 显著 |
|---|---|---:|---|---:|---|
| MSI PCA | ln(Oxidative/MEHP) | 0.157 | 0.100, 0.213 | 0.003421 | 是 |
| MSI-core partial | ln(Oxidative/MEHP) | 0.183 | 0.109, 0.257 | 0.003421 | 是 |
| ln(HOMA-IR) | ln(Oxidative/MEHP) | 0.218 | 0.129, 0.308 | 0.003421 | 是 |
| MSI no BMI | ln(Oxidative/MEHP) | 0.172 | 0.100, 0.244 | 0.003421 | 是 |
| HbA1c | ln(Oxidative/MEHP) | 0.135 | 0.079, 0.190 | 0.003421 | 是 |
| MSI-core partial | %Oxidative per 10 pp | 0.168 | 0.072, 0.265 | 0.016124 | 是 |
| ln(HOMA-IR) | %Oxidative per 10 pp | 0.182 | 0.074, 0.290 | 0.016124 | 是 |
| HbA1c | %Oxidative per 10 pp | 0.110 | 0.033, 0.186 | 0.030217 | 是 |

核心解释：

> DEHP oxidative metabolic profile is associated with higher metabolic susceptibility and insulin-resistance/glycemic markers in NHANES.

### 5.2 Quartile dose-response trend

`ln(Oxidative/MEHP)` quartile 趋势：

- MSI-core weighted mean：Q1 -0.259 -> Q4 0.109。
- ln(HOMA-IR) weighted mean：Q1 0.697 -> Q4 1.123。
- HbA1c weighted mean：Q1 5.555 -> Q4 5.810。

解释：加权均值随 oxidative profile 分位上升呈单调趋势，支持 Figure 2 的 dose-response 可视化。

### 5.3 高级敏感性和干实验补强

Module B 已补充：

- RCS spline coefficients and prediction grid。
- composition/mixture proxy。
- sex、age、obesity、diabetes history、race/ethnicity、diet-source proxy 分层。
- 排除糖尿病史。
- 不调整尿肌酐敏感性。
- negative-control-like exposure/outcome。

关键敏感性：

| Model | Outcome | Exposure | Estimate | 95% CI | q |
|---|---|---|---:|---|---:|
| primary | MSI-core | ln(Oxidative/MEHP) | 0.183 | 0.106, 0.259 | 7.54e-06 |
| exclude diabetes history | MSI-core | ln(Oxidative/MEHP) | 0.140 | 0.063, 0.217 | 0.000516 |
| exclude diabetes history | ln(HOMA-IR) | ln(Oxidative/MEHP) | 0.182 | 0.089, 0.274 | 0.000223 |
| without urinary creatinine covariate | MSI-core | ln(Oxidative/MEHP) | 0.203 | 0.143, 0.264 | 5.35e-10 |
| negative-control-like outcome height | adult height | ln(Oxidative/MEHP) | -0.066 | -0.533, 0.401 | 0.781 |

注意：negative-control-like exposure `ln_URXMIB` 仍与部分代谢表型有关，因此不能作为完美负控，只能提示非 DEHP phthalate exposure 也可能反映共同暴露来源。

## 6. Phase 3：CGMacros MSI 与自由生活 PPGR vulnerability

### 6.1 MSI tertile 描述结果

| MSI tertile | n subjects | n meals | median MSI | median iAUC | mean iAUC | median peak | mean peak | high iAUC rate | high peak rate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| low | 14 | 570 | -0.679 | 1792.6 | 2543.1 | 34.3 | 43.4 | 0.184 | 0.174 |
| middle | 13 | 481 | 0.341 | 2313.2 | 3007.6 | 48.0 | 51.8 | 0.268 | 0.262 |
| high | 13 | 447 | 0.899 | 2515.0 | 3686.1 | 49.8 | 60.4 | 0.315 | 0.336 |

解释：高 MSI 组总体呈现更高 iAUC、peak 和 population-level high-response rate。

### 6.2 主模型结果

Cluster-robust meal-level models by subject：

| Outcome | Term | Estimate | 95% CI | q | n |
|---|---|---:|---|---:|---:|
| iAUC/1000 | carbs per 10 g | 0.180 | 0.141, 0.219 | 1.95e-18 | 1498 |
| iAUC/1000 | MSI centered | 1.070 | 0.540, 1.599 | 0.000199 | 1498 |
| iAUC/1000 | carbs x MSI | 0.042 | -0.011, 0.094 | 0.161 | 1498 |
| peak delta | carbs per 10 g | 2.484 | 1.908, 3.060 | 5.31e-16 | 1498 |
| peak delta | MSI centered | 17.356 | 9.643, 25.069 | 0.000035 | 1498 |
| peak delta | carbs x MSI | 0.488 | -0.275, 1.251 | 0.252 | 1498 |
| high iAUC top quartile | MSI centered | 0.129 | 0.063, 0.195 | 0.000293 | 1498 |
| high peak top quartile | MSI centered | 0.131 | 0.063, 0.198 | 0.000362 | 1498 |

核心结论：

> MSI is a robust main-effect marker of PPGR vulnerability, while the simple carbohydrate-load-by-MSI interaction is positive but not definitive.

### 6.3 Subject bootstrap

Subject-level bootstrap 支持 MSI 主效应稳定：

| Outcome | Term | boot mean | 95% bootstrap CI | positive probability |
|---|---|---:|---|---:|
| iAUC/1000 | MSI centered | 1.089 | 0.587, 1.667 | 0.998 |
| peak delta | MSI centered | 17.750 | 9.831, 26.145 | 1.000 |
| high iAUC population | MSI centered | 0.132 | 0.066, 0.204 | 0.998 |
| high peak population | MSI centered | 0.133 | 0.057, 0.209 | 1.000 |

`load x MSI` 的 positive probability 为 0.908-0.934，但 CI 仍跨 0。

## 7. Food matrix / digestibility-risk 干实验补强

Module C 将简单宏量营养扩展为 food matrix proxy，包括：

- available carbohydrates
- carbohydrate/fiber ratio
- refined starch proxy
- liquid carbohydrate proxy
- dessert/sweetened proxy
- high fat + high carb matrix
- visible fiber proxy
- protein co-ingestion proxy
- estimated NOVA proxy
- GI/GL proxy
- digestibility-risk score

### 7.1 Food matrix model 结果

| Outcome | Term | Estimate | 95% CI | q | n |
|---|---|---:|---|---:|---:|
| iAUC/1000 | MSI centered | 1.288 | 0.654, 1.923 | 0.000214 | 1497 |
| iAUC/1000 | digestibility-risk centered | 0.388 | 0.239, 0.537 | 2.88e-06 | 1497 |
| iAUC/1000 | MSI x digestibility-risk | 0.410 | 0.216, 0.605 | 0.000118 | 1497 |
| peak delta | carbs per 10 g | 1.571 | 0.426, 2.716 | 0.016869 | 1497 |
| peak delta | MSI centered | 20.290 | 11.919, 28.662 | 0.000012 | 1497 |
| peak delta | digestibility-risk centered | 4.113 | 2.168, 6.057 | 0.000118 | 1497 |
| peak delta | MSI x digestibility-risk | 4.988 | 2.664, 7.313 | 0.000104 | 1497 |

这是当前非消化实验版本中最有新意的结果。它把原先较弱的 `carbs x MSI` 叙事升级为：

> high MSI individuals appear especially vulnerable to high-digestibility-risk meal matrices.

注意：当前 food matrix 是 dry-lab proxy annotation，尚未完成图片人工标注和外部食品数据库校正。因此适合写作 proxy 或 exploratory food matrix score，不应写成真实消化动力学结论。

## 8. CGM 动态曲线表型

Module D 将餐后反应从 iAUC/peak 扩展为曲线表型，包括：

- early slope proxy
- delayed peak
- prolonged elevation
- high iAUC but moderate peak
- high peak but fast recovery
- low stable response
- shape cluster

### 8.1 Shape clusters

| Cluster label | n meals | n subjects | mean iAUC | mean peak | mean time to peak | mean recovery | mean MSI | mean digestibility |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| low_stable_response | 24 | 14 | 52.2 | 6.9 | 77.7 | 71.7 | 0.197 | -0.200 |
| low_stable_response | 291 | 40 | 368.3 | 8.1 | 25.2 | 31.6 | 0.037 | -0.655 |
| delayed_peak | 537 | 40 | 1783.0 | 36.4 | 95.5 | 95.9 | 0.212 | -0.228 |
| high_peak_fast_recovery | 431 | 39 | 3598.4 | 61.9 | 51.5 | 80.4 | 0.092 | 0.518 |
| large_prolonged_response | 215 | 33 | 8963.3 | 129.8 | 85.9 | 100.0 | 0.601 | 0.857 |

最高风险 cluster 是 `large_prolonged_response`，它同时具有最高 iAUC、peak、MSI 和 digestibility-risk。

### 8.2 Curve phenotype models

| Outcome | Term | Estimate | 95% CI | q |
|---|---|---:|---|---:|
| early slope proxy | digestibility-risk | 0.069 | 0.018, 0.120 | 0.030 |
| early slope proxy | MSI x digestibility-risk | 0.058 | 0.013, 0.103 | 0.042 |
| delayed peak flag | MSI | 0.227 | 0.167, 0.287 | 2.18e-12 |
| delayed peak flag | digestibility-risk | 0.035 | 0.011, 0.058 | 0.019 |
| delayed peak flag | MSI x digestibility-risk | 0.039 | 0.018, 0.060 | 0.0023 |
| prolonged elevation flag | MSI | 0.279 | 0.210, 0.347 | 4.78e-14 |
| prolonged elevation flag | digestibility-risk | 0.047 | 0.026, 0.068 | 9.05e-05 |
| prolonged elevation flag | MSI x digestibility-risk | 0.034 | 0.019, 0.049 | 9.17e-05 |
| low stable response flag | MSI | -0.119 | -0.184, -0.054 | 0.0024 |

解释：MSI 与 delayed/prolonged dynamics 关联很强，支持“动态血糖脆弱性”而不只是峰值升高。

## 9. Phase 4：预测模型与个体化

### 9.1 Nested leave-subject-out prediction

模型：

- M0：carb only
- M1：macro + timing
- M2：macro + pre-CGM + context
- M3：MSI-enhanced

| Target | Model | MAE | RMSE | R2 | AUC high response | AUPRC | calibration slope | net benefit pt25 |
---|---|---:|---:|---:|---:|---:|---:|---:|
| iAUC | M0 carb only | 2294.8 | 3089.2 | 0.040 | 0.603 | 0.310 | 0.887 | 0.000 |
| iAUC | M2 macro/pre-CGM/context | 2166.3 | 2907.8 | 0.150 | 0.688 | 0.418 | 0.902 | 0.052 |
| iAUC | M3 MSI-enhanced | 2011.3 | 2722.3 | 0.255 | 0.762 | 0.520 | 0.931 | 0.080 |
| peak | M0 carb only | 32.0 | 42.4 | 0.046 | 0.589 | 0.298 | 0.910 | 0.001 |
| peak | M2 macro/pre-CGM/context | 29.8 | 39.1 | 0.189 | 0.703 | 0.426 | 0.923 | 0.058 |
| peak | M3 MSI-enhanced | 27.1 | 35.8 | 0.318 | 0.787 | 0.571 | 0.963 | 0.094 |

### 9.2 M3 相对 M2 的提升

| Target | Comparison | MAE delta | MAE percent change | AUC delta | calibration slope delta |
|---|---|---:|---:|---:|---:|
| iAUC | M3 minus M2 | -155.0 | -7.16% | +0.074 | +0.029 |
| peak | M3 minus M2 | -2.69 | -9.02% | +0.084 | +0.039 |

解释：

> MSI improves high-response discrimination, calibration and overall error beyond meal/pre-CGM/context features.

### 9.3 Conformal interval coverage

M3 coverage：

- iAUC：q90 coverage 0.891；q95 coverage 0.937；q90 width 8025；q95 width 9923。
- peak：q90 coverage 0.886；q95 coverage 0.939；q90 width 108.3；q95 width 137.1。

解释：预测不确定性大，但 interval calibration 大体合理；这也说明模型适合 risk stratification，不适合精确临床定量预测。

### 9.4 Few-shot personalization

已经生成 few-shot recalibration performance。当前更适合放在补充材料，作为个体化潜力而非主文核心。原因：

- 0-shot MSI-enhanced 模型已经有明确提升。
- few-shot 在不同 shot 数和 MSI tertile 中表现不完全稳定。
- 若主文篇幅有限，应优先呈现 M0-M3、calibration、high-response AUC/AUPRC。

## 10. 外部验证与边界分析

### 10.1 Dataset-level boundary

| Dataset | n subjects | n events | event type | median iAUC | median peak | boundary metric |
|---|---:|---:|---|---:|---:|---:|
| CGMacros | 40 | 1498 | free-living meals | 2146.3 | 42.6 | NA |
| Stanford CGMDB | 38 | 588 | standardized food challenges | 2441.3 | 49.8 | high-rate 0.25 |
| T1D-UOM | 15 | 3820 | T1D logged meals | 1326.4 | 42.3 | high-rate 0.25 |
| Jaeb healthy adults | 169 | 383117 | healthy adult CGM readings | NA | NA | time above 140 = 0.0207 |

### 10.2 Stanford CGMDB

Stanford MSI proxy 不显著：

| Outcome | Term | Estimate | 95% CI | p |
|---|---|---:|---|---:|
| iAUC | stanford_msi_proxy | 0.552 | -0.385, 1.490 | 0.248 |
| peak | stanford_msi_proxy | 2.850 | -8.604, 14.304 | 0.626 |

解释：Stanford 可用于“标准化食物挑战和个体差异边界”，不能作为 MSI 主链条的直接外部验证。

### 10.3 T1D-UOM

T1D 自由生活餐食中，碳水与纤维方向符合生物学预期：

| Outcome | Term | Estimate | 95% CI | p |
|---|---|---:|---|---:|
| iAUC/1000 | carbs per 10 g | 0.240 | 0.052, 0.427 | 0.012 |
| iAUC/1000 | fiber per 5 g | -0.297 | -0.497, -0.098 | 0.0035 |
| peak | carbs per 10 g | 3.351 | 1.213, 5.488 | 0.0021 |
| peak | fiber per 5 g | -3.647 | -6.597, -0.697 | 0.015 |

解释：外部 T1D 数据支持 meal macro direction，但不能直接泛化到健康/非 T1D 人群。

## 11. 文献、机制与数据库补强

### 11.1 文献证据图谱

Module A 已整理 seed evidence map：

- 20 条核心 anchor references。
- 覆盖 PPGR precision nutrition、DEHP/metabolic health、food structure、prediction reporting、mechanism databases。
- 明确研究空白：DEHP/metabolic susceptibility、PPGR dynamic phenotype、food matrix/digestibility 之间尚未被统一到同一条研究链中。

### 11.2 机制知识图谱

Module E 输出：

- `dehp_msi_mechanism_knowledge_graph_edges.csv`
- 141 curated edges。
- 主要 pathway：
  - PPAR signaling：25 edges，5 genes，higher-confidence edges 10。
  - insulin signaling：25 edges，5 genes，higher-confidence edges 5。
  - oxidative stress：25 edges，5 genes，higher-confidence edges 5。
  - beta-cell function：20 edges。
  - inflammation：20 edges。
  - mitochondrial function：20 edges。

解释：机制图谱可以支持 Discussion 和 Supplementary，但不应作为独立机制发现。

## 12. 反事实餐食重构：纯计算版本

本部分不纳入消化实验，仅作为 model-based counterfactual decision analysis。

| Scenario | Mean predicted iAUC delta | Meals with predicted reduction | High-risk mean delta |
|---|---:|---:|---:|
| Cap carbs at 45 g | -557.5 | 45.4% | -1513.4 |
| Carb -20% to protein, isocaloric | -285.6 | 75.8% | -678.0 |
| Fiber +5 g | -213.6 | 74.4% | -513.5 |
| Protein +10 g, energy added | -192.3 | 68.6% | -419.4 |
| Cap carbs at 60 g | -182.7 | 38.1% | -480.9 |
| Carb -20%, energy reduced | -161.5 | 63.0% | -417.2 |
| Carb -20% to fat, isocaloric | -132.7 | 60.1% | -407.1 |
| Late meal to noon | +184.5 | 5.1% | +1.5 |

解释：

- 限制 available carbohydrates 是平均效应最大的模型预测策略。
- 碳水替换蛋白和增加纤维覆盖更多餐食。
- 这些结果是预测模型下的 g-computation/counterfactual，不是临床干预结果。

## 13. 可复现性与报告规范

当前已完成：

- Phase 0-5 file manifest。
- dry-lab booster A-I 52 个产物。
- Module I reproducibility package。
- analysis manifest。
- data dictionary。
- code/data/protocol availability statement 草稿。
- TRIPOD+AI checklist draft。
- PROBAST+AI self-assessment。
- prediction model card。
- leakage audit。
- predictor dictionary。

这部分使当前研究具备投稿准备的基本可复现框架。

## 14. 当前可以组成的论文故事：无消化实验版本

如果完全不考虑消化实验，当前论文可定位为：

> An integrated environmental epidemiology and CGM precision nutrition study showing that a DEHP oxidative metabolic profile is associated with metabolic susceptibility in NHANES, and that the same susceptibility phenotype stratifies real-world postprandial glycemic vulnerability and improves high-response meal prediction in CGMacros.

建议主图：

### Figure 1

Study framework and datasets：

NHANES exposure-metabolic susceptibility analysis -> CGMacros MSI-PPGR analysis -> prediction/counterfactual meal-risk analysis -> external boundary datasets。

### Figure 2

NHANES results：

- R survey forest plot。
- Quartile trend。
- Sensitivity summary。

### Figure 3

CGMacros susceptibility and PPGR：

- MSI tertile iAUC/peak/high-response distribution。
- Cluster-robust MSI models。
- Subject bootstrap。

### Figure 4

Food matrix and dynamic CGM phenotype：

- digestibility-risk and MSI x digestibility-risk effects。
- curve phenotype clusters。
- delayed/prolonged response models。

### Figure 5

Prediction and counterfactual personalization：

- M0-M3 performance。
- AUC/AUPRC/calibration。
- counterfactual meal redesign scenarios。
- external dataset boundary map。

## 15. 当前结论强度分级

### 可作为主文核心结论

1. DEHP oxidative profile 与 MSI/HOMA-IR/HbA1c 在 NHANES 中稳定相关。
2. MSI 在 CGMacros 中稳定预测自由生活餐后 iAUC、peak 和 high-response risk。
3. MSI-enhanced prediction 改善 high-response discrimination 和 calibration。
4. digestibility-risk score 与 MSI x digestibility-risk 显著预测 PPGR，提示高 susceptibility 个体对高消化风险餐食更脆弱。
5. CGM curve phenotype 显示高 MSI 与 delayed/prolonged/high-risk response 相关。

### 适合作为补充材料或支持证据

1. RCS 与 composition/mixture proxy。
2. Mechanism knowledge graph。
3. Stanford/T1D/Jaeb external boundary map。
4. Few-shot personalization。
5. Counterfactual meal redesign。

### 必须谨慎表述

1. DEHP 与 CGMacros PPGR 的连接是通过 MSI 作为 bridge phenotype，不是同一个人群中的直接暴露-反应链。
2. Simple `carbs x MSI` interaction 不稳，应以 `MSI x digestibility-risk` 替代为更强叙事。
3. Food matrix 当前是 proxy，不是人工标注和实验验证后的真实食品结构变量。
4. Counterfactual redesign 是模型预测，不是干预试验。
5. 外部 T1D 数据支持方向，不支持直接泛化。

## 16. 当前最大短板：不考虑消化实验时

如果完全不纳入消化实验，当前研究仍有几个审稿风险：

1. NHANES 与 CGMacros 不是同一批参与者，DEHP -> MSI -> PPGR 是跨数据集证据链。
2. Food matrix/digestibility-risk 仍是 proxy annotation。
3. CGMacros 样本量为 40 subjects，虽然有 1498 meals，但 subject-level 外部验证不足。
4. prediction performance 有提升，但绝对误差仍较大，应聚焦 high-response risk stratification 而非精确定量预测。
5. 机制图谱是数据库支持，不是实验验证。

## 17. 不考虑消化实验时的投稿定位

### 更合适的期刊定位

如果暂时不做消化实验，建议目标更偏向：

- American Journal of Clinical Nutrition
- Clinical Nutrition
- npj Science of Food
- Nutrition & Diabetes
- Environmental Health / Environment International 方向的拆分论文
- JMIR/NPJ Digital Medicine 类型的数字营养预测方向，前提是重写为 prediction-focused

### 不建议直接主打的定位

不纳入消化实验时，冲击 Nature Food、Cell Metabolism 或 Nature Metabolism 会偏弱。原因是：

- 机制和干预闭环不足；
- 跨数据集桥接需要很克制；
- food matrix 仍是 proxy。

## 18. 下一步在“非消化实验”框架内最值得做的事

如果继续坚持先不做消化实验，建议优先完成：

1. Figure 2-5 投稿级图表。
2. Food matrix 人工图片标注与数据库校正。
3. Module B R survey RCS/分层最终复核。
4. 完成 manuscript outline 和英文 abstract。
5. 将 CGMacros food matrix/curve phenotype 结果做成主文 Figure 4。
6. 将 prediction 部分按 TRIPOD+AI 完成 Supplementary。
7. 将外部数据只作为 boundary，不做过度验证。

## 19. 结论

当前不考虑消化实验时，研究已经具备一篇较强的整合型计算/观察性论文雏形。最核心的亮点不是单纯预测模型，而是：

> 一个环境暴露相关 metabolic susceptibility phenotype，可以在独立 CGM 餐食数据中表现为 PPGR vulnerability，并可用于 high-response meal risk stratification。

如果主文聚焦这一点，并把 `MSI x digestibility-risk` 和 CGM curve phenotype 作为深化亮点，当前结果已经足以支持向较高水平营养、代谢或数字健康期刊推进。若目标是旗舰级期刊，仍需要更强的机制或干预证据。
