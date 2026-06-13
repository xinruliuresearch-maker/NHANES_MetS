# Module C：CGMacros 餐食结构与食品加工特征

日期：2026-06-10

## 注释类型

当前版本为 dry-lab proxy annotation，基于已记录的 calories/carbs/protein/fat/fiber、meal type、Stage 5 候选餐食和图片路径完整性生成。它不是最终人工图像标注。

## 关键变量

- `available_carbs_g`：carbs - fiber，下限为 0。
- `carb_fiber_ratio_capped`：碳水/纤维比，0 纤维时用 carbs+1 代理，并截断到 80。
- `refined_starch_proxy`：carbs >=45 g 且 fiber <=3 g。
- `liquid_carb_proxy`：低能量、高碳水、低蛋白、低脂的饮料/液体碳水代理。
- `high_fat_high_carb_matrix`：carbs >=45 g 且 fat >=20 g。
- `estimated_NOVA_proxy`：基于高脂高碳水/低纤维/加工代理的粗略 NOVA 估计。
- `gi_proxy` 与 `glycemic_load_proxy`：用于排序和模型敏感性，不等同于真实 GI。
- `digestibility_risk_score`：整合 available carbs、碳纤比、精制/液体/甜食/高脂高碳水代理，并扣除可见纤维和蛋白共摄入。

## 论文使用边界

可以作为 food matrix proxy 和实验选餐依据；如果进入主文结论，需用人工图片标注或 USDA/Sydney GI/Open Food Facts 进一步校正。
