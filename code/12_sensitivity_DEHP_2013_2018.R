# ============================================================
# NHANES 2013-2018
# 12_sensitivity_DEHP_2013_2018.R
# Sensitivity analyses for DEHP metabolites and metabolic markers
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

# ------------------------------------------------------------
# 1. 构建肌酐校正暴露变量
# ------------------------------------------------------------

analysis_df <- analysis_df %>%
  mutate(
    cr_ln_URXMHP = ifelse(!is.na(URXMHP) & !is.na(URXUCR) & URXMHP > 0 & URXUCR > 0,
                          log(URXMHP / URXUCR), NA_real_),
    cr_ln_URXMHH = ifelse(!is.na(URXMHH) & !is.na(URXUCR) & URXMHH > 0 & URXUCR > 0,
                          log(URXMHH / URXUCR), NA_real_),
    cr_ln_URXMOH = ifelse(!is.na(URXMOH) & !is.na(URXUCR) & URXMOH > 0 & URXUCR > 0,
                          log(URXMOH / URXUCR), NA_real_),
    cr_ln_URXECP = ifelse(!is.na(URXECP) & !is.na(URXUCR) & URXECP > 0 & URXUCR > 0,
                          log(URXECP / URXUCR), NA_real_)
  )

# ------------------------------------------------------------
# 2. 暴露与结局定义
# ------------------------------------------------------------

dehp_map <- tibble::tribble(
  ~label,  ~standard_exposure, ~creatinine_exposure,
  "MEHP",  "ln_URXMHP",       "cr_ln_URXMHP",
  "MEHHP", "ln_URXMHH",       "cr_ln_URXMHH",
  "MEOHP", "ln_URXMOH",       "cr_ln_URXMOH",
  "MECPP", "ln_URXECP",       "cr_ln_URXECP"
)

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE,
  "TyG", "TyG index", FALSE,
  "ln_TG_HDL", "ln(TG/HDL-C)", TRUE
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")

covars_model2 <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

covars_model2_no_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "cycle"
)

covars_lifestyle <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle",
  "ever_smoker", "alcohol_ever", "any_physical_activity"
)

terms_model2 <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

terms_model2_no_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + factor(cycle)"
)

terms_lifestyle <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle) + ",
  "factor(ever_smoker) + factor(alcohol_ever) + factor(any_physical_activity)"
)

# ------------------------------------------------------------
# 3. 加权线性回归函数
# ------------------------------------------------------------

run_svy_linear_sensitivity <- function(data, outcome, outcome_label, is_log_outcome,
                                       exposure, label, scenario,
                                       covar_vars, covar_terms,
                                       trim_exposure = FALSE) {
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars)
  
  d <- data %>%
    dplyr::select(dplyr::any_of(model_vars)) %>%
    tidyr::drop_na()
  
  if (trim_exposure && nrow(d) > 0) {
    qs <- quantile(d[[exposure]], probs = c(0.01, 0.99), na.rm = TRUE)
    d <- d %>%
      filter(.data[[exposure]] >= qs[1], .data[[exposure]] <= qs[2])
  }
  
  if (nrow(d) < 100) {
    return(tibble(
      scenario = scenario,
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
    return(tibble(
      scenario = scenario,
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
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) {
    return(tibble(
      scenario = scenario,
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
    scenario = scenario,
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

# ------------------------------------------------------------
# 4. 批量运行敏感性分析
# ------------------------------------------------------------

results_list <- list()

for (i in seq_len(nrow(dehp_map))) {
  
  label_i <- dehp_map$label[i]
  exp_std <- dehp_map$standard_exposure[i]
  exp_cr <- dehp_map$creatinine_exposure[i]
  
  for (j in seq_len(nrow(outcome_map))) {
    
    outcome_j <- outcome_map$outcome[j]
    outcome_label_j <- outcome_map$outcome_label[j]
    is_log_j <- outcome_map$is_log_outcome[j]
    
    # A. 主模型复现
    results_list[[length(results_list) + 1]] <- run_svy_linear_sensitivity(
      data = analysis_df,
      outcome = outcome_j,
      outcome_label = outcome_label_j,
      is_log_outcome = is_log_j,
      exposure = exp_std,
      label = label_i,
      scenario = "A_Main_Model2",
      covar_vars = covars_model2,
      covar_terms = terms_model2,
      trim_exposure = FALSE
    )
    
    # B. 排除糖尿病患者
    results_list[[length(results_list) + 1]] <- run_svy_linear_sensitivity(
      data = analysis_df %>% filter(diabetes_history == 0),
      outcome = outcome_j,
      outcome_label = outcome_label_j,
      is_log_outcome = is_log_j,
      exposure = exp_std,
      label = label_i,
      scenario = "B_Exclude_diabetes",
      covar_vars = covars_model2,
      covar_terms = terms_model2,
      trim_exposure = FALSE
    )
    
    # C. 排除暴露极端值 P1-P99
    results_list[[length(results_list) + 1]] <- run_svy_linear_sensitivity(
      data = analysis_df,
      outcome = outcome_j,
      outcome_label = outcome_label_j,
      is_log_outcome = is_log_j,
      exposure = exp_std,
      label = label_i,
      scenario = "C_Trim_exposure_P1_P99",
      covar_vars = covars_model2,
      covar_terms = terms_model2,
      trim_exposure = TRUE
    )
    
    # D. 额外调整生活方式
    results_list[[length(results_list) + 1]] <- run_svy_linear_sensitivity(
      data = analysis_df,
      outcome = outcome_j,
      outcome_label = outcome_label_j,
      is_log_outcome = is_log_j,
      exposure = exp_std,
      label = label_i,
      scenario = "D_Lifestyle_adjusted",
      covar_vars = covars_lifestyle,
      covar_terms = terms_lifestyle,
      trim_exposure = FALSE
    )
    
    # E. 肌酐校正暴露浓度，不再额外调整尿肌酐
    results_list[[length(results_list) + 1]] <- run_svy_linear_sensitivity(
      data = analysis_df,
      outcome = outcome_j,
      outcome_label = outcome_label_j,
      is_log_outcome = is_log_j,
      exposure = exp_cr,
      label = label_i,
      scenario = "E_Creatinine_corrected_exposure",
      covar_vars = covars_model2_no_creatinine,
      covar_terms = terms_model2_no_creatinine,
      trim_exposure = FALSE
    )
  }
}

sensitivity_results <- bind_rows(results_list) %>%
  group_by(scenario, outcome) %>%
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
# 5. 生成稳健性汇总表
# ------------------------------------------------------------

stability_summary <- sensitivity_results %>%
  filter(label %in% c("MEHHP", "MEOHP", "MECPP"),
         outcome_label %in% c("ln(HOMA-IR)", "HbA1c")) %>%
  group_by(label, outcome_label) %>%
  summarise(
    n_models = n(),
    positive_models = sum(direction == "positive", na.rm = TRUE),
    nominal_sig_models = sum(p_value < 0.05, na.rm = TRUE),
    fdr_sig_models = sum(q_value < 0.05, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    stability_judgement = case_when(
      positive_models >= 4 & nominal_sig_models >= 3 ~ "strong",
      positive_models >= 4 & nominal_sig_models >= 1 ~ "moderate",
      positive_models >= 3 ~ "suggestive",
      TRUE ~ "weak"
    )
  )

print(sensitivity_results)
print(stability_summary)

write_csv(
  sensitivity_results,
  file.path(result_dir, "sensitivity_DEHP_metabolic_2013_2018.csv")
)

write_xlsx(
  list(
    sensitivity_results = sensitivity_results,
    stability_summary = stability_summary
  ),
  file.path(result_dir, "sensitivity_DEHP_metabolic_2013_2018.xlsx")
)

cat("DEHP 敏感性分析完成：sensitivity_DEHP_metabolic_2013_2018.xlsx\n")