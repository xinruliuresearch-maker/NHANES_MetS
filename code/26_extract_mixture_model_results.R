# ============================================================
# 26_extract_mixture_model_results.R
# Extract key mixture model results
# ============================================================

library(dplyr)
library(readr)
library(writexl)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")

qgcomp_2013 <- read_csv(
  file.path(result_dir, "survey_qgcomp_DEHP_2013_2018_mixture_results.csv"),
  show_col_types = FALSE
)

qgcomp_2013_weights <- read_csv(
  file.path(result_dir, "survey_qgcomp_DEHP_2013_2018_component_weights.csv"),
  show_col_types = FALSE
)

qgcomp_2003_overall <- read_csv(
  file.path(result_dir, "survey_qgcomp_DEHP_2003_2018_overall_results.csv"),
  show_col_types = FALSE
)

qgcomp_2003_period <- read_csv(
  file.path(result_dir, "survey_qgcomp_DEHP_2003_2018_period_results.csv"),
  show_col_types = FALSE
)

wqs_exists <- file.exists(
  file.path(result_dir, "WQS_DEHP_2013_2018_sensitivity_results.csv")
)

if (wqs_exists) {
  wqs_results <- read_csv(
    file.path(result_dir, "WQS_DEHP_2013_2018_sensitivity_results.csv"),
    show_col_types = FALSE
  )
  
  wqs_weights <- read_csv(
    file.path(result_dir, "WQS_DEHP_2013_2018_sensitivity_weights.csv"),
    show_col_types = FALSE
  )
} else {
  wqs_results <- tibble()
  wqs_weights <- tibble()
}

# ------------------------------------------------------------
# 1. Main qgcomp results
# ------------------------------------------------------------

main_qgcomp_key <- qgcomp_2013 %>%
  filter(outcome_label %in% c("ln(HOMA-IR)", "HbA1c")) %>%
  select(
    dataset,
    mixture,
    outcome_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    evidence_level,
    psi,
    psi_se
  ) %>%
  arrange(outcome_label, mixture)

# ------------------------------------------------------------
# 2. Long-cycle validation
# ------------------------------------------------------------

long_overall_key <- qgcomp_2003_overall %>%
  filter(outcome_label %in% c("ln(HOMA-IR)", "HbA1c")) %>%
  select(
    dataset,
    period,
    mixture,
    outcome_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    evidence_level,
    psi,
    psi_se
  ) %>%
  arrange(outcome_label, mixture)

long_period_key <- qgcomp_2003_period %>%
  filter(outcome_label %in% c("ln(HOMA-IR)", "HbA1c")) %>%
  select(
    dataset,
    period,
    mixture,
    outcome_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    evidence_level,
    psi,
    psi_se
  ) %>%
  arrange(outcome_label, mixture, period)

long_period_summary <- qgcomp_2003_period %>%
  filter(outcome_label %in% c("ln(HOMA-IR)", "HbA1c")) %>%
  mutate(
    direction = case_when(
      psi > 0 ~ "positive",
      psi < 0 ~ "negative",
      TRUE ~ "null"
    )
  ) %>%
  group_by(outcome_label, mixture) %>%
  summarise(
    n_periods = n(),
    positive_periods = sum(direction == "positive", na.rm = TRUE),
    nominal_sig_periods = sum(p_value < 0.05, na.rm = TRUE),
    fdr_sig_periods = sum(q_value < 0.05, na.rm = TRUE),
    consistency = case_when(
      positive_periods == n_periods & nominal_sig_periods >= 2 ~ "strong",
      positive_periods == n_periods ~ "direction-consistent",
      positive_periods >= 2 ~ "partial",
      TRUE ~ "weak"
    ),
    .groups = "drop"
  ) %>%
  arrange(outcome_label, mixture)

# ------------------------------------------------------------
# 3. Component weights summary
# ------------------------------------------------------------

component_weight_key <- qgcomp_2013_weights %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    direction == "positive"
  ) %>%
  group_by(mixture, outcome_label) %>%
  arrange(desc(positive_weight), .by_group = TRUE) %>%
  mutate(rank = row_number()) %>%
  ungroup() %>%
  select(
    mixture,
    outcome_label,
    component,
    beta_component,
    positive_weight,
    rank
  )

# ------------------------------------------------------------
# 4. Interpretation table
# ------------------------------------------------------------

interpretation_table <- main_qgcomp_key %>%
  mutate(
    interpretation = case_when(
      evidence_level == "FDR-significant" ~ "The DEHP mixture shows robust positive association in the main 2013-2018 analysis.",
      evidence_level == "Nominally significant" ~ "The DEHP mixture shows nominal positive association in the main 2013-2018 analysis.",
      evidence_level == "Positive direction only" ~ "The DEHP mixture shows positive direction but limited statistical evidence.",
      TRUE ~ "The DEHP mixture does not provide clear support for this outcome."
    )
  )

# ------------------------------------------------------------
# 5. Export
# ------------------------------------------------------------

write_xlsx(
  list(
    main_qgcomp_key = main_qgcomp_key,
    long_overall_key = long_overall_key,
    long_period_key = long_period_key,
    long_period_summary = long_period_summary,
    component_weight_key = component_weight_key,
    wqs_results = wqs_results,
    wqs_weights = wqs_weights,
    interpretation_table = interpretation_table
  ),
  file.path(result_dir, "mixture_model_key_results.xlsx")
)

print(main_qgcomp_key)
print(long_period_summary)
print(component_weight_key)

cat("Mixture model key results exported: mixture_model_key_results.xlsx\n")