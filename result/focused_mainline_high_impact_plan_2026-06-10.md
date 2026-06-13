# 聚焦版高水平研究主线方案

日期：2026-06-10  
适用项目：CGMacros + NHANES-DEHP + 外部 CGM 数据 + 少量仿生消化实验

## 1. 一句话主线

慢性环境塑化剂暴露相关的代谢易感性，使个体在面对高糖负荷/高加工餐食时更容易产生异常餐后血糖反应；食物消化释放动力学是连接环境暴露、饮食结构和餐后血糖风险的可验证、可干预机制。

这句话应成为整篇论文的中心。所有分析都必须服务于它；不能服务的分析放入补充材料或另写独立论文。

## 2. 为什么上一版显得分散

上一版把 NHANES-DEHP、CGMacros、外部 CGM、Stanford CGMDB、D1NAMO、Shanghai、Jaeb、体外消化、食品接触、预测模型、机制数据库都放进了同一个大框架，但没有明确谁是主角、谁是证据、谁只是辅助。因此主线容易变成：

- 一部分像环境流行病学论文。
- 一部分像 CGM/个体化营养算法论文。
- 一部分像体外消化食品科学论文。
- 一部分像数据库综述。

新的方案必须压缩为一个核心命题：

> Environmental metabolic susceptibility modifies meal-induced postprandial glycemic vulnerability, and digestion-informed meal redesign can reduce that vulnerability.

中文可写为：

> 环境代谢易感性放大餐食诱导的餐后血糖脆弱性，而基于消化动力学的餐食重构可降低这种风险。

## 3. 唯一核心科学问题

谁在同样或相近的餐食负荷下更容易出现高餐后血糖反应，为什么，以及能否通过改变食物结构和消化释放过程降低这种风险？

这个问题天然分成三层：

1. 人群层：哪些慢性环境暴露和代谢表型提示个体处于更高代谢易感状态？
2. 个体动态层：这种代谢易感状态是否表现为更高 PPGR、更差模型校准和更强个体化需求？
3. 机制干预层：高风险餐食的快速糖释放是否能解释这种 PPGR，并能否通过餐食重构降低？

## 4. 关键桥梁变量：Metabolic Susceptibility Index

两个项目不能个体级合并，因为 CGMacros 没有 DEHP 暴露，NHANES 没有餐食级 CGM。真正能桥接两者的是一个共同的代谢易感性表型。

建议构建两个版本：

### 4.1 MSI-core

用于 NHANES 和 CGMacros 共同分析，尽量使用两个项目共有变量：

- BMI
- HbA1c
- fasting glucose
- fasting insulin
- HOMA-IR
- triglycerides / HDL-C ratio

CGMacros 中可由以下字段构建：

- `BMI`
- `A1c PDL (Lab)`
- `Fasting GLU - PDL (Lab)`
- `Insulin`
- `Triglycerides`
- `HDL`

NHANES 中可由以下字段构建：

- `BMXBMI`
- `HbA1c`
- `LBXGLU`
- `LBXIN`
- `HOMA_IR`
- `TG_HDL` 或 `ln_TG_HDL`

推荐做法：

1. 对各指标进行方向统一，值越高代表代谢易感性越高。
2. 对连续指标做 rank-based inverse normal transformation 或 z-score。
3. 取均值或第一主成分作为 `MSI-core`。
4. 在敏感性分析中分别使用 HOMA-IR、HbA1c、TG/HDL-C 作为单指标替代。

### 4.2 MSI-NHANES

仅用于 NHANES 内部人群分析，可包含 waist circumference、TyG、metabolic syndrome components 等更丰富变量。

重要原则：

- MSI 不能包含 DEHP 暴露变量，否则会造成循环论证。
- DEHP oxidative profile 是 MSI 的上游解释变量。
- MSI 是 CGMacros 的分层变量和效应修饰变量。

## 5. 新证据链

### Evidence 1：NHANES 证明环境暴露与代谢易感性相关

主问题：

> DEHP oxidative metabolic profile 是否与 MSI、HOMA-IR、HbA1c、TyG、TG/HDL-C 稳定相关？

主暴露：

- ln(Sigma DEHP)
- %Oxidative metabolites per 10 percentage points
- ln(Oxidative/MEHP)
- ILR oxidative-vs-primary balance

主结局：

- MSI-core
- ln(HOMA-IR)
- HbA1c

次要结局：

- TyG
- ln(TG/HDL-C)
- metabolic syndrome

现有结果已经支持这一层：

- %Oxidative 与 ln(HOMA-IR)、HbA1c、TyG、ln(TG/HDL-C) 均方向一致。
- oxidative/MEHP log-ratio 对 ln(HOMA-IR) 的关联强。
- 组成暴露和混合模型提供补充支持。

这一层的意义不是证明 DEHP 会直接改变 CGMacros 的 PPGR，而是建立：

> DEHP oxidative profile marks or contributes to an insulin-resistant metabolic susceptibility phenotype in the population.

### Evidence 2：CGMacros 证明代谢易感性放大餐后血糖脆弱性

主问题：

> MSI-core 是否预测同等餐食负荷下更高的 PPGR？

主结局：

- 2h iAUC
- 2h peak delta
- high PPGR，定义为 iAUC 或 peak delta 的 top quartile

主模型：

```text
PPGR ~ meal load + pre-meal glucose + MSI-core + meal load × MSI-core + time/context + subject structure
```

其中 meal load 不应只用 carbohydrate，建议分层：

- carbohydrate grams
- available carbohydrate 或 glycemic-load proxy
- carbohydrate/fiber ratio
- carbohydrate/protein ratio
- carbohydrate/fat ratio
- energy density
- meal timing

关键检验：

1. MSI-core 是否与 PPGR 独立相关。
2. `meal load × MSI-core` 是否显著：同样碳水或同样 GL 下，高 MSI 个体反应更强。
3. 高 MSI 个体是否有更差校准：模型是否系统低估高反应餐。
4. 高 MSI 个体是否从 few-shot personalization 中获益更大。

如果这四点成立，CGMacros 就不再只是“预测餐后血糖”，而是证明：

> Insulin-resistant metabolic susceptibility is expressed as exaggerated postprandial glycemic vulnerability.

### Evidence 3：外部 CGM 数据限定模型边界

外部数据不再并列为主角，只回答一个问题：

> 这种 PPGR vulnerability 框架在健康、T1D、T2D、标准化食物挑战中是否仍有可解释边界？

主用数据：

- T1D-UOM：meal macros + CGM + insulin + activity/sleep，用于 disease-state transfer。
- Stanford CGMDB：标准化食物挑战，用于食物反应异质性和机制参考。
- Jaeb healthy adults：健康成人 CGM 正常波动范围。
- ShanghaiT1DM/T2DM：中国糖尿病 CGM phenotype 外部参考。
- D1NAMO：食物图片/描述 case study。

注意：

- 外部数据不做大杂烩训练。
- 不把 T1D/T2D 结果当作 CGMacros 同分布验证。
- 主文最多放一个外部验证图，其余放补充。

### Evidence 4：仿生消化验证可干预机制

主问题：

> 模型识别出的高风险餐食，是否具有更快或更高的体外 glucose release？模型推荐的低风险替换，是否能降低 release Cmax、early slope 或 release iAUC？

这才是体外实验在主线中的作用。它不是另一个独立食品科学研究，而是验证 CGMacros 模型的关键机制。

优先实验对象：

1. 高 MSI 个体中高 PPGR 的真实餐。
2. 高 carbohydrate/fiber ratio 或高 energy density 餐。
3. 同等碳水但 PPGR 差异大的餐。
4. NHANES source-oriented analysis 指向的高加工/外食/包装接触相关饮食类型。

建议第一轮只做 10-12 个餐食原型，不要过大：

| 餐食类型 | 原型数 | 干预版本 |
|---|---:|---|
| 精制主食高 GL 餐 | 3 | 加纤维/抗性淀粉 |
| 高脂高碳水加工餐 | 3 | 降碳水或加蛋白 |
| 同碳水不同结构餐 | 3 | 完整颗粒 vs 粉碎/糊化 |
| 模型高误差真实餐 | 3 | 模型推荐替换 |

检测指标：

- glucose release Cmax
- release iAUC 0-60 min
- release iAUC 0-120 min
- early release slope
- Tmax
- half-release time
- viscosity
- particle size
- resistant starch or starch gelatinization/retrogradation proxy

关键判据：

- 高风险原餐的 early glucose release 高于替换餐。
- 体外 release 指标与 CGMacros 中同类餐的 PPGR 方向一致。
- digestion-informed features 能改善同碳水餐预测误差或至少解释误差来源。

## 6. 一篇主论文的最终标题和摘要骨架

### 推荐标题

Environmental metabolic susceptibility and digestion-informed postprandial glycemic vulnerability: a multiscale study integrating NHANES, CGM nutrition cohorts, and bionic digestion

### 中文标题

环境代谢易感性与消化机制约束的餐后血糖脆弱性：整合 NHANES、连续血糖营养队列和仿生消化的多尺度研究

### 摘要主线

Background:

餐后血糖反应不仅由餐食碳水决定，还受个体胰岛素抵抗、糖脂代谢状态、慢性环境暴露和食物消化释放动力学共同影响。

Methods:

在 NHANES 中评估 DEHP oxidative profile 与 MSI/HOMA-IR/HbA1c/TyG 的关系；在 CGMacros 中检验 MSI 是否预测餐食级 PPGR 和少样本个体化收益；在外部 CGM 数据中评估边界；在体外仿生消化系统中验证高风险餐食及替换策略的 glucose release kinetics。

Results:

预期主结果应按顺序报告：

1. DEHP oxidative profile 与 MSI/insulin resistance 稳定相关。
2. MSI 在 CGMacros 中独立预测高 PPGR。
3. 高 MSI 个体对高 meal load 更敏感，存在 `MSI × meal load` 交互。
4. 高 MSI 个体模型校准更差，但 few-shot personalization 改善更明显。
5. 仿生消化实验显示低风险替换降低早期 glucose release。

Conclusion:

环境相关代谢易感性可解释部分餐后血糖异质性；消化机制约束的餐食重构为精准营养干预提供可验证路径。

## 7. 主结果只保留这些

### 主文结果 1：NHANES environmental metabolic susceptibility

只放：

- DEHP oxidative profile -> MSI-core / HOMA-IR / HbA1c / TyG / TG-HDL。
- 一张森林图或热图。
- 一个 dose-response 图。

不放主文：

- 全部 phthalate 代谢物大表。
- 死亡分析。
- 过多 BKMR 图。
- 复杂机制网络。

### 主文结果 2：CGMacros PPGR vulnerability

只放：

- MSI-core 分层下 PPGR 分布。
- `meal load × MSI-core` 交互。
- 加入 MSI 后模型是否改善。
- 高 MSI 组 few-shot personalization 收益。

不放主文：

- 所有模型排行榜。
- 所有外部数据细节。
- 所有微生物组变量。

### 主文结果 3：外部边界验证

只放：

- 健康成人、CGMacros、T1D/T2D 的 CGM/PPGR phenotype 对比。
- 或 T1D-UOM 的简洁外部 transfer/calibration 图。

不放主文：

- 每个外部库逐项展开。

### 主文结果 4：仿生消化机制验证

只放：

- 原餐 vs 替换餐 glucose release curves。
- release iAUC/Cmax/early slope 与模型预测 PPGR 方向一致性。
- digestion-informed feature 对关键误差餐的解释。

## 8. 主图设计

Figure 1：一条清晰机制链  
`DEHP oxidative profile -> metabolic susceptibility -> meal-load amplified PPGR -> digestion-informed meal redesign`

Figure 2：NHANES 人群证据  
DEHP oxidative profile 与 MSI/HOMA-IR/HbA1c/TyG/TG-HDL 的森林图和 dose-response。

Figure 3：CGMacros 动态表型证据  
MSI 分层的 PPGR 分布、`meal load × MSI` 交互和 high-response risk。

Figure 4：个体化与校准  
高 MSI 与低 MSI 个体中 0/1/3/5/10-shot personalization 的误差和 calibration slope。

Figure 5：体外消化机制  
高风险餐与替换餐的 glucose release curves、release Cmax/iAUC、与模型预测方向的一致性。

Supplementary：

- NHANES 敏感性分析。
- qgcomp/WQS/BKMR。
- 负控、E-value、IPW/MI。
- 外部数据详细验证。
- 机制数据库。
- 微生物组探索。

## 9. 实验方案重新收敛

### Stage 1：构建 MSI

CGMacros：

- 清洗 `A1c PDL (Lab)`、`Fasting GLU - PDL (Lab)`、`Insulin`、`Triglycerides`、`HDL`、`BMI`。
- 构建 HOMA-IR。
- 构建 TG/HDL。
- 构建 MSI-core。

NHANES：

- 使用相同变量构建 MSI-core。
- 使用更丰富变量构建 MSI-NHANES 作为敏感性。

### Stage 2：NHANES 暴露-易感性分析

模型：

```text
MSI-core ~ DEHP oxidative profile + covariates + survey design
```

协变量：

- age
- sex
- race/ethnicity
- education
- PIR
- energy intake
- smoking
- alcohol
- physical activity
- urinary creatinine
- NHANES cycle

### Stage 3：CGMacros 易感性-PPGR 分析

模型：

```text
PPGR ~ meal_load + MSI-core + meal_load × MSI-core + pre_meal_glucose + meal_time + activity + subject structure
```

主结局：

- iAUC 2h
- peak delta 2h
- high PPGR top quartile

### Stage 4：预测模型重排

不要再以“模型性能排行榜”为主。改为检验一个明确问题：

> 加入 MSI-core 是否改善高风险餐识别、校准和个体化效率？

模型层级：

- M0：carb-only
- M1：macro + meal timing
- M2：M1 + pre-CGM/activity
- M3：M2 + MSI-core
- M4：M3 + few-shot personalization
- M5：M4 + digestion-informed features

### Stage 5：体外消化实验

样本：

- 10-12 个餐食原型。
- 每个原餐 1 个替换版本。
- 每组 3 次技术重复。
- 总 60-72 个实验单元。

主要终点：

- release iAUC 0-60 min
- glucose release Cmax
- early release slope

次要终点：

- release iAUC 0-120 min
- Tmax
- viscosity
- particle size
- resistant starch/gelatinization proxy

## 10. 目标期刊对应的叙事

### Nature Food / Cell Metabolism / Nature Metabolism

必须完成：

- NHANES 主结果稳健。
- CGMacros 中 MSI × meal load 交互明确。
- 体外消化实验有方向一致且有机制解释。
- 外部 CGM 数据至少提供边界验证。

### Environmental Health Perspectives / Environment International

重点：

- DEHP oxidative profile -> metabolic susceptibility。
- CGMacros/PPGR 作为动态代谢表型验证。
- 体外消化作为机制补强。

### American Journal of Clinical Nutrition / Diabetes Care

重点：

- PPGR vulnerability。
- MSI 分层精准营养。
- 少样本个体化和可执行餐食替换。

## 11. 必须删除或降级的内容

为了主线清楚，以下内容不应进入主文核心：

1. NHANES 死亡分析：与餐后血糖主线太远，放补充或另文。
2. 过多机制数据库网络：只保留简洁 pathway support。
3. 所有外部数据库逐项描述：放方法和补充。
4. 微生物组高维探索：样本小，最多作探索。
5. D1NAMO 食物图片深度建模：另作后续论文或补充 case study。
6. 复杂 BKMR 主张：作为敏感性，避免成为审稿靶点。

## 12. 最终证据等级

| 证据层 | 问题 | 数据/实验 | 主文地位 |
|---|---|---|---|
| Population exposure | DEHP oxidative profile 是否关联代谢易感性 | NHANES | 主证据 1 |
| Dynamic phenotype | 代谢易感性是否放大 PPGR | CGMacros | 主证据 2 |
| Personalization | 高易感个体是否更需要个体化 | CGMacros few-shot/calibration | 主证据 3 |
| Mechanism | 食物释放动力学是否解释和降低高风险 | 仿生消化 | 主证据 4 |
| Boundary | 框架是否跨人群有解释力 | 外部 CGM | 辅助证据 |
| Biological plausibility | 通路是否合理 | CTD/CompTox/ToxCast | 辅助证据 |

## 13. 结论

新版主线不再是“把 DEHP、PPGR、外部数据库、仿生消化都放在一起”，而是围绕一个中心构念展开：

> metabolic susceptibility to postprandial glycemic vulnerability

NHANES 证明这种易感性与环境塑化剂暴露有关；CGMacros 证明这种易感性在真实餐食后表现为动态血糖异常；仿生消化证明可以通过改变食物结构和糖释放过程降低这种风险。

这是一条从“环境暴露”到“代谢易感性”到“餐后动态表型”再到“机制干预”的单线证据链。它比上一版更少、更窄，但更像一篇高水平论文。
