# ============================================================
# NHANES 2013-2018
# 25_WQS_DEHP_2013_2018_sensitivity.R
# Exploratory WQS sensitivity analysis using gWQS
# ============================================================

if (!requireNamespace("gWQS", quietly = TRUE)) {
  install.packages("gWQS")
}

library(dplyr)
library(tidyr)
library(readr)
library(tibble)
library(writexl)
library(gWQS)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

data_file_derived <- file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds")
data_file_base <- file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")

if (file.exists(data_file_derived)) {
  df <- readRDS(data_file_derived)
} else {
  df <- readRDS(data_file_base)
}

mix_all <- c("ln_URXMHP", "ln_URXMHH", "ln_URXMOH", "ln_URXECP")
mix_oxidative <- c("ln_URXMHH", "ln_URXMOH", "ln_URXECP")

component_labels <- tibble::tribble(
  ~variable, ~component,
  "ln_URXMHP", "MEHP",
  "ln_URXMHH", "MEHHP",
  "ln_URXMOH", "MEOHP",
  "ln_URXECP", "MECPP"
)

covars <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

prepare_wqs_data <- function(outcome, mix_vars) {
  model_vars <- c(outcome, mix_vars, covars)
  
  df %>%
    select(any_of(model_vars)) %>%
    drop_na() %>%
    mutate(
      RIAGENDR = factor(RIAGENDR),
      RIDRETH3 = factor(RIDRETH3),
      DMDEDUC2 = factor(DMDEDUC2),
      cycle = factor(cycle)
    )
}

run_wqs_model <- function(outcome, outcome_label, mix_name, mix_vars, seed_i = 2026) {
  
  d <- prepare_wqs_data(outcome, mix_vars)
  
  if (nrow(d) < 300) {
    return(list(
      result = tibble(),
      weights = tibble()
    ))
  }
  
  f <- as.formula(
    paste0(
      outcome,
      " ~ wqs + RIDAGEYR + RIAGENDR + RIDRETH3 + INDFMPIR + ",
      "DMDEDUC2 + DR1TKCAL + ln_URXUCR + cycle"
    )
  )
  
  fit <- tryCatch(
    gwqs(
      formula = f,
      mix_name = mix_vars,
      data = d,
      q = 4,
      validation = 0.6,
      b = 100,
      b1_pos = TRUE,
      b1_constr = FALSE,
      family = "gaussian",
      seed = seed_i,
      wqs2 = FALSE,
      plots = FALSE,
      tables = FALSE
    ),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(list(
      result = tibble(),
      weights = tibble()
    ))
  }
  
  fit_sum <- summary(fit$fit)$coefficients
  
  if (!"wqs" %in% rownames(fit_sum)) {
    return(list(
      result = tibble(),
      weights = tibble()
    ))
  }
  
  beta <- fit_sum["wqs", "Estimate"]
  se <- fit_sum["wqs", "Std. Error"]
  p_value <- fit_sum["wqs", "Pr(>|t|)"]
  
  low <- beta - 1.96 * se
  high <- beta + 1.96 * se
  
  result <- tibble(
    dataset = "NHANES 2013-2018",
    method = "gWQS exploratory sensitivity",
    mixture = mix_name,
    outcome = outcome,
    outcome_label = outcome_label,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = ifelse(outcome == "ln_HOMA_IR", (exp(beta) - 1) * 100, beta),
    effect_low = ifelse(outcome == "ln_HOMA_IR", (exp(low) - 1) * 100, low),
    effect_high = ifelse(outcome == "ln_HOMA_IR", (exp(high) - 1) * 100, high)
  )
  
  weights <- fit$final_weights %>%
    as_tibble() %>%
    rename(
      variable = mix_name,
      weight = mean_weight
    ) %>%
    left_join(component_labels, by = "variable") %>%
    mutate(
      dataset = "NHANES 2013-2018",
      method = "gWQS exploratory sensitivity",
      mixture = mix_name,
      outcome = outcome,
      outcome_label = outcome_label
    )
  
  list(
    result = result,
    weights = weights
  )
}

runs <- list(
  run_wqs_model("ln_HOMA_IR", "ln(HOMA-IR)", "DEHP_all", mix_all, seed_i = 202601),
  run_wqs_model("HbA1c", "HbA1c", "DEHP_all", mix_all, seed_i = 202602),
  run_wqs_model("ln_HOMA_IR", "ln(HOMA-IR)", "DEHP_oxidative", mix_oxidative, seed_i = 202603),
  run_wqs_model("HbA1c", "HbA1c", "DEHP_oxidative", mix_oxidative, seed_i = 202604)
)

wqs_results <- bind_rows(lapply(runs, `[[`, "result")) %>%
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
    evidence_level = case_when(
      q_value < 0.05 ~ "FDR-significant",
      p_value < 0.05 ~ "Nominally significant",
      beta > 0 ~ "Positive direction only",
      TRUE ~ "Weak/no support"
    )
  )

wqs_weights <- bind_rows(lapply(runs, `[[`, "weights"))

print(wqs_results)
print(wqs_weights)

write_csv(
  wqs_results,
  file.path(result_dir, "WQS_DEHP_2013_2018_sensitivity_results.csv")
)

write_csv(
  wqs_weights,
  file.path(result_dir, "WQS_DEHP_2013_2018_sensitivity_weights.csv")
)

write_xlsx(
  list(
    wqs_results = wqs_results,
    wqs_weights = wqs_weights
  ),
  file.path(result_dir, "WQS_DEHP_2013_2018_sensitivity.xlsx")
)

cat("Exploratory WQS sensitivity analysis completed.\n")