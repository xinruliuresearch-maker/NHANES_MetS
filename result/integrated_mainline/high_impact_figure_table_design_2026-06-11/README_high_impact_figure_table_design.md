# 冲击高水平期刊的图表体系总设计

生成日期：2026-06-11

## 1. 总体策略

当前文章的主线应收束为：

**DEHP oxidative-metabolism profile -> metabolic susceptibility phenotype (MSI) -> CGM-measured postprandial glycemic vulnerability -> personalized meal-risk stratification**

高水平期刊的图表不能只是结果堆叠，而要完成四件事：

1. 建立跨数据集证据链的可信结构。
2. 证明 MSI 不是任意构造，而是稳健桥接表型。
3. 展示真实 meal-level CGM 生理异质性，而不是只给模型系数。
4. 主动处理审稿人会攻击的点：混杂、样本量、proxy 食物基质、外部可迁移性、预测泄漏、过度因果。

## 2. 推荐主文图表数量

- **主图**：8 张必备图 + 1 张机制/图形摘要候选图。
- **Extended Data / Supplementary Figures**：16 张。
- **主表**：4 张必备表 + 1 张 claim guardrail 表。
- **Supplementary Tables**：30 张，主要用于完整结果、敏感性分析、数据字典和 reproducibility。

## 3. 当前已有图如何使用

`ajcn_publication_figures_v2_2026-06-10` 中的 5 张图可以作为基础，但不是最终冲顶版本：

- Figure 1 v2 -> 升级为主文 Figure 2。
- Figure 2 v2 -> 升级为主文 Figure 4。
- Figure 3 v2 -> 拆分/升级为主文 Figure 5 和 Figure 6。
- Figure 4 v2 -> 升级为主文 Figure 7。
- Figure 5 v2 -> 升级为主文 Figure 8。

缺失的关键图是：主文 Figure 1 研究架构图、Figure 3 MSI 构建/验证图、Figure 9 机制 plausibility 图。

## 4. 最关键的取舍

如果目标是 AJCN/Clinical Nutrition 等高水平专科期刊，可保留 5-6 张主图。  
如果目标是 Nature Medicine / Cell Metabolism / Nature Food / Lancet 系列，需要 7-9 张主图，并将 Extended Data 体系补齐。

## 5. 设计文件

- `main_figures/main_figure_design_high_impact.md`
- `extended_figures/extended_figure_design_high_impact.md`
- `tables/table_design_high_impact.md`
- `source_mapping/display_source_data_map.csv`
- `reviewer_strategy/reviewer_concern_response_matrix.csv`
- `workbook_source/*.csv`
