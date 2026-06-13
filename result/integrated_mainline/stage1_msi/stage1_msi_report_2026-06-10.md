# Stage 1 报告：MSI-core 代谢易感性指数构建

日期：2026-06-10

## 目的

构建一个不包含 DEHP/phthalate 暴露变量、可在 NHANES 与 CGMacros 之间桥接的 `MSI-core` 代谢易感性指数。该指数将在后续阶段承担两个角色：

1. 在 NHANES 中作为 DEHP oxidative profile 的下游代谢表型。
2. 在 CGMacros 中作为餐食级 PPGR vulnerability 的个体分层变量。

## 指数组件

`MSI-core` 使用 5 个共同临床代谢组件：

- BMI
- HbA1c
- fasting glucose
- ln(HOMA-IR)
- ln(TG/HDL-C)

CGMacros 的 HOMA-IR 由 `fasting glucose mg/dL × fasting insulin uU/mL / 405` 计算。TG/HDL-C 由 triglycerides / HDL 计算。

## 标准化策略

主指数 `msi_core_partial_nhanes_ref` 使用 NHANES 2013-2018 作为外部人群参考：

1. 对每个组件按 NHANES p1-p99 winsorization。
2. 用 NHANES winsorized mean/sd 标准化。
3. 对至少 3 个组件非缺失的个体取平均。

同时输出：

- `msi_core_complete_nhanes_ref`：5 个组件完整时的均值。
- `msi_core_ranknorm_within_dataset`：各数据集内部 rank-normalized 版本。
- `msi_core_tertile_within_dataset`：数据集内部 low/middle/high 三分位。

## 数据规模

| 数据集 | 总样本 | partial MSI 非缺失 | complete MSI 非缺失 | partial MSI 中位数 |
|---|---:|---:|---:|---:|
| NHANES 2013-2018 | 5267 | 2491 | 2368 | -0.101 |
| CGMacros subjects | 40 | 40 | 40 | 0.325 |

## 输出文件

- `cgmacros_subject_msi_core.csv`：CGMacros 受试者级 MSI 表。
- `cgmacros_meal_level_with_msi_core.csv`：合并 MSI 的 CGMacros 餐食级表。
- `nhanes_2013_2018_msi_core.csv`：NHANES MSI 和 DEHP 关键变量表。
- `stage1_msi_component_scaler.csv`：NHANES 参考标准化参数。
- `stage1_msi_summary_by_dataset.csv`：两个数据集 MSI 概览。
- `stage1_msi_component_missingness.csv`：组件缺失情况。


## 下一步

Stage 2 将在 NHANES 中检验：

`DEHP oxidative profile -> MSI-core / HOMA-IR / HbA1c / TyG / TG/HDL-C`

Stage 3 将在 CGMacros 中检验：

`MSI-core -> PPGR vulnerability` 和 `MSI-core × meal load` 交互。
