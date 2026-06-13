# 下一轮高水平证据链优化方案

生成日期: 2026-06-11

## 总体判断

你对研究水平的担心是对的。最新一轮干实验不是失败，但它把真正的短板暴露得更清楚了:

1. **NHANES暴露层需要回到原始单体代谢物。** 现在的 `ln_Sigma_DEHP`、`pct_oxidative_10`、`ln_oxidative_to_MEHP` 是派生指标，正式qgcomp提示共线/aliasing。高水平期刊会要求MEHP、MEHHP、MEOHP、MECPP等原始单体进入混合物模型。
2. **non-glycemic MSI不能替代主RVI。** 它与主MSI高度相关，但在CGMacros subject-disjoint预测中R2为负，只能作为反循环论证的保守敏感性分析。
3. **食物基质还没有达到发表级。** 规则双预标注kappa只有中等，且FDC DEMO_KEY限流导致最终匹配0/1498。必须做人工双评和正式FDC匹配。
4. **外部验证要重新分层。** Stanford仍是最有价值的外部数据；D1NAMO是T1D胰岛素边界测试且方向不稳，Jaeb没有餐食事件，只能说明CGM波动边界。
5. **机制层必须从数据库重叠升级为方向性证据。** 需要CompTox/ToxCast assay endpoints和GEO差异表达。

## 当前最能支撑的主线

**Raw phthalate/DEHP metabolite mixture -> metabolic susceptibility -> food-matrix-dependent PPGR vulnerability.**

中文表述为:

**邻苯二甲酸酯/DEHP原始代谢物混合暴露与代谢易感性相关，而代谢易感性可能塑造个体面对不同食物基质时的餐后血糖反应脆弱性。**

这条主线比“DEHP直接导致PPGR异常”更窄，但更能防守。

## 本轮结果带来的重新定位

- NHANES仍是强人群锚点: response_vulnerability_index/ln_oxidative_to_MEHP: beta=0.146, p=0.00031, q=0.0039; msi_core_partial/ln_oxidative_to_MEHP: beta=0.173, p=0.0005, q=0.0039; ln_HOMA_IR/ln_oxidative_to_MEHP: beta=0.177, p=0.00055, q=0.0039
- R qgcomp可识别派生组合仍有强信号: response_vulnerability_index/dehp_load_plus_oxidative_ratio: psi=0.152, p=2.4e-09, q=1.1e-08; response_vulnerability_index/dehp_load_plus_oxidative_fraction: psi=0.152, p=2.4e-09, q=1.1e-08; ln_HOMA_IR/dehp_load_plus_oxidative_ratio: psi=0.219, p=2.7e-09, q=1.1e-08
- 但qgcomp共线问题必须处理: 16/32 qgcomp rows failed or were skipped because derived exposure metrics are collinear/aliased.
- non-glycemic MSI用于敏感性，而非主模型: iauc_2h non_glycemic_msi_foodmatrix: R2=-0.271, r=0.222; peak_delta_2h non_glycemic_msi_foodmatrix: R2=-0.302, r=0.245
- 食物快速消化性仍有独立价值: iauc_2h: beta=109.657, p=0.0269, q=0.0462; peak_delta_2h: beta=1.621, p=0.0255, q=0.0437
- 食物/FDC层目前不能过度声称: kappa=0.336, agreement=0.513, manual_review=730; assigned=0/1498, manual_review=1498; DEMO_KEY/API limit caused 429 in latest run.

## 下一步优先级

### Priority 1: 重建NHANES原始单体暴露混合物

这是最值得马上做的干实验。不要再把派生比例当主混合物。应下载各周期PHTHTE原始文件，保留MEHP、MEHHP、MEOHP、MECPP、MEP、MBP、MiBP、MBzP、MCPP等变量、LOD标记、尿肌酐和复杂抽样权重。主模型用survey-weighted qgcomp/gWQS/BKMR，派生指标只作为“DEHP代谢转化/氧化比例”的二级分析。

### Priority 2: Stanford分子层外部验证

Stanford CGMDB有CGM、metadata、lipid、metabolomics、Olink。下一步应构建PPGR response type、mitigator response、炎症/脂质/胰岛素相关分子签名，而不是只做一个R2边界验证。这样才能接近2025年Nature Medicine标准化餐食多组学PPGR研究的证据形态。

### Priority 3: 食物基质从proxy升级到人工审定

当前规则双评只能做预标注。需要两名人工独立评估餐食图像/描述，再由第三方裁决；FDC必须使用正式API key或离线数据库，保留FDC ID、候选项、匹配分、人工确认。否则食物基质创新点会被审稿人打穿。

### Priority 4: GEO/CompTox方向性机制

已有CTD/KEGG/Reactome说明机制“合理”，但还不够。应筛出真正DEHP/MEHP暴露的GEO数据，跑差异表达，再与PPAR、AMPK、PI3K-Akt、insulin signaling、TNF/炎症、oxidative stress、lipid metabolism做方向一致性验证。CompTox/ToxCast则用于补受体/线粒体/氧化应激/内分泌相关assay endpoint。

### Priority 5: 同受试者CGM-exposome pilot

如果目标是最高水平期刊，这一步几乎不可替代。设计为N=60可行性或N=120正式桥接: 重复晨尿DEHP代谢物 + 10-14天CGM + 标准化餐食重复挑战 + mitigator测试 + 基础代谢表型。它能补上当前最大断点: 同一人内的环境暴露、代谢易感性和餐后血糖反应。

## 投稿策略

只靠当前计算结果，适合较强但不是顶级的计算型营养/环境健康论文。若完成原始单体NHANES、人工食物基质、Stanford分子验证和GEO/CompTox机制，才适合冲击AJCN、Clinical Nutrition、Environment International、EHP。若再加同受试者CGM-exposome pilot，才有现实机会向Nature Food、Cell Metabolism或Nature Medicine风格靠近。

## 最重要的取舍

不要继续横向堆更多弱外部数据集。下一步要做的是把最关键的三处证据做实:

1. **真实原始暴露混合物。**
2. **真实人工审定食物基质。**
3. **同受试者或分子层桥接验证。**

这三处补上后，论文才会从“聪明的跨数据库整合”变成“证据链闭合的高水平研究”。
