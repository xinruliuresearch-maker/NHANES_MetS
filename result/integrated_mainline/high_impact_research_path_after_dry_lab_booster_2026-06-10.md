# 干实验补强后高水平期刊研究路径判断

日期：2026-06-10

项目：CGMacros + NHANES DEHP/MSI + 外部 CGM + 食品结构/仿生消化

## 1. 当前结果的总体判断

当前研究已经从“分散的多个分析”推进为一条相对完整的跨尺度证据链：

> DEHP oxidative profile -> metabolic susceptibility phenotype -> PPGR vulnerability -> digestion-informed meal redesign

这条主线现在有 4 层证据：

1. NHANES 人群级上游证据：DEHP oxidative profile 与 MSI/HOMA-IR/HbA1c 稳定相关。
2. CGMacros 个体级动态证据：MSI 与餐后 iAUC、peak、曲线表型和高风险餐食响应稳定相关。
3. 预测与决策证据：MSI-enhanced 模型改善 high-response detection，反事实餐食重构显示限制 available carbohydrates、增加纤维、碳水替换蛋白具有潜在收益。
4. 机制支持证据：food matrix/digestibility-risk、机制知识图谱和外部 CGM 数据支持该主线，但仍属于支持层，不是决定性机制证据。

因此，当前项目已经具备冲击较高水平营养/代谢/食品科学期刊的基础；但若目标是极高水平综合型或旗舰级期刊，决定性短板仍是：

> 还缺少真实实验验证证明“模型识别的高风险餐食，经消化动力学重构后确实降低早期葡萄糖释放”。

## 2. 当前最强结果

### 2.1 NHANES 上游暴露-代谢易感性证据

R survey 与 Python weighted cluster-robust 结果方向一致。干实验补强后，关键结果为：

- ln(Oxidative/MEHP) -> MSI-core：0.183，95% CI 0.106 到 0.259，q=7.54e-06。
- ln(Oxidative/MEHP) -> ln(HOMA-IR)：0.218，95% CI 0.128 到 0.309，q=6.57e-06。
- ln(Oxidative/MEHP) -> HbA1c：0.135，95% CI 0.077 到 0.193，q=1.30e-05。

这部分已经可以支撑主文 Figure 2。需要注意的是，NHANES 是横断面，不能表述为 DEHP 导致 PPGR 升高，只能写作：

> DEHP oxidative metabolic profile is associated with a metabolic susceptibility phenotype.

### 2.2 CGMacros MSI -> PPGR vulnerability 证据

现有 Phase 3 和 Module C/D 结果显示，MSI 不只是静态临床指标，而是能映射到动态餐后血糖脆弱性。

Module C 新增结果尤其重要：

- MSI predicts 2h iAUC/1000：beta=1.288，95% CI 0.654 到 1.923，q=0.000214。
- digestibility-risk predicts 2h iAUC/1000：beta=0.388，95% CI 0.239 到 0.537，q=2.88e-06。
- MSI x digestibility-risk predicts 2h iAUC/1000：beta=0.410，95% CI 0.216 到 0.605，q=0.000118。
- MSI predicts 2h peak：beta=20.290，95% CI 11.919 到 28.662，q=1.16e-05。
- MSI x digestibility-risk predicts 2h peak：beta=4.988，95% CI 2.664 到 7.313，q=0.000104。

这是目前整篇研究最有潜力的新增亮点。它把原来较弱的 `carbs x MSI` 叙事，升级成更合理的：

> high metabolic susceptibility individuals are more vulnerable to high-digestibility-risk meal matrices.

### 2.3 CGM 动态曲线表型

Module D 将 iAUC/peak 扩展为曲线表型。最高风险 cluster 为：

- `large_prolonged_response`
- n=215 meals
- mean iAUC=8963.3
- mean peak=129.8
- mean MSI=0.601

这说明高 MSI 不只是让血糖峰值更高，也可能对应更持久的餐后暴露。这个结果适合放在 Figure 3 或 Extended Data。

### 2.4 预测与个体化

M3 MSI-enhanced 模型表现：

- iAUC：MAE=2011.3，AUC_high_response=0.762，calibration slope=0.931。
- peak：MAE=27.1，AUC_high_response=0.787，calibration slope=0.963。

与 M2 相比，MSI-enhanced 模型改善 MAE、high-response AUC 和 calibration。该部分可以支撑 Figure 4，但不应把论文写成单纯 prediction model paper。它更适合作为：

> susceptibility-aware personalization layer.

### 2.5 餐食重构

反事实结果显示：

- Cap carbs at 45 g：平均 iAUC delta=-557.5；高风险餐食 delta=-1513.4。
- Carb -20% to protein：平均 iAUC delta=-285.6；高风险餐食 delta=-678.0。
- Fiber +5 g：平均 iAUC delta=-213.6；高风险餐食 delta=-513.5。

这些结果应作为仿生消化实验的设计依据，而不是作为最终干预结论。

## 3. 当前最大短板

### 3.1 跨数据集证据链存在因果断点

NHANES 有 DEHP 和 MSI，但没有 CGM。CGMacros 有 MSI 和 CGM，但没有 DEHP。审稿人会质疑：

> DEHP 与 PPGR 的连接是否只是两个数据集之间的概念拼接？

应对策略：

- 主文避免写 DEHP directly predicts PPGR。
- 将 MSI 明确定义为 bridge phenotype。
- 用 NHANES 证明 DEHP oxidative profile 与 MSI 相关。
- 用 CGMacros 证明 MSI 表现为 PPGR vulnerability。
- 用仿生消化证明 vulnerability 可通过 meal matrix/redesign 被机制性干预。

### 3.2 Food matrix 目前仍是 proxy annotation

Module C 的 digestibility-risk score 很有价值，但目前主要来自宏量营养和规则代理，尚未完成：

- 人工图片标注；
- USDA FoodData Central 校正；
- Sydney GI/GL 校正；
- Open Food Facts/NOVA 加工属性校正；
- 真实配方复原。

如果直接把 proxy 当作真实食品结构结论，会被审稿人抓住。下一步必须把它升级为 expert-coded food matrix annotation。

### 3.3 仿生消化还没有真实实验数据

当前最大空白。没有仿生消化结果时，这篇文章比较像：

> 多数据集观察性整合 + 预测模型 + 机制推测。

有仿生消化结果后，论文才会变成：

> population exposure signal + dynamic human phenotype + prediction-guided meal redesign + mechanistic digestion validation.

这就是能否冲击高水平期刊的分界线。

### 3.4 NHANES 高级分析需要 R survey 最终复核

主模型已有 R survey 复核，但 Module B 新增的 RCS、分层、混合/组成代理目前是 Python weighted cluster-robust 版本。投稿前应把关键 RCS 和分层图迁移到 R `survey`/`splines`。

## 4. 建议的目标期刊路线

### 路线 A：冲击整合型高水平期刊

推荐目标：

- Nature Food
- Cell Metabolism
- Nature Metabolism
- npj Science of Food
- American Journal of Clinical Nutrition

适用条件：

- 仿生消化 pilot 与 full experiment 结果方向一致；
- original -> redesigned 明显降低 early glucose release iAUC/Cmax/early slope；
- food matrix annotation 完成专家校正；
- 主图能形成 Figure 1-5 的完整故事。

### 路线 B：更稳妥的高质量专业期刊

推荐目标：

- American Journal of Clinical Nutrition
- Clinical Nutrition
- npj Science of Food
- Nutrients 高质量专题或 Environmental Health/Environment International 方向

适用条件：

- 仿生消化结果较弱或样本不足；
- 预测和观察性证据强，但机制闭环不够。

### 路线 C：拆成两篇

如果仿生消化无法形成强 Figure 5，可拆为：

1. 环境流行病学论文：DEHP oxidative profile and metabolic susceptibility in NHANES。
2. CGM 精准营养论文：metabolic susceptibility-aware PPGR vulnerability and meal redesign。

## 5. 接下来的研究路径

### Step 1：冻结主文主线和 5 张主图

优先级最高。不要再扩散到微生物组、复杂深度学习或过多外部数据。

建议主图：

- Figure 1：跨尺度研究框架。
- Figure 2：NHANES DEHP oxidative profile -> MSI/HOMA/HbA1c。
- Figure 3：CGMacros MSI/digestibility-risk -> PPGR and curve phenotype。
- Figure 4：MSI-enhanced prediction and counterfactual meal redesign。
- Figure 5：bionic digestion original vs redesigned glucose release。

### Step 2：完成 12 个候选餐食人工图片与配方 QC

必须解决：

- 12/12 fiber=0 是否真实；
- 8/12 重复宏量指纹是否代表同一类食物；
- 每张图片对应真实食物组成；
- 每餐能否复原为实验配方；
- 是否需要用更有代表性的餐食替换重复候选。

交付物：

- `bionic_candidate_photo_qc_sheet_final.xlsx`
- `bionic_candidate_recipe_reconstruction_final.csv`
- `original_redesigned_meal_pair_protocol.csv`

### Step 3：升级 Food Matrix Annotation

在 Module C proxy 基础上新增 expert-coded version：

- refined starch；
- intact grain；
- liquid carbohydrate；
- dessert/sweetened beverage；
- high fat + high carb matrix；
- visible vegetable/fiber；
- protein co-ingestion；
- processing/NOVA proxy；
- estimated GI/GL；
- preparation method。

每餐至少两名标注者，记录 disagreement 和 adjudication。这样 Module C 才能进入主文。

### Step 4：R survey 最终复核 Module B

只复核主文需要的部分，不要过度消耗时间：

- `ln(Oxidative/MEHP)` -> MSI-core、ln(HOMA-IR)、HbA1c；
- RCS dose-response；
- sex、obesity、diabetes history 分层；
- negative-control-like exposure/outcome；
- urinary creatinine 敏感性；
- 排除糖尿病/降糖药敏感性。

目标是让 Figure 2 经得起环境流行病学审稿。

### Step 5：仿生消化 pilot

先做 3-4 个餐食，不要一上来做完整 12 个。

建议选择：

- high MSI + high PPGR + high digestibility-risk 餐食 2 个；
- high digestibility-risk 但不同 matrix 的餐食 1 个；
- redesigned 低风险版本 1 个。

终点：

- glucose release iAUC 0-60 min；
- Cmax；
- early release slope；
- Tmax；
- iAUC 0-120 min。

Go/No-Go：

- 如果 3-4 个 pilot 中至少 3 个 original > redesigned，进入 full experiment。
- 如果方向不稳，先调整 redesign 规则和餐食选择。

### Step 6：完整仿生消化实验

建议最终：

- 8-12 个餐食原型；
- original/redesigned 配对；
- 每组 3 个技术重复；
- 总实验单元约 48-72；
- primary endpoint：glucose release iAUC 0-60 min；
- secondary endpoints：Cmax、Tmax、early slope、iAUC 0-120 min。

主文核心句应是：

> Model-prioritized high-risk meals showed higher early glucose release, and digestion-informed redesign attenuated release kinetics in paired bionic digestion experiments.

### Step 7：将消化实验结果回填模型

如果样本足够：

- 用 release iAUC/Cmax/early slope 解释 high-error/high-risk meal prototypes；
- 比较 M3 vs M4 digestion-informed feature model；
- 不强求预测性能显著提升，更重要是机制解释一致。

### Step 8：投稿包

对齐高水平期刊要求：

- TRIPOD+AI：prediction 部分。
- PROBAST+AI：bias/applicability。
- STROBE-ME：NHANES 暴露生物标志物。
- STROBE-nut：营养/餐食分析。
- Nature/Cell data、code、protocol availability。
- 仿生消化 protocol 和 raw release curve 数据。

## 6. 8 周执行顺序

### Week 1

- 完成 300 字英文 abstract。
- 完成 Figure 1-5 storyboard。
- 生成 Figure 2-4 初稿。
- 完成候选餐食图片 QC 模板。

### Week 2

- 完成人工 food matrix annotation。
- 完成 R survey RCS/分层复核。
- 确定 pilot 餐食与 original/redesigned 配方。

### Week 3-4

- 开展 3-4 餐食仿生消化 pilot。
- 生成 pilot release features 和 decision report。
- 根据 pilot 调整 full experiment。

### Week 5-6

- 完整仿生消化实验。
- 生成 Figure 5。
- 回填 digestion features 解释模型误差和高风险餐食。

### Week 7

- 完成英文主文初稿。
- 完成 supplementary tables。
- 完成 reporting checklists。

### Week 8

- 完成 cover letter。
- 完成投稿包和数据/代码/协议可用性声明。
- 根据目标期刊格式调整。

## 7. 最重要的决策

当前不要再优先做更多模型或更多外部数据。真正能提高期刊层级的不是“分析更多”，而是完成以下三件事：

1. 把 food matrix 从 proxy 升级为人工标注和数据库校正版本。
2. 把仿生消化 pilot 做出来，验证 original vs redesigned 的早期葡萄糖释放差异。
3. 把 Figure 1-5 和英文 manuscript 同步推进，让每个结果都服务同一条主线。

如果这三件事完成，这项研究可以作为整合型高水平论文推进；如果仿生消化结果不强，则建议降级为较稳的 AJCN/npj Science of Food/Clinical Nutrition 路线，或拆成两篇文章。

## 8. 对齐的规范和期刊要求

- Nature Food reporting standards and data/code/protocol availability: https://www.nature.com/natfood/editorial-policies/reporting-standards
- Cell Press STAR Methods/resource availability: https://www.cell.com/pb-assets/journals/research/cell/methods/Methods_Guide_general-1678470557763.pdf
- TRIPOD+AI: https://www.bmj.com/content/385/bmj-2023-078378
- PROBAST+AI: https://www.bmj.com/content/388/bmj-2024-082505
- STROBE-ME: https://www.equator-network.org/reporting-guidelines/strobe-me/
- STROBE-nut: https://www.equator-network.org/reporting-guidelines/strobe-nut/
