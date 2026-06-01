# ============================================================
# NHANES 2013-2018
# 32_Evalue_binary_sensitivity_2013_2018.R
# E-value sensitivity analysis for binary metabolic endpoints
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

# ------------------------------------------------------------
# 1. Read best available analysis data
# ------------------------------------------------------------

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_master_analysis_mechanism.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]

if (is.na(data_file)) {
  stop("找不到 2013-2018 分析数据，请检查 output 文件夹。")
}

df <- readRDS(data_file)

# ------------------------------------------------------------
# 2. Helper functions
# ------------------------------------------------------------

weighted_quantile <- function(x, w, probs) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]
  w <- w[ok]
  
  if (length(x) == 0) {
    return(rep(NA_real_, length(probs)))
  }
  
  ord <- order(x)
  x <- x[ord]
  w <- w[ord] / sum(w)
  cw <- cumsum(w)
  
  sapply(probs, function(p) x[which(cw >= p)[1]])
}

make_weighted_quartile <- function(x, w) {
  out <- rep(NA_integer_, length(x))
  ok <- !is.na(x) & !is.na(w) & w > 0
  
  if (sum(ok) < 50) return(out)
  
  breaks <- weighted_quantile(x[ok], w[ok], probs = c(0, 0.25, 0.5, 0.75, 1))
  breaks[1] <- -Inf
  breaks[5] <- Inf
  breaks <- unique(breaks)
  
  if (length(breaks) < 5) return(out)
  
  out[ok] <- as.integer(
    cut(x[ok], breaks = breaks, include.lowest = TRUE, labels = FALSE)
  )
  
  out
}

evalue_rr <- function(rr) {
  if (is.na(rr) || rr <= 0) return(NA_real_)
  
  rr_use <- ifelse(rr < 1, 1 / rr, rr)
  rr_use + sqrt(rr_use * (rr_use - 1))
}

or_to_rr_approx <- function(or, p0) {
  if (is.na(or) || is.na(p0)) return(NA_real_)
  or / ((1 - p0) + (p0 * or))
}

weighted_mean_binary <- function(y, w) {
  ok <- !is.na(y) & !is.na(w) & w > 0
  if (sum(ok) == 0) return(NA_real_)
  sum(y[ok] * w[ok]) / sum(w[ok])
}

# ------------------------------------------------------------
# 3. Construct binary outcomes and exposure quartiles
# ------------------------------------------------------------

df <- df %>%
  mutate(
    high_HOMA_IR_q75 = ifelse(
      !is.na(HOMA_IR),
      as.integer(HOMA_IR >= quantile(HOMA_IR, 0.75, na.rm = TRUE)),
      NA_integer_
    ),
    high_HOMA_IR_2_5 = ifelse(
      !is.na(HOMA_IR),
      as.integer(HOMA_IR >= 2.5),
      NA_integer_
    ),
    elevated_HbA1c_5_7 = ifelse(
      !is.na(HbA1c),
      as.integer(HbA1c >= 5.7),
      NA_integer_
    ),
    diabetes_range_HbA1c_6_5 = ifelse(
      !is.na(HbA1c),
      as.integer(HbA1c >= 6.5),
      NA_integer_
    )
  )

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~include_creatinine,
  "ln_Sigma_DEHP", "ln(Sigma DEHP)", TRUE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE,
  "ln_URXMHH", "MEHHP", TRUE,
  "ln_URXMOH", "MEOHP", TRUE,
  "ln_URXECP", "MECPP", TRUE
)

binary_outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label,
  "high_HOMA_IR_q75", "High HOMA-IR, top quartile",
  "high_HOMA_IR_2_5", "High HOMA-IR >= 2.5",
  "elevated_HbA1c_5_7", "HbA1c >= 5.7%",
  "diabetes_range_HbA1c_6_5", "HbA1c >= 6.5%",
  "obesity", "Obesity",
  "central_obesity", "Central obesity",
  "metabolic_syndrome", "Metabolic syndrome"
)

for (i in seq_len(nrow(exposure_map))) {
  var_i <- exposure_map$exposure[i]
  q_i <- paste0("q_", var_i)
  
  df[[q_i]] <- make_weighted_quartile(df[[var_i]], df$WTSB6YR_MAIN)
}

# ------------------------------------------------------------
# 4. Model settings
# ------------------------------------------------------------

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
# 5. Run Q4 vs Q1 logistic models and E-values
# ------------------------------------------------------------

run_evalue_model <- function(outcome, outcome_label,
                             exposure, exposure_label, include_creatinine) {
  
  q_var <- paste0("q_", exposure)
  
  covar_vars <- if (include_creatinine) covars_with_creatinine else covars_without_creatinine
  covar_terms <- if (include_creatinine) terms_with_creatinine else terms_without_creatinine
  
  model_vars <- c(outcome, q_var, covar_vars, design_vars)
  
  d <- df %>%
    select(any_of(model_vars)) %>%
    drop_na() %>%
    filter(.data[[q_var]] %in% c(1, 4)) %>%
    mutate(
      exposure_Q4_vs_Q1 = ifelse(.data[[q_var]] == 4, 1, 0)
    )
  
  if (nrow(d) < 100 || length(unique(d[[outcome]])) < 2) {
    return(tibble())
  }
  
  p0 <- d %>%
    filter(exposure_Q4_vs_Q1 == 0) %>%
    summarise(p0 = weighted_mean_binary(.data[[outcome]], WTSB6YR_MAIN)) %>%
    pull(p0)
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(outcome, " ~ exposure_Q4_vs_Q1 + ", covar_terms)
  )
  
  fit <- tryCatch(
    svyglm(f, design = des, family = quasibinomial()),
    error = function(e) NULL
  )
  
  if (is.null(fit)) return(tibble())
  
  coef_table <- summary(fit)$coefficients
  
  if (!"exposure_Q4_vs_Q1" %in% rownames(coef_table)) return(tibble())
  
  beta <- coef_table["exposure_Q4_vs_Q1", "Estimate"]
  se <- coef_table["exposure_Q4_vs_Q1", "Std. Error"]
  p_value <- coef_table["exposure_Q4_vs_Q1", "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  OR <- exp(beta)
  OR_low <- exp(beta - tcrit * se)
  OR_high <- exp(beta + tcrit * se)
  
  RR_approx <- or_to_rr_approx(OR, p0)
  RR_low_approx <- or_to_rr_approx(OR_low, p0)
  RR_high_approx <- or_to_rr_approx(OR_high, p0)
  
  E_value_point <- evalue_rr(RR_approx)
  
  if (!is.na(RR_approx) && RR_approx >= 1) {
    E_value_CI <- ifelse(RR_low_approx > 1, evalue_rr(RR_low_approx), 1)
  } else if (!is.na(RR_approx) && RR_approx < 1) {
    E_value_CI <- ifelse(RR_high_approx < 1, evalue_rr(RR_high_approx), 1)
  } else {
    E_value_CI <- NA_real_
  }
  
  tibble(
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    contrast = "Q4 vs Q1",
    n = nrow(d),
    events = sum(d[[outcome]] == 1, na.rm = TRUE),
    p0_weighted = p0,
    beta = beta,
    se = se,
    p_value = p_value,
    OR = OR,
    OR_low = OR_low,
    OR_high = OR_high,
    RR_approx = RR_approx,
    RR_low_approx = RR_low_approx,
    RR_high_approx = RR_high_approx,
    E_value_point = E_value_point,
    E_value_CI = E_value_CI
  )
}

evalue_results <- expand_grid(
  outcome_row = seq_len(nrow(binary_outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result = map2(outcome_row, exposure_row, function(i, j) {
      run_evalue_model(
        outcome = binary_outcome_map$outcome[i],
        outcome_label = binary_outcome_map$outcome_label[i],
        exposure = exposure_map$exposure[j],
        exposure_label = exposure_map$exposure_label[j],
        include_creatinine = exposure_map$include_creatinine[j]
      )
    })
  ) %>%
  select(result) %>%
  unnest(result) %>%
  group_by(outcome_label) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    OR_CI = sprintf("%.3f (%.3f, %.3f)", OR, OR_low, OR_high),
    RR_approx_CI = sprintf("%.3f (%.3f, %.3f)", RR_approx, RR_low_approx, RR_high_approx),
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
    interpretation = case_when(
      E_value_point >= 2.5 & E_value_CI > 1 ~ "Relatively robust to moderate unmeasured confounding",
      E_value_point >= 2.0 & E_value_CI > 1 ~ "Moderately robust",
      E_value_point > 1 & E_value_CI == 1 ~ "Point estimate shows sensitivity, but CI includes null",
      TRUE ~ "Limited robustness"
    )
  )

key_evalue <- evalue_results %>%
  filter(
    outcome_label %in% c(
      "High HOMA-IR, top quartile",
      "High HOMA-IR >= 2.5",
      "HbA1c >= 5.7%",
      "Metabolic syndrome"
    ),
    exposure_label %in% c(
      "ln(Sigma DEHP)",
      "%Oxidative per 10 percentage points",
      "MEHHP",
      "MEOHP",
      "MECPP"
    )
  ) %>%
  arrange(outcome_label, exposure_label)

print(key_evalue)

write_csv(
  evalue_results,
  file.path(result_dir, "Evalue_binary_sensitivity_2013_2018.csv")
)

write_xlsx(
  list(
    evalue_results = evalue_results,
    key_evalue = key_evalue
  ),
  file.path(result_dir, "Evalue_binary_sensitivity_2013_2018.xlsx")
)

cat("E-value binary sensitivity analysis completed successfully.\n")