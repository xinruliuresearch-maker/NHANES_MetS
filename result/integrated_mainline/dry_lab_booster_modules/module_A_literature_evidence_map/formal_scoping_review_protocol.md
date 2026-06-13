# Module A：正式文献调研扩展方案

日期：2026-06-10

## 目标

当前 `dry_lab_evidence_map_seed.csv` 是 20 条 anchor evidence，用于固定论文主线。正式投稿前建议扩展为 80-120 篇可筛查文献，并保留检索日期、数据库、纳入/排除理由。

## 数据库

- PubMed/MEDLINE
- Web of Science 或 Scopus
- Embase（如可访问）
- Google Scholar 用于追踪高被引方法学和数据库文献
- EQUATOR Network 用于报告规范
- USDA FoodData Central、Open Food Facts、Sydney GI、EPA CompTox、CTD、Reactome 用于数据库方法部分

## 核心检索式

1. `(continuous glucose monitoring OR CGM OR postprandial glycemic response OR PPGR) AND (personalized nutrition OR precision nutrition OR machine learning OR prediction)`
2. `(DEHP OR phthalate OR MEHP OR MEHHP OR MEOHP OR MECPP) AND (insulin resistance OR HOMA-IR OR metabolic syndrome OR diabetes OR HbA1c) AND NHANES`
3. `(food matrix OR glycemic index OR glycemic load OR starch digestibility OR in vitro digestion OR INFOGEST) AND (glucose release OR postprandial glucose)`
4. `(TRIPOD-AI OR PROBAST-AI OR STROBE-ME OR STROBE-nut OR target trial emulation) AND prediction`
5. `(DEHP OR MEHP) AND (oxidative stress OR PPAR OR insulin signaling OR mitochondrial dysfunction OR adipogenesis)`

## 筛选框架

- 一级纳入：人群研究、CGM/PPGR、NHANES/环境暴露、食品消化机制、预测模型方法规范。
- 一级排除：与糖代谢无关、无餐后动态表型、动物/细胞机制但不能连接 insulin resistance 的非核心文献。
- 分层标注：study design、population、exposure、outcome、methodological strength、direct relevance、paper section。

## 预期输出

- `dry_lab_evidence_map_full_screening.csv`
- `dry_lab_prisma_flow_counts.csv`
- `dry_lab_key_paper_annotation.md`

## 当前论文可用结论

即使不等待完整 PRISMA，现有 anchor evidence 已足够支持本文的立论：DEHP/代谢易感性、PPGR 精准营养和食品消化动力学三个领域分别成熟，但三者尚未被统一到同一条“环境-宿主-餐食-消化干预”证据链中。
