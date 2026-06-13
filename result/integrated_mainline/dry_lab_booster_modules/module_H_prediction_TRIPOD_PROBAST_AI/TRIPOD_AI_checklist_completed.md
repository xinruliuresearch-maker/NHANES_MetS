# Module H：TRIPOD+AI Checklist Draft

    日期：2026-06-10

    ## Prediction Question

    Predict meal-level 2h iAUC and 2h peak glucose excursion, and identify high-response meals, using deployable meal/pre-CGM/context features plus MSI.

    ## Completed Reporting Items

    | TRIPOD+AI domain | Status | Evidence file |
    |---|---|---|
    | Source data and setting | Complete | Stage 1/Phase 4 reports |
    | Eligibility and participants | Complete | `phase4_nested_lso_prediction_records.csv` |
    | Outcome definition | Complete | meal-level iAUC/peak definitions |
    | Predictor dictionary | Complete | `prediction_predictor_dictionary.csv` |
    | Missingness handling | Partial | needs final manuscript text |
    | Leakage audit | Complete | `prediction_leakage_audit.csv` |
    | Validation strategy | Complete | nested leave-subject-out |
    | Calibration | Complete | `phase4_calibration_deciles.csv` |
    | Discrimination/high-response | Complete | `prediction_model_performance_summary.csv` |
    | Uncertainty intervals | Complete | `prediction_conformal_interval_coverage.csv` |
    | Subgroup performance | Complete | `phase4_performance_by_msi.csv` |
    | Deployment limits | Complete | model card below |

    ## Key Performance Deltas

    - iauc_2h: M3_msi_enhanced minus M2_macro_precgm_context improved MAE by -155 (-7.2%), AUC delta 0.0741.
- iauc_2h: M3_msi_enhanced minus M0_carb_only improved MAE by -284 (-12.4%), AUC delta 0.159.
- peak_delta_2h: M3_msi_enhanced minus M2_macro_precgm_context improved MAE by -2.69 (-9.0%), AUC delta 0.0842.
- peak_delta_2h: M3_msi_enhanced minus M0_carb_only improved MAE by -4.88 (-15.2%), AUC delta 0.198.
