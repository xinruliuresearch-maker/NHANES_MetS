# NHANES DEHP-代谢异常项目：高水平期刊推进方案

生成日期：2026-06-10

## 1. 我对当前项目的总体判断

这个项目已经不是早期探索阶段，而是有较完整证据链的环境流行病学研究雏形。现有文件包含 NHANES 2013-2018 主数据、NHANES 2003-2018 DEHP-only 验证数据、死亡随访扩展、DAG、主模型、剂量反应、混合暴露、组成数据分析、IPW/MI、负控、E-value、LOD/肌酐敏感性、糖尿病用药排除、来源调整、BKMR、CTD/CompTox/ToxCast 机制证据和图件。

最值得收敛成主论文的问题不是泛泛地说“DEHP 与肥胖/代谢综合征相关”，而是：

> 在美国成年人中，DEHP 氧化代谢谱（% oxidative metabolites、oxidative/MEHP log-ratio、ILR oxidative-vs-primary balance）是否比总 DEHP 暴露负荷更能表征胰岛素抵抗和早期糖脂代谢紊乱？

这个主线更有新意：它从“暴露总量”推进到“代谢处理/生物转化谱”，并且能自然连接到 HOMA-IR、HbA1c、TyG、TG/HDL-C、机制数据库和毒理通路。

## 2. 已有核心证据

### 2.1 数据规模

- NHANES 2013-2018 主分析数据：n=5,267。
- DEHP 派生暴露变量非缺失：n=5,147。
- HOMA-IR：n=2,446；HbA1c：n=5,094；TyG：n=2,417；ln(TG/HDL-C)：n=2,418。
- NHANES 2003-2018 DEHP-only 验证数据：n=13,655。
- 死亡随访数据集：n=13,655，MORTSTAT 非缺失 n=13,621。

### 2.2 主模型结果

2013-2018 survey-weighted 模型显示：

- ln(Sigma DEHP) 与 ln(HOMA-IR) 正相关：11.27% (5.59%, 17.26%), q<0.001。
- %Oxidative 每升高 10 个百分点，ln(HOMA-IR) 增加：23.47% (13.08%, 34.81%), q<0.001。
- oxidative/MEHP log-ratio 与 ln(HOMA-IR) 关联更强：24.08% (15.13%, 33.73%), q<0.001。
- HbA1c 方向一致但效应较小：%Oxidative 每 10 个百分点对应 HbA1c +0.068 (0.027, 0.108), q=0.002。
- TyG 和 ln(TG/HDL-C) 对总 DEHP 不明显，但对氧化代谢谱明显：TyG +0.132 (0.062, 0.202), q<0.001；ln(TG/HDL-C) +14.13% (5.34%, 23.66%), q=0.004。

这支持一个重要叙事：总暴露负荷主要解释 HOMA-IR/HbA1c，而氧化代谢构成对脂质-胰岛素相关指标更敏感。

### 2.3 二分类结局

- 总 DEHP 与肥胖、中心性肥胖、代谢综合征并不稳定显著。
- 氧化代谢谱与肥胖、中心性肥胖、代谢综合征均强相关：
  - Obesity: OR 1.58 (1.30, 1.93), q<0.001。
  - Central obesity: OR 1.36 (1.18, 1.57), q<0.001。
  - Metabolic syndrome: OR 1.94 (1.36, 2.79), q=0.001。

这些结果可以作为次要表型证据，但不建议把“肥胖/代谢综合征”放在标题核心，因为横断面反向因果更强、机制解释也更容易被审稿人质疑。

### 2.4 剂量反应和组成证据

- Q4 vs Q1：%Oxidative 对 ln(HOMA-IR) 的效应约 +49.8% (27.3%, 76.4%)，p-trend<0.001。
- HbA1c 的 Q4 vs Q1 也为正：+0.154 (0.073, 0.236)。
- ILR oxidative-vs-primary balance 在 HOMA-IR 和 HbA1c 上经总负荷调整后仍显著。

这部分非常适合作为主图，因为它表达了“代谢谱而非单纯浓度”的贡献。

### 2.5 敏感性分析

现有敏感性分析比较扎实：

- LOD/肌酐处理：主结果在肌酐极端值排除、肌酐标准化、LOD 限制、winsorization 后仍基本稳健。
- IPW/多重插补：总体方向一致。
- 糖尿病诊断/用药排除：HbA1c 结果在排除诊断或用药者后仍保留，但在严格正常血糖人群中减弱或改变方向。
- 负控结局成人身高：未见明显关联。
- permutation negative control：观测效应超过置换零分布。
- E-value：部分二分类 Q4 vs Q1 对未测混杂有中等稳健性。

### 2.6 混合暴露和机制证据

- qgcomp-like 混合模型：DEHP oxidative mixture 对 HOMA-IR 和 HbA1c 为 FDR 显著。
- WQS：作为敏感性结果支持 HOMA-IR 和 HbA1c。
- BKMR：仅 n=800 子样本、3000 iterations，方向支持，但应定位为补充/探索性。
- CTD/CompTox/ToxCast 机制证据已经整理出 PPAR/nuclear receptor、oxidative stress、inflammation、insulin/glucose signaling、lipid metabolism、mitochondrial/ER stress 等通路。

## 3. 投稿级别的主要短板

### 3.1 研究问题还需要收敛

现有分析非常多，但主线容易发散。建议一篇主论文只讲一个中心发现：

> DEHP oxidative metabolic profile is consistently associated with insulin resistance and glycemic-lipid dysregulation in adults.

死亡、来源分析、CTD 机制、BKMR、负控都作为支撑模块，而不是并列主角。

### 3.2 复现工程需要重构

目前多个 R 脚本硬编码旧路径：

- `C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project`
- `C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project`

另有脚本会在运行时 `install.packages()`，不利于复现。高水平期刊投稿前建议：

- 使用 `here::here()` 或统一 `config.yml` 管理路径。
- 用 `renv` 固定 R 包版本。
- 用 `targets` 或 `drake` 重构成可一键复现 pipeline。
- 输出 `sessionInfo()`、数据下载日志、变量字典、样本流图。
- 所有结果表和图件由代码再生成，不手工修改。

### 3.3 混合模型命名要谨慎

现有 `survey_qgcomp` 是“survey-weighted quantile g-computation-like”，不是标准 `qgcomp` 包或完整 g-computation 实现。稿件中建议写成：

- Main mixture sensitivity: survey-weighted quantile-score mixture index。
- WQS: exploratory WQS sensitivity, unweighted。
- BKMR: exploratory nonlinear mixture analysis, weighted subsample unavailable/limited。

不要在标题或摘要中过度强调 BKMR，否则审稿人会抓 n=800 和 survey weights 的问题。

### 3.4 死亡分析需要重新审计

Excel 摘要显示 linked mortality analytic_n_linked=13,617、all-cause deaths=1,737；但 continuous Cox 结果中 n=2,772、events=156，且 CVD/heart/cancer/diabetes cause-specific 模型失败。需要检查：

- 是否因完整协变量导致样本大幅下降。
- 是否 survey Cox 设计、权重或 strata/PSU 导致失败。
- 是否应改为更简单的补充模型：all-cause primary, cause-specific descriptive only。

死亡结果可保留为“long-term relevance exploratory extension”，不要放主结论。

### 3.5 图件需要期刊化

当前图件能表达分析结果，但更像脚本输出：

- 部分图标题裁切。
- 机制网络黑底、留白大、边过多、图例异常。
- 主图需要统一字体、单位、颜色、缩写解释。

建议主文只保留 4-5 张高质量图，补充材料放大量细节图。

## 4. 推荐主论文设计

### 4.1 暂定题目

中文工作题目：

> 尿中 DEHP 氧化代谢谱与美国成年人胰岛素抵抗和糖脂代谢紊乱：NHANES 2003-2018 的组成暴露、混合模型和机制三角验证研究

英文工作题目：

> Oxidative metabolic profiling of DEHP exposure and insulin resistance in U.S. adults: compositional, mixture, and mechanistic triangulation using NHANES and public toxicogenomic databases

### 4.2 核心假设

1. DEHP 总负荷与 HOMA-IR 和 HbA1c 升高相关。
2. 在总负荷之外，DEHP 氧化代谢谱代表更高的代谢敏感状态，与 HOMA-IR、TyG、TG/HDL-C 更稳定相关。
3. 该关联可由核受体/PPAR、氧化应激、炎症、胰岛素/葡萄糖信号、脂质代谢和线粒体/ER stress 通路提供机制可解释性。

### 4.3 主要结局和次要结局

Primary outcomes:

- ln(HOMA-IR)
- HbA1c

Secondary outcomes:

- TyG index
- ln(TG/HDL-C)
- obesity / central obesity / metabolic syndrome

Exploratory extension:

- linked all-cause mortality
- source-oriented dietary/personal-care proxies
- CTD/CompTox/ToxCast/GEO/Open TG-GATEs mechanism models

### 4.4 主暴露

Primary exposure:

- ln(Sigma DEHP)
- %Oxidative metabolites per 10 percentage points
- ln((MEHHP + MEOHP + MECPP) / MEHP)
- ILR oxidative-vs-primary balance

Secondary exposure:

- individual metabolites: MEHP, MEHHP, MEOHP, MECPP
- mixture indices: survey-weighted quantile-score mixture index, WQS, BKMR

### 4.5 主分析框架

1. NHANES 2013-2018 作为机制完整 discovery dataset。
2. NHANES 2003-2012 或 2003-2018 period validation 作为 temporal replication。
3. Survey-weighted GLM 为主。
4. Restricted cubic spline / quartile dose-response 展示非线性和趋势。
5. Composition analysis 使用 log-ratio 和 ILR，证明结果不只是总量驱动。
6. Missingness 使用 complete-case + IPW + MI。
7. Sensitivity 包括 LOD、肌酐、糖尿病用药、负控、permutation、E-value。

## 5. 公开数据库训练和验证路线

### 5.1 人群数据层：预测/验证模型

目的不是替代因果分析，而是回答：

> DEHP 氧化代谢谱是否能在传统人口学、饮食、生活方式变量之外改善代谢异常风险识别？

建议建模任务：

- Outcome 1: high HOMA-IR，例如 top quartile 或 HOMA-IR >=2.5。
- Outcome 2: prediabetes/glycemic risk，例如 HbA1c >=5.7%。
- Outcome 3: high TyG 或 metabolic dysregulation composite。

特征集分三层比较：

- Model A: age, sex, race/ethnicity, PIR, education, energy intake, cycle。
- Model B: Model A + ln(Sigma DEHP)。
- Model C: Model B + %Oxidative/log-ratio/ILR composition。

训练验证策略：

- Train: NHANES 2003-2012。
- Temporal validation: NHANES 2013-2018。
- Sensitivity: train 2003-2008, validate 2009-2018；或 train 2003-2016, test 2017-2018。

模型建议：

- Baseline: survey-weighted logistic regression。
- Regularized: elastic net logistic regression。
- Nonlinear: XGBoost / LightGBM / random forest。
- Explainability: SHAP, partial dependence, calibration curves。

报告指标：

- AUC / PR-AUC。
- Brier score。
- calibration intercept/slope。
- decision curve analysis。
- net reclassification improvement 只作补充，避免过度解读。

关键原则：

- 不能用测试集调参。
- 不能把同一周期同时用于变量筛选和最终验证。
- 预测模型结论要写成“risk stratification improvement”，不要写成因果证明。

### 5.2 机制数据库层：通路/基因签名训练

建议建立一个 `DEHP-metabolic pathway signature`：

1. 从 CTD 提取 DEHP/MEHP/MEHHP/MEOHP/MECPP 相关基因、疾病、表型证据。
2. 从 CompTox/ToxCast/Tox21 提取核受体、PPAR、oxidative stress、mitochondrial、endocrine、insulin/glucose 相关 assay。
3. 从 GEO/Open TG-GATEs 搜索 DEHP/MEHP 暴露的肝细胞、脂肪细胞、胰岛/代谢组织 transcriptomic datasets。
4. 构建机制面板：PPAR/nuclear receptor、oxidative stress、inflammation、insulin/glucose signaling、lipid metabolism、mitochondrial/ER stress。
5. 用公开转录组训练或验证 pathway activity score，例如 ssGSEA/GSVA、PROGENy、DoRothEA、WGCNA 或 sparse PLS。
6. 将 pathway score 与 NHANES 人群发现做三角验证，而不是声称实验验证。

推荐数据库：

- NHANES: 暴露和代谢表型训练/验证。
- NCHS Linked Mortality Files: 长期死亡结局扩展。
- CTD: chemical-gene-disease/phenotype 机制证据。
- EPA CompTox / ToxCast: chemical assay, target, bioactivity evidence。
- Tox21: qHTS bioactivity and pathway assay。
- NCBI GEO: DEHP/MEHP 暴露转录组、肥胖/胰岛素抵抗转录组。
- Open TG-GATEs: toxicogenomics, liver/kidney in vivo and in vitro toxicant response。
- Reactome/KEGG/MSigDB: pathway annotation and enrichment。
- GTEx/Human Protein Atlas: tissue expression plausibility。

### 5.3 一个高水平的整合模型

可以设计成三层证据：

Layer 1: Human population association

- Survey-weighted effect estimates。
- Dose-response。
- Composition and mixture models。

Layer 2: Predictive/replication evidence

- Temporal validation across NHANES cycles。
- Incremental prediction by oxidative profile。
- Model calibration and interpretability。

Layer 3: Mechanistic triangulation

- CTD/CompTox/ToxCast/Tox21 evidence。
- GEO/Open TG-GATEs pathway signature。
- Network and enrichment analysis。

最终论文结论应是：

> DEHP oxidative metabolic profile is a reproducible marker of insulin-resistance-related metabolic disruption and is mechanistically consistent with nuclear receptor, oxidative stress, inflammatory, and glucose-lipid signaling pathways.

## 6. 建议重排结果和图表

### Main Figure 1

Study design + sample flow + exposure construction:

- NHANES cycles。
- DEHP metabolites to Sigma DEHP and oxidative profile。
- Discovery/validation split。
- Main outcomes。

### Main Figure 2

Core association heatmap / forest plot:

- Rows: HOMA-IR, HbA1c, TyG, TG/HDL-C, obesity, central obesity, MetS。
- Columns: ln(Sigma DEHP), %Oxidative, log-ratio, ILR。
- 标出 FDR q<0.05。

### Main Figure 3

Dose-response / quartile plot:

- 只保留 HOMA-IR 和 HbA1c。
- 暴露只保留 ln(Sigma DEHP)、%Oxidative、ILR。
- 不要太多面板。

### Main Figure 4

Temporal validation / prediction:

- Train older cycles, validate newer cycles。
- Compare clinical model vs +total DEHP vs +oxidative profile。
- AUC + calibration + SHAP summary。

### Main Figure 5

Mechanistic triangulation:

- 不建议用当前大网络图。
- 改为机制证据热图或 Sankey-like pathway summary。
- 显示 CTD/CompTox/ToxCast/GEO 支持的通路。

Supplementary figures:

- RCS 全部结果。
- qgcomp/WQS/BKMR。
- LOD/肌酐/MI/IPW/糖尿病用药敏感性。
- 死亡分析。
- source-oriented results。
- negative-control/permutation/E-value。

## 7. 后续 8 周执行计划

### 第 1 周：工程化和复现

- 修复所有 `project_dir` 硬编码。
- 建立 `renv.lock`。
- 整理 `README`, `data_dictionary`, `analysis_plan`。
- 重建 pipeline，使主结果一键生成。
- 重新生成所有图表和表格。

### 第 2 周：确定主分析版本

- 冻结 primary exposure/outcome/covariate。
- 明确 discovery 与 validation 周期。
- 重新跑主模型、composition、quartile/RCS。
- 生成主表和主图雏形。

### 第 3 周：训练和 temporal validation

- 建立 Model A/B/C。
- 完成 train/validation split。
- 输出 AUC、calibration、Brier、decision curve。
- SHAP 解释氧化代谢谱贡献。

### 第 4 周：机制数据库扩展

- 更新 CTD/CompTox/ToxCast/Tox21 数据。
- 系统检索 GEO/Open TG-GATEs。
- 建立 pathway signature。
- 进行 enrichment / network diffusion / GSVA。

### 第 5 周：审稿人会问的敏感性分析

- LOD、肌酐、MI/IPW、糖尿病用药、糖尿病诊断排除。
- 负控、permutation、E-value。
- sex/age/obesity/race effect modification。

### 第 6 周：图表期刊化

- 统一英文术语和单位。
- 主图 4-5 张。
- 补图编号完整。
- Table 1、Table 2、Supplementary Tables 完成。

### 第 7 周：初稿

- Introduction: phthalates/DEHP、代谢异常、为什么看 oxidative profile。
- Methods: NHANES、survey design、exposure construction、modeling、ML、mechanistic databases。
- Results: 按证据层推进。
- Discussion: 生物机制、公共卫生意义、优势局限。

### 第 8 周：投稿前质控

- STROBE checklist。
- TRIPOD-AI/PROBAST-AI checklist，如果保留预测模型。
- 环境混合暴露方法描述核对。
- GitHub/OSF 可复现材料。
- 目标期刊格式化。

## 8. 推荐投稿定位

第一梯队（需要机制/验证补强后再冲）：

- Environmental Health Perspectives
- Environment International
- The Lancet Planetary Health

第二梯队（当前基础上更现实）：

- Environmental Health
- Journal of Hazardous Materials
- Science of the Total Environment
- Environmental Research

如果预测模型做得很强，可考虑：

- BMC Medicine / eBioMedicine 的环境健康方向，但需要外部验证和临床解释更强。

## 9. 投稿前必须完成的核查清单

- [ ] 所有脚本路径改为项目相对路径。
- [ ] 删除脚本中自动 `install.packages()`，改用 `renv`。
- [ ] 明确 primary hypothesis，不把所有结果堆成一篇。
- [ ] 重新审计死亡 Cox 模型样本量下降和 cause-specific model failure。
- [ ] qgcomp-like、WQS、BKMR 的方法限制写清楚。
- [ ] 主图重绘，避免标题裁切和网络图过密。
- [ ] GEO/Open TG-GATEs 检索记录可复现。
- [ ] 训练/验证 split 预先固定。
- [ ] 代码、数据来源、变量字典、样本流图和 session 信息齐全。

## 10. 结论

这个项目最有潜力的高水平版本是：

> 以 NHANES 为人群证据，证明 DEHP 氧化代谢谱是胰岛素抵抗和糖脂代谢紊乱的稳健标志；再用 temporal validation、可解释预测模型和公开毒理/转录组数据库做机制三角验证。

下一步不是再无限加模型，而是收敛问题、提高复现性、做外部/时间验证、把机制证据从“数据库罗列”升级为“可训练、可验证的通路签名”。

