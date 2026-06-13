# Module F：外部验证与 transportability map

日期：2026-06-10

## 完成内容

本模块整合 Phase 5 已完成的 Stanford CGMDB、T1D-UOM、Jaeb/健康参考和 CGMacros 边界结果，输出 dataset-level transportability map 与 domain shift metrics。

## 解释边界

- Stanford CGMDB：标准化食物挑战，用于证明同食物下仍有强个体差异。
- T1D-UOM：疾病状态边界，用于检验碳水/纤维方向是否大体一致，不用于直接复制 MSI。
- 健康 CGM 参考：提供低波动边界。
- CGMacros：唯一可以完整检验 MSI -> PPGR 主链条的数据集。

## 输出

- `external_transportability_map.csv`
- `external_domain_shift_metrics.csv`
- `external_macro_direction_consistency.csv`
- `FigureS_external_boundary_map.png`（若 matplotlib 可用）
