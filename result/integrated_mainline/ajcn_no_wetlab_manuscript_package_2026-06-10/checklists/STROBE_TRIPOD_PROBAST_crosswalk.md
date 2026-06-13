# Reporting Checklist Crosswalk

## STROBE / STROBE-nut / STROBE-ME

- Study design, setting, data sources: addressed in Methods.
- Participants and dataset roles: Table 1.
- Variables and outcome definitions: Methods and source_data tables.
- Bias and limitations: Discussion and Supplementary Methods.
- Statistical methods: Methods; model outputs in Tables 2-5 and source_data.
- Nutritional exposure/meal annotation details: food-matrix proxy supplement and source_data.
- Molecular/environmental exposure details: NHANES DEHP oxidative profile Methods and Table 2.

## TRIPOD+AI / PROBAST+AI

- Intended use and non-use: Methods, Discussion, and prediction model card source file.
- Predictor and leakage audit: source_data/prediction_leakage_audit.csv.
- Performance metrics: Table 5.
- Calibration: Table 5 and source_data.
- Uncertainty intervals: source_data/prediction_conformal_interval_coverage.csv.
- External validation: not yet completed as a direct model validation; external datasets are boundary evidence only.
