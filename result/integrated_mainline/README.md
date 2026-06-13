# Integrated Mainline Analysis

Created: 2026-06-10

Mainline hypothesis:

Environmental-plasticizer-related metabolic susceptibility amplifies meal-induced postprandial glycemic vulnerability, and digestion-informed meal redesign can reduce that vulnerability.

## Stage Outputs

| Stage | Folder | Status | Main output |
|---|---|---|---|
| Stage 1 | `stage1_msi` | Completed | Shared MSI-core index for NHANES and CGMacros |
| Stage 2 | `stage2_nhanes_dehp_msi` | Completed | NHANES DEHP oxidative profile -> MSI/metabolic susceptibility |
| Stage 3 | `stage3_cgmacros_msi_ppgr` | Completed | CGMacros MSI-core -> PPGR vulnerability |
| Stage 4 | `stage4_prediction_personalization` | Completed | MSI-aware prediction and few-shot personalization benchmark |
| Stage 5 | `stage5_bionic_digestion_design` | Completed as dry-lab design | Candidate meals and bionic digestion protocol |

## Key Files

- `stage1_msi/stage1_msi_report_2026-06-10.md`
- `stage2_nhanes_dehp_msi/stage2_nhanes_dehp_msi_report_2026-06-10.md`
- `stage3_cgmacros_msi_ppgr/stage3_cgmacros_msi_ppgr_report_2026-06-10.md`
- `stage4_prediction_personalization/stage4_prediction_personalization_report_2026-06-10.md`
- `stage5_bionic_digestion_design/stage5_bionic_digestion_protocol_2026-06-10.md`

## Reproducible Scripts

- `scripts/15_integrated_stage1_build_msi_core.py`
- `scripts/16_integrated_stage2_nhanes_dehp_msi.py`
- `scripts/17_integrated_stage3_cgmacros_msi_ppgr.py`
- `scripts/18_integrated_stage4_prediction_personalization.py`
- `scripts/19_integrated_stage5_bionic_digestion_design.py`

## Interpretation Snapshot

Stage 2 supports the upstream population-level link:

`DEHP oxidative profile -> metabolic susceptibility`

Stage 3 supports the dynamic phenotype link:

`MSI-core -> higher PPGR and high-response risk`

Stage 4 suggests MSI is useful for risk stratification and modestly improves a transparent PPGR prediction benchmark, especially after few-shot personalization.

Stage 5 translates the dry-lab findings into a focused bionic digestion validation design.
