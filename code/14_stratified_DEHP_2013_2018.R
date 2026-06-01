# ============================================================
# NHANES 2013-2018
# 14_stratified_DEHP_2013_2018.R
# Stratified analyses by sex and obesity status
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

dehp_map <- tibble::tribble(
  ~label,  ~exposure,
  "MEHHP", "ln_URXMHH",
  "MEOHP", "ln_URXMOH",
  "MECPP", "ln_URXECP"
)

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")

run_stratified_linear <- function(data, outcome, outcome_label, is_log_outcome,
                                  exposure, label, strata_name, strata_level,
                                  covar_terms, covar_vars) {
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars)
  
  d <- data %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100) {
    return(tibble(
      strata = strata_name,
      strata_level = strata_level,
      outcome = outcome,
      outcome_label = outcome_label,
      label = label,
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
    strata = strata_name,
    strata_level = strata_level,
    outcome = outcome,
    outcome_label = outcome_label,
    label = label,
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

results_list <- list()

# ------------------------------------------------------------
# 1. 性别分层
# ------------------------------------------------------------

sex_strata <- list(
  Male = analysis_df %>% filter(RIAGENDR == 1),
  Female = analysis_df %>% filter(RIAGENDR == 2)
)

covars_no_sex <- c(
  "RIDAGEYR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

terms_no_sex <- paste0(
  "RIDAGEYR + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

for (sex_name in names(sex_strata)) {
  for (i in seq_len(nrow(dehp_map))) {
    for (j in seq_len(nrow(outcome_map))) {
      results_list[[length(results_list) + 1]] <- run_stratified_linear(
        data = sex_strata[[sex_name]],
        outcome = outcome_map$outcome[j],
        outcome_label = outcome_map$outcome_label[j],
        is_log_outcome = outcome_map$is_log_outcome[j],
        exposure = dehp_map$exposure[i],
        label = dehp_map$label[i],
        strata_name = "Sex",
        strata_level = sex_name,
        covar_terms = terms_no_sex,
        covar_vars = covars_no_sex
      )
    }
  }
}

# ------------------------------------------------------------
# 2. 肥胖状态分层
# ------------------------------------------------------------

obesity_strata <- list(
  Non_obese = analysis_df %>% filter(obesity == 0),
  Obese = analysis_df %>% filter(obesity == 1)
)

covars_model2 <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

terms_model2 <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

for (ob_name in names(obesity_strata)) {
  for (i in seq_len(nrow(dehp_map))) {
    for (j in seq_len(nrow(outcome_map))) {
      results_list[[length(results_list) + 1]] <- run_stratified_linear(
        data = obesity_strata[[ob_name]],
        outcome = outcome_map$outcome[j],
        outcome_label = outcome_map$outcome_label[j],
        is_log_outcome = outcome_map$is_log_outcome[j],
        exposure = dehp_map$exposure[i],
        label = dehp_map$label[i],
        strata_name = "Obesity_status",
        strata_level = ob_name,
        covar_terms = terms_model2,
        covar_vars = covars_model2
      )
    }
  }
}

stratified_results <- bind_rows(results_list) %>%
  group_by(strata, strata_level, outcome) %>%
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

print(stratified_results)

write_csv(
  stratified_results,
  file.path(result_dir, "stratified_DEHP_2013_2018.csv")
)

write_xlsx(
  list(
    stratified_results = stratified_results
  ),
  file.path(result_dir, "stratified_DEHP_2013_2018.xlsx")
)

cat("DEHP 分层分析完成：stratified_DEHP_2013_2018.xlsx\n")