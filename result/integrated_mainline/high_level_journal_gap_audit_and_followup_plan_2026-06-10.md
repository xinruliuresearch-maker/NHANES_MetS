# 投稿高水平期刊前的证据审计与后续研究方案

日期：2026-06-10  
适用项目：CGMacros + NHANES MetS/DEHP + 外部 CGM 数据 + 陈晓东教授体外消化仿生系统

## 0. 结论先行

当前研究已经从“多个分散项目”收束为一条较有潜力的多尺度证据链：

> DEHP oxidative profile -> MSI-core metabolic susceptibility -> PPGR vulnerability -> digestion-informed meal redesign

更适合写成中文主线：

> 环境塑化剂暴露相关的代谢易感性，可能标记或参与形成更高的餐后血糖脆弱性；基于消化释放动力学的餐食重构，有机会降低这种脆弱性。

但是，以目前 Stage 1-5 的完成度，还不能直接冲击极高水平期刊。现有工作已经足够形成一个清晰的高水平研究骨架，但仍属于“探索性整合 + 初步证据”。投稿前必须补强四类证据：

1. **NHANES 端必须升级为正式复杂抽样分析**：当前 Stage 2 是 Python 加权近似，方向有力，但投稿前必须用 R `survey` 或等价复杂抽样框架复核。
2. **CGMacros 端必须升级为严格重复测量/混合模型证据**：现有结果支持 MSI 与 PPGR 强相关，但 `carbs x MSI` 交互尚未显著，不能把“放大碳水效应”作为过度确定的主结论。
3. **预测模型必须符合 TRIPOD+AI/PROBAST+AI 思路**：当前 Stage 4 是透明 ridge benchmark，适合探索，不足以作为最终预测模型论文证据。
4. **体外消化必须从方案变为实测机制证据**：Stage 5 目前只是候选餐食和实验矩阵；如果要冲击 Nature Food、Cell Metabolism、Nature Metabolism 等层级，必须有真实 glucose release kinetics 数据。

最稳妥的高水平主张应从“DEHP 直接导致 PPGR 异常”调整为：

> NHANES 中 DEHP oxidative profile 与 insulin-resistant metabolic susceptibility 相关；CGMacros 中同一代谢易感性表型表现为更高 PPGR vulnerability；仿生消化实验进一步验证高风险餐食的快速葡萄糖释放及可干预性。

这条表述既有科学吸引力，也能避免两个数据集没有同一受试者 DEHP+CGM 的硬伤。

## 1. 当前已有研究内容审计

### 1.1 Stage 1：MSI-core 桥梁变量已经成立

已完成内容：

- 构建了不包含 DEHP 暴露变量的 `MSI-core`。
- 使用共同临床代谢组件：BMI、HbA1c、fasting glucose、ln(HOMA-IR)、ln(TG/HDL-C)。
- 使用 NHANES 2013-2018 作为外部参考标准化。
- 生成 CGMacros subject-level、CGMacros meal-level、NHANES subject-level 三套可连接数据。

当前证据：

| 数据集 | 总样本 | partial MSI 非缺失 | complete MSI 非缺失 | partial MSI 中位数 |
|---|---:|---:|---:|---:|
| NHANES 2013-2018 | 5267 | 2491 | 2368 | -0.101 |
| CGMacros subjects | 40 | 40 | 40 | 0.325 |

判断：

- 这是两个项目整合的关键创新点，方向正确。
- MSI 不包含 DEHP，避免循环论证。
- 后续需要补做 MSI 敏感性版本：PCA-MSI、rank-normalized MSI、complete-case MSI、去除 BMI 的 MSI、仅 insulin-resistance/lipid-glycemic MSI。

### 1.2 Stage 2：NHANES 端有较强上游人群证据，但还不是最终版

已完成内容：

- 使用 NHANES 2013-2018 检验 DEHP oxidative profile 与 MSI-core、HOMA-IR、HbA1c、TyG、TG/HDL-C 的关系。
- 当前模型为 Python 加权最小二乘 + cluster-robust 近似。
- 协变量包括年龄、性别、种族/族裔、教育、PIR、能量摄入、吸烟、饮酒、体力活动、尿肌酐、cycle。

关键结果：

| 暴露 -> 结局 | 效应 |
|---|---:|
| %Oxidative per 10 pp -> MSI-core | 0.168 (0.065, 0.272), q=0.006 |
| ln(Oxidative/MEHP) -> MSI-core | 0.183 (0.106, 0.259), q<0.001 |
| ln(Sigma DEHP) -> MSI-core | 0.066 (-0.004, 0.135), q=0.080 |
| %Oxidative per 10 pp -> ln(HOMA-IR) | 19.958% (6.896, 34.617), q=0.006 |
| %Oxidative per 10 pp -> HbA1c | 0.110 (0.031, 0.188), q=0.012 |
| %Oxidative per 10 pp -> TyG | 0.108 (0.001, 0.216), q=0.067 |

判断：

- 方向非常有价值：oxidative DEHP profile 比 total DEHP burden 更稳定地关联代谢易感性。
- 这可以作为主文 Figure 2 的核心。
- 但目前不能作为最终投稿统计版本，因为 NHANES 必须尊重复杂抽样设计、权重、PSU、strata、subsample weights 和跨周期权重构造。

投稿前必须补强：

- 用 R `survey` 复核所有主模型。
- 明确使用 phthalate subsample 权重，并正确构造 2013-2018 多周期权重。
- 做 LOD 替代、尿肌酐处理、糖尿病/药物使用、BMI 是否调整、能量摄入、饮食来源变量等敏感性分析。
- 生成正式样本流程图、加权 Table 1、主模型森林图、dose-response 图。

### 1.3 Stage 3：CGMacros 端支持 MSI 与 PPGR vulnerability，但交互证据仍弱

已完成内容：

- 餐食级样本 1498 餐，40 名受试者。
- 检验 MSI-core、carbs_10g、`carbs_10g x MSI-core` 与 2h iAUC、2h peak delta、high-response risk 的关系。

当前分层结果：

| MSI tertile | subjects | meals | median iAUC 2h | high iAUC rate | median peak delta |
|---|---:|---:|---:|---:|---:|
| low | 14 | 570 | 1792.6 | 0.184 | 34.3 |
| high | 13 | 447 | 2515.0 | 0.315 | 49.8 |

关键模型结果：

| 结局 | 变量 | 估计值 |
|---|---|---:|
| 2h iAUC | carbs_10g | 0.236 (0.181, 0.292), q<0.001 |
| 2h iAUC | MSI-core | 1.170 (0.597, 1.742), q<0.001 |
| 2h iAUC | carbs x MSI | 0.041 (-0.012, 0.094), q=0.163 |
| 2h peak delta | carbs_10g | 3.343 (2.524, 4.163), q<0.001 |
| 2h peak delta | MSI-core | 18.883 (10.551, 27.214), q<0.001 |
| 2h peak delta | carbs x MSI | 0.516 (-0.246, 1.277), q=0.229 |

判断：

- MSI 对 PPGR 的独立关联强，是主线中最重要的 CGMacros 证据。
- 高 MSI 组 high-response rate 更高，适合做直观图。
- 交互项方向为正但未显著，因此主文不能把“MSI 显著放大碳水效应”写成强结论。
- 更稳妥的主结论应是：“MSI is a strong susceptibility stratifier for PPGR vulnerability; evidence for effect modification by carbohydrate load is directionally consistent but requires larger validation.”

投稿前必须补强：

- 使用 subject random intercept 的 mixed-effects 模型，或 GEE/cluster bootstrap。
- 加入更合理 meal load：available carbohydrate、carb/fiber ratio、carb/protein ratio、glycemic-load proxy、energy density。
- 做 subject-level bootstrap，避免餐食数多但受试者少造成精度虚高。
- 人工复核极端餐食与图片，尤其是重复出现的 66 g carb、0 fiber、高 PPGR 餐食。

### 1.4 Stage 4：MSI-aware prediction 有探索价值，但仍不是最终预测模型证据

已完成内容：

- 用纯 numpy ridge regression 做 leave-subject-out 验证。
- 比较 M2（macro + timing + pre-CGM/activity）与 M3（加入 MSI/HOMA/TG-HDL）。
- 做 0/1/3/5/10-shot subject-specific recalibration。

关键结果：

| 分层 | shots | M2 MAE | M3 MAE | 改善 |
|---|---:|---:|---:|---:|
| Low MSI, iAUC | 0 | 2102.2 | 1797.5 | -14.5% |
| High MSI, iAUC | 0 | 2546.9 | 2459.9 | -3.4% |
| High MSI, iAUC | 10 | 2186.4 | 2047.3 | -6.4% |

判断：

- MSI 能改善部分分层预测，尤其低 MSI 0-shot 结果明显。
- 高 MSI 仍是最难预测的人群，这本身是有价值的发现。
- 当前模型过于简化，不能代表最终 AI/ML 模型性能。

投稿前必须补强：

- 将 MSI 纳入既有正式 CGMacros 模型训练脚本，而不是单独用 ridge benchmark。
- 使用 nested leave-subject-out 或留出受试者验证，所有超参数调优在内层完成。
- 报告 MAE/RMSE、calibration slope/intercept、high-response AUC/AUPRC、decision curve、conformal interval coverage。
- 按 TRIPOD+AI 报告模型开发、验证、预测变量定义、缺失处理、调参、过拟合控制和代码可得性。
- 用 PROBAST+AI 思路自查 risk of bias：participants/data source、predictors、outcome、analysis 四个域。

### 1.5 Stage 5：仿生消化是冲击高水平期刊的关键，但目前只是实验设计

已完成内容：

- 从 CGMacros 中筛选 12 个候选真实餐。
- 每餐设计 original 和 redesigned 两个版本。
- 计划每组 3 个技术重复，共约 72 个技术单元。
- 主要终点为 glucose release iAUC 0-60 min、Cmax、early slope。

判断：

- 这是整篇论文从“观察性 + 预测模型”升级为“机制可验证 + 可干预”的关键。
- 目前还没有真实实验数据，因此不能把它作为已完成证据。
- 如果没有 Stage 5 实验结果，论文更适合投环境流行病学/营养预测模型方向；如果 Stage 5 结果漂亮，才有机会冲击 Nature Food / Cell Metabolism / Nature Metabolism 等更高层级。

投稿前必须补强：

- 先做 3-4 个餐食的 pilot，检查消化系统稳定性和 glucose assay 动态范围。
- 再扩展到 10-12 个候选餐食。
- 所有餐食必须图片复核、配方复原、重量记录、加工方式记录。
- 统计上使用 paired original-vs-redesigned comparison，并报告 batch、replicate、bootstrap CI。
- 若做塑化剂/食品接触材料检测，必须使用玻璃器皿、field blank、procedural blank、recovery 和 LC-MS QC；否则不要把 phthalate contamination 扩展为新主线。

## 2. 高水平期刊投稿前的核心缺口

### 缺口 1：主线需要严格避免“跨数据集因果跳跃”

当前两个核心数据集不能同一个体合并：

- NHANES 有 DEHP 和代谢指标，但没有真实餐食级 CGM PPGR。
- CGMacros 有真实餐食级 CGM PPGR，但没有 DEHP 暴露。

因此不能写：

> DEHP exposure causes higher PPGR in CGMacros participants.

应写：

> DEHP oxidative profile is associated with a metabolic susceptibility phenotype in NHANES; the same susceptibility phenotype is expressed as higher PPGR vulnerability in CGMacros.

这一区分非常重要。高水平期刊审稿人会敏感地追问：DEHP 与 PPGR 是否在同一受试者中测量？如果没有，必须把 MSI-core 作为桥梁表型，而不是把 DEHP 直接带入 CGMacros 结论。

### 缺口 2：NHANES 端必须从探索性近似变成规范复杂抽样结果

必须完成：

- `svydesign(ids=~SDMVPSU, strata=~SDMVSTRA, weights=~combined_phthalate_weight, nest=TRUE)`
- 正确构造 2013-2018 三个周期权重。
- 对 fasting subsample、phthalate urinary subsample、dietary variables 明确选择权重。
- 使用 subpopulation 分析而不是简单删样本造成权重/方差偏差。
- 生成可复现 R 脚本、session info、Table 1、主模型表和敏感性表。

建议敏感性分析：

| 类型 | 具体分析 | 目的 |
|---|---|---|
| 暴露处理 | total DEHP、%oxidative、oxidative/MEHP、molar sum | 判断 oxidative profile 是否优于总负荷 |
| 尿稀释 | covariate-adjusted creatinine、creatinine-standardized、比重如可得 | 避免尿液稀释处理驱动结果 |
| LOD | LOD/sqrt(2)、multiple imputation、排除高 LOD 变量 | 暴露测量稳健性 |
| 协变量 | 不调 BMI / 调 BMI / 腰围替代 | 区分 confounder 与中介/表型组件 |
| 人群 | 排除糖尿病、排除降糖药、按性别/年龄/肥胖分层 | 检验异质性 |
| 饮食来源 | 加工食品、外食、包装食品 proxy | 为 Stage 5 餐食机制提供背景 |

### 缺口 3：CGMacros 的样本量和重复测量结构必须被诚实处理

CGMacros 有很多餐食，但只有 40 名受试者。高水平期刊会关注：

- 受试者数是否足够支撑 subject-level susceptibility inference？
- 餐食级样本是否伪重复？
- 模型是否被少数高反应者或异常餐食驱动？
- 餐食记录和营养成分是否可靠？

必须完成：

- subject random intercept mixed models。
- subject-cluster bootstrap 或 leave-one-subject-out sensitivity。
- 每个受试者最多贡献餐食数的影响检查。
- 主要图展示 subject-level summaries，而不只展示 meal-level p 值。
- 重新定义 high-response：subject-specific top quartile、absolute threshold、population top quartile 三种版本。

### 缺口 4：预测模型需要从“性能比较”升级为“临床/营养决策价值”

高水平期刊不关心单纯模型排行榜，更关心：

- MSI 是否帮助识别高风险餐食？
- MSI 是否改善高风险人群校准？
- 少量个体化样本是否明显降低高 MSI 个体误差？
- 模型建议的餐食替换是否能被体外消化验证？

建议最终模型层级：

| 模型 | 内容 | 用途 |
|---|---|---|
| M0 | carbohydrate-only | baseline |
| M1 | macros + timing | nutrition baseline |
| M2 | M1 + pre-CGM/activity | dynamic context |
| M3 | M2 + MSI-core | susceptibility-aware model |
| M4 | M3 + few-shot recalibration | personalization |
| M5 | M4 + digestion-informed features | mechanism-informed model |

主文不需要展示所有模型细节。主文只回答：

1. 加入 MSI 是否改善 high-response detection？
2. 高 MSI 组是否校准更差、个体化收益更大？
3. 加入消化释放特征后，能否解释同碳水餐食之间的 PPGR 差异？

### 缺口 5：外部数据库必须服务主线，而不是变成数据库堆砌

已经下载/整理的外部数据非常有价值，但主文中不能全部并列展开。推荐策略：

- 主文最多放 1 个外部验证图。
- 其余外部数据放补充材料或后续论文。
- 外部数据只回答边界问题：在健康、T1D/T2D、标准化食物挑战中，PPGR vulnerability 框架是否仍有解释力？

优先级：

1. **T1D-UOM**：宏量营养、CGM、胰岛素、活动/睡眠较丰富，适合 disease-state boundary。
2. **Stanford CGMDB**：标准化食物挑战，适合说明相同食物的个体差异和机制背景。
3. **Jaeb healthy adults / CGMND**：适合给健康成人 CGM 波动范围参考。
4. **ShanghaiT1DM/T2DM**：适合作为中国糖尿病 CGM phenotype 边界参考。
5. **D1NAMO**：更适合做图像/餐食描述 case study，不建议成为主文核心。

### 缺口 6：体外消化必须产生“方向一致”的机制证据

Stage 5 的成败将决定论文上限。

至少需要证明：

1. 模型识别的高风险原餐具有更高 early glucose release。
2. redesigned 餐食能降低 release iAUC 0-60 min、Cmax 或 early slope。
3. 体外释放动力学与 CGMacros 中同类餐食的 PPGR 方向一致。
4. release features 能解释同碳水餐食之间的 PPGR 差异。

最低可接受实验结果：

- 10-12 个餐食原型中，至少 8 个 original -> redesigned 方向一致降低 early release。
- paired mean reduction 具有 bootstrap CI 支持。
- glucose release curve 图形清晰，并能与模型推荐策略对应。

理想结果：

- 高 MSI 高 PPGR 餐食的 original 版本释放曲线明显更陡。
- 增加纤维/抗性淀粉/完整谷物结构后 early release 明显下降。
- digestion-informed feature 加入 M5 后，能改善高风险餐食识别或解释模型误差。

## 3. 后续研究路线图

### Phase 0：冻结主线与统计分析计划

时间：3-5 天  
目标：避免后续分析继续发散。

任务：

- 写一版 internal statistical analysis plan。
- 固定主假设、次假设和探索性分析。
- 明确哪些内容进主文，哪些进补充材料，哪些另写论文。
- 建立“不能过度声称”的句子库。

主假设：

1. NHANES 中 DEHP oxidative profile 与 MSI-core 及 insulin-resistance phenotype 正相关。
2. CGMacros 中 MSI-core 与更高 PPGR vulnerability 正相关。
3. MSI-aware 模型能改善高风险餐食识别、校准或少样本个体化。
4. Digestion-informed redesign 能降低高风险餐食的 early glucose release。

不作为主假设：

- DEHP 直接导致 CGMacros 受试者 PPGR 升高。
- 所有外部 CGM 数据都能验证同一模型。
- 体外消化可以完全替代人体 PPGR。

交付物：

- `outputs/integrated_mainline/statistical_analysis_plan_v1.md`
- `outputs/integrated_mainline/main_claims_and_no_overclaim_rules.md`

### Phase 1：数据质量与 MSI 稳健性

时间：1-2 周  
目标：保证桥梁变量和餐食数据不会被审稿人一击击穿。

任务：

- 复核 CGMacros 实验室变量单位，尤其 fasting glucose、insulin、TG、HDL。
- 人工检查 Stage 5 候选餐食图片和宏量营养，剔除明显录入错误或无法复原的餐食。
- 生成 MSI 的多个敏感版本：NHANES z-score、rank-normalized、PCA、complete-case、without BMI。
- 检验 MSI 与单独 HOMA-IR、HbA1c、TG/HDL-C 的一致性。

关键输出：

- MSI sensitivity table。
- candidate meal QC sheet。
- outlier decision log。

成功标准：

- 主结果不依赖某一个 MSI 构造方式。
- 候选餐食可以被真实复原，并且图片/营养成分一致。

### Phase 2：NHANES 正式复杂抽样分析

时间：2-3 周  
目标：把 Stage 2 从“方向性探索”升级为“投稿主结果”。

任务：

- 在 NHANES 项目中写正式 R `survey` 脚本。
- 构造 2013-2018 phthalate subsample combined weights。
- 输出 weighted Table 1。
- 主模型：`MSI-core ~ DEHP oxidative profile + covariates + survey design`。
- 次模型：HOMA-IR、HbA1c、TyG、TG/HDL-C。
- 做剂量反应、分层、敏感性分析。

关键输出：

- Figure 2：DEHP oxidative profile 与代谢易感性森林图/剂量反应图。
- Supplementary Table：全部暴露-结局组合和敏感性分析。
- 可复现 R session info。

成功标准：

- `%Oxidative` 或 `ln(Oxidative/MEHP)` 对 MSI-core/HOMA-IR 的方向和显著性基本保留。
- 即使部分结局变弱，整体方向保持一致。

### Phase 3：CGMacros 严格推断分析

时间：2-3 周  
目标：把 Stage 3 变成能经受审稿的重复测量分析。

任务：

- mixed-effects model：subject random intercept，必要时 random slope。
- GEE 或 cluster bootstrap 作为稳健性。
- meal load 扩展为 carb、available carb、carb/fiber、carb/protein、energy density。
- high-response 采用 population top quartile、subject-specific top quartile、absolute peak threshold 三种定义。
- 做 leave-one-subject-out influence analysis。

主文重点：

- MSI high vs low 的 PPGR distribution。
- MSI 对 iAUC/peak/high-response 的独立关联。
- `meal load x MSI` 作为 effect modification，若不显著则诚实报告为 directional evidence。

成功标准：

- MSI 主效应在多数模型中稳定。
- 高 MSI 组 high-response risk 明显更高。
- 交互如果仍不显著，主文将主张降级为“susceptibility stratification”，不强行主张 effect modification。

### Phase 4：预测模型与个体化决策价值

时间：3-4 周  
目标：把 Stage 4 从 benchmark 升级为可投稿预测模型证据。

任务：

- 将 MSI 纳入正式 CGMacros 模型训练管线。
- 使用 nested leave-subject-out / time-aware validation。
- 对 high-response classification 报告 AUC、AUPRC、sensitivity、specificity、PPV、NPV。
- 对连续 PPGR 报告 MAE、RMSE、calibration slope/intercept、coverage。
- 做 few-shot recalibration：0/1/3/5/10 餐。
- 做 decision curve 或 net benefit：识别高风险餐食是否有实际营养决策价值。

主文重点：

- MSI 是否帮助识别高风险餐食。
- 高 MSI 组是否更难预测。
- 少量个体化数据是否更能改善高 MSI 组。

成功标准：

- M3/M4 在 high-response detection 或 calibration 上有明确收益。
- 如果 MAE 改善有限，也要展示 MSI 的风险分层价值，而不是强推性能提升。

### Phase 5：外部验证与边界分析

时间：3-5 周  
目标：增加外部可信度，但不让主文发散。

任务：

- 优先选择一个外部 CGM 数据集进入主文，建议 T1D-UOM 或 Stanford CGMDB。
- 建立最小 harmonization：meal time、CGM window、iAUC/peak、macro features。
- 不强求 MSI，因为外部数据未必有完整实验室指标；可以验证 meal-load/PPGR heterogeneity 和模型边界。
- 其余数据放补充材料，作为 phenotype landscape。

成功标准：

- 至少有一个外部数据集支持“餐食响应具有强个体差异/疾病状态边界”。
- 不把 T1D/T2D 外部数据错误解释为健康人 CGMacros 的直接重复验证。

### Phase 6：陈晓东教授体外消化仿生系统实验

时间：pilot 2-3 周；完整实验 6-10 周  
目标：把论文从观察性整合升级为机制与干预验证。

实验流程：

1. 从 Stage 5 候选餐食中人工确认 10-12 个可复原餐食。
2. 每个餐食构建 original 与 redesigned。
3. 每组 3 个技术重复。
4. 动态采样：gastric 0/15/30/60 min；intestinal 75/90/120/180 min。
5. 测定 glucose release，并尽量记录 viscosity、particle size、resistant starch 或 gelatinization/retrogradation proxy。

统计：

- paired original-vs-redesigned difference。
- bootstrap CI。
- batch-adjusted sensitivity。
- release feature 与 CGMacros predicted PPGR / observed PPGR 的方向一致性。

成功标准：

- redesigned 餐食在多数原型中降低 early release。
- 释放曲线能解释模型推荐逻辑。
- 结果可以形成主文 Figure 5。

### Phase 7：论文组装、规范清单与数据代码准备

时间：2-3 周  
目标：达到高水平期刊投稿的可审稿状态。

任务：

- 形成 5 张主图、3-5 张扩展数据图、完整补充表。
- 写 Data Availability、Code Availability、Protocol Availability。
- 准备 STROBE/STROBE-ME、STROBE-nut、TRIPOD+AI、PROBAST+AI 自查表。
- 冻结分析代码和环境：R session info、Python requirements、随机种子、数据字典。
- 所有派生数据表加 manifest、hash 和来源说明。

## 4. 主文结构建议

### 推荐标题

Environmental metabolic susceptibility and digestion-informed postprandial glycemic vulnerability: integrating NHANES, CGM nutrition cohorts, and bionic digestion

中文工作标题：

环境代谢易感性与消化机制约束的餐后血糖脆弱性：整合 NHANES、连续血糖营养队列与仿生消化的多尺度研究

### 摘要逻辑

Background：

餐后血糖反应不仅由餐食碳水决定，还受个体 insulin resistance、glycemic-lipid metabolic state、慢性环境暴露相关代谢易感性和食物消化释放动力学共同影响。

Methods：

在 NHANES 中评估 DEHP oxidative profile 与 MSI-core/insulin-resistance phenotype 的关系；在 CGMacros 中评估 MSI-core 与餐食级 PPGR vulnerability 的关系；在预测模型中检验 MSI 对高风险餐食识别和少样本个体化的价值；在仿生消化系统中验证模型识别餐食及 redesigned 餐食的 glucose release kinetics。

Results：

按照证据链报告，而不是按照数据集堆砌报告：

1. DEHP oxidative profile 与 MSI-core/HOMA-IR/HbA1c 相关。
2. MSI-core 与更高 iAUC、peak delta、high-response risk 相关。
3. MSI-aware model 改善高风险餐食识别或校准，并显示高 MSI 人群更需要个体化。
4. Redesigned meals 降低 early glucose release。

Conclusion：

代谢易感性可能是连接环境暴露、餐食结构和餐后动态血糖异质性的桥梁；消化释放动力学提供了可验证、可干预的精准营养路径。

## 5. 主图设计

| 图 | 内容 | 投稿前状态 |
|---|---|---|
| Figure 1 | 整体机制图：DEHP oxidative profile -> MSI -> PPGR vulnerability -> digestion-informed redesign | 可立即绘制 |
| Figure 2 | NHANES 复杂抽样正式结果：森林图 + dose-response | 需要 Phase 2 |
| Figure 3 | CGMacros：MSI 分层 PPGR、high-response risk、meal-load interaction | 需要 Phase 3 |
| Figure 4 | Prediction/personalization：M2/M3/M4 校准、高风险识别、few-shot benefit | 需要 Phase 4 |
| Figure 5 | Bionic digestion：original vs redesigned glucose release curves | 需要 Phase 6 |

补充材料：

- MSI 构造和敏感性分析。
- NHANES LOD/creatinine/subgroup/negative control。
- CGMacros subject influence and bootstrap。
- 外部 CGM 边界分析。
- 完整实验协议和 QC。

## 6. 目标期刊与最低证据门槛

### Nature Food / Cell Metabolism / Nature Metabolism 级别

必须具备：

- NHANES 复杂抽样结果稳定。
- CGMacros 中 MSI 与 PPGR vulnerability 稳定，最好有明确 interaction 或高风险识别价值。
- 至少一个外部数据集支持边界/泛化。
- 仿生消化实验证明 original vs redesigned 释放动力学差异。
- 数据、代码、协议和报告清单完整。

风险：

- 40 名 CGMacros 受试者可能仍被认为样本量偏小。
- 没有同一受试者 DEHP+CGM 会限制因果力度。

### Nature Food / npj Science of Food / AJCN / Diabetes Care / Environment International 之间的现实路线

如果 Stage 5 实验结果强，优先投：

- Nature Food
- Cell Metabolism / Nature Metabolism 的机会取决于机制深度和外部验证强度
- AJCN
- Diabetes Care

如果 Stage 5 不做或结果较弱，优先转向：

- Environment International
- Environmental Health Perspectives
- American Journal of Clinical Nutrition
- npj Science of Food
- Clinical Nutrition

### 如果结果不理想，建议拆成两篇

论文 1：

> DEHP oxidative profile and metabolic susceptibility in NHANES

定位：环境流行病学，主投 Environment International / EHP。

论文 2：

> MSI-aware PPGR vulnerability and digestion-informed meal redesign

定位：精准营养/CGM/食品机制，主投 AJCN / npj Science of Food / Clinical Nutrition。

## 7. Go / No-Go 决策标准

可以继续合并为一篇高水平整合论文的条件：

1. R `survey` 复核后，NHANES `%Oxidative` 或 `ln(Oxidative/MEHP)` 与 MSI/HOMA-IR 的关联保留。
2. CGMacros 混合模型中 MSI 主效应稳定。
3. Prediction 阶段至少在 high-response detection、calibration 或 high-MSI personalization 上有一个明确收益。
4. 至少一个外部 CGM 数据集提供边界支持。
5. 体外消化 original vs redesigned 的 early glucose release 多数方向一致下降。

需要降级或拆分的情况：

- NHANES 正式复杂抽样后主关联消失。
- CGMacros MSI 效应主要由少数受试者驱动。
- Prediction 模型加入 MSI 后没有任何校准、分类或个体化收益。
- 体外消化实验不支持模型推荐方向。

即使降级，也不是失败。它会变成两篇更稳的论文，而不是一篇主张过大的论文。

## 8. 下一步最优先的 12 个任务

1. 在 NHANES 项目中建立正式 R `survey` 分析脚本。
2. 构造 2013-2018 phthalate subsample combined weights。
3. 复现 Stage 2 主结果并输出正式 Table 1/forest plot。
4. 对 MSI 做 PCA/rank/complete-case/without-BMI 敏感性。
5. 对 CGMacros 跑 mixed-effects/GEE/subject bootstrap。
6. 人工复核 Stage 5 候选餐食图片、营养成分和可复原性。
7. 把 MSI 合并进正式 CGMacros 模型训练流程。
8. 完成 high-response classification 和 calibration 分析。
9. 选择一个外部 CGM 数据集做主文边界验证。
10. 完成 3-4 个仿生消化 pilot 餐食。
11. 根据 pilot 优化完整 10-12 餐食实验矩阵。
12. 建立 Nature-style Data/Code/Protocol Availability 文件夹和 manifest。

## 9. 规范与来源链接

本方案参考并对齐以下报告与期刊规范：

- TRIPOD+AI：预测模型报告规范，适用于 regression 和 machine learning 预测模型研究。链接：[BMJ TRIPOD+AI](https://www.bmj.com/content/385/bmj-2023-078378)，[EQUATOR TRIPOD+AI](https://www.equator-network.org/reporting-guidelines/tripod-statement/)
- PROBAST+AI：预测模型质量、偏倚风险和适用性评估。链接：[BMJ PROBAST+AI](https://www.bmj.com/content/388/bmj-2024-082505)
- STROBE：观察性研究报告规范。链接：[STROBE Statement](https://www.strobe-statement.org/)，[EQUATOR STROBE](https://www.equator-network.org/reporting-guidelines/strobe/)
- STROBE-ME：分子/生物标志物暴露相关观察性研究报告扩展。链接：[EQUATOR STROBE-ME](https://www.equator-network.org/reporting-guidelines/strobe-me/)
- STROBE-nut：营养流行病学与饮食评估报告扩展。链接：[EQUATOR STROBE-nut](https://www.equator-network.org/reporting-guidelines/strobe-nut/)
- NHANES 分析指南、权重和复杂抽样教程。链接：[NHANES Analytic Guidelines](https://wwwn.cdc.gov/nchs/nhanes/analyticguidelines.aspx)，[NHANES Weighting Tutorial](https://wwwn.cdc.gov/nchs/nhanes/tutorials/weighting.aspx)
- Nature Portfolio 数据、代码、材料和协议可得性要求。链接：[Nature Portfolio Reporting Standards](https://www.nature.com/nature-portfolio/editorial-policies/reporting-standards)，[Nature Food Reporting Standards](https://www.nature.com/natfood/editorial-policies/reporting-standards)

## 10. 最终判断

目前最有前景的论文不是“DEHP 项目 + CGM 项目 + 消化实验”的简单拼接，而是一条可被审稿人理解的多尺度路径：

> population exposure signal -> metabolic susceptibility phenotype -> dynamic postprandial vulnerability -> mechanism-informed meal redesign

这条路径的优势是新颖、跨尺度、有干预出口；短板是跨数据集桥接、CGMacros 受试者数、预测模型规范性和体外机制数据尚未完成。

因此，下一阶段的核心策略是：少做分散探索，多做投稿级补强。只要 NHANES 正式分析、CGMacros 稳健推断、预测模型规范验证和仿生消化实测结果能够形成方向一致的证据链，这个研究就有机会从“有意思的整合项目”提升为真正具备高水平期刊竞争力的论文。
