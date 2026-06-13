# 主线决策备忘录

日期：2026-06-10

## 唯一主线

环境塑化剂暴露相关的代谢易感性会放大餐食诱导的餐后血糖脆弱性；基于消化释放动力学的餐食重构可以降低这种风险。

## 主文必须回答的 4 个问题

1. NHANES 中，DEHP oxidative profile 是否与 MSI/HOMA-IR/HbA1c/TyG/TG-HDL 相关？
2. CGMacros 中，MSI 是否预测高 PPGR，并与 meal load 存在交互？
3. 高 MSI 个体是否有更差校准、更高高反应餐风险，以及更大的 few-shot personalization 收益？
4. 仿生消化实验中，模型推荐的低风险替换是否降低 early glucose release？

## 主文保留

- NHANES DEHP oxidative profile -> metabolic susceptibility。
- CGMacros MSI -> PPGR vulnerability。
- MSI × meal load interaction。
- Few-shot personalization by MSI strata。
- 10-12 个餐食原型的仿生消化机制验证。
- 1 个简洁外部 CGM 边界验证图。

## 放补充

- NHANES LOD/creatinine/IPW/MI/E-value/negative control。
- qgcomp/WQS/BKMR。
- 外部数据逐库结果。
- CTD/CompTox/ToxCast 机制证据。
- 微生物组探索。

## 不放本篇主文

- NHANES 死亡分析。
- 大而全的机制网络。
- D1NAMO 食物图片深度模型。
- 所有模型排行榜。
- 所有反事实场景。

## 论文题目方向

Environmental metabolic susceptibility and digestion-informed postprandial glycemic vulnerability

## 最小可发表主结果

如果只保留最核心结果，主文应有：

1. NHANES: %Oxidative / oxidative-to-MEHP 与 MSI/HOMA-IR 正相关。
2. CGMacros: MSI high vs low 的 PPGR 明显不同。
3. CGMacros: 高 MSI 放大 carbohydrate/glycemic-load 对 PPGR 的影响。
4. CGMacros: 加入 MSI 改善 high-response detection 或 calibration。
5. Bionic digestion: 原餐 vs 替换餐 glucose release 曲线方向支持模型推荐。
