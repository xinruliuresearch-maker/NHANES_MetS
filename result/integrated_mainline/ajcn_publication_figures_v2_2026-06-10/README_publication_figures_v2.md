# Publication Figure Redesign Notes

Generated: 2026-06-10T23:58:32

## Why this version replaces the first AJCN draft figures

The previous figure set was useful as a narrative sketch but too schematic for high-level peer review. The v2 set is built from actual run outputs and meal-level/source result tables:

- NHANES survey estimates, quartile dose-response summaries, and spline grids.
- CGMacros meal-level MSI/PPGR records and subject-level summaries.
- Food-matrix annotation records and curve-phenotype outputs.
- Leave-subject-out prediction records, calibration deciles, and model performance tables.
- External CGM transportability summaries and domain-shift metrics.

## Output formats

Each figure is exported as PDF, PNG, and TIFF at 600 dpi. PDF should be used for vector-first editing/submission when accepted; TIFF/PNG are included for journal upload or review decks.

## Design decisions

- English labels and compact panel titles suitable for AJCN submission.
- Colorblind-aware palette.
- Figure legends kept in a separate file rather than long in-figure text.
- Source data for each panel exported to `source_data/`.
- Raw distributions are shown where possible; iAUC and digestibility axes are clipped only for visual readability and source data retain complete values.

## Generated figures

- Figure1_NHANES: C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\ajcn_publication_figures_v2_2026-06-10\figures\Figure1_NHANES_exposure_response_publication_v2.pdf
- Figure2_CGMacros: C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\ajcn_publication_figures_v2_2026-06-10\figures\Figure2_CGMacros_MSI_PPGR_publication_v2.pdf
- Figure3_FoodMatrix_Curve: C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\ajcn_publication_figures_v2_2026-06-10\figures\Figure3_FoodMatrix_CurvePhenotypes_publication_v2.pdf
- Figure4_Prediction: C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\ajcn_publication_figures_v2_2026-06-10\figures\Figure4_Prediction_Calibration_publication_v2.pdf
- Figure5_ExternalBoundary: C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\ajcn_publication_figures_v2_2026-06-10\figures\Figure5_ExternalBoundary_publication_v2.pdf
