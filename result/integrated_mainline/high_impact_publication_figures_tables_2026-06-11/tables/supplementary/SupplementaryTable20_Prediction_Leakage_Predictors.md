| source_table | column | reason | dtype | missing_rate | feature_set | feature | type | description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| leakage | #1 Contour Fingerstick GLU | explicitly_forbidden | int64 | 0.0 |  |  |  |  |
| leakage | #2 Contour Fingerstick GLU | explicitly_forbidden | int64 | 0.0 |  |  |  |  |
| leakage | #3 Contour Fingerstick GLU | explicitly_forbidden | int64 | 0.0 |  |  |  |  |
| leakage | Collection time PDL (Lab) | explicitly_forbidden | str | 0.0 |  |  |  |  |
| leakage | Time (t) | explicitly_forbidden | str | 0.0 |  |  |  |  |
| leakage | Time (t).1 | explicitly_forbidden | str | 0.0 |  |  |  |  |
| leakage | Time (t).2 | explicitly_forbidden | str | 0.0 |  |  |  |  |
| leakage | amount_consumed | explicitly_forbidden | float64 | 0.0200267022696929 |  |  |  |  |
| leakage | amount_factor | explicitly_forbidden | float64 | 0.0193591455273698 |  |  |  |  |
| leakage | auc_2h | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | auc_3h | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | calories | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | carbs | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | fat | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | fiber | explicitly_forbidden | float64 | 0.000667556742323 |  |  |  |  |
| leakage | glucose_source | explicitly_forbidden | str | 0.0 |  |  |  |  |
| leakage | iauc_2h | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | iauc_3h | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | image_path | explicitly_forbidden | str | 0.0313751668891855 |  |  |  |  |
| leakage | n_post2h_points | explicitly_forbidden | int64 | 0.0 |  |  |  |  |
| leakage | n_pre_points | explicitly_forbidden | int64 | 0.0 |  |  |  |  |
| leakage | peak_delta_2h | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | peak_glucose_2h | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | protein | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| leakage | recovery_time_2h | explicitly_forbidden | float64 | 0.5200267022696929 |  |  |  |  |
| leakage | time_to_peak_2h | explicitly_forbidden | float64 | 0.0 |  |  |  |  |
| predictors |  |  |  |  | M2_deployable_core | eff_calories | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | eff_carbs | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | eff_protein | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | eff_fat | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | eff_fiber | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | baseline_glucose | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | pre_glucose_mean_30 | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | pre_glucose_sd_30 | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | pre_glucose_slope_60 | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | hr_mean_pre30 | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | activity_calories_pre30 | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | mets_mean_pre30 | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | meal_hour_sin | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | meal_hour_cos | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | prev_meal_gap_min | numeric | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M2_deployable_core | meal_type | categorical | meal + preprandial CGM + wearable/time |
| predictors |  |  |  |  | M3_clinical_enhanced | eff_calories | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | eff_carbs | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | eff_protein | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | eff_fat | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | eff_fiber | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | baseline_glucose | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | pre_glucose_mean_30 | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | pre_glucose_sd_30 | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | pre_glucose_slope_60 | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | hr_mean_pre30 | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | activity_calories_pre30 | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | mets_mean_pre30 | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | meal_hour_sin | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | meal_hour_cos | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | prev_meal_gap_min | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | Age | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | BMI | numeric | M2 + clinical baseline |
| predictors |  |  |  |  | M3_clinical_enhanced | Body weight | numeric | M2 + clinical baseline |
