# 证据链硬化执行报告

生成日期: 2026-06-11

## 总体结论

本轮已经把五个关键短板推进到可复核文件层面。最重要的变化是: NHANES 主暴露已经从派生比例回到原始单体代谢物；食物基质从简单 proxy 升级为双规则预标注 + 人工双评模板 + 官方 FDC 离线匹配；Stanford 从弱边界验证升级为 CGM 标准餐 + 代谢组/脂质组/Olink 分子桥接；GEO 方向性转录组脚本已准备并可运行；CompTox/ToxCast 记录了可复核但当前 API 不可直接解析的边界。

## 1. NHANES原始单体混合物

dehp_raw_oxidative_three/ln_HOMA_IR: psi=0.114, p=0.00341, q=0.0546; dehp_raw_four_monomers/ln_HOMA_IR: psi=0.090, p=0.0149, q=0.0595; dehp_raw_oxidative_three/response_vulnerability_index: psi=0.088, p=0.015, q=0.0595; dehp_raw_oxidative_three/msi_no_bmi: psi=0.108, p=0.0166, q=0.0595; dehp_raw_oxidative_three/msi_core_partial: psi=0.108, p=0.0186, q=0.0595

解释: 原始氧化 DEHP 单体混合物对 ln(HOMA-IR)、response vulnerability、HbA1c 等方向基本一致，但效应强度弱于派生氧化比例。主文应将其作为更可信的主暴露模型，派生比例作为代谢转化/氧化二级机制指标。

## 2. 食物基质与FDC

- 双规则预标注 agreement=0.378, kappa=0.218。
- 需要人工图像复核: 932 餐。
- 官方离线 FDC proxy item-level ID: 1498/1498。
- 低置信度 FDC 匹配: 113。

解释: 这一层已经从 DEMO_KEY API 失败修复为官方离线库匹配，但 CGMacros 没有真实餐食文本，FDC 仍是 proxy item-level。投稿前必须由两名人工基于图片完成最终类别和 FDC ID 确认。

## 3. Stanford分子层外部验证

- 标准化餐食/挑战记录: 588。
- 受试者: 74。
- 分子层: 3 个 block，包括 lipidomics、metabolomics、Olink。
- 最佳预测摘要: {'outcome': 'stanford_mean_peak_delta_2h', 'model': 'clinical_meta', 'n': 38, 'rmse': 20.502175899416695, 'mae': 14.8600535050238, 'pearson_r': 0.227248203796361, 'r2': 0.017110092775279417}。

解释: Stanford 现在用于桥接“代谢易感性-标准餐PPGR-分子表型”，比 D1NAMO/Jaeb 更接近高水平 PPGR 论文所需的证据形态。

## 4. GEO与CompTox/ToxCast机制层

- GEO 差异表达由 `scripts/37_run_geo_directional_mechanism.R` 完成，输出 GSE212641 配对 MEHP RNA-seq 和 GSE293605 MEHP DEG/KEGG。
- GEO 面板结果: GSE212641_hiPSC_endothelial_RNAseq/lipid_ppar: FDR genes=3, direction=mostly_downregulated; GSE212641_hiPSC_endothelial_RNAseq/inflammation_tnf: FDR genes=1, direction=mostly_downregulated; GSE293605_human_liver_organoid_supplied_DEG/insulin_resistance: FDR genes=6, direction=mixed_direction; GSE293605_human_liver_organoid_supplied_DEG/lipid_ppar: FDR genes=10, direction=mostly_upregulated; GSE293605_human_liver_organoid_supplied_DEG/oxidative_stress: FDR genes=5, direction=mostly_upregulated; GSE293605_human_liver_organoid_supplied_DEG/inflammation_tnf: FDR genes=4, direction=mixed_direction; GSE293605_human_liver_organoid_supplied_DEG/mitochondrial_stress: FDR genes=2, direction=mostly_downregulated
- GSE293605 KEGG 关键通路: Insulin resistance (padj=0.00217); PI3K-Akt signaling pathway (padj=0.00526); AGE-RAGE signaling pathway in diabetic complications (padj=0.00661); Sphingolipid signaling pathway (padj=0.00332)
- CompTox/ToxCast 检查化学物数: 3；当前 dashboard 可复核，但 assay endpoint API 在本次运行中不可直接解析。

解释: 机制层不能再写成简单 CTD/KEGG 交集。主文应使用 GEO 方向性结果支撑 insulin resistance、lipid/PPAR、oxidative stress、TNF/inflammation、mitochondrial stress 五个机制面板。

## 5. 同受试者CGM-exposome pilot

已输出 `60_same_participant_CGM_exposome_pilot_protocol.csv`。若目标是最高层级期刊，这个 pilot 是最关键的湿/临床桥接：同一受试者内同时测尿 DEHP 单体、CGM、标准餐、食物基质和代谢表型，才能真正闭合当前跨数据库证据链。

## 关键文件

- `00_raw_nhanes_monomer_mixture_report.md`
- `05_survey_weighted_single_monomer_glm.csv`
- `06_survey_weighted_raw_monomer_mixture_qgcomp_like.csv`
- `10_bkmr_pip_summary.csv`
- `20_food_matrix_dual_AI_rule_preadjudication.csv`
- `21_food_matrix_manual_human_dual_annotation_template_v3.csv`
- `24_cgmacros_FDC_official_item_level_proxy_matches.csv`
- `30_stanford_standardized_meal_ppgr_features.csv`
- `31_stanford_subject_msi_ppgr_bridge.csv`
- `33_stanford_omics_pc_correlations.csv`
- `34_stanford_top_molecular_feature_correlations.csv`
- `35_stanford_molecular_prediction_performance.csv`
- `40_CompTox_ToxCast_dashboard_and_API_status.csv`
- `60_same_participant_CGM_exposome_pilot_protocol.csv`
