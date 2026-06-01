# ============================================================
# 39_extract_lod_creatinine_exposure_key_results.R
# Extract key results for LOD/creatinine/exposure sensitivity
# ============================================================

library(dplyr)
library(readr)
library(writexl)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"
result_dir <- file.path(project_dir, "result")

check_file <- file.path(result_dir, "exposure_lod_creatinine_check_2013_2018.xlsx")
model_file <- file.path(result_dir, "lod_creatinine_exposure_sensitivity_models_2013_2018.csv")

if (!file.exists(model_file)) {
  stop("缺少模型结果，请先运行脚本 38。")
}

sensitivity_results <- read_csv(model_file, show_col_types = FALSE)

key_results <- sensitivity_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    scenario %in% c(
      "Main model, creatinine-adjusted",
      "Exclude urinary creatinine <30 or >300 mg/dL",
      "Creatinine-standardized exposure, no creatinine covariate",
      "Exclude oxidative components below LOD",
      "Winsorized exposure, 1st-99th percentile"
    )
  ) %>%
  mutate(
    result_interpretation = case_when(
      q_value < 0.05 & beta > 0 ~ "FDR-significant positive association",
      p_value < 0.05 & beta > 0 ~ "Nominal positive association",
      beta > 0 ~ "Positive direction only",
      beta < 0 ~ "Negative direction",
      TRUE ~ "Weak/no support"
    )
  ) %>%
  select(
    outcome_label,
    scenario,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    result_interpretation,
    beta,
    se
  ) %>%
  arrange(outcome_label, exposure_label, scenario)

robustness_by_exposure <- sensitivity_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c")
  ) %>%
  mutate(
    exposure_family = case_when(
      grepl("Sigma", exposure_label) ~ "Sigma DEHP",
      grepl("Oxidative", exposure_label) ~ "%Oxidative",
      grepl("MEHHP", exposure_label) ~ "MEHHP",
      grepl("MEOHP", exposure_label) ~ "MEOHP",
      grepl("MECPP", exposure_label) ~ "MECPP",
      TRUE ~ "Other"
    )
  ) %>%
  group_by(outcome_label, exposure_family) %>%
  summarise(
    n_models = n(),
    positive_models = sum(beta > 0, na.rm = TRUE),
    nominal_sig_models = sum(p_value < 0.05, na.rm = TRUE),
    fdr_sig_models = sum(q_value < 0.05, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    robustness = case_when(
      positive_models == n_models & nominal_sig_models >= ceiling(n_models / 2) ~ "strong",
      positive_models == n_models ~ "direction-consistent",
      positive_models >= ceiling(n_models / 2) ~ "partial",
      TRUE ~ "weak"
    )
  )

method_interpretation <- tibble::tibble(
  sensitivity_component = c(
    "LOD comment codes",
    "Exclude detected-limit samples",
    "Urinary creatinine adjustment",
    "Creatinine-standardized exposure",
    "Exclude urinary creatinine extremes",
    "Winsorized exposure"
  ),
  purpose = c(
    "Describe the extent to which DEHP metabolite measurements were below the lower detection limit.",
    "Evaluate whether substitution of values below LOD drives the main association.",
    "Primary approach to account for urine dilution in urinary biomarker models.",
    "Alternative approach to handle urine dilution without adding urinary creatinine as a covariate.",
    "Evaluate whether very dilute or concentrated urine samples drive the association.",
    "Evaluate whether extreme exposure values drive the association."
  ),
  manuscript_language = c(
    "Comment code variables were used to identify observations below the lower detection limit.",
    "Sensitivity analyses restricted the sample to participants with detected oxidative DEHP metabolites.",
    "Primary models adjusted for log urinary creatinine.",
    "Sensitivity models used creatinine-standardized DEHP variables and omitted urinary creatinine from the covariate set.",
    "Participants with urinary creatinine <30 or >300 mg/dL were excluded in a sensitivity analysis.",
    "Exposure variables were winsorized at the 1st and 99th percentiles in sensitivity models."
  )
)

write_xlsx(
  list(
    key_results = key_results,
    robustness_by_exposure = robustness_by_exposure,
    method_interpretation = method_interpretation
  ),
  file.path(result_dir, "lod_creatinine_exposure_key_results_2013_2018.xlsx")
)

print(key_results)
print(robustness_by_exposure)

cat("Key LOD/creatinine/exposure sensitivity results exported successfully.\n")