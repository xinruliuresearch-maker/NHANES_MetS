# ============================================================
# NHANES 2003-2018
# 20_models_DEHP_only_2003_2018.R
# Overall long-cycle validation models
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

df <- readRDS(
  file.path(output_dir, "NHANES_2003_2018_DEHP_only_master.rds")
)

# ------------------------------------------------------------
# 1. Exposures and outcomes
# ------------------------------------------------------------

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~include_creatinine,
  "ln_URXMHP", "MEHP", TRUE,
  "ln_URXMHH", "MEHHP", TRUE,
  "ln_URXMOH", "MEOHP", TRUE,
  "ln_URXECP", "MECPP", TRUE,
  "ln_Sigma_DEHP", "ln(Sigma DEHP)", TRUE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE,
  "ln_oxidative_to_MEHP", "ln(Oxidative/MEHP ratio)", FALSE
)

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSDEHP16YR")

covars_with_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "race_eth",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

covars_without_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "race_eth",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "cycle"
)

terms_with_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(race_eth) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

terms_without_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(race_eth) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + factor(cycle)"
)

# ------------------------------------------------------------
# 2. Model function
# ------------------------------------------------------------

run_linear <- function(outcome, outcome_label, is_log_outcome,
                       exposure, exposure_label, include_creatinine,
                       data = df,
                       model_label = "Overall_2003_2018") {
  
  covar_vars <- if (include_creatinine) covars_with_creatinine else covars_without_creatinine
  covar_terms <- if (include_creatinine) terms_with_creatinine else terms_without_creatinine
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars)
  
  d <- data %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100) {
    return(tibble(
      model = model_label,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
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
    weights = ~WTSDEHP16YR,
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
  
  if (is.null(fit)) {
    return(tibble())
  }
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) {
    return(tibble())
  }
  
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
    model = model_label,
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = effect,
    effect_low = effect_low,
    effect_high = effect_high
  )
}

# ------------------------------------------------------------
# 3. Batch run
# ------------------------------------------------------------

overall_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result = map2(outcome_row, exposure_row, function(i, j) {
      run_linear(
        outcome = outcome_map$outcome[i],
        outcome_label = outcome_map$outcome_label[i],
        is_log_outcome = outcome_map$is_log_outcome[i],
        exposure = exposure_map$exposure[j],
        exposure_label = exposure_map$exposure_label[j],
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
    ),
    direction = case_when(
      is.na(beta) ~ NA_character_,
      beta > 0 ~ "positive",
      beta < 0 ~ "negative",
      TRUE ~ "null"
    )
  )

# ------------------------------------------------------------
# 4. Focused key results
# ------------------------------------------------------------

key_overall_results <- overall_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    exposure_label %in% c(
      "MEHHP", "MEOHP", "MECPP",
      "ln(Sigma DEHP)",
      "%Oxidative per 10 percentage points",
      "ln(Oxidative/MEHP ratio)"
    )
  ) %>%
  select(
    outcome_label,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    beta,
    se,
    direction
  )

print(overall_results)
print(key_overall_results)

# ------------------------------------------------------------
# 5. Export
# ------------------------------------------------------------

write_csv(
  overall_results,
  file.path(result_dir, "DEHP_only_2003_2018_overall_models.csv")
)

write_xlsx(
  list(
    overall_results = overall_results,
    key_overall_results = key_overall_results
  ),
  file.path(result_dir, "DEHP_only_2003_2018_overall_models.xlsx")
)

cat("DEHP-only 2003-2018 overall models completed successfully.\n")