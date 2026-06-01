# ============================================================
# NHANES 2013-2018
# 48_ipw_multiple_imputation_sensitivity_2013_2018.R
# IPW and multiple-imputation sensitivity analyses
# ============================================================

# ------------------------------------------------------------
# 0. Packages
# ------------------------------------------------------------

required_packages <- c(
  "dplyr", "tidyr", "purrr", "readr", "tibble",
  "survey", "ggplot2", "writexl", "mice"
)

installed <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed)

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(tibble)
library(survey)
library(ggplot2)
library(writexl)
library(mice)

options(survey.lonely.psu = "adjust")

# ------------------------------------------------------------
# 1. Project paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir    <- file.path(result_dir, "figures_ipw_mi")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 2. Read newest available analytic dataset
# ------------------------------------------------------------

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset_with_DIQ050_DIQ070.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset_with_DIQmed.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_logratio_composition_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_exposure_sensitivity_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_mechanism.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]

if (is.na(data_file)) {
  stop("找不到 2013-2018 分析数据，请检查 output 文件夹。")
}

df <- readRDS(data_file) %>%
  as_tibble()

cat("Using data file:\n", data_file, "\n")
cat("Dataset dimensions:", nrow(df), "rows,", ncol(df), "columns\n")

# ------------------------------------------------------------
# 3. Helper functions
# ------------------------------------------------------------

find_var_safe <- function(dat, exact_candidates = character(), pattern_candidates = character()) {
  nms <- names(dat)
  lower_nms <- tolower(nms)
  
  exact_hit <- nms[lower_nms %in% tolower(exact_candidates)]
  if (length(exact_hit) > 0) return(exact_hit[1])
  
  if (length(pattern_candidates) > 0) {
    pattern <- paste(pattern_candidates, collapse = "|")
    pattern_hit <- nms[grepl(pattern, nms, ignore.case = TRUE)]
    if (length(pattern_hit) > 0) return(pattern_hit[1])
  }
  
  NA_character_
}

get_numeric_var <- function(dat, var_name) {
  if (is.na(var_name) || length(var_name) == 0 || !(var_name %in% names(dat))) {
    return(rep(NA_real_, nrow(dat)))
  }
  as.numeric(dat[[var_name]])
}

format_p <- function(p) {
  ifelse(
    is.na(p),
    NA_character_,
    ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

effect_transform <- function(beta, low, high, outcome_type) {
  if (outcome_type == "log_ratio_outcome") {
    c(
      effect = (exp(beta) - 1) * 100,
      effect_low = (exp(low) - 1) * 100,
      effect_high = (exp(high) - 1) * 100
    )
  } else {
    c(
      effect = beta,
      effect_low = low,
      effect_high = high
    )
  }
}

rubin_scalar <- function(beta_vec, var_vec) {
  ok <- !is.na(beta_vec) & !is.na(var_vec)
  beta_vec <- beta_vec[ok]
  var_vec <- var_vec[ok]
  
  m <- length(beta_vec)
  
  if (m < 2) {
    return(list(
      beta = NA_real_,
      se = NA_real_,
      df = NA_real_,
      p_value = NA_real_
    ))
  }
  
  qbar <- mean(beta_vec)
  ubar <- mean(var_vec)
  b <- stats::var(beta_vec)
  total_var <- ubar + (1 + 1 / m) * b
  se <- sqrt(total_var)
  
  if (is.na(b) || b == 0) {
    df <- Inf
  } else {
    df <- (m - 1) * (1 + ubar / ((1 + 1 / m) * b))^2
  }
  
  t_value <- qbar / se
  p_value <- 2 * stats::pt(abs(t_value), df = df, lower.tail = FALSE)
  
  list(
    beta = qbar,
    se = se,
    df = df,
    p_value = p_value
  )
}

winsorize_weight <- function(w, probs = c(0.01, 0.99)) {
  qs <- quantile(w, probs = probs, na.rm = TRUE)
  pmin(pmax(w, qs[1]), qs[2])
}

fill_num <- function(x) {
  x <- as.numeric(x)
  med <- median(x, na.rm = TRUE)
  if (!is.finite(med)) med <- 0
  ifelse(is.na(x), med, x)
}

missing_ind <- function(x) {
  as.integer(is.na(x))
}

factor_missing <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "Missing"
  factor(x)
}

# ------------------------------------------------------------
# 4. Ensure derived variables exist
# ------------------------------------------------------------

# Outcomes
if (!("ln_HOMA_IR" %in% names(df))) {
  if ("HOMA_IR" %in% names(df)) {
    df <- df %>% mutate(ln_HOMA_IR = log(HOMA_IR))
  } else if ("homa_ir" %in% names(df)) {
    df <- df %>% mutate(ln_HOMA_IR = log(homa_ir))
  }
}

if (!("HbA1c" %in% names(df))) {
  if ("LBXGH" %in% names(df)) {
    df <- df %>% mutate(HbA1c = LBXGH)
  }
}

# Urinary creatinine
if (!("ln_URXUCR" %in% names(df))) {
  if ("URXUCR" %in% names(df)) {
    df <- df %>% mutate(ln_URXUCR = log(URXUCR))
  }
}

# Cycle
if (!("cycle" %in% names(df))) {
  if ("SDDSRVYR" %in% names(df)) {
    df <- df %>% mutate(cycle = SDDSRVYR)
  }
}

# %Oxidative per 10 percentage points
if (!("pct_oxidative_10" %in% names(df))) {
  if ("pct_oxidative" %in% names(df)) {
    df <- df %>% mutate(pct_oxidative_10 = pct_oxidative / 10)
  }
}

# Glucose mg/dL if needed
if (!("glucose_mgdl" %in% names(df))) {
  var_glucose_mg <- find_var_safe(
    df,
    exact_candidates = c("LBXGLU", "glucose", "fasting_glucose", "glucose_mgdl"),
    pattern_candidates = c("^LBXGLU$", "fast.*glucose", "glucose.*mg")
  )
  
  var_glucose_si <- find_var_safe(
    df,
    exact_candidates = c("LBDGLUSI", "glucose_mmol", "fasting_glucose_mmol"),
    pattern_candidates = c("glucose.*mmol", "LBDGLUSI")
  )
  
  glucose_mgdl_vec <- if (!is.na(var_glucose_mg)) {
    get_numeric_var(df, var_glucose_mg)
  } else if (!is.na(var_glucose_si)) {
    get_numeric_var(df, var_glucose_si) * 18.0182
  } else {
    rep(NA_real_, nrow(df))
  }
  
  glucose_mgdl_vec <- ifelse(glucose_mgdl_vec > 0, glucose_mgdl_vec, NA_real_)
  df <- df %>% mutate(glucose_mgdl = glucose_mgdl_vec)
}

# TyG and TG/HDL-C if possible
if (!("TyG_index" %in% names(df))) {
  var_trig_mg <- find_var_safe(
    df,
    exact_candidates = c("LBXTR", "triglycerides", "triglyceride", "trig", "TG"),
    pattern_candidates = c("^LBXTR$", "trig.*mg", "triglycer")
  )
  
  trig_vec <- get_numeric_var(df, var_trig_mg)
  trig_vec <- ifelse(trig_vec > 0, trig_vec, NA_real_)
  
  df <- df %>%
    mutate(TyG_index = log(trig_vec * glucose_mgdl / 2))
}

if (!("ln_TG_HDL_C" %in% names(df))) {
  var_trig_mg <- find_var_safe(
    df,
    exact_candidates = c("LBXTR", "triglycerides", "triglyceride", "trig", "TG"),
    pattern_candidates = c("^LBXTR$", "trig.*mg", "triglycer")
  )
  
  var_hdl_mg <- find_var_safe(
    df,
    exact_candidates = c("LBDHDD", "HDL", "hdl", "hdl_c", "HDL_C"),
    pattern_candidates = c("^LBDHDD$", "hdl.*mg", "hdl.*chol")
  )
  
  trig_vec <- get_numeric_var(df, var_trig_mg)
  hdl_vec <- get_numeric_var(df, var_hdl_mg)
  
  trig_vec <- ifelse(trig_vec > 0, trig_vec, NA_real_)
  hdl_vec <- ifelse(hdl_vec > 0, hdl_vec, NA_real_)
  
  df <- df %>%
    mutate(
      TG_HDL_C = trig_vec / hdl_vec,
      ln_TG_HDL_C = log(TG_HDL_C)
    )
}

# ------------------------------------------------------------
# 5. Survey weight
# ------------------------------------------------------------

if ("WTSB6YR_MAIN" %in% names(df)) {
  weight_var <- "WTSB6YR_MAIN"
} else if ("WTSB6YR_FAST" %in% names(df)) {
  weight_var <- "WTSB6YR_FAST"
} else if ("WTSAF6YR" %in% names(df)) {
  weight_var <- "WTSAF6YR"
} else if ("WTSAF2YR" %in% names(df)) {
  df <- df %>% mutate(WTSB6YR_IPW_MI = WTSAF2YR / 3)
  weight_var <- "WTSB6YR_IPW_MI"
} else if ("WTMEC6YR" %in% names(df)) {
  weight_var <- "WTMEC6YR"
} else if ("WTMEC2YR" %in% names(df)) {
  df <- df %>% mutate(WTMEC6YR_IPW_MI = WTMEC2YR / 3)
  weight_var <- "WTMEC6YR_IPW_MI"
} else {
  stop("找不到合适的 survey weight。")
}

cat("\nUsing survey weight:", weight_var, "\n")

required_design <- c("SDMVPSU", "SDMVSTRA", weight_var)
missing_design <- setdiff(required_design, names(df))

if (length(missing_design) > 0) {
  stop(paste0("缺少复杂抽样设计变量：", paste(missing_design, collapse = ", ")))
}

# ------------------------------------------------------------
# 6. Model maps
# ------------------------------------------------------------

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~outcome_type,
  "ln_HOMA_IR", "ln(HOMA-IR)", "log_ratio_outcome",
  "HbA1c", "HbA1c", "absolute_outcome",
  "TyG_index", "TyG index", "absolute_outcome",
  "ln_TG_HDL_C", "ln(TG/HDL-C)", "log_ratio_outcome"
) %>%
  filter(outcome %in% names(df))

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~exposure_type, ~include_creatinine, ~include_total_burden,
  "ln_Sigma_DEHP", "lnΣDEHP", "total burden", TRUE, FALSE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", "oxidative fraction", FALSE, FALSE,
  "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]", "log-ratio composition", TRUE, TRUE,
  "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance", "ILR composition", TRUE, TRUE
) %>%
  filter(exposure %in% names(df))

if (nrow(outcome_map) == 0) stop("没有可用结局变量。")
if (nrow(exposure_map) == 0) stop("没有可用暴露变量。")

base_covars <- c(
  "RIDAGEYR",
  "factor(RIAGENDR)",
  "factor(RIDRETH3)",
  "INDFMPIR",
  "factor(DMDEDUC2)",
  "DR1TKCAL",
  "factor(cycle)"
)

base_vars <- c(
  "RIDAGEYR",
  "RIAGENDR",
  "RIDRETH3",
  "INDFMPIR",
  "DMDEDUC2",
  "DR1TKCAL",
  "cycle",
  "SDMVPSU",
  "SDMVSTRA",
  weight_var
)

missing_covars <- setdiff(
  c("RIDAGEYR", "RIAGENDR", "RIDRETH3", "INDFMPIR", "DMDEDUC2", "DR1TKCAL", "cycle"),
  names(df)
)

if (length(missing_covars) > 0) {
  stop(paste0("缺少基础协变量：", paste(missing_covars, collapse = ", ")))
}

cat("\nOutcomes:\n")
print(outcome_map)

cat("\nExposures:\n")
print(exposure_map)

# ------------------------------------------------------------
# 7. Complete-case model runner
# ------------------------------------------------------------

run_complete_case_model <- function(dat,
                                    outcome, outcome_label, outcome_type,
                                    exposure, exposure_label, exposure_type,
                                    include_creatinine, include_total_burden,
                                    weight_name = weight_var,
                                    analysis_label = "Complete-case") {
  
  covar_terms <- base_covars
  needed_vars <- c(outcome, exposure, base_vars)
  
  if (weight_name != weight_var) {
    needed_vars <- c(setdiff(needed_vars, weight_var), weight_name)
  }
  
  if (include_creatinine) {
    covar_terms <- c(covar_terms, "ln_URXUCR")
    needed_vars <- c(needed_vars, "ln_URXUCR")
  }
  
  if (include_total_burden) {
    if ("ln_Sigma_DEHP_comp" %in% names(dat)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP_comp")
      needed_vars <- c(needed_vars, "ln_Sigma_DEHP_comp")
    } else if ("ln_Sigma_DEHP" %in% names(dat)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP")
      needed_vars <- c(needed_vars, "ln_Sigma_DEHP")
    }
  }
  
  missing_needed <- setdiff(unique(needed_vars), names(dat))
  
  if (length(missing_needed) > 0) {
    return(tibble(
      analysis = analysis_label,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n = NA_integer_,
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = paste0("Missing variables: ", paste(missing_needed, collapse = ", "))
    ))
  }
  
  d <- dat %>%
    filter(RIDAGEYR >= 20) %>%
    select(all_of(unique(needed_vars))) %>%
    drop_na()
  
  if (nrow(d) < 300) {
    return(tibble(
      analysis = analysis_label,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Insufficient sample"
    ))
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = as.formula(paste0("~", weight_name)),
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(
      outcome,
      " ~ ",
      exposure,
      " + ",
      paste(covar_terms, collapse = " + ")
    )
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble(
      analysis = analysis_label,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Model failed"
    ))
  }
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) {
    return(tibble(
      analysis = analysis_label,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Coefficient unavailable"
    ))
  }
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  eff <- effect_transform(beta, low, high, outcome_type)
  
  tibble(
    analysis = analysis_label,
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_type = exposure_type,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = eff["effect"],
    effect_low = eff["effect_low"],
    effect_high = eff["effect_high"],
    result = case_when(
      is.na(p_value) ~ "Unavailable",
      p_value < 0.05 & beta > 0 ~ "Nominal positive",
      p_value < 0.05 & beta < 0 ~ "Nominal negative",
      beta > 0 ~ "Positive direction",
      beta < 0 ~ "Negative direction",
      TRUE ~ "Weak/no support"
    )
  )
}

# ------------------------------------------------------------
# 8. Complete-case reference results
# ------------------------------------------------------------

complete_case_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, exposure_row),
      function(i, j) {
        run_complete_case_model(
          dat = df,
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          outcome_type = outcome_map$outcome_type[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          exposure_type = exposure_map$exposure_type[j],
          include_creatinine = exposure_map$include_creatinine[j],
          include_total_burden = exposure_map$include_total_burden[j],
          analysis_label = "Complete-case"
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl)

# ------------------------------------------------------------
# 9. IPW module
# ------------------------------------------------------------

prepare_ipw_dataset <- function(dat,
                                outcome, exposure,
                                include_creatinine,
                                include_total_burden) {
  
  final_covars <- c(
    "RIDAGEYR",
    "RIAGENDR",
    "RIDRETH3",
    "INDFMPIR",
    "DMDEDUC2",
    "DR1TKCAL",
    "cycle"
  )
  
  if (include_creatinine) {
    final_covars <- c(final_covars, "ln_URXUCR")
  }
  
  if (include_total_burden) {
    if ("ln_Sigma_DEHP_comp" %in% names(dat)) {
      final_covars <- c(final_covars, "ln_Sigma_DEHP_comp")
    } else if ("ln_Sigma_DEHP" %in% names(dat)) {
      final_covars <- c(final_covars, "ln_Sigma_DEHP")
    }
  }
  
  eligible_vars <- c(
    outcome,
    exposure,
    "SDMVPSU",
    "SDMVSTRA",
    weight_var,
    "RIDAGEYR",
    "RIAGENDR",
    "RIDRETH3",
    "cycle"
  )
  
  d0 <- dat %>%
    filter(RIDAGEYR >= 20) %>%
    mutate(row_id_ipw = row_number())
  
  # Eligible population: observed outcome, exposure, age/sex/race/cycle/design/weight.
  d_eligible <- d0 %>%
    filter(
      !is.na(.data[[outcome]]),
      !is.na(.data[[exposure]]),
      !is.na(SDMVPSU),
      !is.na(SDMVSTRA),
      !is.na(.data[[weight_var]]),
      !is.na(RIDAGEYR),
      !is.na(RIAGENDR),
      !is.na(RIDRETH3),
      !is.na(cycle)
    ) %>%
    mutate(
      included_complete_case =
        if_all(all_of(intersect(final_covars, names(.))), ~ !is.na(.x))
    )
  
  if (nrow(d_eligible) < 300) {
    return(NULL)
  }
  
  # IPW prediction variables.
  bmi_var <- if ("BMXBMI" %in% names(d_eligible)) "BMXBMI" else NA_character_
  
  d_ipw <- d_eligible %>%
    mutate(
      ipw_age = fill_num(RIDAGEYR),
      ipw_sex = factor_missing(RIAGENDR),
      ipw_race = factor_missing(RIDRETH3),
      ipw_cycle = factor_missing(cycle),
      
      ipw_pir = if ("INDFMPIR" %in% names(.)) fill_num(INDFMPIR) else 0,
      ipw_pir_missing = if ("INDFMPIR" %in% names(.)) missing_ind(INDFMPIR) else 1,
      
      ipw_edu = if ("DMDEDUC2" %in% names(.)) factor_missing(DMDEDUC2) else factor("Missing"),
      
      ipw_energy = if ("DR1TKCAL" %in% names(.)) fill_num(DR1TKCAL) else 0,
      ipw_energy_missing = if ("DR1TKCAL" %in% names(.)) missing_ind(DR1TKCAL) else 1,
      
      ipw_bmi = if (!is.na(bmi_var)) fill_num(.data[[bmi_var]]) else 0,
      ipw_bmi_missing = if (!is.na(bmi_var)) missing_ind(.data[[bmi_var]]) else 1,
      
      ipw_diabetes = if ("diagnosed_diabetes" %in% names(.)) {
        factor_missing(as.integer(diagnosed_diabetes))
      } else {
        factor("Missing")
      }
    )
  
  d_ipw
}

run_ipw_model <- function(outcome, outcome_label, outcome_type,
                          exposure, exposure_label, exposure_type,
                          include_creatinine, include_total_burden) {
  
  d_ipw <- prepare_ipw_dataset(
    dat = df,
    outcome = outcome,
    exposure = exposure,
    include_creatinine = include_creatinine,
    include_total_burden = include_total_burden
  )
  
  if (is.null(d_ipw) || nrow(d_ipw) < 300) {
    return(tibble(
      analysis = "IPW",
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n_eligible = ifelse(is.null(d_ipw), 0, nrow(d_ipw)),
      n_included = NA_integer_,
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Insufficient eligible sample"
    ))
  }
  
  # Inclusion model.
  ipw_formula <- included_complete_case ~
    ipw_age +
    ipw_sex +
    ipw_race +
    ipw_cycle +
    ipw_pir +
    ipw_pir_missing +
    ipw_edu +
    ipw_energy +
    ipw_energy_missing +
    ipw_bmi +
    ipw_bmi_missing +
    ipw_diabetes
  
  des_inclusion <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = as.formula(paste0("~", weight_var)),
    nest = TRUE,
    data = d_ipw
  )
  
  fit_inclusion <- tryCatch(
    svyglm(ipw_formula, design = des_inclusion, family = quasibinomial()),
    error = function(e) NULL
  )
  
  if (is.null(fit_inclusion)) {
    return(tibble(
      analysis = "IPW",
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n_eligible = nrow(d_ipw),
      n_included = sum(d_ipw$included_complete_case, na.rm = TRUE),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Inclusion model failed"
    ))
  }
  
  pred_p <- as.numeric(predict(fit_inclusion, type = "response"))
  pred_p <- pmin(pmax(pred_p, 0.025), 0.995)
  
  marginal_p <- mean(d_ipw$included_complete_case, na.rm = TRUE)
  
  d_ipw <- d_ipw %>%
    mutate(
      pred_inclusion_p = pred_p,
      stabilized_ipw = marginal_p / pred_inclusion_p,
      stabilized_ipw_truncated = winsorize_weight(stabilized_ipw),
      final_ipw_weight = .data[[weight_var]] * stabilized_ipw_truncated
    )
  
  # Final model uses included complete cases only.
  d_final <- d_ipw %>%
    filter(included_complete_case %in% TRUE)
  
  if (nrow(d_final) < 300) {
    return(tibble(
      analysis = "IPW",
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n_eligible = nrow(d_ipw),
      n_included = nrow(d_final),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Insufficient included sample"
    ))
  }
  
  # Fit final IPW weighted model.
  ipw_result <- run_complete_case_model(
    dat = d_final,
    outcome = outcome,
    outcome_label = outcome_label,
    outcome_type = outcome_type,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_type = exposure_type,
    include_creatinine = include_creatinine,
    include_total_burden = include_total_burden,
    weight_name = "final_ipw_weight",
    analysis_label = "IPW-adjusted"
  ) %>%
    mutate(
      n_eligible = nrow(d_ipw),
      n_included = nrow(d_final),
      mean_pred_inclusion_p = mean(d_ipw$pred_inclusion_p, na.rm = TRUE),
      min_pred_inclusion_p = min(d_ipw$pred_inclusion_p, na.rm = TRUE),
      max_pred_inclusion_p = max(d_ipw$pred_inclusion_p, na.rm = TRUE),
      mean_stabilized_ipw = mean(d_ipw$stabilized_ipw, na.rm = TRUE),
      mean_truncated_ipw = mean(d_ipw$stabilized_ipw_truncated, na.rm = TRUE)
    )
  
  ipw_result
}

ipw_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, exposure_row),
      function(i, j) {
        run_ipw_model(
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          outcome_type = outcome_map$outcome_type[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          exposure_type = exposure_map$exposure_type[j],
          include_creatinine = exposure_map$include_creatinine[j],
          include_total_burden = exposure_map$include_total_burden[j]
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl)

# ------------------------------------------------------------
# 10. Multiple imputation module
# ------------------------------------------------------------

run_mi_model <- function(outcome, outcome_label, outcome_type,
                         exposure, exposure_label, exposure_type,
                         include_creatinine, include_total_burden,
                         m = 20, maxit = 10, seed = 20260530) {
  
  covar_terms <- base_covars
  model_vars <- c(outcome, exposure, base_vars)
  
  if (include_creatinine) {
    covar_terms <- c(covar_terms, "ln_URXUCR")
    model_vars <- c(model_vars, "ln_URXUCR")
  }
  
  if (include_total_burden) {
    if ("ln_Sigma_DEHP_comp" %in% names(df)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP_comp")
      model_vars <- c(model_vars, "ln_Sigma_DEHP_comp")
    } else if ("ln_Sigma_DEHP" %in% names(df)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP")
      model_vars <- c(model_vars, "ln_Sigma_DEHP")
    }
  }
  
  missing_model_vars <- setdiff(unique(model_vars), names(df))
  
  if (length(missing_model_vars) > 0) {
    return(tibble(
      analysis = "Multiple imputation",
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n = NA_integer_,
      m = m,
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = paste0("Missing variables: ", paste(missing_model_vars, collapse = ", "))
    ))
  }
  
  d0 <- df %>%
    filter(RIDAGEYR >= 20) %>%
    select(all_of(unique(model_vars))) %>%
    filter(
      !is.na(.data[[outcome]]),
      !is.na(.data[[exposure]]),
      !is.na(SDMVPSU),
      !is.na(SDMVSTRA),
      !is.na(.data[[weight_var]])
    )
  
  if (nrow(d0) < 300) {
    return(tibble(
      analysis = "Multiple imputation",
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n = nrow(d0),
      m = m,
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Insufficient sample"
    ))
  }
  
  # Convert categorical variables before mice.
  d_mi <- d0 %>%
    mutate(
      RIAGENDR = factor(RIAGENDR),
      RIDRETH3 = factor(RIDRETH3),
      DMDEDUC2 = factor(DMDEDUC2),
      cycle = factor(cycle)
    )
  
  # MICE methods.
  meth <- make.method(d_mi)
  
  # Do not impute outcome, exposure, survey design, weight.
  no_impute_vars <- c(outcome, exposure, "SDMVPSU", "SDMVSTRA", weight_var)
  
  # If total burden is in model and equals exposure, avoid duplicate issue.
  no_impute_vars <- intersect(unique(no_impute_vars), names(d_mi))
  meth[no_impute_vars] <- ""
  
  # Assign methods to variables that still have missingness.
  for (v in names(d_mi)) {
    if (v %in% no_impute_vars) next
    
    if (sum(is.na(d_mi[[v]])) == 0) {
      meth[v] <- ""
    } else if (is.factor(d_mi[[v]])) {
      if (nlevels(d_mi[[v]]) == 2) {
        meth[v] <- "logreg"
      } else {
        meth[v] <- "polyreg"
      }
    } else {
      meth[v] <- "pmm"
    }
  }
  
  pred <- make.predictorMatrix(d_mi)
  
  # Do not use PSU/strata as predictors to avoid technical issues.
  pred[, c("SDMVPSU", "SDMVSTRA")] <- 0
  
  # Do not impute design variables.
  pred[c("SDMVPSU", "SDMVSTRA", weight_var), ] <- 0
  
  # Keep outcome/exposure as predictors, but do not impute them.
  pred[no_impute_vars, ] <- 0
  
  set.seed(seed)
  
  imp <- tryCatch(
    mice(
      d_mi,
      m = m,
      maxit = maxit,
      method = meth,
      predictorMatrix = pred,
      printFlag = FALSE,
      seed = seed
    ),
    error = function(e) NULL
  )
  
  if (is.null(imp)) {
    return(tibble(
      analysis = "Multiple imputation",
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      n = nrow(d0),
      m = m,
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "MICE failed"
    ))
  }
  
  f <- as.formula(
    paste0(
      outcome,
      " ~ ",
      exposure,
      " + ",
      paste(covar_terms, collapse = " + ")
    )
  )
  
  beta_vec <- rep(NA_real_, m)
  var_vec <- rep(NA_real_, m)
  n_vec <- rep(NA_integer_, m)
  
  for (i in seq_len(m)) {
    d_i <- complete(imp, action = i)
    
    # Ensure factors remain factors.
    d_i <- d_i %>%
      mutate(
        RIAGENDR = factor(RIAGENDR),
        RIDRETH3 = factor(RIDRETH3),
        DMDEDUC2 = factor(DMDEDUC2),
        cycle = factor(cycle)
      ) %>%
      drop_na(all_of(c(outcome, exposure, "SDMVPSU", "SDMVSTRA", weight_var)))
    
    n_vec[i] <- nrow(d_i)
    
    if (nrow(d_i) < 300) next
    
    des_i <- svydesign(
      ids = ~SDMVPSU,
      strata = ~SDMVSTRA,
      weights = as.formula(paste0("~", weight_var)),
      nest = TRUE,
      data = d_i
    )
    
    fit_i <- tryCatch(
      svyglm(f, design = des_i),
      error = function(e) NULL
    )
    
    if (is.null(fit_i)) next
    
    coef_i <- coef(fit_i)
    vcov_i <- vcov(fit_i)
    
    if (!(exposure %in% names(coef_i))) next
    
    beta_vec[i] <- coef_i[exposure]
    var_vec[i] <- vcov_i[exposure, exposure]
  }
  
  pooled <- rubin_scalar(beta_vec, var_vec)
  
  beta <- pooled$beta
  se <- pooled$se
  p_value <- pooled$p_value
  df_mi <- pooled$df
  
  tcrit <- ifelse(is.na(df_mi) || is.infinite(df_mi), 1.96, qt(0.975, df = df_mi))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  eff <- effect_transform(beta, low, high, outcome_type)
  
  tibble(
    analysis = "Multiple imputation",
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_type = exposure_type,
    n = round(mean(n_vec, na.rm = TRUE)),
    m = m,
    mi_df = df_mi,
    beta = beta,
    se = se,
    p_value = p_value,
    effect = eff["effect"],
    effect_low = eff["effect_low"],
    effect_high = eff["effect_high"],
    result = case_when(
      is.na(p_value) ~ "Unavailable",
      p_value < 0.05 & beta > 0 ~ "Nominal positive",
      p_value < 0.05 & beta < 0 ~ "Nominal negative",
      beta > 0 ~ "Positive direction",
      beta < 0 ~ "Negative direction",
      TRUE ~ "Weak/no support"
    )
  )
}

mi_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, exposure_row),
      function(i, j) {
        run_mi_model(
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          outcome_type = outcome_map$outcome_type[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          exposure_type = exposure_map$exposure_type[j],
          include_creatinine = exposure_map$include_creatinine[j],
          include_total_burden = exposure_map$include_total_burden[j],
          m = 20,
          maxit = 10,
          seed = 20260530 + i * 10 + j
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl)

# ------------------------------------------------------------
# 11. Combine and format all results
# ------------------------------------------------------------

combined_results <- bind_rows(
  complete_case_results,
  ipw_results %>%
    select(any_of(names(complete_case_results))),
  mi_results %>%
    select(any_of(names(complete_case_results)))
) %>%
  group_by(analysis, outcome_label) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    effect_CI = ifelse(
      is.na(effect),
      NA_character_,
      sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high)
    ),
    p_value_fmt = format_p(p_value),
    q_value_fmt = format_p(q_value),
    inference = case_when(
      q_value < 0.05 & beta > 0 ~ "FDR-significant positive association",
      p_value < 0.05 & beta > 0 ~ "Nominal positive association",
      p_value < 0.05 & beta < 0 ~ "Nominal negative association",
      beta > 0 ~ "Positive but not significant",
      beta < 0 ~ "Negative but not significant",
      TRUE ~ "Weak/no association"
    )
  )

reference <- combined_results %>%
  filter(analysis == "Complete-case") %>%
  select(
    outcome,
    exposure,
    beta_complete = beta,
    effect_complete = effect
  )

combined_compared <- combined_results %>%
  left_join(reference, by = c("outcome", "exposure")) %>%
  mutate(
    same_direction_as_complete = case_when(
      is.na(beta) | is.na(beta_complete) ~ NA,
      beta == 0 | beta_complete == 0 ~ NA,
      sign(beta) == sign(beta_complete) ~ TRUE,
      TRUE ~ FALSE
    ),
    beta_ratio_vs_complete = beta / beta_complete,
    robustness_decision = case_when(
      analysis == "Complete-case" ~ "Reference",
      same_direction_as_complete == TRUE & q_value < 0.05 & beta > 0 ~ "FDR robust positive",
      same_direction_as_complete == TRUE & p_value < 0.05 & beta > 0 ~ "Nominal robust positive",
      same_direction_as_complete == TRUE & beta > 0 ~ "Directionally consistent",
      same_direction_as_complete == FALSE ~ "Direction changed",
      TRUE ~ "Unclear"
    )
  )

key_combined <- combined_compared %>%
  filter(
    exposure %in% c(
      "ln_Sigma_DEHP",
      "pct_oxidative_10",
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    ),
    outcome %in% c(
      "ln_HOMA_IR",
      "HbA1c",
      "TyG_index",
      "ln_TG_HDL_C"
    )
  ) %>%
  select(
    analysis,
    outcome_label,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    inference,
    same_direction_as_complete,
    beta_ratio_vs_complete,
    robustness_decision
  ) %>%
  arrange(outcome_label, exposure_label, analysis)

# ------------------------------------------------------------
# 12. Plot key results
# ------------------------------------------------------------

plot_df <- combined_compared %>%
  filter(
    exposure %in% c(
      "pct_oxidative_10",
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    ),
    outcome %in% c("ln_HOMA_IR", "HbA1c", "TyG_index", "ln_TG_HDL_C"),
    analysis %in% c("Complete-case", "IPW-adjusted", "Multiple imputation"),
    !is.na(effect),
    !is.na(effect_low),
    !is.na(effect_high)
  ) %>%
  mutate(
    analysis = factor(
      analysis,
      levels = rev(c("Complete-case", "IPW-adjusted", "Multiple imputation"))
    ),
    outcome_label = factor(
      outcome_label,
      levels = c("ln(HOMA-IR)", "HbA1c", "TyG index", "ln(TG/HDL-C)")
    ),
    exposure_label = factor(
      exposure_label,
      levels = c(
        "%Oxidative per 10 percentage points",
        "ln[(MEHHP+MEOHP+MECPP)/MEHP]",
        "ILR oxidative-vs-primary balance"
      )
    ),
    sig_label = case_when(
      q_value < 0.05 ~ "**",
      p_value < 0.05 ~ "*",
      TRUE ~ ""
    )
  )

if (nrow(plot_df) > 0) {
  p_forest <- ggplot(plot_df, aes(x = effect, y = analysis)) +
    geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.35) +
    geom_errorbarh(
      aes(xmin = effect_low, xmax = effect_high),
      height = 0.18,
      linewidth = 0.45
    ) +
    geom_point(size = 2.3) +
    geom_text(
      aes(label = sig_label),
      nudge_y = 0.18,
      size = 3.3,
      fontface = "bold"
    ) +
    facet_grid(outcome_label ~ exposure_label, scales = "free_x") +
    labs(
      title = "IPW and multiple-imputation sensitivity analyses",
      subtitle = "Comparison of complete-case, inverse-probability-weighted, and multiple-imputation estimates",
      x = "Effect estimate",
      y = NULL,
      caption = "* nominal P < 0.05; ** FDR q < 0.05. For log-transformed outcomes, estimates represent percent differences."
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold", size = 8.2),
      strip.background = element_rect(fill = "grey90", color = "grey35"),
      panel.grid.minor = element_line(color = "grey92"),
      panel.grid.major = element_line(color = "grey86"),
      axis.text.y = element_text(size = 8.5),
      plot.caption = element_text(size = 8.3, hjust = 0)
    )
  
  print(p_forest)
  
  ggsave(
    file.path(fig_dir, "IPW_MI_forest_key_results_2013_2018.png"),
    p_forest,
    width = 15,
    height = 9,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "IPW_MI_forest_key_results_2013_2018.pdf"),
    p_forest,
    width = 15,
    height = 9
  )
  
  ggsave(
    file.path(fig_dir, "IPW_MI_forest_key_results_2013_2018.tiff"),
    p_forest,
    width = 15,
    height = 9,
    dpi = 600,
    compression = "lzw"
  )
}

# ------------------------------------------------------------
# 13. Export results
# ------------------------------------------------------------

write_xlsx(
  list(
    complete_case_results = complete_case_results,
    ipw_results = ipw_results,
    ipw_diagnostics = ipw_results %>%
      select(
        outcome_label,
        exposure_label,
        n_eligible,
        n_included,
        mean_pred_inclusion_p,
        min_pred_inclusion_p,
        max_pred_inclusion_p,
        mean_stabilized_ipw,
        mean_truncated_ipw
      ),
    key_ipw_results = ipw_results %>%
      filter(exposure %in% c("pct_oxidative_10", "ln_oxidative_MEHP_ratio", "ilr_oxidative_vs_primary"))
  ),
  file.path(result_dir, "ipw_missingness_sensitivity_results_2013_2018.xlsx")
)

write_xlsx(
  list(
    mi_results = mi_results,
    key_mi_results = mi_results %>%
      filter(exposure %in% c("pct_oxidative_10", "ln_oxidative_MEHP_ratio", "ilr_oxidative_vs_primary"))
  ),
  file.path(result_dir, "multiple_imputation_sensitivity_results_2013_2018.xlsx")
)

write_xlsx(
  list(
    combined_results = combined_compared,
    key_combined_results = key_combined
  ),
  file.path(result_dir, "ipw_mi_combined_summary_2013_2018.xlsx")
)

write_csv(
  combined_compared,
  file.path(result_dir, "ipw_mi_combined_summary_2013_2018.csv")
)

cat("\nIPW and multiple-imputation sensitivity analyses completed successfully.\n")
cat("Results saved to:\n")
cat(file.path(result_dir, "ipw_missingness_sensitivity_results_2013_2018.xlsx"), "\n")
cat(file.path(result_dir, "multiple_imputation_sensitivity_results_2013_2018.xlsx"), "\n")
cat(file.path(result_dir, "ipw_mi_combined_summary_2013_2018.xlsx"), "\n")
cat("Figure saved to:\n")
cat(file.path(fig_dir, "IPW_MI_forest_key_results_2013_2018.png"), "\n")