# 面向高水平期刊发表的下一步路线图

日期：2026-06-10  
项目：CGMacros + NHANES DEHP/MSI + 外部 CGM + 仿生消化系统

## 1. 当前投稿级判断

目前研究已经具备一条清晰主线：

> DEHP oxidative profile -> metabolic susceptibility phenotype -> PPGR vulnerability -> digestion-informed meal redesign

R `survey` 正式复核已完成，NHANES 上游证据稳定；CGMacros 中 MSI 对 PPGR vulnerability 的主效应稳定；MSI-aware prediction 明显改善高反应餐食识别和校准；外部 CGM 数据支持餐食反应异质性和碳水/纤维方向。

当前最大短板不是统计，而是机制与干预证据：Stage 5 体外消化还停留在候选餐食和方案层面。如果希望冲击 Nature Food / Cell Metabolism / Nature Metabolism 级别，必须把仿生消化实验做成真正能支撑 Figure 5 的机制证据。

## 2. 推荐目标路线

### 首选路线：整合型高水平论文

目标期刊：

- Nature Food
- Cell Metabolism
- Nature Metabolism
- npj Science of Food
- American Journal of Clinical Nutrition

核心卖点：

1. 人群级环境暴露信号：NHANES R survey 结果。
2. 个体级动态表型：CGMacros MSI -> PPGR vulnerability。
3. 预测与个体化：MSI-aware prediction 改善 high-response detection。
4. 机制与干预：仿生消化 original vs redesigned glucose release。

能否冲击最顶层，主要取决于第 4 点。

### 备用路线：拆成两篇更稳论文

如果仿生消化结果不够强，建议拆分：

论文 1：环境流行病学论文  
题目方向：DEHP oxidative profile and metabolic susceptibility in NHANES  
目标：Environment International / Environmental Health Perspectives

论文 2：精准营养与 CGM 论文  
题目方向：Metabolic susceptibility-aware postprandial glycemic vulnerability and personalized meal redesign  
目标：AJCN / npj Science of Food / Clinical Nutrition

## 3. 接下来 8 周的关键步骤

### Week 1：冻结主文叙事和图表骨架

目标：先把论文框架定死，防止继续发散。

必须完成：

- 写一版 300 字英文 structured abstract。
- 写一版 5 figure story board。
- 明确主文只回答 4 个问题：
  1. DEHP oxidative profile 是否与 MSI/HOMA/HbA1c 相关？
  2. MSI 是否在 CGMacros 中表现为 PPGR vulnerability？
  3. MSI 是否提升 high-response prediction / personalization？
  4. digestion-informed redesign 是否降低 early glucose release？

交付物：

- `manuscript_outline_v1.md`
- `figure_storyboard_v1.md`
- `main_claims_table_v1.csv`

### Week 1-2：完成 Figure 2-4 的投稿级图表

目标：先把已经完成的干实验结果变成主文图。

Figure 2：NHANES R survey  
内容：

- `ln(Oxidative/MEHP)` 和 `%Oxidative` 对 MSI-core、MSI no BMI、MSI PCA、ln(HOMA-IR)、HbA1c 的森林图。
- 辅助图：按 exposure quartile 的 MSI/HOMA/HbA1c trend。

Figure 3：CGMacros PPGR vulnerability  
内容：

- MSI tertile 下 iAUC/peak/high-response risk 分布。
- subject-level MSI vs median iAUC/high-response rate。
- carbs、MSI、carbs x MSI 的模型效应图。

Figure 4：Prediction and personalization  
内容：

- M0/M1/M2/M3 的 MAE、AUC、calibration slope。
- high MSI vs low MSI 的误差/校准对比。
- 0/1/3/5/10-shot personalization 曲线。

交付物：

- `figures_main/Figure2_NHANES_survey.*`
- `figures_main/Figure3_CGMacros_MSI_PPGR.*`
- `figures_main/Figure4_prediction_personalization.*`

### Week 2：仿生消化候选餐食人工 QC

目标：把 12 个候选餐食从“算法筛选”变成“可实验复原”的餐食原型。

必须完成：

- 打开 12 张候选餐食图片。
- 记录每餐真实组成、加工方式、估计重量、可复原配方。
- 判断是否保留、替换或合并重复宏量指纹。
- 每个原餐设计一个 redesigned 版本。

当前注意点：

- 12/12 图片存在。
- 12/12 宏量营养基本合理。
- 12/12 纤维为 0，必须人工判断是否真实。
- 8/12 有重复宏量指纹，必须避免实验样本过度重复。

交付物：

- `bionic_digestion_meal_qc_sheet.xlsx`
- `bionic_digestion_recipe_reconstruction_v1.csv`
- `bionic_digestion_original_redesigned_pairs_v1.csv`

### Week 3-4：仿生消化 pilot

目标：先用 3-4 个餐食确认系统、检测方法和效应方向。

建议 pilot 餐食：

- 高 MSI + 高 PPGR + 高碳水低纤维餐 2 个。
- 标准高碳水挑战/精制主食餐 1 个。
- 相对低风险或 redesigned 对照 1 个。

实验设计：

- original vs redesigned。
- 每组 3 个技术重复。
- gastric phase：0、15、30、60 min。
- intestinal phase：75、90、120、180 min。

主要终点：

- glucose release iAUC 0-60 min。
- glucose release Cmax。
- early release slope。

Go/No-Go：

- 如果 3-4 个 pilot 中至少 3 个方向一致降低 early release，进入完整实验。
- 如果方向不一致，先调整 redesign 策略，不急着扩大样本。

交付物：

- `bionic_pilot_glucose_release_raw.csv`
- `bionic_pilot_release_features.csv`
- `bionic_pilot_decision_report.md`

### Week 5-6：完整仿生消化实验

目标：形成主文 Figure 5。

设计：

- 8-12 个最终餐食原型。
- original/redesigned 配对。
- 每组 3 个技术重复。
- 总实验单元约 48-72。

统计：

- paired original vs redesigned。
- 每个餐食计算 release iAUC、Cmax、early slope、Tmax。
- bootstrap CI。
- 按 prototype class 分层。

成功标准：

- 多数餐食 original -> redesigned 方向一致降低 early release。
- 平均 paired reduction 有 CI 支持。
- release features 与 CGMacros predicted/observed high PPGR 方向一致。

交付物：

- `bionic_full_glucose_release_raw.csv`
- `bionic_full_release_features.csv`
- `Figure5_bionic_glucose_release_curves.*`
- `bionic_full_experiment_report.md`

### Week 6-7：把仿生消化特征回填预测模型

目标：证明机制特征不仅“好看”，还能解释模型误差或改善高风险识别。

做法：

- 将 release iAUC、Cmax、early slope 映射到餐食 prototype。
- 建立 M5：M4 + digestion-informed features。
- 比较 M4 vs M5 对高风险餐食识别、误差解释和校准的改善。

注意：

- 如果样本少，不要过度声称预测提升。
- 更稳妥写法是：digestion features explain selected high-error/high-risk meal prototypes。

交付物：

- `phase6_digestion_informed_model_results.csv`
- `digestion_features_model_error_explanation.md`

### Week 7-8：论文初稿和投稿包

目标：形成可以给合作者/导师看的完整 manuscript package。

必须完成：

- 英文主文初稿。
- 5 张主图。
- Supplementary tables。
- STROBE/STROBE-ME/STROBE-nut/TRIPOD+AI 对照清单。
- Data availability statement。
- Code availability statement。
- Protocol availability statement。
- Reproducibility package。

交付物：

- `manuscript/main_text_v1.docx`
- `manuscript/supplementary_tables_v1.xlsx`
- `manuscript/reporting_checklists/`
- `manuscript/data_code_availability.md`
- `manuscript/cover_letter_v1.md`

## 4. 主文图表最终设计

### Figure 1：机制框架图

展示：

`DEHP oxidative profile -> MSI-core -> PPGR vulnerability -> digestion-informed redesign`

作用：

- 让审稿人第一眼看懂不是简单拼接项目。

### Figure 2：NHANES 人群级证据

展示：

- R survey 森林图。
- oxidative profile 与 MSI/HOMA/HbA1c 的 dose-response 或 quartile trend。

主结论：

DEHP oxidative profile 与 metabolic susceptibility 相关。

### Figure 3：CGMacros 动态表型证据

展示：

- MSI tertile 下 PPGR 分布。
- subject-level MSI vs PPGR。
- load/MSI/interaction 模型结果。

主结论：

MSI 是 PPGR vulnerability 的稳定风险分层变量。

### Figure 4：预测与个体化

展示：

- M0-M3 性能。
- high-response AUC/AUPRC。
- calibration。
- few-shot personalization。

主结论：

MSI 不只是解释变量，也能提升 susceptibility-aware personalization。

### Figure 5：仿生消化机制实验

展示：

- original vs redesigned release curves。
- paired release iAUC/Cmax/early slope。
- release features 与模型高风险餐食方向一致。

主结论：

食物消化释放动力学提供可验证、可干预机制。

## 5. 需要避免的写法

不要写：

- DEHP 直接导致 CGMacros PPGR 升高。
- carbs x MSI 已经显著证明 effect modification。
- 外部 T1D 数据直接验证健康人 CGMacros 模型。
- 体外消化完全等同人体 PPGR。

建议写：

- DEHP oxidative profile is associated with a metabolic susceptibility phenotype.
- The same susceptibility phenotype is expressed as higher PPGR vulnerability in CGMacros.
- Evidence for load-by-susceptibility effect modification was directionally positive but not definitive.
- Bionic digestion provides mechanistic support for digestion-informed meal redesign.

## 6. 投稿决策标准

### 继续冲击整合型高水平期刊

满足以下条件：

- R survey 结果已保留方向和显著性：已满足。
- MSI -> PPGR 主效应 subject bootstrap 稳定：已满足。
- MSI-aware prediction 有明确提升：已满足。
- 外部数据支持边界：基本满足。
- 仿生消化 original vs redesigned 方向一致降低 early release：待完成。

### 降级或拆分

如果仿生消化 pilot 方向不一致：

- 不强行冲击 Nature Food/Cell Metabolism。
- 改投 AJCN/npj Science of Food/Clinical Nutrition。
- 或拆成环境流行病学论文 + CGM 精准营养论文。

## 7. 最重要的下一步

接下来真正该做的是：

1. 生成 Figure 2-4 投稿级图表。
2. 人工 QC 12 个候选餐食图片和配方。
3. 开展 3-4 个餐食的仿生消化 pilot。
4. 根据 pilot 决定是否进入完整 8-12 餐食实验。
5. 同步启动英文主文初稿。

换句话说，当前项目已经过了“是否有主线”的阶段。下一阶段要做的是把主线变成审稿人可以一眼理解、可以复核、并且有机制实验支撑的一篇论文。

## 8. 对齐的期刊与规范要求

- Nature Portfolio Reporting Standards: https://www.nature.com/nature-portfolio/editorial-policies/reporting-standards
- Nature Portfolio Data Availability: https://www.nature.com/nature-portfolio/editorial-policies/data-availability
- Nature Food reporting standards: https://www.nature.com/natfood/editorial-policies/reporting-standards
- Cell Press STAR Methods and data/code availability policies: https://www.cell.com/star-authors-guide
- Environmental Health Perspectives author instructions: https://ehp.niehs.nih.gov/instructions-to-authors
- American Journal of Clinical Nutrition instructions for authors: https://www.sciencedirect.com/journal/the-american-journal-of-clinical-nutrition/publish/guide-for-authors
- TRIPOD+AI: https://www.bmj.com/content/385/bmj-2023-078378
- PROBAST+AI: https://www.bmj.com/content/388/bmj-2024-082505
- STROBE-ME: https://www.equator-network.org/reporting-guidelines/strobe-me/
- STROBE-nut: https://www.equator-network.org/reporting-guidelines/strobe-nut/
