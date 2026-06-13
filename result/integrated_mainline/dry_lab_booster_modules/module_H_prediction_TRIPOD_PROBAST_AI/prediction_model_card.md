# Module H：Prediction Model Card

日期：2026-06-10

## Intended Use

Research-use model to stratify postprandial glycemic vulnerability and prioritize meals for redesign or bionic digestion validation.

## Not Intended For

Clinical diagnosis, medication adjustment, or patient-facing diet prescription without prospective validation.

## Inputs

Meal macros, meal timing, pre-meal CGM/wearable context, and baseline MSI. Optional food matrix features are currently dry-lab proxies.

## Outputs

Predicted 2h iAUC, predicted 2h peak glucose excursion, high-response flag, calibration and conformal interval summaries.

## Main Finding

MSI-enhanced models improved leave-subject-out performance relative to macro/pre-CGM/context models, especially for high-response discrimination.

## Fairness and Applicability

Subgroup performance by MSI is available. Demographic subgroup analyses remain limited by sample size.
