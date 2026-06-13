# Formal dry-lab strengthening report

Generated: 2026-06-11T14:05:23

## Module status

1. R formal NHANES mixture rerun: completed for survey GLM, RCS, qgcomp identifiable derived mixtures, negative controls, and quantitative bias grid. Weighted gWQS and BKMR MCMC are retained as long-run blocks because they exceeded interactive runtime.
2. Non-glycemic MSI: completed using BMI and ln(TG/HDL) only, excluding HbA1c, fasting glucose, insulin/HOMA-IR, and TyG.
3. CGMacros subject-disjoint prediction and cluster-robust hierarchical inference: completed with non-glycemic MSI and food-matrix features.
4. Food-matrix annotation: AI/rule-based dual prelabels, manual dual-annotation template, codebook v2, and FDC item-level proxy matches completed. This is not claimed as final human annotation.
5. External CGM validation: D1NAMO meal-level T1D boundary validation and Jaeb healthy-adult day-level CGM variability validation completed.
6. Mechanism layer: CompTox/ToxCast query manifest and GEO toxicogenomics candidate search completed, integrated with existing CTD/KEGG/Reactome evidence.

## Key computational findings

- CGMacros non-glycemic MSI best iAUC model: non_glycemic_msi_foodmatrix R2=-0.271, r=0.222, n=1498.
- CGMacros non-glycemic MSI best peak model: non_glycemic_msi_foodmatrix R2=-0.302, r=0.245, n=1498.
- Dual prelabel food-matrix agreement: kappa=0.336, agreement=0.513, meals needing manual review=730.
- FDC item-level proxy matching: assigned 0/1498 meals, median confidence=nan.
- D1NAMO external meal-level boundary validation records: 78 iAUC meals summarized.
- Jaeb healthy-adult CGM variability boundary records: 169 subjects in correlation summaries.

## Interpretation guardrails

- The non-glycemic MSI strengthens the argument against circularity, but it is narrower and should be presented as a conservative sensitivity index rather than the primary MSI.
- Automated dual prelabels are useful for triage and reproducibility, but final publication should still use true blinded human ratings for meals flagged as uncertain.
- D1NAMO is insulin-treated T1D data; it can stress-test PPGR feature extraction and food-matrix directionality but cannot be described as healthy-adult replication.
- Jaeb has no meal events; it supports CGM variability transportability only.
- CompTox/ToxCast currently adds a reproducible query layer. Assay-level claims require API-key/flat-file extraction.

## Non-glycemic MSI inference terms

- iauc_2h / non_glycemic_msi: beta=206.187, p=0.372, q=0.496.
- iauc_2h / non_glycemic_x_rapid: beta=10.562, p=0.901, q=0.901.
- peak_delta_2h / non_glycemic_msi: beta=3.953, p=0.236, q=0.283.
- peak_delta_2h / non_glycemic_x_rapid: beta=0.053, p=0.966, q=0.966.