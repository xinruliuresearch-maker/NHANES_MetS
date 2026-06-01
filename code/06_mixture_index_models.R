# ============================================================
# NHANES 2017-2018
# 06_mixture_index_models.R
# Exploratory mixture index models
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

# ------------------------------------------------------------
# 1. 定义污染物组
# ------------------------------------------------------------

bisphenol_vars <- c("ln_URXBPH", "ln_URXBPF", "ln_URXBPS")

phthalate_vars <- c(
  "ln_URXMEP", "ln_URXMBP", "ln_URXMIB",
  "ln_URXMHP", "ln_URXMHH", "ln_URXMOH",
  "ln_URXECP", "ln_URXMZP"
)

plasticizer_vars <- c(
  "ln_URXCOP", "ln_URXCNP", "ln_URXMNP", "ln_URXMONP"
)

bisphenol_vars <- intersect(bisphenol_vars, names(analysis_df))
phthalate_vars <- intersect(phthalate_vars, names(analysis_df))
plasticizer_vars <- intersect(plasticizer_vars, names(analysis_df))

all_pollutant_vars <- c(bisphenol_vars, phthalate_vars, plasticizer_vars)

# ------------------------------------------------------------
# 2. 分位数函数：把污染物分成 1-4 分
# ------------------------------------------------------------

make_quartile_score <- function(x) {
  qs <- quantile(x, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
  qs <- unique(qs)
  
  if (length(qs) < 3) {
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
      all_of(all_pollutant_vars),
      make_quartile_score,
      .names = "q_{.col}"
    )
  )

q_bisphenol_vars <- paste0("q_", bisphenol_vars)
q_phthalate_vars <- paste0("q_", phthalate_vars)
q_plasticizer_vars <- paste0("q_", plasticizer_vars)
q_all_vars <- paste0("q_", all_pollutant_vars)

mixture_df <- mixture_df %>%
  mutate(
    bisphenol_mixture_q = ifelse(
      rowSums(!is.na(across(all_of(q_bisphenol_vars)))) > 0,
      rowMeans(across(all_of(q_bisphenol_vars)), na.rm = TRUE),
      NA_real_
    ),
    phthalate_mixture_q = ifelse(
      rowSums(!is.na(across(all_of(q_phthalate_vars)))) > 0,
      rowMeans(across(all_of(q_phthalate_vars)), na.rm = TRUE),
      NA_real_
    ),
    plasticizer_mixture_q = ifelse(
      rowSums(!is.na(across(all_of(q_plasticizer_vars)))) > 0,
      rowMeans(across(all_of(q_plasticizer_vars)), na.rm = TRUE),
      NA_real_
    ),
    total_mixture_q = ifelse(
      rowSums(!is.na(across(all_of(q_all_vars)))) > 0,
      rowMeans(across(all_of(q_all_vars)), na.rm = TRUE),
      NA_real_
    )
  )

# ------------------------------------------------------------
# 3. 混合指数模型函数
# ------------------------------------------------------------

mixture_map <- tibble::tribble(
  ~mixture_var, ~mixture_label,
  "bisphenol_mixture_q", "Bisphenol mixture index",
  "phthalate_mixture_q", "Phthalate mixture index",
  "plasticizer_mixture_q", "Plasticizer mixture index",
  "total_mixture_q", "Total organic pollutant mixture index"
)

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label,
  "obesity", "Obesity",
  "central_obesity", "Central obesity",
  "metabolic_syndrome", "Metabolic syndrome"
)

run_mixture_logistic <- function(outcome, mixture_var) {
  
  model_vars <- c(
    outcome,
    mixture_var,
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
  
  d <- mixture_df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100 || length(unique(d[[outcome]])) < 2) {
    return(tibble(
      outcome = outcome,
      mixture_var = mixture_var,
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
    weights = ~WTSB2YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(
      outcome, " ~ ", mixture_var,
      " + RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3)",
      " + INDFMPIR + DR1TKCAL + ln_URXUCR"
    )
  )
  
  fit <- tryCatch(
    svyglm(f, design = des, family = quasibinomial()),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble(
      outcome = outcome,
      mixture_var = mixture_var,
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
  
  beta <- coef_table[mixture_var, "Estimate"]
  se <- coef_table[mixture_var, "Std. Error"]
  p_value <- coef_table[mixture_var, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  if (is.null(df_resid) || is.na(df_resid) || df_resid <= 0) {
    tcrit <- 1.96
  } else {
    tcrit <- qt(0.975, df = df_resid)
  }
  
  tibble(
    outcome = outcome,
    mixture_var = mixture_var,
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

mixture_results <- expand_grid(
  outcome = outcome_map$outcome,
  mixture_var = mixture_map$mixture_var
) %>%
  mutate(
    result = map2(outcome, mixture_var, run_mixture_logistic)
  ) %>%
  select(result) %>%
  unnest(result) %>%
  left_join(outcome_map, by = "outcome") %>%
  left_join(mixture_map, by = "mixture_var") %>%
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
  select(
    outcome,
    outcome_label,
    mixture_var,
    mixture_label,
    n,
    events,
    OR,
    OR_low,
    OR_high,
    OR_CI,
    p_value,
    p_value_fmt,
    beta,
    se
  )

print(mixture_results)

write_csv(
  mixture_results,
  file.path(result_dir, "mixture_index_logistic_results.csv")
)

write_xlsx(
  list(
    mixture_index_logistic_results = mixture_results
  ),
  file.path(result_dir, "mixture_index_logistic_results.xlsx")
)

cat("混合暴露指数模型结果已导出到 result 文件夹。\n")