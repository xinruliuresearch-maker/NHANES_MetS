# ============================================================
# NHANES 2013-2018
# 15_DEHP_mixture_index_2013_2018.R
# DEHP-specific mixture index analysis
# ============================================================

library(dplyr)
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

dehp_vars <- c(
  "ln_URXMHP",
  "ln_URXMHH",
  "ln_URXMOH",
  "ln_URXECP"
)

dehp_vars <- intersect(dehp_vars, names(analysis_df))

make_quartile_score <- function(x) {
  qs <- quantile(x, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
  qs <- unique(qs)
  
  if (length(qs) < 5) {
    return(rep(NA_integer_, length(x)))
  }
  
  as.integer(cut(
    x,
    breaks = qs,
    include.lowest = TRUE,
    labels = FALSE
  ))
}

mixture_df <- analysis_df %>%
  mutate(
    across(
      all_of(dehp_vars),
      make_quartile_score,
      .names = "q_{.col}"
    )
  )

q_dehp_vars <- paste0("q_", dehp_vars)

mixture_df <- mixture_df %>%
  mutate(
    DEHP_mixture_q = ifelse(
      rowSums(!is.na(across(all_of(q_dehp_vars)))) > 0,
      rowMeans(across(all_of(q_dehp_vars)), na.rm = TRUE),
      NA_real_
    )
  )

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~model_type, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", "linear", TRUE,
  "HbA1c", "HbA1c", "linear", FALSE,
  "TyG", "TyG index", "linear", FALSE,
  "ln_TG_HDL", "ln(TG/HDL-C)", "linear", TRUE,
  "metabolic_syndrome", "Metabolic syndrome", "logistic", FALSE
)

covar_vars <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")

covar_terms <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

run_mixture_model <- function(outcome, outcome_label, model_type, is_log_outcome) {
  
  model_vars <- c(outcome, "DEHP_mixture_q", covar_vars, design_vars)
  
  d <- mixture_df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100) {
    return(tibble(
      outcome = outcome,
      outcome_label = outcome_label,
      model_type = model_type,
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
    paste0(outcome, " ~ DEHP_mixture_q + ", covar_terms)
  )
  
  fit <- tryCatch(
    {
      if (model_type == "logistic") {
        svyglm(f, design = des, family = quasibinomial())
      } else {
        svyglm(f, design = des)
      }
    },
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble())
  }
  
  coef_table <- summary(fit)$coefficients
  
  beta <- coef_table["DEHP_mixture_q", "Estimate"]
  se <- coef_table["DEHP_mixture_q", "Std. Error"]
  p_value <- coef_table["DEHP_mixture_q", "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  if (model_type == "logistic") {
    effect <- exp(beta)
    effect_low <- exp(low)
    effect_high <- exp(high)
  } else if (is_log_outcome) {
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
    model_type = model_type,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = effect,
    effect_low = effect_low,
    effect_high = effect_high
  )
}

dehp_mixture_results <- outcome_map %>%
  rowwise() %>%
  mutate(
    result = list(
      run_mixture_model(outcome, outcome_label, model_type, is_log_outcome)
    )
  ) %>%
  ungroup() %>%
  select(result) %>%
  unnest(result) %>%
  mutate(
    q_value = p.adjust(p_value, method = "BH"),
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

print(dehp_mixture_results)

write_csv(
  dehp_mixture_results,
  file.path(result_dir, "DEHP_mixture_index_2013_2018.csv")
)

write_xlsx(
  list(
    DEHP_mixture_index_results = dehp_mixture_results
  ),
  file.path(result_dir, "DEHP_mixture_index_2013_2018.xlsx")
)

cat("DEHP 混合暴露指数分析完成：DEHP_mixture_index_2013_2018.xlsx\n")