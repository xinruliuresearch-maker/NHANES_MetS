# Stage 3 报告：CGMacros MSI-core 与 PPGR vulnerability

日期：2026-06-10

## 目的

检验 Stage 1 构建的 `MSI-core` 是否在 CGMacros 中表现为餐后动态血糖脆弱性，即：

1. 高 MSI 个体是否有更高 PPGR。
2. MSI 是否放大餐食碳水负荷对 PPGR 的影响。
3. 高 MSI 个体是否更容易出现 high-response meals。

## 数据

- 餐食级样本：1498
- 受试者：40
- MSI 分层：数据集内部三分位 low / middle / high。

## MSI 分层描述

| MSI tertile | subjects | meals | median iAUC 2h | high iAUC rate | median peak delta |
|---|---:|---:|---:|---:|---:|
| low | 14 | 570 | 1792.6 | 0.184 | 34.3 |
| high | 13 | 447 | 2515.0 | 0.315 | 49.8 |

## 交互模型关键结果

模型形式：

`PPGR ~ carbs_10g + MSI-core + carbs_10g × MSI-core + pre-meal glucose + meal timing + context`

### 2h iAUC

- `carbs_10g`: 0.236 (0.181, 0.292), p=9.86e-17, q=<0.001, n=1480
- `MSI-core`: 1.170 (0.597, 1.742), p=6.23e-05, q=<0.001, n=1480
- `carbs_10g × MSI-core`: 0.041 (-0.012, 0.094), p=0.127, q=0.163, n=1480

### 2h peak delta

- `carbs_10g`: 3.343 (2.524, 4.163), p=1.3e-15, q=<0.001, n=1480
- `MSI-core`: 18.883 (10.551, 27.214), p=8.91e-06, q=<0.001, n=1480
- `carbs_10g × MSI-core`: 0.516 (-0.246, 1.277), p=0.184, q=0.229, n=1480

### High-response risk

- High iAUC `carbs_10g × MSI-core`: 0.003 (-0.006, 0.012), p=0.463, q=0.521, n=1480
- High peak `carbs_10g × MSI-core`: 0.007 (-0.001, 0.016), p=0.0977, q=0.135, n=1480

## 解释

Stage 3 的核心不是证明 DEHP 直接导致 PPGR，而是检验 NHANES 中定义的代谢易感性桥梁是否在 CGMacros 中表现为餐后动态血糖脆弱性。若 `MSI-core` 和 `carbs_10g × MSI-core` 为正，说明高代谢易感个体在面对更高碳水负荷时更容易产生高 PPGR，这正好连接 Stage 2 与 Stage 5。

## 输出文件

- `stage3_cgmacros_msi_ppgr_model_results.csv`
- `stage3_cgmacros_msi_ppgr_key_results.csv`
- `stage3_msi_tertile_ppgr_summary.csv`
- `stage3_cgmacros_msi_ppgr_report_2026-06-10.md`
