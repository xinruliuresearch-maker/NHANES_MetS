# ============================================================
# NHANES 2003-2018
# 22_extract_DEHP_validation_results.R
# Extract key validation results for manuscript and PPT
# ============================================================

library(dplyr)
library(readr)
library(writexl)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")

overall_results <- read_csv(
  file.path(result_dir, "DEHP_only_2003_2018_overall_models.csv"),
  show_col_types = FALSE
)

period_results <- read_csv(
  file.path(result_dir, "DEHP_only_2003_2018_period_results.csv"),
  show_col_types = FALSE
)

# ------------------------------------------------------------
# 1. Overall focused results
# ------------------------------------------------------------

overall_key <- overall_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    exposure_label %in% c(
      "MEHHP", "MEOHP", "MECPP",
      "ln(Sigma DEHP)",
      "%Oxidative per 10 percentage points",
      "ln(Oxidative/MEHP ratio)"
    )
  ) %>%
  mutate(
    evidence_level = case_when(
      q_value < 0.05 ~ "FDR-significant",
      p_value < 0.05 ~ "Nominally significant",
      beta > 0 ~ "Positive direction only",
      TRUE ~ "Weak/no support"
    )
  ) %>%
  select(
    outcome_label,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    evidence_level,
    beta,
    se
  ) %>%
  arrange(outcome_label, exposure_label)

# ------------------------------------------------------------
# 2. Period consistency summary
# ------------------------------------------------------------

period_key <- period_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    exposure_label %in% c(
      "MEHHP", "MEOHP", "MECPP",
      "ln(Sigma DEHP)",
      "%Oxidative per 10 percentage points"
    )
  ) %>%
  mutate(
    evidence_level = case_when(
      q_value < 0.05 ~ "FDR-significant",
      p_value < 0.05 ~ "Nominally significant",
      beta > 0 ~ "Positive direction only",
      TRUE ~ "Weak/no support"
    )
  ) %>%
  select(
    period,
    outcome_label,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    evidence_level,
    beta,
    se
  ) %>%
  arrange(outcome_label, exposure_label, period)

period_summary_final <- period_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    exposure_label %in% c(
      "MEHHP", "MEOHP", "MECPP",
      "ln(Sigma DEHP)",
      "%Oxidative per 10 percentage points"
    )
  ) %>%
  mutate(
    direction = case_when(
      beta > 0 ~ "positive",
      beta < 0 ~ "negative",
      TRUE ~ "null"
    )
  ) %>%
  group_by(outcome_label, exposure_label) %>%
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
  arrange(outcome_label, exposure_label)

# ------------------------------------------------------------
# 3. Manuscript-ready interpretation table
# ------------------------------------------------------------

interpretation_table <- period_summary_final %>%
  mutate(
    manuscript_interpretation = case_when(
      consistency == "strong" ~ "Long-cycle validation strongly supports the 2013-2018 finding.",
      consistency == "direction-consistent" ~ "Long-cycle validation supports the direction of association, although statistical significance varies by period.",
      consistency == "partial" ~ "Long-cycle validation provides partial support; associations may vary across periods.",
      TRUE ~ "Long-cycle validation does not consistently support this association."
    )
  )

# ------------------------------------------------------------
# 4. Export
# ------------------------------------------------------------

write_xlsx(
  list(
    overall_key = overall_key,
    period_key = period_key,
    period_summary_final = period_summary_final,
    interpretation_table = interpretation_table
  ),
  file.path(result_dir, "DEHP_2003_2018_validation_key_results.xlsx")
)

print(overall_key)
print(period_summary_final)
print(interpretation_table)

cat("Key validation results exported: DEHP_2003_2018_validation_key_results.xlsx\n")