# Stage 5 报告：仿生消化实验样本选择与方案

日期：2026-06-10

## 目的

用少量、数据驱动选择的餐食原型验证主线机制：

`high metabolic susceptibility + high-risk meal load -> exaggerated PPGR`

以及：

`digestion-informed meal redesign -> lower early glucose release`

## 样本选择

从 CGMacros meal-level 数据中按以下因素构建优先级：

- 2h iAUC 和 2h peak delta 高。
- 受试者 MSI-core 高。
- 碳水负荷高。
- carbohydrate/fiber ratio 高。
- 脂肪和碳水组合负荷高。
- 纤维低。

为避免样本过度集中，同一 subject 最多选 2 餐，同一 prototype class 最多选 3 餐。

本轮选出 12 个候选真实餐，对应 24 个 original/redesigned 实验组。每组 3 个技术重复，预计总实验单元 72 个。

## 候选类别

| prototype_class | n |
|---|---:|
| high_carb_high_fat_processed_proxy | 3 |
| high_msi_high_ppgr_real_meal | 3 |
| model_high_risk_other | 3 |
| high_carb_high_protein_mixed | 2 |
| refined_high_carb_low_fiber | 1 |

## 实验设计

每个候选餐建立两个版本：

1. original：按真实餐食宏量结构复原。
2. redesigned：按模型推荐进行低风险重构，包括可利用碳水上限、增加纤维、抗性淀粉/完整谷物替换、或碳水-蛋白/非淀粉蔬菜替换。

## 动态消化采样

建议采样时间点：

- gastric phase: 0, 15, 30, 60 min
- intestinal phase: 75, 90, 120, 180 min

主要终点：

- glucose release iAUC 0-60 min
- glucose release Cmax
- early release slope

次要终点：

- glucose release iAUC 0-120 min
- Tmax
- half-release time
- simulated gastric emptying half-time
- viscosity/rheology
- particle size D50
- resistant starch or starch gelatinization/retrogradation proxy

## 统计分析

1. 对每个 candidate 比较 original vs redesigned 的 paired difference。
2. 使用技术重复均值和 bootstrap CI。
3. 主判据：redesigned 版本的 early glucose release iAUC 0-60 min 下降，且方向与 CGMacros 模型预测的 PPGR 降低一致。
4. 将 release features 映射为 digestion-informed features，用于后续 M5 模型。

## 质量控制

- 每批包含空白消化液对照。
- 每批包含标准葡萄糖/淀粉阳性对照。
- 餐食制备重量、含水量、处理温度和冷却时间记录。
- 若涉及食品接触材料或塑化剂检测，必须使用玻璃器皿阴性对照、field blank、procedural blank 和回收率评估。

## 输出文件

- `stage5_candidate_meals_for_bionic_digestion.csv`
- `stage5_bionic_digestion_experiment_matrix.csv`
- `stage5_bionic_digestion_protocol_2026-06-10.md`
