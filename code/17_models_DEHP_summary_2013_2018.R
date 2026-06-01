# ============================================================
# NHANES 2013-2018
# 17_models_DEHP_summary_2013_2018.R
# Models for ΣDEHP and DEHP metabolic profile indicators
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
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds")
)

# ------------------------------------------------------------
# 1. Exposure map
# ------------------------------------------------------------

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~exposure_interpretation, ~include_creatinine,
  "ln_Sigma_DEHP", "ln(ΣDEHP)", "per ln-unit increase in molar ΣDEHP", TRUE,
  "ln_Sigma_DEHP_MECPP_equiv", "ln(ΣDEHP, MECPP-equivalent)", "per ln-unit increase in MECPP-equivalent ΣDEHP", TRUE,
  "pct_MEHP_10", "%MEHP per 10 percentage points", "per 10 percentage-point increase in %MEHP", FALSE,
  "pct_oxidative_10", "%Oxidative metabolites per 10 percentage points", "per 10 percentage-point increase in oxidative metabolite proportion", FALSE,
  "ln_oxidative_to_MEHP", "ln(Oxidative/MEHP ratio)", "per ln-unit increase in oxidative-to-MEHP ratio", FALSE
)

# ------------------------------------------------------------
# 2. Outcomes
# ------------------------------------------------------------

continuous_outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE,
  "TyG", "TyG index", FALSE,
  "ln_TG_HDL", "ln(TG/HDL-C)", TRUE
)

binary_outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label,
  "obesity", "Obesity",
  "central_obesity", "Central obesity",
  "metabolic_syndrome", "Metabolic syndrome"
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")

covars_with_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

covars_without_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "cycle"
)

terms_with_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

terms_without_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + factor(cycle)"
)

# ------------------------------------------------------------
# 3. Linear models
# ------------------------------------------------------------

run_linear <- function(outcome, outcome_label, is_log_outcome,
                       exposure, exposure_label, exposure_interpretation,
                       include_creatinine) {
  
  covar_vars <- if (include_creatinine) covars_with_creatinine else covars_without_creatinine
  covar_terms <- if (include_creatinine) terms_with_creatinine else terms_without_creatinine
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars)
  
  d <- analysis_df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100) {
    return(tibble(
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_interpretation = exposure_interpretation,
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
    paste0(outcome, " ~ ", exposure, " + ", covar_terms)
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit)) return(tibble())
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) return(tibble())
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
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
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_interpretation = exposure_interpretation,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = effect,
    effect_low = effect_low,
    effect_high = effect_high
  )
}

continuous_results <- expand_grid(
  outcome_row = seq_len(nrow(continuous_outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result = map2(outcome_row, exposure_row, function(i, j) {
      run_linear(
        outcome = continuous_outcome_map$outcome[i],
        outcome_label = continuous_outcome_map$outcome_label[i],
        is_log_outcome = continuous_outcome_map$is_log_outcome[i],
        exposure = exposure_map$exposure[j],
        exposure_label = exposure_map$exposure_label[j],
        exposure_interpretation = exposure_map$exposure_interpretation[j],
        include_creatinine = exposure_map$include_creatinine[j]
      )
    })
  ) %>%
  select(result) %>%
  unnest(result) %>%
  group_by(outcome) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    effect_CI = sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high),
    p_value_fmt = case_when(
      is.na(p_value) ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_value)
    ),
    q_value_fmt = case_when(
      is.na(q_value) ~ NA_character_,
      q_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", q_value)
    )
  )

# ------------------------------------------------------------
# 4. Logistic models
# ------------------------------------------------------------

run_logistic <- function(outcome, outcome_label,
                         exposure, exposure_label, exposure_interpretation,
                         include_creatinine) {
  
  covar_vars <- if (include_creatinine) covars_with_creatinine else covars_without_creatinine
  covar_terms <- if (include_creatinine) terms_with_creatinine else terms_without_creatinine
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars)
  
  d <- analysis_df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100 || length(unique(d[[outcome]])) < 2) {
    return(tibble(
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_interpretation = exposure_interpretation,
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
    paste0(outcome, " ~ ", exposure, " + ", covar_terms)
  )
  
  fit <- tryCatch(
    svyglm(f, design = des, family = quasibinomial()),
    error = function(e) NULL
  )
  
  if (is.null(fit)) return(tibble())
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) return(tibble())
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  tibble(
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_interpretation = exposure_interpretation,
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

logistic_results <- expand_grid(
  outcome_row = seq_len(nrow(binary_outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result = map2(outcome_row, exposure_row, function(i, j) {
      run_logistic(
        outcome = binary_outcome_map$outcome[i],
        outcome_label = binary_outcome_map$outcome_label[i],
        exposure = exposure_map$exposure[j],
        exposure_label = exposure_map$exposure_label[j],
        exposure_interpretation = exposure_map$exposure_interpretation[j],
        include_creatinine = exposure_map$include_creatinine[j]
      )
    })
  ) %>%
  select(result) %>%
  unnest(result) %>%
  group_by(outcome) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    OR_CI = sprintf("%.3f (%.3f, %.3f)", OR, OR_low, OR_high),
    p_value_fmt = case_when(
      is.na(p_value) ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_value)
    ),
    q_value_fmt = case_when(
      is.na(q_value) ~ NA_character_,
      q_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", q_value)
    )
  )

# ------------------------------------------------------------
# 5. Export
# ------------------------------------------------------------

write_csv(
  continuous_results,
  file.path(result_dir, "DEHP_summary_continuous_models_2013_2018.csv")
)

write_csv(
  logistic_results,
  file.path(result_dir, "DEHP_summary_logistic_models_2013_2018.csv")
)

write_xlsx(
  list(
    continuous_results = continuous_results,
    logistic_results = logistic_results
  ),
  file.path(result_dir, "DEHP_summary_models_2013_2018.xlsx")
)

cat("ΣDEHP 与 DEHP 代谢模式模型已完成。\n")