# Module D：CGM 曲线表型与 functional data analysis 代理

日期：2026-06-10

## 已完成

本模块基于已有 meal-level CGM 摘要构建动态表型，而不是重新读取原始连续曲线。生成了 early slope proxy、delayed peak、prolonged elevation、3h persistence、high iAUC/moderate peak、high peak/fast recovery、low stable response 和 5 类 shape cluster。

## 主要输出

- `cgmacros_ppgr_curve_features.csv`
- `cgmacros_ppgr_shape_clusters.csv`
- `curve_shape_msi_food_matrix_models.csv`
- `FigureS_curve_phenotypes.png`（若 matplotlib 可用）

## 投稿解释

当前版本可作为 dynamic phenotype sensitivity。若结果进入主文，建议下一步从原始 CGM 时间序列重构 0-180 min 统一时间网格，再做 FPCA/trajectory clustering。
