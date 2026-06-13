# Stage 4 报告：MSI-aware PPGR prediction and personalization

日期：2026-06-10

## 目的

检验加入 `MSI-core` 后是否改善 PPGR 预测、校准和少样本个体化，尤其是高 MSI 个体。

## 方法

由于当前 Python 环境无 `sklearn`，本阶段使用纯 numpy 实现 ridge regression，并采用 leave-subject-out 验证。

模型阶梯：

- M1: macro + meal timing
- M2: M1 + pre-CGM/activity context
- M3: M2 + MSI-core / HOMA-IR / TG-HDL 等代谢易感性特征
- M4: 对 M2/M3 进行 0/1/3/5/10-shot subject-specific recalibration

## 关键结果快照：2h iAUC

- Low MSI, 0-shot: M2 MAE=2102.2, M3 MAE=1797.5, delta=-304.7 (-14.5%), n=570
- High MSI, 0-shot: M2 MAE=2546.9, M3 MAE=2459.9, delta=-87.0 (-3.4%), n=447
- High MSI, 10-shot: M2 MAE=2186.4, M3 MAE=2047.3, delta=-139.1 (-6.4%), n=317

## 如何解释

Stage 4 的主线问题是：MSI 是否提升模型对 PPGR vulnerability 的识别，以及高 MSI 个体是否更需要少样本个体化。若 M3 在高 MSI 组降低 MAE 或改善 calibration slope，可作为主文证据；若改善不稳定，也仍可报告为“MSI 是强风险分层变量，但进入简单线性模型后的预测增益有限”，将重点放在分层风险和个体化收益。

## 输出文件

- `stage4_global_prediction_records.csv`
- `stage4_fewshot_prediction_records.csv`
- `stage4_performance_by_msi.csv`
- `stage4_msi_model_comparison.csv`
- `stage4_prediction_personalization_report_2026-06-10.md`
