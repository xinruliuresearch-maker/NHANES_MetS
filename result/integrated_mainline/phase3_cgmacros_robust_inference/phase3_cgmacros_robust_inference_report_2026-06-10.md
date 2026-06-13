# Phase 3 完成报告：CGMacros 稳健重复测量推断

    ## 已完成

    - 对 5 种 meal load 定义运行 subject-clustered OLS/LPM：carbs、available carbs、carb/fiber ratio、carb/protein ratio、energy。
    - 对 6 类结局运行模型：iAUC、peak、population high response、subject-specific high response、peak high response、absolute peak>=40。
    - 对 primary carbs model 做 500 次 subject bootstrap。
    - 做 leave-one-subject-out influence analysis。
    - 生成 subject-level MSI-PPGR summary，避免只依赖餐食级 p 值。

    ## Primary carbs model 快照

    | outcome_label | term | estimate_CI | p_value | q_value | n | n_clusters |
| --- | --- | --- | --- | --- | --- | --- |
| 2h iAUC / 1000 | carbs_10g | 0.180 (0.141, 0.219) | 8.139e-20 | 8.996e-19 | 1498 | 40 |
| 2h iAUC / 1000 | msi_centered | 1.070 (0.540, 1.599) | 7.46e-05 | 0.0001685 | 1498 | 40 |
| 2h iAUC / 1000 | load_x_msi | 0.042 (-0.011, 0.094) | 0.1231 | 0.1616 | 1498 | 40 |
| 2h peak delta | carbs_10g | 2.484 (1.908, 3.060) | 2.952e-17 | 2.583e-16 | 1498 | 40 |
| 2h peak delta | msi_centered | 17.356 (9.643, 25.069) | 1.032e-05 | 2.928e-05 | 1498 | 40 |
| 2h peak delta | load_x_msi | 0.488 (-0.275, 1.251) | 0.2103 | 0.2676 | 1498 | 40 |

    ## Subject-level 关联

    - MSI 与 subject median iAUC Spearman: 0.391
    - MSI 与 subject high iAUC rate Spearman: 0.476
    - MSI 与 subject median peak delta Spearman: 0.450

    ## 投稿判断

    如果 `msi_centered` 在 bootstrap 和 leave-one-subject-out 后仍稳定，则 CGMacros 主文应强调 MSI 是 PPGR vulnerability 的强风险分层变量。若 `load_x_msi` 仍方向一致但置信区间跨 0，则主文应谨慎写为 directional effect modification evidence，而不是确定性交互结论。
