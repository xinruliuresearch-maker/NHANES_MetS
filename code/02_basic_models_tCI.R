# ============================================================
# NHANES 2017-2018
# Organic Pollutants and Obesity / Metabolic Syndrome
# 02_basic_models_tCI.R
# t-based CI for survey-weighted logistic models
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

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

analysis_df <- readRDS(
  file.path(output_dir, "NHANES_2017_2018_master_analysis.rds")
)

cat("读取分析数据成功。\n")
cat("总样本量：", nrow(analysis_df), "\n")

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

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label,
  "obesity", "Obesity",
  "central_obesity", "Central obesity",
  "metabolic_syndrome", "Metabolic syndrome"
)

run_svy_logistic <- function(outcome, exposure) {
  
  model_vars <- c(
    outcome,
    exposure,
    "RIDAGEYR",
    "RIAGENDR",
    "RIDRETH3",
    "INDFMPIR",
    "DR1TKCAL",
    "ln_URXUCR",
    "SDMVPSU",
    "SDMVSTRA",
    "WTSB2YR_MAIN"
  )
  
  d <- analysis_df %>%
    dplyr::select(dplyr::any_of(model_vars)) %>%
    tidyr::drop_na()
  
  if (nrow(d) < 100 || length(unique(d[[outcome]])) < 2) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      events = ifelse(outcome %in% names(d), sum(d[[outcome]] == 1, na.rm = TRUE), NA_integer_),
      beta = NA_real_,
      se = NA_real_,
      df_resid = NA_real_,
      p_value = NA_real_,
      OR = NA_real_,
      OR_low = NA_real_,
      OR_high = NA_real_
    ))
  }
  
  des <- survey::svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB2YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(
      outcome, " ~ ", exposure,
      " + RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3)",
      " + INDFMPIR + DR1TKCAL + ln_URXUCR"
    )
  )
  
  fit <- tryCatch(
    survey::svyglm(
      f,
      design = des,
      family = quasibinomial()
    ),
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
      df_resid = NA_real_,
      p_value = NA_real_,
      OR = NA_real_,
      OR_low = NA_real_,
      OR_high = NA_real_
    ))
  }
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      events = sum(d[[outcome]] == 1, na.rm = TRUE),
      beta = NA_real_,
      se = NA_real_,
      df_resid = NA_real_,
      p_value = NA_real_,
      OR = NA_real_,
      OR_low = NA_real_,
      OR_high = NA_real_
    ))
  }
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  
  if (is.null(df_resid) || is.na(df_resid) || df_resid <= 0) {
    tcrit <- 1.96
  } else {
    tcrit <- qt(0.975, df = df_resid)
  }
  
  tibble(
    outcome = outcome,
    exposure = exposure,
    n = nrow(d),
    events = sum(d[[outcome]] == 1, na.rm = TRUE),
    beta = beta,
    se = se,
    df_resid = df_resid,
    p_value = p_value,
    OR = exp(beta),
    OR_low = exp(beta - tcrit * se),
    OR_high = exp(beta + tcrit * se)
  )
}

basic_results_tCI <- tidyr::expand_grid(
  outcome = outcome_map$outcome,
  exposure = pollutant_map$exposure
) %>%
  mutate(
    result = purrr::map2(outcome, exposure, run_svy_logistic)
  ) %>%
  dplyr::select(result) %>%
  tidyr::unnest(result) %>%
  left_join(outcome_map, by = "outcome") %>%
  left_join(pollutant_map, by = "exposure") %>%
  mutate(
    OR_CI = ifelse(
      is.na(OR),
      NA_character_,
      sprintf("%.3f (%.3f, %.3f)", OR, OR_low, OR_high)
    ),
    p_value_fmt = case_when(
      is.na(p_value) ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_value)
    )
  ) %>%
  dplyr::select(
    outcome,
    outcome_label,
    group,
    pollutant,
    label,
    exposure,
    n,
    events,
    OR,
    OR_low,
    OR_high,
    OR_CI,
    p_value,
    p_value_fmt,
    beta,
    se,
    df_resid
  )

print(basic_results_tCI)

write_csv(
  basic_results_tCI,
  file.path(result_dir, "basic_weighted_logistic_results_tCI.csv")
)

write_xlsx(
  list(
    basic_weighted_logistic_results_tCI = basic_results_tCI
  ),
  file.path(result_dir, "basic_weighted_logistic_results_tCI.xlsx")
)

cat("t-based CI 修正后的基础模型结果已经导出到 result 文件夹。\n")