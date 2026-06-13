# GEO方向性机制证据

生成日期: 2026-06-11

## 已完成

- `GSE212641`: 下载 raw read counts，构建 3 对 DMSO/MEHP 配对设计，使用 logCPM + limma 运行 MEHP vs DMSO 差异表达。
- `GSE293605`: 下载作者提供的 MEHP vs DMSO DEG 与 KEGG 富集表，提取与 insulin resistance、lipid/PPAR、oxidative stress、TNF/inflammation、mitochondrial stress 相关的方向性证据。

## 输出文件

- `51_GEO_GSE212641_MEHP_vs_DMSO_limma_all.csv`
- `52_GEO_GSE212641_MEHP_vs_DMSO_top200.csv`
- `53_GEO_GSE212641_directional_panel_summary.csv`
- `54_GEO_GSE293605_MEHP_vs_DMSO_supplied_DEG_top300.csv`
- `55_GEO_GSE293605_MEHP_KEGG_relevant_terms.csv`
- `56_GEO_directional_mechanism_synthesis.csv`

## 使用边界

GSE212641 是 endothelial cell MEHP 暴露，GSE293605 是 human liver organoid MEHP 暴露。二者都不能单独证明 NHANES 暴露-代谢关系的因果性，但能把机制层从数据库重叠推进为可复核的方向性转录组证据。
