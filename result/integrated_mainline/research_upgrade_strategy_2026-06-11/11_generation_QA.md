# Research upgrade strategy QA

Generated: 2026-06-11 02:18:11

## File integrity

- Output directory: `C:\Users\liu12\OneDrive\Desktop\ShiYiSiNan_CGMacros\outputs\integrated_mainline\research_upgrade_strategy_2026-06-11`
- Mirror directory: `C:\Users\liu12\OneDrive\Desktop\NHANES_MetS_Project\result\integrated_mainline\research_upgrade_strategy_2026-06-11`
- Total planned files excluding README: 9
- Encoding: UTF-8 for Markdown and UTF-8 with BOM for CSV, so Excel on Windows can read Chinese headers and content.

## Web verification notes

- CGMacros was checked on PhysioNet. The page lists version 1.0.0, publication date January 28, 2025, 45 participants, dual CGM, macronutrients, food photographs, physical activity, blood analyses and gut microbiome profiles.
- CDC NHANES laboratory search page was checked. Urinary phthalates/plasticizer metabolites are available across multiple cycles including 2005-2006 through 2017-2018, and fasting glucose/insulin files are listed for relevant cycles.
- USDA FoodData Central was checked. The download page provides CSV and JSON releases, including April 2026 downloads for major data types.
- Stanford CGM Database was checked. It provides phenotype, CGM, lipid, metadata, metabolomics and Olink data files.
- EPA CompTox Chemicals Dashboard was checked. The page describes chemistry, toxicity and exposure information for over one million chemicals and batch/advanced search functions.

## Interpretation guardrail

The package intentionally recommends a triangulated cross-dataset bridge-phenotype design. It does not recommend claiming direct DEHP-to-PPGR causality or formal mediation without same-participant exposure and CGM data.
