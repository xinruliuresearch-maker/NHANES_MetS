# Stage Progress Log

Date: 2026-06-10

## Stage 1: MSI-core

Completed.

Generated a shared metabolic susceptibility index using BMI, HbA1c, fasting glucose, ln(HOMA-IR), and ln(TG/HDL-C). MSI excludes DEHP/phthalate variables.

Key result:

- NHANES partial MSI available for 2491 participants; complete MSI for 2368.
- CGMacros MSI available for 40/40 subjects.
- CGMacros has higher NHANES-referenced MSI median than NHANES, supporting its use as a metabolically enriched PPGR cohort.

## Stage 2: NHANES DEHP -> MSI

Completed using Python WLS with NHANES weights and stratum-PSU cluster-robust SE.

Key result:

- `%Oxidative per 10 pp -> MSI-core`: positive.
- `ln(Oxidative/MEHP) -> MSI-core`: positive and FDR-significant.
- Direction is consistent for HOMA-IR, HbA1c, TyG, and TG/HDL-C.

Note:

- Before submission, rerun final NHANES models in R survey design if an R environment is available.

## Stage 3: CGMacros MSI -> PPGR

Completed using meal-level models with subject-clustered SE.

Key result:

- High MSI tertile has higher median iAUC and higher high-iAUC meal rate than low MSI tertile.
- MSI-core is independently associated with iAUC, peak delta, and high-response risk.
- `carbs x MSI` is positive but not consistently significant; treat as supportive, not the central claim.

## Stage 4: MSI-aware Prediction and Personalization

Completed using numpy ridge leave-subject-out benchmark.

Key result:

- Adding MSI features modestly improves MAE across MSI strata.
- High MSI group shows continued improvement after few-shot recalibration.
- Use this as a transparent mainline benchmark; existing ensemble models remain stronger methodologically but should be re-run later with MSI-aware stratified reporting.

## Stage 5: Bionic Digestion Design

Completed as dry-lab experimental design.

Generated:

- 12 candidate CGMacros meals for bionic digestion validation.
- 24 original/redesigned experiment groups.
- 72 total technical experimental units if each group has 3 replicates.

Key observation:

- Many top candidates share high-carbohydrate, zero-fiber, high-PPGR structure, making them suitable prototypes for testing fiber/resistant-starch or carbohydrate-capping redesigns.

## Next Priority

1. Visually inspect candidate meal images and reconstruct recipes.
2. Re-run Stage 3/4 after excluding questionable food-entry outliers and after confirming meal identities.
3. Build manuscript-ready Figure 1-5 from the stage outputs.
4. Prepare bionic digestion SOP and sample preparation sheet for experimental collaborators.
