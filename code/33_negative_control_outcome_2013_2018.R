# ============================================================
# NHANES 2013-2018
# 33_negative_control_outcome_2013_2018.R
# Negative-control outcome analysis
# ============================================================

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(tibble)
library(survey)
library(writexl)

options(survey.lonely.psu = "adjust")

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_master_analysis_mechanism.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]

if (is.na(data_file)) {
  stop("找不到 2013-2018 分析数据。")
}

df <- readRDS(data_file)

# ------------------------------------------------------------
# 1. Define negative-control outcomes
# ------------------------------------------------------------

negative_outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~interpretation,
  "BMXHT", "Adult height", "Primary negative-control outcome: current urinary DEHP metabolites should not causally affect attained adult height."
)

# If BMXHT is missing from the dataset, stop with clear message
if (!"BMXHT" %in% names(df)) {
  stop("当前数据中没有 BMXHT。请确认主分析数据合并了 Body Measures 文件并保留 BMXHT。")
}

# ------------------------------------------------------------
# 2. Exposure map
# ------------------------------------------------------------

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~include_creatinine,
  "ln_Sigma_DEHP", "ln(Sigma DEHP)", TRUE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE,
  "ln_URXMHH", "MEHHP", TRUE,
  "ln_URXMOH", "MEOHP", TRUE,
  "ln_URXECP", "MECPP", TRUE
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
# 3. Model function
# ------------------------------------------------------------

run_negative_control_model <- function(outcome, outcome_label, interpretation,
                                       exposure, exposure_label, include_creatinine) {
  
  covar_vars <- if (include_creatinine) covars_with_creatinine else covars_without_creatinine
  covar_terms <- if (include_creatinine) terms_with_creatinine else terms_without_creatinine
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars)
  
  d <- df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 200) {
    return(tibble())
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
  
  tibble(
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = beta,
    effect_low = low,
    effect_high = high,
    negative_control_rationale = interpretation
  )
}

negative_control_results <- expand_grid(
  outcome_row = seq_len(nrow(negative_outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result = map2(outcome_row, exposure_row, function(i, j) {
      run_negative_control_model(
        outcome = negative_outcome_map$outcome[i],
        outcome_label = negative_outcome_map$outcome_label[i],
        interpretation = negative_outcome_map$interpretation[i],
        exposure = exposure_map$exposure[j],
        exposure_label = exposure_map$exposure_label[j],
        include_creatinine = exposure_map$include_creatinine[j]
      )
    })
  ) %>%
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
    ),
    falsification_interpretation = case_when(
      q_value < 0.05 ~ "Potential concern: association observed with negative-control outcome",
      p_value < 0.05 ~ "Nominal concern: weak negative-control association",
      TRUE ~ "No evidence of negative-control association"
    )
  )

print(negative_control_results)

write_csv(
  negative_control_results,
  file.path(result_dir, "negative_control_outcome_2013_2018.csv")
)

write_xlsx(
  list(
    negative_control_results = negative_control_results
  ),
  file.path(result_dir, "negative_control_outcome_2013_2018.xlsx")
)

cat("Negative-control outcome analysis completed successfully.\n")