# ============================================================
# NHANES 2013-2018
# 08_main_models_2013_2018.R
# Logistic + metabolic markers + FDR
# ============================================================

library(dplyr)
library(purrr)
library(tidyr)
library(readr)
library(tibble)
library(survey)
library(writexl)

options(survey.lonely.psu = "adjust")

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

analysis_df <- readRDS(
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

pollutant_map <- tibble::tribble(
  ~pollutant, ~label, ~group,
  "URXBPH",   "BPA",   "Bisphenols",
  "URXBPF",   "BPF",   "Bisphenols",
  "URXBPS",   "BPS",   "Bisphenols",
  "URXMEP",   "MEP",   "Phthalates",
  "URXMBP",   "MBP",   "Phthalates",
  "URXMIB",   "MiBP",  "Phthalates",
  "URXMHP",   "MEHP",  "Phthalates",
  "URXMHH",   "MEHHP", "Phthalates",
  "URXMOH",   "MEOHP", "Phthalates",
  "URXECP",   "MECPP", "Phthalates",
  "URXMZP",   "MBzP",  "Phthalates",
  "URXCOP",   "MCOP",  "Plasticizers",
  "URXCNP",   "MCNP",  "Plasticizers",
  "URXMNP",   "MNP",   "Plasticizers",
  "URXMONP",  "MONP",  "Plasticizers"
) %>%
  mutate(exposure = paste0("ln_", pollutant)) %>%
  filter(exposure %in% names(analysis_df))

binary_outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label,
  "obesity", "Obesity",
  "central_obesity", "Central obesity",
  "metabolic_syndrome", "Metabolic syndrome"
)

continuous_outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label,
  "ln_HOMA_IR", "ln(HOMA-IR)",
  "TyG", "TyG index",
  "ln_TG_HDL", "ln(TG/HDL-C)",
  "HbA1c", "HbA1c",
  "non_HDL_C", "Non-HDL-C"
)

base_covars <- c(
  "RIDAGEYR",
  "RIAGENDR",
  "RIDRETH3",
  "INDFMPIR",
  "DMDEDUC2",
  "DR1TKCAL",
  "ln_URXUCR",
  "cycle"
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")

run_logistic <- function(outcome, exposure) {
  
  model_vars <- c(outcome, exposure, base_covars, design_vars)
  
  d <- analysis_df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100 || length(unique(d[[outcome]])) < 2) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      events = ifelse(outcome %in% names(d), sum(d[[outcome]] == 1, na.rm = TRUE), NA_integer_),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      OR = NA_real_,
      OR_low = NA_real_,
      OR_high = NA_real_
    ))
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(
      outcome, " ~ ", exposure,
      " + RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3)",
      " + INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
    )
  )
  
  fit <- tryCatch(
    svyglm(f, design = des, family = quasibinomial()),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      events = sum(d[[outcome]] == 1, na.rm = TRUE),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      OR = NA_real_,
      OR_low = NA_real_,
      OR_high = NA_real_
    ))
  }
  
  coef_table <- summary(fit)$coefficients
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  tibble(
    outcome = outcome,
    exposure = exposure,
    n = nrow(d),
    events = sum(d[[outcome]] == 1, na.rm = TRUE),
    beta = beta,
    se = se,
    p_value = p_value,
    OR = exp(beta),
    OR_low = exp(beta - tcrit * se),
    OR_high = exp(beta + tcrit * se)
  )
}

run_linear <- function(outcome, exposure) {
  
  model_vars <- c(outcome, exposure, base_covars, design_vars)
  
  d <- analysis_df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_
    ))
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(
      outcome, " ~ ", exposure,
      " + RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3)",
      " + INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
    )
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_
    ))
  }
  
  coef_table <- summary(fit)$coefficients
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  is_log_outcome <- outcome %in% c("ln_HOMA_IR", "ln_TG_HDL")
  
  if (is_log_outcome) {
    effect <- (exp(beta) - 1) * 100
    effect_low <- (exp(low) - 1) * 100
    effect_high <- (exp(high) - 1) * 100
  } else {
    effect <- beta
    effect_low <- low
    effect_high <- high
  }
  
  tibble(
    outcome = outcome,
    exposure = exposure,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = effect,
    effect_low = effect_low,
    effect_high = effect_high
  )
}

logistic_results <- expand_grid(
  outcome = binary_outcome_map$outcome,
  exposure = pollutant_map$exposure
) %>%
  mutate(result = map2(outcome, exposure, run_logistic)) %>%
  select(result) %>%
  unnest(result) %>%
  left_join(binary_outcome_map, by = "outcome") %>%
  left_join(pollutant_map, by = "exposure") %>%
  group_by(outcome) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    OR_CI = sprintf("%.3f (%.3f, %.3f)", OR, OR_low, OR_high),
    p_value_fmt = ifelse(p_value < 0.001, "<0.001", sprintf("%.3f", p_value)),
    q_value_fmt = ifelse(q_value < 0.001, "<0.001", sprintf("%.3f", q_value))
  )

continuous_results <- expand_grid(
  outcome = continuous_outcome_map$outcome,
  exposure = pollutant_map$exposure
) %>%
  mutate(result = map2(outcome, exposure, run_linear)) %>%
  select(result) %>%
  unnest(result) %>%
  left_join(continuous_outcome_map, by = "outcome") %>%
  left_join(pollutant_map, by = "exposure") %>%
  group_by(outcome) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    effect_CI = sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high),
    p_value_fmt = ifelse(p_value < 0.001, "<0.001", sprintf("%.3f", p_value)),
    q_value_fmt = ifelse(q_value < 0.001, "<0.001", sprintf("%.3f", q_value))
  )

write_xlsx(
  list(
    logistic_results = logistic_results,
    continuous_results = continuous_results
  ),
  file.path(result_dir, "main_models_2013_2018_Model2.xlsx")
)

write_csv(
  logistic_results,
  file.path(result_dir, "logistic_results_2013_2018_Model2.csv")
)

write_csv(
  continuous_results,
  file.path(result_dir, "continuous_results_2013_2018_Model2.csv")
)

cat("2013-2018 主模型结果已导出。\n")