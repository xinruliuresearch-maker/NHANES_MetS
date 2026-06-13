# 干实验补强与高水平期刊深化研究计划

日期：2026-06-10  
项目：CGMacros + NHANES DEHP/MSI + 外部 CGM + 食品结构/机制数据库 + 仿生消化

## 1. 总体判断

当前项目已经有一条可以发表高水平论文的主线：

> DEHP oxidative profile -> metabolic susceptibility -> postprandial glycemic vulnerability -> digestion-informed meal redesign

R `survey` 复核后，NHANES 上游证据已经过统计门槛；CGMacros 中 MSI 对 PPGR vulnerability 的主效应稳定；MSI-aware prediction 能提升高反应餐食识别和校准。下一步干实验补强的目的不是再做更多松散分析，而是把这条证据链做成“审稿人很难拆散”的多层证据体系。

干实验部分应新增 6 个核心支柱：

1. **文献与证据图谱**：证明本研究的空白不是“又一个 PPGR 预测模型”，而是环境代谢易感性、食品结构和餐后动态血糖之间的跨尺度连接。
2. **NHANES 高级环境流行病学分析**：RCS、混合暴露、分层、负控、饮食来源/加工来源分析。
3. **CGMacros 餐食结构与 CGM 曲线表型深化**：从 iAUC/peak 扩展到曲线形状、餐食矩阵、加工代理、GI/GL/纤维结构。
4. **外部数据 transportability map**：明确健康人、T1D、T2D、标准化食物挑战中的可迁移与不可迁移边界。
5. **机制知识图谱**：DEHP/代谢物 -> oxidative stress / insulin signaling / PPAR / mitochondrial dysfunction / adipogenesis -> MSI components。
6. **反事实餐食重构与决策价值**：用 g-computation/target-trial-emulation 思路模拟“减少精制碳水、增加纤维、替换食物结构”能降低多少 PPGR。

## 2. 文献搜索后的关键启发

### 2.1 PPGR 与精准营养领域

Zeevi 等在 Cell 的经典研究证明，相同食物可产生高度个体化 PPGR，并用 800 人、46,898 餐建立个体化预测框架。PREDICT/Nature Medicine 系列进一步显示，餐食组成、个体代谢特征、肠道微生物和生活方式共同影响餐后反应。

近年研究继续推进到：

- 妊娠/GDM 人群 PPGR 预测；
- T1D 人群加入胰岛素剂量、营养和活动数据的模型；
- functional data analysis 分析完整 CGM 曲线，而不是只看 iAUC/peak；
- 随机临床试验检验 personalized nutrition program 对 cardiometabolic health 的影响。

本项目的差异化机会：

> 不是再证明“PPGR 可以预测”，而是提出 metabolic susceptibility 作为环境暴露与 PPGR vulnerability 之间的桥梁，并用食品消化释放动力学提供可干预机制。

### 2.2 环境暴露与代谢易感性领域

既有 NHANES 和流行病学研究支持 phthalates/DEHP 与 insulin resistance、metabolic syndrome、diabetes risk 存在关联，但结果经常受到以下问题限制：

- 暴露混合物复杂；
- 尿液稀释与 LOD 处理；
- 横断面因果不足；
- 饮食来源混杂；
- sex/race/age/obesity 异质性；
- 缺少动态代谢表型。

本项目的机会：

> 用 DEHP oxidative metabolic profile 连接 insulin-resistant MSI，再把 MSI 映射到真实餐食后的 CGM 动态表型，提供比传统 MetS/HOMA 更“动态”的下游表型。

### 2.3 食品结构与体外消化领域

INFOGEST 和相关体外消化文献提示，食物矩阵结构、淀粉可及性、加工方式、纤维/蛋白/脂肪共摄入会影响葡萄糖释放动力学。近年也有研究使用 in vitro glucose release protocol 评估食物消化后葡萄糖释放。

本项目的机会：

> 在干实验中先构建 food matrix/digestibility features，再用陈晓东教授仿生消化系统验证这些特征是否能解释高风险餐食。

### 2.4 方法学规范

高水平期刊会重点关注：

- TRIPOD+AI：预测模型报告完整性；
- PROBAST+AI：预测模型偏倚与适用性；
- STROBE/STROBE-ME/STROBE-nut：观察性、暴露、生物标志物和营养流行病学报告；
- target trial emulation：观察性研究中避免过度因果声称；
- WQS/qgcomp/BKMR：环境混合暴露；
- data/code/protocol availability：Nature/Cell/AJCN 等期刊共同要求。

## 3. 干实验补强模块设计

### Module A：系统文献与证据图谱

目标：

形成一张 evidence map，说明本研究位于三个领域交叉处：

1. environmental phthalate exposure and metabolic susceptibility；
2. personalized PPGR/CGM precision nutrition；
3. food structure and digestion kinetics。

具体任务：

- 检索并整理 80-120 篇核心文献。
- 按研究类型分类：NHANES/流行病学、PPGR prediction、CGM intervention、food digestion、mechanistic toxicology、methods/guidelines。
- 建立 evidence gap table：
  - 已知：DEHP 与 insulin resistance 相关；
  - 已知：PPGR 具有个体差异；
  - 已知：食物结构影响消化释放；
  - 未知：环境相关代谢易感性是否表现为真实餐食 PPGR vulnerability；
  - 未知：消化释放动力学能否成为餐食重构的机制桥梁。

交付物：

- `outputs/integrated_mainline/literature_evidence_map/dry_lab_evidence_map.csv`
- `dry_lab_scoping_review_notes.md`
- `FigureS1_evidence_gap_map.*`

主文用途：

- Introduction 最后一段；
- Supplementary evidence map。

### Module B：NHANES 高级环境流行病学补强

目标：

把 Phase 2 从“主模型显著”提升为“环境流行病学证据完整”。

#### B1. RCS 剂量反应

问题：

DEHP oxidative profile 与 MSI/HOMA/HbA1c 是否呈线性、阈值或非线性关系？

方法：

- R `survey` + restricted cubic splines。
- 暴露：`ln(Oxidative/MEHP)`、`%Oxidative`、`ln(Sigma DEHP)`。
- 结局：MSI-core、MSI no BMI、ln(HOMA-IR)、HbA1c。

输出：

- `phase2_R_survey_rcs_results.csv`
- `Figure2B_dose_response_RCS.*`

#### B2. 混合暴露与组成分析

问题：

是 DEHP 总负荷重要，还是 oxidative/primary metabolite balance 更重要？

方法：

- qgcomp/WQS/BKMR 作为敏感性；
- molar composition；
- log-ratio / ILR composition；
- 与现有 `ln(Oxidative/MEHP)` 对照。

输出：

- `nhanes_dehp_mixture_composition_results.csv`
- `FigureS_mixture_composition_DEHP.*`

#### B3. 异质性分层

问题：

哪些人群中 DEHP oxidative profile 与 MSI 更强？

分层：

- sex；
- age：<40、40-60、>60；
- obesity；
- diabetes history；
- race/ethnicity；
- high vs low dietary processing/source proxy。

输出：

- `nhanes_effect_modification_results.csv`
- `FigureS_effect_modification_forest.*`

#### B4. 负控与稳健性

目标：

增强横断面研究可信度。

建议：

- negative control outcome：理论上不应受短期 DEHP 影响的变量；
- negative control exposure：非 DEHP 或低相关环境变量；
- urinary creatinine 处理敏感性；
- LOD 处理敏感性；
- 排除糖尿病/降糖药；
- IPW/multiple imputation。

输出：

- `nhanes_negative_control_results.csv`
- `nhanes_creatinine_lod_sensitivity.csv`
- `nhanes_missingness_ipw_mi_results.csv`

主文用途：

- Figure 2 主结果；
- Extended Data / Supplementary 稳健性。

### Module C：CGMacros 餐食结构与食品加工特征补强

目标：

把餐食变量从简单宏量营养提升为“食品结构/加工/消化可及性”特征。

#### C1. Food matrix annotation

为每餐标注：

- refined starch；
- whole grain / intact grain；
- liquid carbohydrate；
- dessert/sweetened beverage；
- high fat + high carb matrix；
- visible fiber/vegetable；
- protein co-ingestion；
- fried/processed/packaged proxy；
- estimated NOVA category；
- carbohydrate/fiber ratio；
- available carbohydrate；
- glycemic load proxy；
- digestion-risk score。

数据来源：

- CGMacros meal photos；
- USDA FoodData Central；
- University of Sydney GI Database；
- Open Food Facts / NOVA；
- manual expert coding。

输出：

- `cgmacros_food_matrix_annotation.csv`
- `cgmacros_gi_gl_digestibility_features.csv`
- `food_matrix_annotation_codebook.md`

#### C2. Meal photo assisted QC

目标：

解决当前 12 个候选餐食 0 fiber 和重复宏量指纹问题。

任务：

- 对所有 Stage 5 候选餐食人工查看图片；
- 标注真实食物组成；
- 修正或标记可疑宏量营养；
- 判断是否适合进入仿生消化。

输出：

- `bionic_candidate_photo_qc_sheet.csv`
- `bionic_candidate_recipe_reconstruction.csv`

#### C3. Food matrix effect model

模型：

```text
PPGR ~ MSI + macro load + food matrix features + MSI x digestibility-risk + pre-CGM context + subject structure
```

目标：

回答：

- 高风险 PPGR 是否由“高碳水”之外的食品结构解释？
- 高 MSI 个体是否更容易受 digestibility-risk score 影响？
- 加入 food matrix features 是否解释 Stage 4 中的预测误差？

输出：

- `cgmacros_food_matrix_ppgr_models.csv`
- `food_matrix_prediction_error_explanation.csv`
- `Figure3_food_matrix_effects.*`

主文用途：

- 强化 Figure 3；
- 为仿生消化实验选择餐食提供干实验证据。

### Module D：CGM 曲线表型与 functional data analysis

目标：

从 iAUC/peak 扩展到完整餐后曲线形态，提升动态表型深度。

建议表型：

- early spike：0-45 min 上升快；
- delayed peak：Tmax > 60 min；
- prolonged elevation：120 min 仍未恢复；
- high iAUC but moderate peak；
- high peak but fast recovery；
- low response / stable response。

计算指标：

- early slope 0-30 / 0-45；
- iAUC 0-60、0-120、0-180；
- Cmax；
- Tmax；
- recovery time；
- residual glucose at 120/180 min；
- shape cluster membership。

方法：

- 对每餐 CGM 曲线插值到统一时间网格；
- PCA/FPCA-like decomposition；
- k-means/层次聚类；
- subject-clustered multinomial/one-vs-rest models；
- MSI 与 meal features 预测 curve phenotype。

输出：

- `cgmacros_ppgr_curve_features.csv`
- `cgmacros_ppgr_shape_clusters.csv`
- `curve_shape_msi_food_matrix_models.csv`
- `FigureS_curve_phenotypes.*`

主文用途：

- 强化“dynamic phenotype”概念；
- 放主文或扩展数据，取决于结果清晰度。

### Module E：机制知识图谱与通路证据

目标：

用公开数据库增强生物学可解释性，但不让机制网络抢主线。

数据源：

- EPA CompTox / ToxCast；
- CTD；
- PubChem；
- Reactome；
- KEGG；
- Gene Ontology；
- DisGeNET；
- HMDB/MetaboAnalyst 通路注释。

节点：

- DEHP；
- MEHP；
- MEHHP；
- MEOHP；
- MECPP；
- oxidative stress；
- PPAR signaling；
- insulin signaling；
- mitochondrial dysfunction；
- adipogenesis；
- beta-cell function；
- lipid metabolism；
- glucose transport；
- inflammatory signaling。

任务：

- 汇总 DEHP 相关基因/靶点/通路；
- 提取 insulin resistance、oxidative stress、lipid metabolism 相关证据；
- 与 MSI 组件建立机制桥梁；
- 形成一个简洁机制图，不做过度网络。

输出：

- `dehp_msi_mechanism_knowledge_graph_edges.csv`
- `dehp_msi_pathway_enrichment.csv`
- `FigureS_mechanism_knowledge_graph.*`

主文用途：

- Introduction/Discussion 支撑；
- Supplementary mechanism evidence。

### Module F：外部验证与 transportability map

目标：

明确哪些结论可迁移，哪些只是边界参照。

数据集角色：

| 数据集 | 角色 | 主问题 |
|---|---|---|
| Stanford CGMDB | 标准化食物挑战 | 相同食物下是否存在强个体差异？ |
| T1D-UOM | T1D 自由生活餐食 | 碳水/纤维方向是否在疾病状态保留？ |
| Jaeb healthy adults | 健康 CGM 参考 | 健康人 CGM 波动范围如何？ |
| OhioT1DM | T1D benchmark | 模型在疾病人群中边界如何？ |
| D1NAMO | 食物图像/胰岛素/CGM case | 可作为图像与事件注释案例 |
| Shanghai T1DM/T2DM | 中国糖尿病 CGM phenotype | 中国人群 CGM 边界参考 |

分析：

- dataset-level phenotype map；
- macro-response direction consistency；
- domain shift diagnostics；
- model transportability：train CGMacros -> test external only if variables允许；
- 不做过度泛化。

输出：

- `external_transportability_map.csv`
- `external_domain_shift_metrics.csv`
- `FigureS_external_boundary_map.*`

主文用途：

- 主文最多一张边界图；
- 其余放补充材料。

### Module G：反事实餐食重构与 target-trial-style 决策分析

目标：

把“模型预测”转化为可解释的饮食干预问题。

问题：

如果将高风险餐食做以下替换，预测 PPGR 降低多少？

干预策略：

1. 精制碳水减少 20 g；
2. 可利用碳水限制到 45 g；
3. 增加 5-10 g 纤维；
4. refined starch -> intact/whole grain；
5. sugar-sweetened beverage -> non-sugar beverage；
6. high carb + high fat processed meal -> protein/vegetable substitution；
7. 增加蛋白/非淀粉蔬菜并保持能量近似。

方法：

- emulated target trial table：
  - eligibility；
  - treatment strategies；
  - assignment；
  - follow-up window；
  - outcome；
  - causal contrast；
  - analysis plan。
- g-computation / model-based counterfactual prediction；
- subject bootstrap；
- high MSI subgroup net benefit。

输出：

- `meal_redesign_target_trial_protocol.md`
- `counterfactual_meal_redesign_effects.csv`
- `counterfactual_high_msi_net_benefit.csv`
- `Figure4_or_5_counterfactual_redesign.*`

主文用途：

- 连接 Phase 4 prediction 与 Stage 5 digestion experiment；
- 说明仿生消化实验不是随便选餐，而是模型驱动的干预验证。

### Module H：TRIPOD+AI / PROBAST+AI 投稿级预测模型包

目标：

把预测部分从“模型效果不错”变成“可审稿的 prediction study”。

必须完成：

- nested leave-subject-out；
- no leakage audit；
- full predictor dictionary；
- missingness handling；
- hyperparameter tuning description；
- calibration slope/intercept；
- AUC/AUPRC for high-response；
- conformal interval coverage；
- decision curve / net benefit；
- subgroup performance；
- model card；
- TRIPOD+AI checklist；
- PROBAST+AI self-assessment。

输出：

- `TRIPOD_AI_checklist_completed.docx/md`
- `PROBAST_AI_self_assessment.md`
- `prediction_model_card.md`
- `prediction_leakage_audit.csv`

主文用途：

- Methods 和 Supplementary；
- 回应预测模型审稿质疑。

### Module I：可复现性与投稿包

目标：

满足 Nature/Cell/AJCN 对 data/code/protocol availability 的要求。

任务：

- 创建 `analysis_manifest.csv`；
- 每个输出文件记录来源脚本、输入数据、hash、日期；
- R session info；
- Python package versions；
- 数据字典；
- 运行顺序；
- public/private data availability 说明；
- external dataset licenses。

输出：

- `reproducibility/analysis_manifest.csv`
- `reproducibility/data_dictionary.xlsx`
- `reproducibility/run_order.md`
- `reproducibility/code_availability_statement.md`
- `reproducibility/data_availability_statement.md`
- `reproducibility/protocol_availability_statement.md`

## 4. 建议新增脚本顺序

建议从 `scripts/21_...` 开始继续：

1. `21_literature_evidence_map.py`
2. `22_nhanes_advanced_survey_sensitivity.R`
3. `23_cgmacros_food_matrix_annotation.py`
4. `24_cgmacros_cgm_curve_phenotypes.py`
5. `25_mechanism_knowledge_graph.py`
6. `26_external_transportability_map.py`
7. `27_counterfactual_meal_redesign_target_trial.py`
8. `28_prediction_tripo_ai_package.py`
9. `29_reproducibility_submission_package.py`

## 5. 时间安排

### Sprint 1：1 周

完成：

- 文献 evidence map；
- NHANES RCS + 分层 + 负控计划；
- Figure 2 投稿级数据整理。

### Sprint 2：1-2 周

完成：

- CGMacros food matrix annotation；
- Stage 5 候选餐食图片/配方 QC；
- digestion-risk score；
- food matrix -> PPGR 模型。

### Sprint 3：1 周

完成：

- CGM curve shape phenotypes；
- MSI 与 curve phenotype 关联；
- Figure 3/Extended Data 动态表型图。

### Sprint 4：1 周

完成：

- external transportability map；
- Stanford/T1D-UOM/Jaeb/Ohio/D1NAMO/Shanghai 边界整理；
- 主文外部验证图候选。

### Sprint 5：1 周

完成：

- counterfactual meal redesign；
- target-trial-style protocol；
- high MSI subgroup decision benefit；
- 与仿生消化实验矩阵对接。

### Sprint 6：1 周

完成：

- TRIPOD+AI / PROBAST+AI；
- reproducibility package；
- Data/Code/Protocol availability；
- manuscript dry-lab methods draft。

## 6. 优先级排序

### 最高优先级

1. CGMacros food matrix annotation。
2. Stage 5 候选餐食图片/配方 QC。
3. CGM curve phenotypes。
4. NHANES RCS/分层/负控。
5. Counterfactual meal redesign。

原因：

这些分析能直接增强主文 Figure 2-5，并且为仿生消化实验提供更清晰的选择依据。

### 中优先级

1. Mechanism knowledge graph。
2. External transportability map。
3. TRIPOD+AI/PROBAST+AI 完整包。

原因：

这些内容提升可信度和投稿完整性，但不应喧宾夺主。

### 低优先级

1. 复杂深度学习模型。
2. 大规模微生物组探索。
3. 死亡结局。
4. 过多 BKMR 图。
5. 全部外部数据库逐个展开。

原因：

这些容易让主线再次发散。

## 7. 预期形成的最终论文结构

### Main Figure 1

Multiscale framework:

DEHP oxidative profile -> MSI -> PPGR vulnerability -> digestion-informed redesign。

### Main Figure 2

NHANES R survey + RCS：

DEHP oxidative profile 与 MSI/HOMA/HbA1c 的关联。

### Main Figure 3

CGMacros dynamic phenotype：

MSI tertile、subject-level PPGR、curve phenotype、food matrix effect。

### Main Figure 4

Prediction and counterfactual personalization：

MSI-aware model、high-response detection、counterfactual meal redesign。

### Main Figure 5

Bionic digestion：

original vs redesigned glucose release kinetics。

## 8. 关键成败标准

### 干实验达到高水平期刊支撑的标准

满足：

- NHANES R survey + RCS + 分层结果方向一致；
- MSI -> PPGR 在 food matrix/curve phenotype 后仍稳定；
- food matrix/digestibility-risk score 能解释部分高风险餐食；
- counterfactual redesign 对 high MSI 组有更大潜在收益；
- 外部数据展示合理边界，而不是互相矛盾；
- prediction 部分符合 TRIPOD+AI/PROBAST+AI；
- 机制知识图谱支持 oxidative stress/insulin signaling 路径。

### 需要降级解释的情况

如果出现：

- food matrix 后 MSI 效应消失；
- curve phenotype 与 MSI 无关；
- counterfactual redesign 效应很弱；
- 外部数据完全不支持 meal-load/fiber方向；

则主文应降级为：

> metabolic susceptibility is a risk stratifier, but mechanism and intervention require further validation。

## 9. 与湿实验的衔接

干实验最终要服务于仿生消化，不是替代仿生消化。

推荐流程：

1. 用 food matrix + PPGR + MSI 选出 8-12 个餐食原型。
2. 用 counterfactual redesign 生成替换方案。
3. 用 digestion-risk score 预测 original vs redesigned 的 glucose release 差异。
4. 仿生消化实验验证 release iAUC/Cmax/early slope。
5. 将 release features 回填 M5 模型或用于解释 high-error meal prototypes。

这样湿实验就不再是附加实验，而是整篇论文的机制闭环。

## 10. 参考与数据资源

### PPGR / 精准营养

- Zeevi et al., Cell 2015, Personalized Nutrition by Prediction of Glycemic Responses: https://www.cell.com/fulltext/S0092-8674(15)01481-6
- PREDICT / Nature Medicine postprandial responses: https://pmc.ncbi.nlm.nih.gov/articles/PMC8265154/
- Personalized nutrition RCT in Nature Medicine 2024: https://www.nature.com/articles/s41591-024-02951-6
- Functional data analysis of postprandial CGM trajectories: https://link.springer.com/article/10.1186/s12874-025-02748-2

### 环境暴露 / phthalates

- DEHP and insulin resistance via oxidative stress: https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0071392
- Urinary phthalates and insulin resistance in adolescents: https://pmc.ncbi.nlm.nih.gov/articles/PMC4528350/
- Phthalates and metabolic syndrome: https://pmc.ncbi.nlm.nih.gov/articles/PMC4832560/
- Phthalate mixture and oxidative imbalance using WQS/qgcomp/BKMR: https://link.springer.com/article/10.1186/s40001-026-04036-1

### 食品结构 / GI / 消化

- USDA FoodData Central API: https://fdc.nal.usda.gov/api-guide
- USDA FoodData Central downloads: https://fdc.nal.usda.gov/download-datasets
- University of Sydney GI Database: https://glycemicindex.com/
- International GI Database metadata: https://researchdata.edu.au/international-glycemic-index-gi-database/11115
- Open Food Facts API / NOVA-related product data: https://openfoodfacts.github.io/openfoodfacts-server/api/
- INFOGEST publications: https://infogest.hub.inrae.fr/infogest-scientific-publications
- Simple in vitro glucose release protocol: https://pmc.ncbi.nlm.nih.gov/articles/PMC12121517/

### 机制数据库

- EPA CompTox Chemicals Dashboard: https://www.epa.gov/comptox-tools/comptox-chemicals-dashboard
- CompTox Dashboard portal: https://comptox.epa.gov/dashboard/

### 方法规范

- TRIPOD+AI BMJ: https://www.bmj.com/content/385/bmj-2023-078378
- TRIPOD+AI EQUATOR: https://www.equator-network.org/reporting-guidelines/tripod-statement/
- PROBAST+AI BMJ: https://www.bmj.com/content/388/bmj-2024-082505
- Target trial framework: https://pmc.ncbi.nlm.nih.gov/articles/PMC10392882/
- STROBE-ME: https://www.equator-network.org/reporting-guidelines/strobe-me/
- STROBE-nut: https://www.equator-network.org/reporting-guidelines/strobe-nut/

## 11. 最终建议

下一阶段应立即优先执行：

1. `23_cgmacros_food_matrix_annotation.py`
2. `24_cgmacros_cgm_curve_phenotypes.py`
3. `27_counterfactual_meal_redesign_target_trial.py`
4. `22_nhanes_advanced_survey_sensitivity.R`

这四项是最能提升论文层级的干实验补强。它们会直接决定主文 Figure 3 和 Figure 4 的质量，并为 Figure 5 的仿生消化实验提供更强的理论和数据依据。
