# Phase 0-5 后的解释性结论与投稿策略

日期：2026-06-10  
脚本：`scripts/20_integrated_phase0_to_phase5_computational_workflow.py`

## 1. 计算工作已完成

本轮已完成 Phase 0-5 中当前电脑可以完成的全部干实验/计算部分，并同步到 NHANES 项目文件夹。随后已定位并使用本机已安装的 R 4.6.0 运行 Phase 2 的 R `survey` 正式复杂抽样模型，生成了正式复核结果。

主结果目录：

- `outputs/integrated_mainline/phase0_protocol`
- `outputs/integrated_mainline/phase1_qc_msi_sensitivity`
- `outputs/integrated_mainline/phase2_nhanes_survey_ready`
- `outputs/integrated_mainline/phase3_cgmacros_robust_inference`
- `outputs/integrated_mainline/phase4_prediction_upgrade`
- `outputs/integrated_mainline/phase5_external_validation`

NHANES 同步目录：

- `C:\Users\liu12\OneDrive\Desktop\NHANES_MetS_Project\result\integrated_mainline`

## 2. 当前最重要的科学结论

### 2.1 MSI 桥梁变量是稳健的

Phase 1 构建并比较了 9 个 MSI 敏感性版本，包括 partial、complete、ranknorm、without BMI、glycemia/IR、IR/lipid、PCA、HOMA 单指标和 TG/HDL 单指标。

关键判断：

- NHANES 中 `ln(Oxidative/MEHP)` 与多个 MSI 版本均稳定正相关。
- CGMacros 中多个 MSI 版本均与 PPGR 指标稳定正相关。
- 因此，主文可以使用 `MSI-core partial NHANES-ref` 作为主版本，其他版本放入补充材料。

### 2.2 NHANES 上游证据已完成 R survey 正式复核

Phase 2 R `survey` complex design 结果显示：

| 结果 | 估计值 |
|---|---:|
| `ln(Oxidative/MEHP) -> MSI PCA` | 0.157 (0.100, 0.213), q=0.003421 |
| `ln(Oxidative/MEHP) -> MSI no BMI` | 0.172 (0.100, 0.244), q=0.003421 |
| `ln(Oxidative/MEHP) -> ln(HOMA-IR)` | 0.218 (0.129, 0.308), q=0.003421 |
| `ln(Oxidative/MEHP) -> MSI-core` | 0.183 (0.109, 0.257), q=0.003421 |
| `%Oxidative -> MSI-core` | 0.168 (0.072, 0.265), q=0.016124 |

解释：

- DEHP oxidative profile 与代谢易感性桥梁表型之间的上游证据较强。
- R `survey` 复核后，beta 与 Python 近似几乎完全一致，方向和主要显著性均保留。

### 2.3 CGMacros 中 MSI 主效应很稳，交互仍应谨慎

Phase 3 使用 subject-clustered 模型、500 次 subject bootstrap、leave-one-subject-out influence analysis。

Primary carbs model：

| 结局 | 变量 | 估计值 |
|---|---|---:|
| 2h iAUC / 1000 | carbs_10g | 0.180 (0.141, 0.219), q<0.001 |
| 2h iAUC / 1000 | MSI | 1.070 (0.540, 1.599), q<0.001 |
| 2h iAUC / 1000 | carbs x MSI | 0.042 (-0.011, 0.094), q=0.162 |
| 2h peak delta | carbs_10g | 2.484 (1.908, 3.060), q<0.001 |
| 2h peak delta | MSI | 17.356 (9.643, 25.069), q<0.001 |
| 2h peak delta | carbs x MSI | 0.488 (-0.275, 1.251), q=0.268 |

Bootstrap：

- `MSI -> iAUC`: bootstrap CI 0.587 to 1.667, positive probability 0.998。
- `MSI -> peak`: bootstrap CI 9.831 to 26.145, positive probability 1.000。
- `carbs x MSI` 方向为正，但 CI 仍跨 0。

投稿写法：

- 强主张：MSI 是 PPGR vulnerability 的稳定风险分层变量。
- 弱主张：meal-load effect modification 方向一致但仍属探索性证据。

### 2.4 加入 MSI 明显改善预测与高反应识别

Phase 4 使用 nested leave-subject-out，并在内层按受试者 5-fold 调参。

M3 MSI-enhanced 相对 M2 pre-CGM/context：

| 结局 | MAE 改善 | AUC 改善 | 校准斜率改善 |
|---|---:|---:|---:|
| 2h iAUC | -155.0 (-7.2%) | +0.074 | +0.029 |
| 2h peak delta | -2.69 (-9.0%) | +0.084 | +0.039 |

解释：

- MSI 不只是解释变量，也有实际预测价值。
- 主文可把 Phase 4 写成“susceptibility-aware personalization”，而不是普通模型排行榜。

### 2.5 外部数据支持边界，但不直接验证 MSI 桥梁

Phase 5 结果：

| 数据集 | 受试者 | 事件 | 作用 |
|---|---:|---:|---|
| CGMacros | 40 | 1498 | 主队列，自由生活餐食 PPGR |
| Stanford CGMDB | 38 | 588 | 标准化食物挑战，展示食物响应异质性 |
| T1D-UOM | 15 | 3820 | T1D 自由生活餐食边界 |
| Jaeb healthy adults | 169 | 383117 | 健康成人 CGM 波动参考 |

Stanford MSI proxy 不显著：

- `MSI proxy -> iAUC`: 0.552 (-0.385, 1.490), p=0.248。
- `MSI proxy -> peak`: 2.850 (-8.604, 14.304), p=0.626。

T1D-UOM 支持餐食负荷边界：

- `carbs_10g -> iAUC`: 0.240 (0.052, 0.427), p=0.012。
- `fiber_5g -> iAUC`: -0.297 (-0.497, -0.098), p=0.0035。
- `carbs_10g -> peak`: 3.351 (1.213, 5.488), p=0.0021。
- `fiber_5g -> peak`: -3.647 (-6.597, -0.697), p=0.015。

解释：

- Stanford 更适合做“同食物挑战下个体反应异质性”的外部边界图。
- T1D-UOM 更适合支持“碳水增加、纤维降低 PPGR”的可干预方向。
- 外部数据不能写成 CGMacros 的同分布重复验证。

## 3. 对高水平期刊主线的更新判断

当前最稳的主线应写成：

> DEHP oxidative profile is associated with a metabolic susceptibility phenotype in NHANES; this susceptibility phenotype robustly stratifies postprandial glycemic vulnerability and improves susceptibility-aware prediction in CGMacros; external CGM datasets support boundary conditions and meal-load/fiber responsiveness.

中文：

> NHANES 中 DEHP 氧化代谢谱与代谢易感性表型稳定相关；该易感性表型在 CGMacros 中表现为更高餐后血糖脆弱性，并能提升个体化预测；外部 CGM 数据支持餐食负荷、纤维和反应异质性的边界证据。

仍不应写成：

> DEHP 直接导致 CGMacros 中更高 PPGR。

也不应把 `carbs x MSI` 作为已经显著成立的核心结论。

## 4. 投稿前还剩的关键动作

### 已完成 1：运行 R survey 正式 NHANES 复核

文件：

- `outputs/integrated_mainline/phase2_nhanes_survey_ready/phase2_formal_R_survey_script.R`

结果：

- 已用 NHANES complex survey design 复核 Python weighted/clustered 结果。
- 方向一致，NHANES 端可以进入主文 Figure 2。

### 必做 2：人工复核 12 个仿生消化候选餐食

Phase 1 QC 显示：

- 图片找到：12/12。
- 宏量营养基本合理：12/12。
- 0 纤维：12/12。
- 重复宏量指纹 >2：8/12。
- 需要人工 recipe QC：12/12。

解释：

这些餐食适合作为高风险候选，但必须用图片和原始记录确认真实配方，不能直接进入湿实验。

### 必做 3：开展 3-4 个餐食的仿生消化 pilot

目标：

- 验证 original vs redesigned 的 early glucose release 是否方向一致。
- 确定 glucose assay 动态范围、批次变异和重复性。

### 必做 4：形成主文图

建议主文图：

1. Figure 1：主线机制图。
2. Figure 2：NHANES DEHP oxidative profile -> MSI/HOMA/HbA1c。
3. Figure 3：CGMacros MSI -> PPGR vulnerability。
4. Figure 4：MSI-aware prediction and personalization。
5. Figure 5：bionic digestion original vs redesigned curves。

## 5. 当前结论

Phase 0-5 的干实验结果支持继续推进一篇高水平整合论文，但主张需要精准：

- 强证据：DEHP oxidative profile 与代谢易感性；MSI 与 PPGR vulnerability；MSI 提升预测/高反应识别。
- 中等证据：外部 CGM 数据支持 PPGR 异质性和餐食负荷/纤维方向。
- 弱证据：`meal load x MSI` 交互和消化机制，目前仍需仿生消化湿实验加强。

这意味着论文上限现在主要取决于陈晓东教授体外消化仿生系统能否证明 redesigned 餐食降低 early glucose release。R survey 正式复核这一关键统计门槛已经通过。
