# A phthalate oxidative-metabolism profile, metabolic susceptibility, and postprandial glycemic vulnerability

**Running title:** Environmental metabolic susceptibility and postprandial glycemia

**Authors:** [Author names to be completed]

**Affiliations:** [Institutional affiliations to be completed]

**Corresponding author:** [Name, address, email, telephone to be completed]

**Funding:** [Funding sources to be completed]

**Conflicts of interest:** [Conflict-of-interest statement to be completed]

**Data sharing:** NHANES data are publicly available from CDC/NCHS. CGMacros raw data and third-party CGM datasets are subject to their original access terms. Derived de-identified tables can be shared where permitted.

**Clinical trial registration:** Not applicable; secondary analysis of existing observational datasets.

**Keywords:** DEHP; phthalates; continuous glucose monitoring; postprandial glycemia; precision nutrition; insulin resistance; NHANES.


## Abstract

**Background:** Postprandial glycemic responses are highly individualized, but few human studies connect environmental metabolic-disruptor profiles with dynamic continuous glucose monitoring (CGM) phenotypes.

**Objectives:** We tested whether a DEHP oxidative-metabolite profile was associated with a metabolic susceptibility phenotype in NHANES and whether the same phenotype identified greater postprandial glycemic vulnerability in CGMacros.

**Methods:** We conducted an integrated computational analysis of NHANES 2013-2018, CGMacros, and three external CGM datasets. A Metabolic Susceptibility Index (MSI) summarized adiposity, glycemia, insulin resistance, and lipid risk. In NHANES, survey-weighted models related urinary DEHP oxidative profile measures to MSI and metabolic markers. In CGMacros, subject-clustered meal-level models related MSI to 2-h incremental area under the glucose curve (iAUC), peak glucose excursion, high-response indicators, food-matrix proxy features, curve phenotypes, and nested prediction models. External datasets were used to define transportability boundaries.

**Results:** In NHANES, ln(oxidative DEHP metabolites/MEHP) was associated with MSI-core (beta 0.183 (0.109, 0.257); q=0.003), ln(HOMA-IR) (beta 0.218 (0.129, 0.308); q=0.003), and HbA1c (beta 0.135 (0.079, 0.190); q=0.003). In CGMacros (40 participants; 1498 meals), higher MSI was associated with greater 2-h iAUC/1000 (beta 1.070 (0.540, 1.599); q=1.99e-04) and peak excursion (beta 17.356 (9.643, 25.069); q=3.54e-05). High versus low MSI tertiles had higher mean iAUC (3686.1 vs 2543.1 mg/dL x min) and peak excursion (60.4 vs 43.4 mg/dL). Exploratory food-matrix analyses showed positive MSI x digestibility-risk interactions for iAUC/1000 (beta 0.410 (0.216, 0.605); q=1.18e-04) and peak excursion (beta 4.988 (2.664, 7.313); q=1.04e-04). MSI-enhanced prediction improved iAUC and peak high-response discrimination relative to macro/pre-CGM context models.

**Conclusions:** A DEHP oxidative-metabolism profile was associated with metabolic susceptibility in NHANES, and this susceptibility phenotype was expressed as higher CGM-measured postprandial glycemic vulnerability in CGMacros. These findings support a susceptibility-aware precision-nutrition framework but require prospective and mechanistic validation before causal or clinical claims.


## Introduction

Postprandial glycemic response (PPGR) is a dynamic phenotype that varies markedly across individuals even for similar foods. CGM-based cohorts have shown that meal composition, timing, baseline physiology, and interindividual susceptibility jointly shape glycemic excursions. This heterogeneity motivates precision-nutrition models that move beyond average carbohydrate effects toward identifying who is vulnerable to which meal contexts.

Environmental metabolic disruptors may contribute to the biological background on which meal responses occur. Di(2-ethylhexyl) phthalate (DEHP) metabolites have been associated with obesity, insulin resistance, and diabetes-related markers in population studies. However, population exposure studies rarely connect environmental profiles to dynamic CGM endpoints, whereas CGM studies rarely include detailed environmental exposure biomarkers. A direct one-dataset test of DEHP exposure and PPGR is therefore not available in the present data resources.

We addressed this gap by using a bridge phenotype: a Metabolic Susceptibility Index (MSI) derived from adiposity, glycemic, insulin-resistance, and lipid-risk markers. The core hypothesis was not that DEHP directly causes higher CGM responses, but that a DEHP oxidative-metabolism profile is associated with a metabolic susceptibility phenotype in NHANES and that the same phenotype is expressed as higher PPGR vulnerability in CGMacros.

## Methods

### Study design and evidence layers

This was an integrated dry-lab analysis combining population survey, free-living CGM meal, and external CGM boundary evidence. The analysis followed a prespecified no-wet-lab scope: no in vitro digestion or bionic digestion data were used. The primary evidence layers were: 1) NHANES 2013-2018 for DEHP oxidative profile and metabolic susceptibility; 2) CGMacros for MSI and meal-level PPGR; 3) dry-lab food-matrix proxy annotation and CGM curve phenotypes for mechanistic refinement; and 4) external CGM datasets for transportability boundaries.

### Data sources

NHANES 2013-2018 contributed urinary DEHP metabolites and metabolic phenotypes. CGMacros contributed 40 participants and 1498 free-living meals with CGM-derived outcomes. External datasets included Stanford CGMDB standardized food challenges, T1D-UOM free-living meals from individuals with type 1 diabetes, and Jaeb CGMND healthy-adult CGM readings. Dataset roles and sample sizes are summarized in Table 1.

### Metabolic Susceptibility Index

MSI summarized BMI, HbA1c, fasting glucose, ln(HOMA-IR), and ln(TG/HDL-C). The primary MSI was a partial index designed to maximize available samples. Sensitivity indices included PCA-based MSI, MSI without BMI, and glycemia/insulin-resistance variants. The primary analyses used centered MSI values. Previous robustness checks showed near-identical behavior between MSI-core and PCA versions in both NHANES and CGMacros.

### DEHP oxidative profile in NHANES

Urinary DEHP metabolite features included MEHP and oxidative DEHP metabolites. The primary exposure was ln(oxidative DEHP metabolites/MEHP), interpreted as an oxidative metabolite profile. A secondary exposure was oxidative metabolite fraction per 10 percentage points. NHANES analyses used survey-weighted regression models and reported beta estimates, 95% CIs, P values, and false-discovery-rate q values.

### CGMacros meal-level outcomes

CGMacros outcomes included 2-h iAUC, 2-h peak glucose excursion, high-iAUC and high-peak top-quartile indicators, food-matrix/digestibility-risk proxy scores, and curve-shape phenotypes. Meal-level models used subject-clustered inference. Primary covariates included carbohydrate load and centered MSI; interaction models tested carbohydrate load x MSI. Food-matrix models tested MSI, digestibility-risk proxy score, and MSI x digestibility-risk score.

### Prediction analysis

Nested prediction models evaluated whether MSI improved meal-level risk stratification beyond carbohydrate-only, macro/timing, and macro/pre-CGM/context models. Performance metrics included MAE, RMSE, R2, calibration slope, AUC and AUPRC for high-response flags, and decision-curve net benefit at a threshold probability of 0.25. These models are for research-use stratification and are not clinical decision tools.

### Reporting standards

This package was organized to support AJCN-style submission and to align with STROBE, STROBE-nut, STROBE-ME, TRIPOD+AI, and PROBAST+AI expectations where applicable. Checklist drafts are provided in the supplement folder.

## Results

### Dataset overview

The integrated analysis included NHANES 2013-2018, CGMacros, Stanford CGMDB, T1D-UOM, and Jaeb CGMND healthy adults (Table 1). MSI was available for all 40 CGMacros participants and for the NHANES analytic subset used for the susceptibility phenotype. External datasets were not used to claim direct replication of the DEHP-MSI-CGM path; they were used to understand context, heterogeneity, and boundary conditions.

### DEHP oxidative profile was associated with metabolic susceptibility in NHANES

Survey-weighted NHANES models showed that ln(oxidative DEHP metabolites/MEHP) was positively associated with MSI-core (beta 0.183 (0.109, 0.257); q=0.003), ln(HOMA-IR) (beta 0.218 (0.129, 0.308); q=0.003), and HbA1c (beta 0.135 (0.079, 0.190); q=0.003) (Table 2; Figure 2). The oxidative metabolite fraction per 10 percentage points also showed a positive association with MSI-core (beta 0.168 (0.072, 0.265); q=0.016). These results support an exposure-profile-to-susceptibility association, while remaining observational and noncausal.

### MSI identified higher postprandial glycemic vulnerability in CGMacros

In CGMacros, higher centered MSI was associated with higher 2-h iAUC/1000 (beta 1.070 (0.540, 1.599); q=1.99e-04) and higher 2-h peak excursion (beta 17.356 (9.643, 25.069); q=3.54e-05) after accounting for carbohydrate load (Table 3). High versus low MSI tertiles had higher mean iAUC (3686.1 vs 2543.1 mg/dL x min) and peak excursion (60.4 vs 43.4 mg/dL) (Figure 3). The simple carbohydrate load x MSI interaction was positive but not definitive because the confidence interval crossed zero; therefore the primary interpretation is a robust MSI main effect rather than a proven load-specific effect modification.

### Food-matrix proxy and curve phenotypes refined the vulnerability signal

Exploratory food-matrix models suggested that high-MSI participants were especially vulnerable to high digestibility-risk meal contexts. MSI x digestibility-risk interactions were positive for iAUC/1000 (beta 0.410 (0.216, 0.605); q=1.18e-04) and peak excursion (beta 4.988 (2.664, 7.313); q=1.04e-04) (Table 4; Figure 4). Curve-phenotype analysis identified a large prolonged-response cluster with 215 meals, mean iAUC 8963.3 mg/dL x min, and mean peak excursion 129.8 mg/dL, characterized by higher MSI and digestibility-risk scores. These food-matrix features are proxy annotations and should be interpreted as hypothesis-generating rather than direct digestion kinetics.

### MSI-enhanced models improved within-CGMacros high-response prediction

The MSI-enhanced model improved within-CGMacros prediction compared with macro/pre-CGM context models. For iAUC, the M3 MSI-enhanced model had MAE 2011.3, R2 0.255, AUC 0.762, and AUPRC 0.520; relative to M2, MAE changed by -7.2% and AUC increased by 0.074. For peak excursion, M3 had MAE 27.1, R2 0.318, AUC 0.787, and AUPRC 0.571; relative to M2, MAE changed by -9.0% and AUC increased by 0.084 (Table 5; Figure 5). External datasets supported PPGR heterogeneity and macro-response directionality but also highlighted transportability limits.

## Discussion

This integrated analysis supports a coherent susceptibility-aware framework linking population environmental metabolic profiles, baseline metabolic susceptibility, and dynamic CGM-measured meal responses. In NHANES, DEHP oxidative profile measures were associated with MSI and related metabolic markers. In CGMacros, the same MSI phenotype identified individuals with greater postprandial glycemic vulnerability and improved high-response meal prediction.

The most important conceptual contribution is the bridge-phenotype design. Because no current dataset simultaneously contains urinary DEHP metabolites and detailed free-living CGM meal responses, a direct DEHP-to-PPGR model would overstate the evidence. Instead, the evidence chain is explicitly staged: DEHP oxidative profile to MSI in NHANES, and MSI to PPGR in CGMacros. This approach is more conservative but also more biologically interpretable, because MSI captures the metabolic state likely to modify or express meal vulnerability.

The food-matrix analysis adds a second advance. Simple carbohydrate load x MSI interactions were not definitive, but the digestibility-risk proxy produced stronger interactions with MSI across iAUC, peak excursion, and dynamic curve phenotypes. This suggests that meal vulnerability is better conceptualized as a person-by-matrix interaction than as a person-by-carbohydrate interaction alone. The present score remains a dry-lab proxy, so the finding should guide subsequent expert-coded food annotation, prospective validation, or controlled digestion work rather than be treated as established digestive mechanism.

The prediction results are promising for research-use stratification. MSI improved discrimination and error metrics within CGMacros, especially for high-response identification. However, the CGMacros sample was modest, external datasets differed in design and population, and the current model is not a clinical tool. TRIPOD+AI and PROBAST+AI materials in this package identify leakage controls, calibration summaries, conformal interval coverage, and residual validation gaps.

Several limitations are central. First, the design is observational and cross-dataset; causal claims about DEHP and PPGR are not supported. Second, MSI is a susceptibility phenotype and not a proven mediator. Third, food-matrix features are proxy annotations and require expert validation. Fourth, CGMacros includes only 40 participants, limiting demographic subgroup analysis and external generalizability. Fifth, urinary phthalate metabolites can reflect recent exposure, metabolism, and shared lifestyle/diet sources, and negative-control-like analyses cannot fully remove residual confounding.

In conclusion, DEHP oxidative-metabolism profile was associated with metabolic susceptibility in NHANES, and this susceptibility phenotype was expressed as higher postprandial glycemic vulnerability in CGMacros. The study provides a high-level dry-lab manuscript foundation for an AJCN-style submission, with the next priority being expert food-matrix validation, prospective external validation, and, if desired later, mechanistic digestion experiments.

## Acknowledgments

[To be completed: author contributions, funding, data access acknowledgments, and any institutional support.]

## Data Availability

NHANES data are publicly available from CDC/NCHS. CGMacros raw data are stored locally for this project and require permission or appropriate data-sharing review before public release. External datasets retain their original access terms and licenses. Derived, de-identified tables that do not violate source dataset terms can be shared with the manuscript repository.

## Code Availability

Analysis scripts will be made available in a public repository at publication, excluding protected raw data and files restricted by third-party dataset licenses. The reproducibility manifest records generated analysis files and source modules.

## References

1. Zeevi D, Korem T, Zmora N, et al. Personalized Nutrition by Prediction of Glycemic Responses. Cell. 2015;163:1079-1094.
2. Berry SE, Valdes AM, Drew DA, et al. Human postprandial responses to food and potential for precision nutrition. Nat Med. 2020;26:964-973.
3. Stahlhut RW, van Wijngaarden E, Dye TD, Cook S, Swan SH. Concentrations of urinary phthalate metabolites are associated with increased waist circumference and insulin resistance in adult U.S. males. Environ Health Perspect. 2007;115:876-882.
4. James-Todd T, Stahlhut R, Meeker JD, et al. Urinary phthalate metabolite concentrations and diabetes among women in NHANES 2001-2008. Environ Health Perspect. 2012;120:1307-1313.
5. Centers for Disease Control and Prevention, National Center for Health Statistics. National Health and Nutrition Examination Survey data and documentation.
6. von Elm E, Altman DG, Egger M, et al. The STROBE statement: guidelines for reporting observational studies. Lancet. 2007;370:1453-1457.
7. Lachat C, Hawwash D, Ocke MC, et al. STROBE-nut: An extension of the STROBE statement for nutritional epidemiology. PLoS Med. 2016;13:e1002036.
8. Gallo V, Egger M, McCormack V, et al. STROBE-ME: An extension of the STROBE statement for molecular epidemiology. PLoS Med. 2011;8:e1001117.
9. Moons KGM, Altman DG, Reitsma JB, et al. Transparent Reporting of a multivariable prediction model for Individual Prognosis Or Diagnosis (TRIPOD). Ann Intern Med. 2015;162:55-63.
10. Collins GS, Dhiman P, Andaur Navarro CL, et al. Protocol and reporting guidance for prediction models using artificial intelligence: TRIPOD+AI and PROBAST+AI resources. [Bibliographic details to be verified before submission.]

## Figure Legends

**Figure 1. Integrated no-wet-lab study framework.** The study used a bridge-phenotype design linking NHANES DEHP oxidative metabolite profile to MSI, then testing whether MSI was expressed as CGM-measured meal vulnerability in CGMacros. External datasets were used for boundary evidence.

**Figure 2. NHANES DEHP oxidative profile and metabolic susceptibility.** Survey-weighted beta estimates and 95% CIs for associations of ln(oxidative DEHP metabolites/MEHP) and oxidative metabolite fraction with MSI and metabolic markers.

**Figure 3. CGMacros MSI tertiles and postprandial glycemic response.** Meal-level summaries of mean 2-h iAUC, mean 2-h peak excursion, and high-response rates across participant MSI tertiles.

**Figure 4. Food-matrix susceptibility and CGM curve phenotypes.** Panel A shows exploratory MSI x digestibility-risk proxy interactions. Panel B maps curve-shape clusters by mean iAUC and peak excursion, with point size reflecting meal count and color reflecting mean MSI.

**Figure 5. Prediction performance and external boundary evidence.** Prediction performance for nested CGMacros models and external CGM context used to assess transportability boundaries.

## Tables

### Table 1. Dataset and phenotype summary

| Dataset | Role in integrated analysis | Participants | Meals/events/readings | MSI available | Median MSI | High MSI tertile |
| --- | --- | --- | --- | --- | --- | --- |
| NHANES 2013-2018 | MSI construction / internal analysis | 5267 |  | 2491 | -0.101 | 830 |
| CGMacros | MSI construction / internal analysis | 40 | 1498 | 40 | 0.325 | 13 |
| Stanford CGMDB | standardized food challenges | 38 | 588 |  |  |  |
| T1D-UOM | T1D logged meals | 15 | 3820 |  |  |  |
| Jaeb CGMND healthy adults | healthy adult CGM readings | 169 | 383117 |  |  |  |

### Table 2. NHANES survey-weighted DEHP oxidative profile results

| Outcome | Exposure | Beta (95% CI) | P | Q |
| --- | --- | --- | --- | --- |
| MSI PCA | ln(oxidative DEHP metabolites/MEHP) | 0.157 (0.100, 0.213) | 2.83e-04 | 0.003 |
| MSI core | ln(oxidative DEHP metabolites/MEHP) | 0.183 (0.109, 0.257) | 5.03e-04 | 0.003 |
| ln(HOMA-IR) | ln(oxidative DEHP metabolites/MEHP) | 0.218 (0.129, 0.308) | 5.52e-04 | 0.003 |
| MSI without BMI | ln(oxidative DEHP metabolites/MEHP) | 0.172 (0.100, 0.244) | 6.71e-04 | 0.003 |
| HbA1c | ln(oxidative DEHP metabolites/MEHP) | 0.135 (0.079, 0.190) | 8.14e-04 | 0.003 |
| MSI core | Oxidative metabolite fraction, per 10 pp | 0.168 (0.072, 0.265) | 0.006 | 0.016 |
| MSI without BMI | Oxidative metabolite fraction, per 10 pp | 0.168 (0.070, 0.267) | 0.006 | 0.016 |
| ln(HOMA-IR) | Oxidative metabolite fraction, per 10 pp | 0.182 (0.074, 0.290) | 0.007 | 0.016 |
| MSI PCA | Oxidative metabolite fraction, per 10 pp | 0.105 (0.038, 0.173) | 0.012 | 0.023 |
| HbA1c | Oxidative metabolite fraction, per 10 pp | 0.110 (0.033, 0.186) | 0.019 | 0.030 |

### Table 3. CGMacros meal-level MSI and PPGR models

| Outcome | Term | Estimate (95% CI) | Q | N meals | N participants | Unit |
| --- | --- | --- | --- | --- | --- | --- |
| 2-h iAUC /1000 | Carbohydrate load, per 10 g | 0.180 (0.141, 0.219) | 1.95e-18 | 1498 | 40 | 1000 mg/dL*min |
| 2-h iAUC /1000 | MSI, centered | 1.070 (0.540, 1.599) | 1.99e-04 | 1498 | 40 | 1000 mg/dL*min |
| 2-h iAUC /1000 | Carbohydrate load x MSI | 0.042 (-0.011, 0.094) | 0.161 | 1498 | 40 | 1000 mg/dL*min |
| 2-h peak delta | Carbohydrate load, per 10 g | 2.484 (1.908, 3.060) | 5.31e-16 | 1498 | 40 | mg/dL |
| 2-h peak delta | MSI, centered | 17.356 (9.643, 25.069) | 3.54e-05 | 1498 | 40 | mg/dL |
| 2-h peak delta | Carbohydrate load x MSI | 0.488 (-0.275, 1.251) | 0.252 | 1498 | 40 | mg/dL |
| High iAUC risk | Carbohydrate load, per 10 g | 0.021 (0.013, 0.028) | 6.39e-07 | 1498 | 40 | risk difference |
| High iAUC risk | MSI, centered | 0.129 (0.063, 0.195) | 2.93e-04 | 1498 | 40 | risk difference |
| High iAUC risk | Carbohydrate load x MSI | 0.004 (-0.006, 0.013) | 0.513 | 1498 | 40 | risk difference |
| High peak risk | Carbohydrate load, per 10 g | 0.018 (0.011, 0.025) | 2.39e-06 | 1498 | 40 | risk difference |
| High peak risk | MSI, centered | 0.131 (0.063, 0.198) | 3.62e-04 | 1498 | 40 | risk difference |
| High peak risk | Carbohydrate load x MSI | 0.007 (-0.002, 0.015) | 0.165 | 1498 | 40 | risk difference |

### Table 4. Food-matrix and curve-phenotype extensions

| Analysis block | Outcome | Term | Estimate (95% CI) | Q | N meals |
| --- | --- | --- | --- | --- | --- |
| food matrix ppgr | 2h iAUC /1000 | MSI, centered | 1.288 (0.654, 1.923) | 2.14e-04 | 1497 |
| food matrix ppgr | 2h iAUC /1000 | Digestibility-risk score, centered | 0.388 (0.239, 0.537) | 2.88e-06 | 1497 |
| food matrix ppgr | 2h iAUC /1000 | MSI x digestibility-risk score | 0.410 (0.216, 0.605) | 1.18e-04 | 1497 |
| food matrix ppgr | 2h peak delta | MSI, centered | 20.290 (11.919, 28.662) | 1.16e-05 | 1497 |
| food matrix ppgr | 2h peak delta | Digestibility-risk score, centered | 4.113 (2.168, 6.057) | 1.18e-04 | 1497 |
| food matrix ppgr | 2h peak delta | MSI x digestibility-risk score | 4.988 (2.664, 7.313) | 1.04e-04 | 1497 |
| curve phenotype | early_slope_proxy_0_to_peak | MSI x digestibility-risk score | 0.058 (0.013, 0.103) | 0.042 | 1417 |
| curve phenotype | delayed_peak_flag | MSI x digestibility-risk score | 0.039 (0.018, 0.060) | 0.002 | 1498 |
| curve phenotype | prolonged_elevation_flag | MSI x digestibility-risk score | 0.034 (0.019, 0.049) | 9.17e-05 | 1498 |
| curve phenotype | low_stable_response_flag | MSI x digestibility-risk score | -0.003 (-0.021, 0.014) | 0.858 | 1498 |

### Table 5. Prediction model performance

| Target | Model | MAE | R2 | AUC high response | AUPRC high response | Calibration slope | Net benefit, pt=0.25 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2h iAUC | M0_carb_only | 2294.8 | 0.040 | 0.603 | 0.310 | 0.887 | 0.000 |
| 2h iAUC | M2_macro_precgm_context | 2166.3 | 0.150 | 0.688 | 0.418 | 0.902 | 0.052 |
| 2h iAUC | M3_msi_enhanced | 2011.3 | 0.255 | 0.762 | 0.520 | 0.931 | 0.080 |
| 2h peak delta | M0_carb_only | 32.0 | 0.046 | 0.589 | 0.298 | 0.910 | 0.001 |
| 2h peak delta | M2_macro_precgm_context | 29.8 | 0.189 | 0.703 | 0.426 | 0.923 | 0.058 |
| 2h peak delta | M3_msi_enhanced | 27.1 | 0.318 | 0.787 | 0.571 | 0.963 | 0.094 |
