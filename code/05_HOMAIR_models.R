# ============================================================
# NHANES 2017-2018
# 05_HOMAIR_models.R
# Survey-weighted linear regression for ln(HOMA-IR)
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
  file.path(output_dir, "NHANES_2017_2018_master_analysis.rds")
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

run_homair_model <- function(exposure) {
  
  model_vars <- c(
    "ln_HOMA_IR",
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
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100) {
    return(tibble(
      exposure = exposure,
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      percent_change = NA_real_,
      percent_low = NA_real_,
      percent_high = NA_real_
    ))
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB2YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(
      "ln_HOMA_IR ~ ", exposure,
      " + RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3)",
      " + INDFMPIR + DR1TKCAL + ln_URXUCR"
    )
  )
  
  fit <- svyglm(f, design = des)
  
  coef_table <- summary(fit)$coefficients
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  if (is.null(df_resid) || is.na(df_resid) || df_resid <= 0) {
    tcrit <- 1.96
  } else {
    tcrit <- qt(0.975, df = df_resid)
  }
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  tibble(
    exposure = exposure,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    percent_change = (exp(beta) - 1) * 100,
    percent_low = (exp(low) - 1) * 100,
    percent_high = (exp(high) - 1) * 100
  )
}

homair_results <- pollutant_map %>%
  mutate(result = map(exposure, run_homair_model)) %>%
  select(result) %>%
  unnest(result) %>%
  left_join(pollutant_map, by = "exposure") %>%
  mutate(
    percent_CI = sprintf(
      "%.2f%% (%.2f%%, %.2f%%)",
      percent_change,
      percent_low,
      percent_high
    ),
    p_value_fmt = case_when(
      is.na(p_value) ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_value)
    )
  ) %>%
  select(
    group,
    pollutant,
    label,
    exposure,
    n,
    beta,
    se,
    percent_change,
    percent_low,
    percent_high,
    percent_CI,
    p_value,
    p_value_fmt
  )

print(homair_results)

write_csv(
  homair_results,
  file.path(result_dir, "HOMAIR_weighted_linear_results.csv")
)

write_xlsx(
  list(
    HOMAIR_weighted_linear_results = homair_results
  ),
  file.path(result_dir, "HOMAIR_weighted_linear_results.xlsx")
)

cat("HOMA-IR 线性回归结果已导出到 result 文件夹。\n")