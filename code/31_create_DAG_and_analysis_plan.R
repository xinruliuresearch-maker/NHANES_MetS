# ============================================================
# NHANES DEHP-Metabolic Outcomes Study
# 31_create_DAG_and_analysis_plan.R
# DAG and causal analysis plan
# ============================================================

library(dplyr)
library(tibble)
library(writexl)
library(readr)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")
dag_dir <- file.path(result_dir, "dag")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(dag_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. DAG nodes
# ------------------------------------------------------------

dag_nodes <- tibble::tribble(
  ~node, ~label, ~role, ~description,
  "DEHP", "DEHP exposure", "Exposure", "Urinary DEHP metabolites, Sigma DEHP, and oxidative metabolite profile",
  "MetabolicOutcome", "Metabolic outcomes", "Outcome", "HOMA-IR, HbA1c, obesity-related outcomes",
  "Age", "Age", "Confounder", "Age affects exposure behavior and metabolic risk",
  "Sex", "Sex", "Confounder/effect modifier", "Sex affects exposure patterns, metabolism, and insulin resistance",
  "RaceEthnicity", "Race/ethnicity", "Confounder", "Race/ethnicity relates to socioeconomic factors, exposure, and metabolic risk",
  "SES", "Socioeconomic status", "Confounder", "Income and education influence consumer product exposure and metabolic health",
  "Diet", "Dietary intake", "Confounder", "Energy intake and food packaging may influence exposure and metabolic outcomes",
  "PhysicalActivity", "Physical activity", "Confounder", "Physical activity affects obesity and insulin resistance; may relate to lifestyle exposure",
  "Smoking", "Smoking", "Confounder", "Smoking relates to exposure sources and metabolic risk",
  "Alcohol", "Alcohol", "Confounder", "Alcohol relates to liver metabolism and metabolic outcomes",
  "UrineDilution", "Urine dilution", "Measurement factor", "Urinary creatinine and urine concentration affect biomarker measurement",
  "KidneyFunction", "Kidney function", "Potential confounder/selection factor", "Renal function affects urinary biomarker excretion and metabolic risk",
  "Inflammation", "Inflammation", "Potential mediator/marker", "Inflammatory markers may lie on pathway from exposure to insulin resistance",
  "LiverMetabolism", "Liver metabolism", "Potential mediator/marker", "Liver enzymes and fatty liver tendency may lie on metabolic pathway",
  "BMI", "Adiposity", "Potential mediator/collider depending on model", "BMI may mediate exposure-metabolic dysfunction pathway and also reflect outcome state",
  "Medication", "Medication/diagnosis", "Potential collider/confounder", "Diabetes diagnosis and medication can affect HbA1c and exposure behavior",
  "Cycle", "NHANES cycle", "Design/time factor", "Captures temporal changes in exposure, laboratory methods, and population structure"
)

# ------------------------------------------------------------
# 2. DAG edges
# ------------------------------------------------------------

dag_edges <- tibble::tribble(
  ~from, ~to, ~rationale,
  "Age", "DEHP", "Age influences diet, consumer product use, and exposure patterns",
  "Age", "MetabolicOutcome", "Age strongly affects insulin resistance and HbA1c",
  "Sex", "DEHP", "Sex influences product use and phthalate exposure",
  "Sex", "MetabolicOutcome", "Sex affects adiposity distribution and insulin resistance",
  "RaceEthnicity", "SES", "Race/ethnicity is associated with socioeconomic position",
  "RaceEthnicity", "DEHP", "Race/ethnicity may influence product exposure through social and environmental factors",
  "RaceEthnicity", "MetabolicOutcome", "Race/ethnicity is associated with metabolic risk",
  "SES", "Diet", "Socioeconomic status affects dietary quality and packaged food consumption",
  "SES", "DEHP", "Socioeconomic factors influence exposure sources",
  "SES", "MetabolicOutcome", "Socioeconomic status affects metabolic health",
  "Diet", "DEHP", "Packaged and processed food can contribute to DEHP exposure",
  "Diet", "MetabolicOutcome", "Energy intake and dietary composition affect metabolic outcomes",
  "PhysicalActivity", "MetabolicOutcome", "Physical activity affects insulin sensitivity and obesity",
  "PhysicalActivity", "DEHP", "Lifestyle patterns may correlate with exposure",
  "Smoking", "DEHP", "Smoking and associated behaviors may correlate with exposure",
  "Smoking", "MetabolicOutcome", "Smoking affects inflammation and metabolic risk",
  "Alcohol", "LiverMetabolism", "Alcohol affects liver enzymes",
  "Alcohol", "MetabolicOutcome", "Alcohol can influence glycemic and lipid metabolism",
  "UrineDilution", "DEHP", "Urinary concentration affects measured urinary metabolites",
  "KidneyFunction", "DEHP", "Renal function affects urinary excretion of biomarkers",
  "KidneyFunction", "MetabolicOutcome", "Kidney function is associated with metabolic disease",
  "DEHP", "Inflammation", "DEHP may be related to inflammatory responses",
  "DEHP", "LiverMetabolism", "DEHP may be related to hepatic and oxidative metabolic processes",
  "DEHP", "BMI", "DEHP may influence adiposity-related pathways",
  "Inflammation", "MetabolicOutcome", "Inflammation contributes to insulin resistance",
  "LiverMetabolism", "MetabolicOutcome", "Hepatic dysfunction and fatty liver are linked to insulin resistance",
  "BMI", "MetabolicOutcome", "Adiposity contributes to insulin resistance and HbA1c",
  "MetabolicOutcome", "Medication", "Metabolic disease diagnosis can lead to medication use",
  "Medication", "MetabolicOutcome", "Medication can alter HbA1c and metabolic biomarkers",
  "Cycle", "DEHP", "Exposure levels vary across survey cycles",
  "Cycle", "MetabolicOutcome", "Population composition and lab methods vary across cycles"
)

# ------------------------------------------------------------
# 3. Adjustment set logic
# ------------------------------------------------------------

adjustment_sets <- tibble::tribble(
  ~analysis_type, ~recommended_adjustment, ~variables_in_project, ~reason,
  "Main model",
  "Age, sex, race/ethnicity, income, education, total energy intake, urinary creatinine, NHANES cycle",
  "RIDAGEYR, RIAGENDR, RIDRETH3, INDFMPIR, DMDEDUC2, DR1TKCAL, ln_URXUCR, cycle",
  "Controls major demographic, socioeconomic, dietary, urinary dilution, and temporal confounding.",
  
  "Lifestyle sensitivity model",
  "Main model plus smoking, alcohol, and physical activity where available",
  "SMQ variables, ALQ variables, PAQ variables",
  "Tests whether lifestyle factors explain the exposure-outcome association.",
  
  "Mechanism-attenuation model",
  "Main model plus hsCRP, WBC/NLR, GGT/ALT, eGFR, or FLI separately",
  "ln_hsCRP, ln_WBC, ln_NLR, ln_GGT, ln_ALT, eGFR_2021, FLI",
  "Exploratory pathway-consistency analysis, not formal mediation.",
  
  "Avoided main adjustment",
  "Do not adjust for BMI when obesity/adiposity may be on pathway to HOMA-IR unless explicitly treated as sensitivity analysis",
  "BMXBMI",
  "BMI may be a mediator or collider depending on the causal question.",
  
  "Avoided main adjustment",
  "Do not adjust for diagnosed diabetes or medication in primary model unless using sensitivity analysis",
  "DIQ variables, RXQ variables",
  "Diagnosis and treatment may be downstream of metabolic status and can induce bias."
)

variable_roles <- tibble::tribble(
  ~variable_group, ~role_in_primary_model, ~recommended_use,
  "DEHP metabolites / Sigma DEHP / oxidative profile", "Exposure", "Primary exposure variables",
  "HOMA-IR and HbA1c", "Primary outcomes", "Core metabolic dysfunction outcomes",
  "Obesity / central obesity / metabolic syndrome", "Secondary outcomes", "Phenotypic metabolic outcomes",
  "Age, sex, race/ethnicity", "Confounders", "Always adjust",
  "Income, education", "Confounders", "Always adjust where available",
  "Energy intake", "Confounder/proxy", "Adjust in main model",
  "Urinary creatinine", "Measurement factor", "Adjust for concentration/dilution when exposure is urinary biomarker",
  "Cycle", "Temporal/design factor", "Always adjust in pooled NHANES cycles",
  "Inflammation/liver/renal markers", "Potential mediators/pathway markers", "Use in exploratory attenuation analysis",
  "BMI", "Potential mediator/collider", "Use in stratified or sensitivity analysis, not universal main adjustment",
  "Diabetes medication/diagnosis", "Potential downstream variable", "Use for sensitivity exclusions, not primary adjustment"
)

# ------------------------------------------------------------
# 4. DAG DOT file
# ------------------------------------------------------------

dot_lines <- c(
  "digraph DAG {",
  "  graph [rankdir=LR];",
  "  node [shape=box, style=rounded];"
)

for (i in seq_len(nrow(dag_edges))) {
  dot_lines <- c(
    dot_lines,
    paste0("  ", dag_edges$from[i], " -> ", dag_edges$to[i], ";")
  )
}

dot_lines <- c(dot_lines, "}")

writeLines(
  dot_lines,
  file.path(dag_dir, "DEHP_metabolic_DAG.dot")
)

# ------------------------------------------------------------
# 5. Manuscript-ready causal analysis plan
# ------------------------------------------------------------

causal_analysis_plan <- tibble::tribble(
  ~section, ~text,
  "Causal estimand",
  "The target estimand is the adjusted association between urinary DEHP-related exposure indicators and metabolic dysfunction markers, particularly HOMA-IR and HbA1c, under a cross-sectional observational design.",
  
  "Primary confounding control",
  "Primary models adjust for age, sex, race/ethnicity, socioeconomic status, education, total energy intake, urinary creatinine, and NHANES cycle.",
  
  "DAG rationale",
  "The adjustment set was selected to block major backdoor paths from socioeconomic, demographic, dietary, urine dilution, and time-related determinants of both DEHP exposure and metabolic outcomes.",
  
  "Potential mediators",
  "Inflammation, liver metabolism, renal function, and adiposity-related markers may partly lie on the biological pathway. These variables are not included in the primary confounder set but are analyzed in exploratory attenuation models.",
  
  "Negative controls",
  "Adult height is used as a negative-control outcome because current short-lived urinary DEHP metabolites are not expected to affect attained adult height after adjustment for demographic and socioeconomic factors.",
  
  "Permutation falsification",
  "Permutation negative-control analyses randomly permute exposure within sex and cycle strata to test whether the modeling pipeline produces systematic false-positive associations.",
  
  "E-value sensitivity",
  "E-value analysis is performed for binary metabolic endpoints and Q4-versus-Q1 exposure contrasts to assess the minimum strength of unmeasured confounding required to explain away observed associations.",
  
  "Interpretation limitation",
  "Because NHANES is cross-sectional and exposure biomarkers are based on spot urine samples, these analyses strengthen causal interpretation but do not establish causality."
)

# ------------------------------------------------------------
# 6. Export
# ------------------------------------------------------------

write_xlsx(
  list(
    dag_nodes = dag_nodes,
    dag_edges = dag_edges,
    variable_roles = variable_roles,
    adjustment_sets = adjustment_sets,
    causal_analysis_plan = causal_analysis_plan
  ),
  file.path(result_dir, "causal_DAG_and_analysis_plan.xlsx")
)

write_csv(dag_nodes, file.path(dag_dir, "dag_nodes.csv"))
write_csv(dag_edges, file.path(dag_dir, "dag_edges.csv"))
write_csv(adjustment_sets, file.path(dag_dir, "adjustment_sets.csv"))

cat("DAG and causal analysis plan exported successfully.\n")