# 暂不考虑湿实验时的高水平期刊研究路径

日期：2026-06-10

项目：CGMacros + NHANES DEHP/MSI + 外部 CGM + 干实验/预测模型

## 1. 当前结果的投稿级判断

如果暂时不考虑湿实验、仿生消化或任何体外机制验证，当前项目仍然可以形成一篇较强的整合型计算/观察性论文，但论文定位必须清楚：

> environmental metabolic susceptibility + free-living CGM precision nutrition + high-response meal risk prediction

当前不应主打“机制验证”或“干预证明”，而应主打：

> A DEHP oxidative metabolic profile is associated with a metabolic susceptibility phenotype in NHANES, and the same phenotype stratifies real-world postprandial glycemic vulnerability and meal-risk prediction in CGMacros.

这条线的强处是多层证据一致：

1. NHANES R survey 已证明 DEHP oxidative profile 与 MSI、HOMA-IR、HbA1c 稳定相关。
2. CGMacros 已证明 MSI 与自由生活餐食 iAUC、peak、high-response risk 稳定相关。
3. food matrix/digestibility-risk proxy 进一步显示高 MSI 个体对高消化风险餐食更脆弱。
4. MSI-enhanced prediction 改善 high-response meal discrimination、calibration 和 MAE。
5. 外部 CGM 数据提供 transportability boundary 和碳水/纤维方向支持。

最大短板也很清楚：

1. DEHP 与 CGM PPGR 不在同一人群中直接观测。
2. food matrix/digestibility-risk 仍是 proxy，不是人工标注和实验验证变量。
3. CGMacros 只有 40 名受试者，虽然有 1498 餐。
4. 预测模型更适合 high-response risk stratification，不适合临床级精确定量预测。
5. 缺少湿实验时，很难冲击需要机制闭环的顶级代谢/食品期刊。

## 2. 当前最有发表价值的结果

### 2.1 NHANES 上游证据已经达到主文级别

R survey 关键结果：

| Outcome | Exposure | beta | 95% CI | q |
|---|---|---:|---|---:|
| MSI-core | ln(Oxidative/MEHP) | 0.183 | 0.109, 0.257 | 0.003421 |
| ln(HOMA-IR) | ln(Oxidative/MEHP) | 0.218 | 0.129, 0.308 | 0.003421 |
| HbA1c | ln(Oxidative/MEHP) | 0.135 | 0.079, 0.190 | 0.003421 |
| MSI-core | %Oxidative per 10 pp | 0.168 | 0.072, 0.265 | 0.016124 |
| HbA1c | %Oxidative per 10 pp | 0.110 | 0.033, 0.186 | 0.030217 |

主文价值：

- 支撑 Figure 2。
- 说明 oxidative metabolic profile 比单纯 DEHP burden 更贴近 metabolic susceptibility。
- 但必须写作 association，不写因果。

### 2.2 CGMacros MSI -> PPGR 是主线核心

CGMacros 主模型：

| Outcome | Term | Estimate | 95% CI | q |
|---|---|---:|---|---:|
| iAUC/1000 | MSI centered | 1.070 | 0.540, 1.599 | 0.000199 |
| peak delta | MSI centered | 17.356 | 9.643, 25.069 | 0.000035 |
| high iAUC top quartile | MSI centered | 0.129 | 0.063, 0.195 | 0.000293 |
| high peak top quartile | MSI centered | 0.131 | 0.063, 0.198 | 0.000362 |

Subject bootstrap：

- MSI -> iAUC/1000：bootstrap CI 0.587 到 1.667，positive probability 0.998。
- MSI -> peak：bootstrap CI 9.831 到 26.145，positive probability 1.000。

主文价值：

- 支撑 Figure 3。
- 证明 MSI 是 dynamic PPGR vulnerability marker。
- `carbs x MSI` 不应作为主结论，因为方向为正但 CI 跨 0。

### 2.3 目前最有新意的是 MSI x digestibility-risk

Module C 结果：

| Outcome | Term | Estimate | 95% CI | q |
|---|---|---:|---|---:|
| iAUC/1000 | MSI centered | 1.288 | 0.654, 1.923 | 0.000214 |
| iAUC/1000 | digestibility-risk centered | 0.388 | 0.239, 0.537 | 2.88e-06 |
| iAUC/1000 | MSI x digestibility-risk | 0.410 | 0.216, 0.605 | 0.000118 |
| peak delta | MSI centered | 20.290 | 11.919, 28.662 | 0.000012 |
| peak delta | digestibility-risk centered | 4.113 | 2.168, 6.057 | 0.000118 |
| peak delta | MSI x digestibility-risk | 4.988 | 2.664, 7.313 | 0.000104 |

这是无湿实验版本里最能提升论文层级的发现。建议把主线从：

> carbohydrate load x MSI

升级为：

> high metabolic susceptibility individuals are more vulnerable to high-digestibility-risk meal matrices.

但必须明确：digestibility-risk 当前是 dry-lab proxy。下一步必须做人工图片标注和数据库校正，才能作为主文强结论。

### 2.4 CGM curve phenotype 可以提升动态表型深度

最高风险 cluster：

- `large_prolonged_response`
- n=215 meals
- mean iAUC=8963.3
- mean peak=129.8
- mean MSI=0.601
- mean digestibility-risk=0.857

模型结果也显示：

- MSI 与 delayed peak flag 显著相关。
- MSI 与 prolonged elevation flag 显著相关。
- digestibility-risk 与 early slope、delayed peak、prolonged elevation 有方向一致关联。

主文价值：

- 支撑 Figure 4。
- 把论文从“两个终点 iAUC/peak”提升为“动态 CGM 表型”。
- 若要更强，下一步需要从原始 CGM 重新构建 0-180 min 曲线，做真正 FPCA/trajectory clustering。

### 2.5 Prediction 部分已经足够支撑风险分层

M3 MSI-enhanced 模型：

| Target | MAE | R2 | AUC high response | AUPRC | calibration slope |
|---|---:|---:|---:|---:|---:|
| iAUC | 2011.3 | 0.255 | 0.762 | 0.520 | 0.931 |
| peak | 27.1 | 0.318 | 0.787 | 0.571 | 0.963 |

M3 相比 M2：

- iAUC：MAE 降低 7.16%，AUC +0.074。
- peak：MAE 降低 9.02%，AUC +0.084。

主文价值：

- 支撑 Figure 5。
- 论文应该强调 high-response meal risk stratification，而不是“精确预测每餐血糖”。
- TRIPOD+AI、PROBAST+AI、自评、model card、leakage audit 已经有基础。

## 3. 暂不考虑湿实验时的目标期刊策略

### 3.1 首选定位

最合适的定位：

> Integrated observational + computational precision nutrition study

适合目标：

1. American Journal of Clinical Nutrition
2. Clinical Nutrition
3. npj Science of Food
4. Nutrition & Diabetes
5. Environment International / Environmental Health，如果拆分或强化 NHANES 环境流行病学部分
6. Digital health / biomedical informatics 方向期刊，如果把 prediction/reporting 写得更重

### 3.2 不建议当前直接主打的定位

暂不考虑湿实验时，不建议当前直接主打：

- Cell Metabolism
- Nature Metabolism
- Nature Food flagship article

原因：

- 这些期刊会期待更强机制或干预闭环。
- 当前 DEHP -> MSI -> PPGR 是跨数据集桥接，而不是同一人群连续链条。
- food matrix 尚未完成 expert-coded validation。

### 3.3 可以争取的高水平路线

最现实的高水平路线是：

> AJCN / npj Science of Food 级别的整合型 precision nutrition paper

必要条件：

1. Figure 2-5 做到投稿级。
2. food matrix annotation 从 proxy 升级为 expert-coded + database-calibrated。
3. R survey 的 RCS/分层结果完成最终复核。
4. prediction 部分完全对齐 TRIPOD+AI/PROBAST+AI。
5. 外部数据明确写成 boundary，不写 direct validation。

## 4. 接下来的研究路径

### Path A：整合型主文路线，推荐

这是当前最优路线。

目标：

把现有结果打磨成一篇完整论文，而不是继续无止境增加分析。

论文主线：

> DEHP oxidative profile identifies a metabolic susceptibility phenotype that stratifies real-world PPGR vulnerability and improves susceptibility-aware meal-risk prediction.

主图设计：

#### Figure 1：Study Design and Bridge Phenotype

内容：

- NHANES：DEHP oxidative profile -> MSI。
- CGMacros：MSI -> PPGR vulnerability。
- Prediction：MSI-enhanced high-response risk stratification。
- External datasets：boundary/transportability。

目的：

- 第一眼解释为什么两个数据集可以被统一。
- 强调 MSI 是 bridge phenotype。

#### Figure 2：NHANES Environmental-Metabolic Association

内容：

- R survey forest plot。
- exposure quartile trend。
- sensitivity/negative-control summary。

必须补强：

- 将主文 RCS/分层模型迁移到 R `survey`，避免 Python proxy 被审稿质疑。

#### Figure 3：CGMacros PPGR Vulnerability

内容：

- MSI tertile 下 iAUC、peak、high-response rate。
- cluster-robust MSI model。
- subject bootstrap。
- leave-one-subject influence 放 Supplement。

重点：

- 只强调 MSI 主效应。
- 不把 carbs x MSI 当主结论。

#### Figure 4：Food Matrix Proxy and Dynamic CGM Phenotypes

内容：

- digestibility-risk effect。
- MSI x digestibility-risk。
- curve phenotype clusters。
- delayed/prolonged response models。

必须补强：

- 对 CGMacros meal photos 做人工标注。
- 用 USDA FoodData Central、Sydney GI、Open Food Facts 校正 food matrix。
- 把变量名从 `digestibility-risk` 改成更保守的 `food-matrix glycemic-risk proxy`，除非完成更强验证。

#### Figure 5：Prediction, Calibration and Transportability Boundary

内容：

- M0-M3 MAE/R2/AUC/AUPRC/calibration。
- M3 vs M2 incremental gain。
- conformal coverage。
- external boundary map。
- counterfactual meal redesign 放 Supplement 或 Figure 5 panel。

重点：

- 写成 risk stratification。
- 不写临床部署。

### Path B：拆分为两篇，更稳妥

如果后续 food matrix 标注无法做好，建议拆分：

#### Paper 1：NHANES 环境流行病学论文

题目方向：

> DEHP oxidative metabolic profile and metabolic susceptibility in NHANES 2013-2018

目标期刊：

- Environment International
- Environmental Health
- Environmental Research

需要补强：

- R survey RCS。
- mixture/composition model。
- sex/obesity/diabetes subgroup。
- negative control。
- urinary creatinine/LOD/missingness sensitivity。

#### Paper 2：CGMacros 精准营养论文

题目方向：

> Metabolic susceptibility-aware prediction of postprandial glycemic vulnerability in free-living meals

目标期刊：

- AJCN
- npj Science of Food
- Clinical Nutrition
- Nutrition & Diabetes

需要补强：

- food matrix annotation。
- CGM curve phenotype。
- prediction reporting。
- external boundary。

## 5. 下一步优先级

### 最高优先级，1-2 周内完成

1. **把 Figure 2-5 做成投稿级图**
   - 当前已有 draft data 和 draft PNG。
   - 下一步需要统一配色、字体、panel 标注、CI、图注。

2. **完成 food matrix expert annotation**
   - 至少对所有 CGMacros 餐食或高风险餐食子集做人工图片标注。
   - 建议先做 1498 餐的分层半自动标注：高风险/高误差/高 MSI 餐优先。
   - 记录两名标注者一致性。

3. **R survey 最终补强**
   - 只补主文会用的 RCS、分层、负控。
   - 不要把所有 Python sensitivity 都迁移，避免消耗过大。

4. **英文 manuscript 初稿**
   - 直接基于 Phase 3 outline 扩展。
   - 先写 Results 和 Methods，再写 Introduction/Discussion。

### 中优先级，2-4 周内完成

5. **原始 CGM 曲线重构**
   - 从原始 CGM 重新提取 0-180 min meal trajectories。
   - 做真正 trajectory clustering / FPCA-like analysis。
   - 替换当前基于 summary proxy 的 curve phenotype。

6. **Prediction reporting 完整化**
   - TRIPOD+AI checklist 加 manuscript line references。
   - PROBAST+AI 风险偏倚自评表格化。
   - model card 和 leakage audit 放 Supplement。

7. **外部数据边界图优化**
   - Stanford：强调 standardized food challenge heterogeneity。
   - T1D-UOM：强调 carb/fiber direction。
   - Jaeb：强调 healthy CGM baseline。
   - 不写 direct external validation。

### 低优先级，暂缓

1. 复杂深度学习模型。
2. 大规模微生物组探索。
3. 继续下载更多外部 CGM 数据。
4. 扩展过多环境暴露物。
5. 把 counterfactual meal redesign 写成干预结论。

这些会让主线重新发散。

## 6. 6 周执行计划

### Week 1：主图和结果骨架

完成：

- Figure 2-5 投稿级草图。
- Main Table 1-2。
- Supplementary Table 清单。
- Results section bullet draft。

交付：

- `manuscript_figures/Figure2_NHANES.pdf`
- `manuscript_figures/Figure3_CGMacros_PPGR.pdf`
- `manuscript_figures/Figure4_food_matrix_curve.pdf`
- `manuscript_figures/Figure5_prediction_boundary.pdf`

### Week 2：food matrix 与 R survey 补强

完成：

- 高风险餐食 expert annotation。
- food matrix codebook v2。
- R survey RCS/分层/负控。

交付：

- `food_matrix_annotation_v2.csv`
- `food_matrix_interrater_agreement.csv`
- `nhanes_R_survey_RCS_subgroup_negative_control.csv`

### Week 3：曲线表型升级

完成：

- 原始 CGM 0-180 min meal trajectories。
- trajectory clusters。
- curve phenotype 模型替换当前 proxy。

交付：

- `cgmacros_meal_trajectory_matrix.csv`
- `curve_phenotype_fpca_or_cluster_results.csv`
- `Figure4_curve_panels_v2.pdf`

### Week 4：Prediction 与补充材料

完成：

- TRIPOD+AI/PROBAST+AI line references。
- calibration/conformal/decision utility 整理。
- external boundary supplement。

交付：

- `TRIPOD_AI_completed_with_lines.docx/md`
- `PROBAST_AI_table_final.md`
- `prediction_supplementary_results.xlsx`

### Week 5：英文主文初稿

完成：

- Methods。
- Results。
- Introduction。
- Discussion。

交付：

- `main_text_v1.docx`
- `supplementary_methods_v1.docx`

### Week 6：投稿包

完成：

- cover letter。
- graphical abstract 或 Figure 1。
- reporting checklist。
- data/code availability。
- journal formatting。

交付：

- `cover_letter_v1.md`
- `data_code_protocol_availability.md`
- `submission_package_v1/`

## 7. 当前最应该坚持的叙事

建议全文围绕这句话展开：

> A metabolic susceptibility phenotype links population-level DEHP oxidative metabolism with individual-level postprandial glycemic vulnerability and improves susceptibility-aware meal-risk prediction.

这句话的优点是：

- 不说 DEHP 直接导致 PPGR。
- 承认 MSI 是 bridge phenotype。
- 把 NHANES 和 CGMacros 统一起来。
- 把 prediction 放在正确位置。
- 给 food matrix 留出解释空间。

## 8. 当前最不该做的事

1. 不要继续下载大量新数据。
2. 不要把微生物组强行纳入主线。
3. 不要把 `carbs x MSI` 写成主发现。
4. 不要把 `digestibility-risk` 写成真实消化实验结果。
5. 不要用“causal pathway”描述 DEHP -> MSI -> PPGR。
6. 不要试图把文章写成顶级机制论文。

## 9. 结论

暂不考虑湿实验时，当前项目最合理的高水平路径是：

> 做成一篇严谨、跨数据源、机制克制但有明确 precision nutrition 价值的计算/观察性论文。

短期目标不应是继续扩大分析，而是把已经完成的强结果变成投稿级主图、主表和英文稿件。只要 food matrix annotation 和 R survey 补强完成，这篇文章有机会冲击 AJCN、npj Science of Food、Clinical Nutrition 或 Nutrition & Diabetes 等较高水平期刊。

若坚持冲击 Nature Food / Cell Metabolism / Nature Metabolism，则在没有湿实验的前提下风险较高，除非 food matrix annotation、trajectory phenotyping 和 prediction reporting 做到非常扎实，并且论文被定位为一个方法学/数字精准营养框架，而不是机制研究。

## 10. 对齐规范与期刊要求

- Nature Food reporting standards and data/code/protocol availability: https://www.nature.com/natfood/editorial-policies/reporting-standards
- npj Science of Food submission guidelines: https://www.nature.com/npjscifood/for-authors-and-referees/submission-guidelines
- American Society for Nutrition Guide for Authors: https://legacyfileshare.elsevier.com/promis_misc/asn-guide-for-authors.pdf
- TRIPOD+AI: https://www.bmj.com/content/385/bmj-2023-078378
- PROBAST+AI: https://www.bmj.com/content/388/bmj-2024-082505
- STROBE: https://www.strobe-statement.org/
- STROBE-nut and STROBE-ME via EQUATOR: https://www.equator-network.org/reporting-guidelines/strobe-nut/
