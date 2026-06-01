# ============================================================
# NHANES 2013-2018
# 35_extract_causal_sensitivity_key_results.R
# Extract key causal sensitivity results
# ============================================================

library(dplyr)
library(readr)
library(writexl)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")

# ------------------------------------------------------------
# 1. Read available outputs
# ------------------------------------------------------------

evalue_file <- file.path(result_dir, "Evalue_binary_sensitivity_2013_2018.csv")
negative_file <- file.path(result_dir, "negative_control_outcome_2013_2018.csv")
permutation_file <- file.path(result_dir, "permutation_negative_control_2013_2018.xlsx")

if (!file.exists(evalue_file)) {
  stop("缺少 E-value 结果，请先运行脚本 32。")
}

if (!file.exists(negative_file)) {
  stop("缺少负对照结局结果，请先运行脚本 33。")
}

evalue_results <- read_csv(evalue_file, show_col_types = FALSE)
negative_results <- read_csv(negative_file, show_col_types = FALSE)

# permutation_summary is easier to read from csv if available
perm_summary_csv <- file.path(result_dir, "permutation_observed_results_2013_2018.csv")
perm_null_csv <- file.path(result_dir, "permutation_null_results_2013_2018.csv")

if (!file.exists(perm_summary_csv) || !file.exists(perm_null_csv)) {
  stop("缺少置换负对照结果，请先运行脚本 34。")
}

observed_results <- read_csv(perm_summary_csv, show_col_types = FALSE)
permutation_results <- read_csv(perm_null_csv, show_col_types = FALSE)

# Rebuild permutation summary for final file
permutation_summary <- permutation_results %>%
  group_by(outcome_label, exposure_label) %>%
  summarise(
    n_perm_success = n(),
    perm_beta_mean = mean(beta, na.rm = TRUE),
    perm_beta_sd = sd(beta, na.rm = TRUE),
    perm_beta_p025 = quantile(beta, 0.025, na.rm = TRUE),
    perm_beta_p975 = quantile(beta, 0.975, na.rm = TRUE),
    perm_p_lt_005_rate = mean(p_value < 0.05, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    observed_results %>%
      select(
        outcome_label,
        exposure_label,
        observed_beta = beta,
        observed_effect = effect,
        observed_p_value = p_value
      ),
    by = c("outcome_label", "exposure_label")
  ) %>%
  mutate(
    empirical_p_two_sided = sapply(seq_len(n()), function(i) {
      out_i <- outcome_label[i]
      exp_i <- exposure_label[i]
      obs_beta <- observed_beta[i]
      
      perm_beta <- permutation_results %>%
        filter(outcome_label == out_i, exposure_label == exp_i) %>%
        pull(beta)
      
      mean(abs(perm_beta) >= abs(obs_beta), na.rm = TRUE)
    }),
    interpretation = case_when(
      observed_p_value < 0.05 & empirical_p_two_sided < 0.05 & perm_p_lt_005_rate <= 0.10 ~
        "Observed association exceeds permutation null",
      observed_p_value < 0.05 & empirical_p_two_sided >= 0.05 ~
        "Observed association not clearly separated from permutation null",
      TRUE ~
        "Limited observed association"
    )
  )

# ------------------------------------------------------------
# 2. Key E-value results
# ------------------------------------------------------------

evalue_key <- evalue_results %>%
  filter(
    outcome_label %in% c(
      "High HOMA-IR, top quartile",
      "High HOMA-IR >= 2.5",
      "HbA1c >= 5.7%",
      "Metabolic syndrome"
    ),
    exposure_label %in% c(
      "ln(Sigma DEHP)",
      "%Oxidative per 10 percentage points",
      "MEHHP",
      "MEOHP",
      "MECPP"
    )
  ) %>%
  select(
    outcome_label,
    exposure_label,
    contrast,
    n,
    events,
    OR_CI,
    RR_approx_CI,
    p_value_fmt,
    q_value_fmt,
    E_value_point,
    E_value_CI,
    interpretation
  ) %>%
  arrange(outcome_label, exposure_label)

# ------------------------------------------------------------
# 3. Negative-control outcome key results
# ------------------------------------------------------------

negative_control_key <- negative_results %>%
  select(
    outcome_label,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    falsification_interpretation,
    negative_control_rationale
  ) %>%
  arrange(exposure_label)

# ------------------------------------------------------------
# 4. Permutation key results
# ------------------------------------------------------------

permutation_key <- permutation_summary %>%
  select(
    outcome_label,
    exposure_label,
    observed_beta,
    observed_effect,
    observed_p_value,
    empirical_p_two_sided,
    perm_p_lt_005_rate,
    perm_beta_p025,
    perm_beta_p975,
    interpretation
  ) %>%
  arrange(outcome_label, exposure_label)

# ------------------------------------------------------------
# 5. Final causal sensitivity interpretation
# ------------------------------------------------------------

causal_sensitivity_interpretation <- tibble::tibble(
  component = c(
    "DAG",
    "E-value",
    "Negative-control outcome",
    "Permutation negative control",
    "Overall interpretation"
  ),
  purpose = c(
    "Clarifies confounding structure and primary adjustment set.",
    "Quantifies the minimum strength of unmeasured confounding needed to explain selected binary associations.",
    "Tests whether DEHP indicators are spuriously associated with an implausible outcome, adult height.",
    "Tests whether the analytical pipeline produces false-positive associations after exposure-outcome linkage is destroyed.",
    "Strengthens but does not prove causal interpretation."
  ),
  manuscript_language = c(
    "A DAG-informed adjustment set was used to control demographic, socioeconomic, dietary, urine dilution, and temporal confounding.",
    "E-value analyses suggested how robust selected Q4-versus-Q1 associations were to potential unmeasured confounding.",
    "Negative-control outcome analyses did not provide strong evidence that the main findings were driven by broad residual confounding, if adult height associations were null.",
    "Permutation analyses evaluated whether observed associations exceeded the null distribution produced by permuted exposures.",
    "Because NHANES is cross-sectional and based on spot urine biomarkers, these analyses should be interpreted as causal-sensitivity and falsification checks, not definitive causal proof."
  )
)

# ------------------------------------------------------------
# 6. Export
# ------------------------------------------------------------

write_xlsx(
  list(
    evalue_key = evalue_key,
    negative_control_key = negative_control_key,
    permutation_key = permutation_key,
    causal_sensitivity_interpretation = causal_sensitivity_interpretation
  ),
  file.path(result_dir, "causal_sensitivity_key_results.xlsx")
)

print(evalue_key)
print(negative_control_key)
print(permutation_key)

cat("Causal sensitivity key results exported: causal_sensitivity_key_results.xlsx\n")