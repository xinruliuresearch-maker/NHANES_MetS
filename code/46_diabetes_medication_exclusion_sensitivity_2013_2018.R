# ============================================================
# NHANES 2013-2018
# 46_diabetes_medication_exclusion_sensitivity_2013_2018.R
# Diabetes / antidiabetic medication exclusion sensitivity analyses
# ============================================================

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(tibble)
library(survey)
library(ggplot2)
library(writexl)

options(survey.lonely.psu = "adjust")

# ------------------------------------------------------------
# 0. Project paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir    <- file.path(result_dir, "figures_diabetes_medication_sensitivity")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Read best available dataset
# Prefer the newest TyG/TG-HDL dataset
# ------------------------------------------------------------

data_candidates <- c(
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

df <- readRDS(data_file)

cat("Using data file:\n", data_file, "\n")
cat("Dataset dimensions:", nrow(df), "rows,", ncol(df), "columns\n")

# ------------------------------------------------------------
# 2. Helper functions
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
  if (is.na(var_name) || length(var_name) == 0) {
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

weighted_quantile <- function(x, w, probs) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]
  w <- w[ok]
  
  if (length(x) < 10) {
    return(rep(NA_real_, length(probs)))
  }
  
  o <- order(x)
  x <- x[o]
  w <- w[o]
  cw <- cumsum(w) / sum(w)
  
  approx(cw, x, xout = probs, ties = "ordered", rule = 2)$y
}

make_weighted_quartile <- function(x, w) {
  q <- weighted_quantile(x, w, probs = c(0, 0.25, 0.50, 0.75, 1))
  
  if (any(is.na(q)) || length(unique(q)) < 5) {
    return(factor(dplyr::ntile(x, 4), levels = 1:4, labels = paste0("Q", 1:4)))
  }
  
  q[1] <- q[1] - 1e-10
  q[5] <- q[5] + 1e-10
  
  cut(
    x,
    breaks = q,
    include.lowest = TRUE,
    labels = paste0("Q", 1:4)
  )
}

# ------------------------------------------------------------
# 3. Ensure required derived variables exist
# ------------------------------------------------------------

# ln(HOMA-IR)
if (!("ln_HOMA_IR" %in% names(df))) {
  if ("HOMA_IR" %in% names(df)) {
    df <- df %>% mutate(ln_HOMA_IR = log(HOMA_IR))
  } else if ("homa_ir" %in% names(df)) {
    df <- df %>% mutate(ln_HOMA_IR = log(homa_ir))
  }
}

# HbA1c
if (!("HbA1c" %in% names(df))) {
  if ("LBXGH" %in% names(df)) {
    df <- df %>% mutate(HbA1c = LBXGH)
  }
}

# ln urinary creatinine
if (!("ln_URXUCR" %in% names(df))) {
  if ("URXUCR" %in% names(df)) {
    df <- df %>% mutate(ln_URXUCR = log(URXUCR))
  }
}

# cycle
if (!("cycle" %in% names(df))) {
  if ("SDDSRVYR" %in% names(df)) {
    df <- df %>% mutate(cycle = SDDSRVYR)
  }
}

# pct_oxidative_10
if (!("pct_oxidative_10" %in% names(df))) {
  if ("pct_oxidative" %in% names(df)) {
    df <- df %>% mutate(pct_oxidative_10 = pct_oxidative / 10)
  }
}

# glucose mg/dL if not already present
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
  
  df <- df %>%
    mutate(glucose_mgdl = glucose_mgdl_vec)
}

# ------------------------------------------------------------
# 4. Detect diabetes diagnosis and medication variables
# ------------------------------------------------------------

var_diq010 <- find_var_safe(
  df,
  exact_candidates = c("DIQ010", "diq010"),
  pattern_candidates = c("^DIQ010$")
)

var_diq050 <- find_var_safe(
  df,
  exact_candidates = c("DIQ050", "diq050"),
  pattern_candidates = c("^DIQ050$")
)

var_diq070 <- find_var_safe(
  df,
  exact_candidates = c("DIQ070", "diq070"),
  pattern_candidates = c("^DIQ070$")
)

cat("\nDetected diabetes questionnaire variables:\n")
cat("DIQ010 diagnosed diabetes:", var_diq010, "\n")
cat("DIQ050 insulin use       :", var_diq050, "\n")
cat("DIQ070 diabetes pills    :", var_diq070, "\n")

diq010_vec <- get_numeric_var(df, var_diq010)
diq050_vec <- get_numeric_var(df, var_diq050)
diq070_vec <- get_numeric_var(df, var_diq070)

has_diagnosis_info <- !is.na(var_diq010)
has_insulin_info   <- !is.na(var_diq050)
has_pill_info      <- !is.na(var_diq070)
has_med_info       <- has_insulin_info | has_pill_info

df_sens <- df %>%
  mutate(
    diagnosed_diabetes = if (has_diagnosis_info) {
      diq010_vec == 1
    } else {
      NA
    },
    
    borderline_diabetes = if (has_diagnosis_info) {
      diq010_vec == 3
    } else {
      NA
    },
    
    insulin_use = if (has_insulin_info) {
      diq050_vec == 1
    } else {
      NA
    },
    
    diabetes_pill_use = if (has_pill_info) {
      diq070_vec == 1
    } else {
      NA
    },
    
    diabetes_medication_use = case_when(
      has_insulin_info & has_pill_info ~ insulin_use | diabetes_pill_use,
      has_insulin_info & !has_pill_info ~ insulin_use,
      !has_insulin_info & has_pill_info ~ diabetes_pill_use,
      TRUE ~ NA
    ),
    
    biochemical_diabetes = case_when(
      !is.na(HbA1c) & !is.na(glucose_mgdl) ~ HbA1c >= 6.5 | glucose_mgdl >= 126,
      !is.na(HbA1c) & is.na(glucose_mgdl) ~ HbA1c >= 6.5,
      is.na(HbA1c) & !is.na(glucose_mgdl) ~ glucose_mgdl >= 126,
      TRUE ~ NA
    ),
    
    biochemical_prediabetes_or_diabetes = case_when(
      !is.na(HbA1c) & !is.na(glucose_mgdl) ~ HbA1c >= 5.7 | glucose_mgdl >= 100,
      !is.na(HbA1c) & is.na(glucose_mgdl) ~ HbA1c >= 5.7,
      is.na(HbA1c) & !is.na(glucose_mgdl) ~ glucose_mgdl >= 100,
      TRUE ~ NA
    ),
    
    flag_full = TRUE,
    
    flag_no_diagnosed_diabetes =
      if (has_diagnosis_info) !diagnosed_diabetes else NA,
    
    flag_no_diabetes_medication =
      if (has_med_info) !diabetes_medication_use else NA,
    
    flag_no_diagnosed_or_medication = case_when(
      has_diagnosis_info & has_med_info ~ !diagnosed_diabetes & !diabetes_medication_use,
      has_diagnosis_info & !has_med_info ~ !diagnosed_diabetes,
      !has_diagnosis_info & has_med_info ~ !diabetes_medication_use,
      TRUE ~ NA
    ),
    
    flag_strict_non_diabetes = case_when(
      has_diagnosis_info & has_med_info ~
        !diagnosed_diabetes & !diabetes_medication_use & !biochemical_diabetes,
      has_diagnosis_info & !has_med_info ~
        !diagnosed_diabetes & !biochemical_diabetes,
      !has_diagnosis_info & has_med_info ~
        !diabetes_medication_use & !biochemical_diabetes,
      TRUE ~ !biochemical_diabetes
    ),
    
    flag_strict_normoglycemia = case_when(
      has_diagnosis_info & has_med_info ~
        !diagnosed_diabetes &
        !borderline_diabetes &
        !diabetes_medication_use &
        !biochemical_prediabetes_or_diabetes,
      has_diagnosis_info & !has_med_info ~
        !diagnosed_diabetes &
        !borderline_diabetes &
        !biochemical_prediabetes_or_diabetes,
      !has_diagnosis_info & has_med_info ~
        !diabetes_medication_use &
        !biochemical_prediabetes_or_diabetes,
      TRUE ~ !biochemical_prediabetes_or_diabetes
    )
  )

write_rds(
  df_sens,
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset.rds")
)

write_csv(
  df_sens,
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset.csv")
)

# ------------------------------------------------------------
# 5. Sensitivity sample definitions
# ------------------------------------------------------------

sample_defs <- tibble::tribble(
  ~sample_id, ~sample_label, ~flag_var, ~primary_use,
  "full", "Full analytic sample", "flag_full", "Reference",
  "no_diagnosed", "Exclude diagnosed diabetes", "flag_no_diagnosed_diabetes", "Sensitivity",
  "no_medication", "Exclude antidiabetic medication users", "flag_no_diabetes_medication", "Sensitivity",
  "no_diagnosed_or_med", "Exclude diagnosed diabetes or medication users", "flag_no_diagnosed_or_medication", "Primary sensitivity",
  "strict_non_diabetes", "Exclude diagnosed/medication/biochemical diabetes", "flag_strict_non_diabetes", "Strict sensitivity",
  "strict_normoglycemia", "Strict normoglycemia only", "flag_strict_normoglycemia", "Exploratory"
)

# Keep only samples with usable flags
sample_defs <- sample_defs %>%
  filter(flag_var %in% names(df_sens))

# ------------------------------------------------------------
# 6. Sample counts
# ------------------------------------------------------------

sample_counts <- map_dfr(
  seq_len(nrow(sample_defs)),
  function(i) {
    flag_var <- sample_defs$flag_var[i]
    
    tibble(
      sample_id = sample_defs$sample_id[i],
      sample_label = sample_defs$sample_label[i],
      flag_var = flag_var,
      adults_n = sum(df_sens$RIDAGEYR >= 20 & df_sens[[flag_var]] %in% TRUE, na.rm = TRUE),
      HOMA_available_n = if ("ln_HOMA_IR" %in% names(df_sens)) {
        sum(df_sens$RIDAGEYR >= 20 & df_sens[[flag_var]] %in% TRUE & !is.na(df_sens$ln_HOMA_IR), na.rm = TRUE)
      } else NA_integer_,
      HbA1c_available_n = if ("HbA1c" %in% names(df_sens)) {
        sum(df_sens$RIDAGEYR >= 20 & df_sens[[flag_var]] %in% TRUE & !is.na(df_sens$HbA1c), na.rm = TRUE)
      } else NA_integer_,
      TyG_available_n = if ("TyG_index" %in% names(df_sens)) {
        sum(df_sens$RIDAGEYR >= 20 & df_sens[[flag_var]] %in% TRUE & !is.na(df_sens$TyG_index), na.rm = TRUE)
      } else NA_integer_,
      TGHDL_available_n = if ("ln_TG_HDL_C" %in% names(df_sens)) {
        sum(df_sens$RIDAGEYR >= 20 & df_sens[[flag_var]] %in% TRUE & !is.na(df_sens$ln_TG_HDL_C), na.rm = TRUE)
      } else NA_integer_
    )
  }
)

print(sample_counts)

# ------------------------------------------------------------
# 7. Survey design and model specs
# ------------------------------------------------------------

if ("WTSB6YR_MAIN" %in% names(df_sens)) {
  weight_var <- "WTSB6YR_MAIN"
} else if ("WTSB6YR_FAST" %in% names(df_sens)) {
  weight_var <- "WTSB6YR_FAST"
} else if ("WTSAF6YR" %in% names(df_sens)) {
  weight_var <- "WTSAF6YR"
} else if ("WTSAF2YR" %in% names(df_sens)) {
  df_sens <- df_sens %>% mutate(WTSB6YR_DIAB_SENS = WTSAF2YR / 3)
  weight_var <- "WTSB6YR_DIAB_SENS"
} else {
  stop("找不到合适的 survey weight。")
}

cat("\nUsing survey weight:", weight_var, "\n")

required_design <- c("SDMVPSU", "SDMVSTRA", weight_var)
missing_design <- setdiff(required_design, names(df_sens))

if (length(missing_design) > 0) {
  stop(paste0("缺少复杂抽样设计变量：", paste(missing_design, collapse = ", ")))
}

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
  names(df_sens)
)

if (length(missing_covars) > 0) {
  stop(paste0("缺少协变量：", paste(missing_covars, collapse = ", ")))
}

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~outcome_type,
  "ln_HOMA_IR", "ln(HOMA-IR)", "log_ratio_outcome",
  "HbA1c", "HbA1c", "absolute_outcome",
  "TyG_index", "TyG index", "absolute_outcome",
  "ln_TG_HDL_C", "ln(TG/HDL-C)", "log_ratio_outcome"
) %>%
  filter(outcome %in% names(df_sens))

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~exposure_type, ~include_creatinine, ~include_total_burden,
  "ln_Sigma_DEHP", "lnΣDEHP", "total burden", TRUE, FALSE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", "oxidative fraction", FALSE, FALSE,
  "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]", "log-ratio composition", TRUE, TRUE,
  "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance", "ILR composition", TRUE, TRUE
) %>%
  filter(exposure %in% names(df_sens))

if (nrow(outcome_map) == 0) {
  stop("没有可用结局变量。")
}

if (nrow(exposure_map) == 0) {
  stop("没有可用暴露变量。")
}

cat("\nOutcomes to be modeled:\n")
print(outcome_map)

cat("\nExposures to be modeled:\n")
print(exposure_map)

# ------------------------------------------------------------
# 8. Model runner
# ------------------------------------------------------------

run_svy_model <- function(sample_id, sample_label, flag_var,
                          outcome, outcome_label, outcome_type,
                          exposure, exposure_label, exposure_type,
                          include_creatinine, include_total_burden) {
  
  covar_terms <- base_covars
  needed_vars <- c(outcome, exposure, base_vars, flag_var)
  
  if (include_creatinine) {
    covar_terms <- c(covar_terms, "ln_URXUCR")
    needed_vars <- c(needed_vars, "ln_URXUCR")
  }
  
  if (include_total_burden) {
    if ("ln_Sigma_DEHP_comp" %in% names(df_sens)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP_comp")
      needed_vars <- c(needed_vars, "ln_Sigma_DEHP_comp")
    } else if ("ln_Sigma_DEHP" %in% names(df_sens)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP")
      needed_vars <- c(needed_vars, "ln_Sigma_DEHP")
    }
  }
  
  missing_needed <- setdiff(unique(needed_vars), names(df_sens))
  
  if (length(missing_needed) > 0) {
    return(tibble(
      sample_id = sample_id,
      sample_label = sample_label,
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
  
  d <- df_sens %>%
    filter(
      RIDAGEYR >= 20,
      .data[[flag_var]] %in% TRUE
    ) %>%
    select(all_of(unique(needed_vars))) %>%
    drop_na()
  
  if (nrow(d) < 300) {
    return(tibble(
      sample_id = sample_id,
      sample_label = sample_label,
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
    weights = as.formula(paste0("~", weight_var)),
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
      sample_id = sample_id,
      sample_label = sample_label,
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
      sample_id = sample_id,
      sample_label = sample_label,
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
    sample_id = sample_id,
    sample_label = sample_label,
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_type = exposure_type,
    include_creatinine = include_creatinine,
    include_total_burden = include_total_burden,
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
# 9. Run all sensitivity models
# ------------------------------------------------------------

sensitivity_results <- expand_grid(
  sample_row = seq_len(nrow(sample_defs)),
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(sample_row, outcome_row, exposure_row),
      function(i, j, k) {
        run_svy_model(
          sample_id = sample_defs$sample_id[i],
          sample_label = sample_defs$sample_label[i],
          flag_var = sample_defs$flag_var[i],
          outcome = outcome_map$outcome[j],
          outcome_label = outcome_map$outcome_label[j],
          outcome_type = outcome_map$outcome_type[j],
          exposure = exposure_map$exposure[k],
          exposure_label = exposure_map$exposure_label[k],
          exposure_type = exposure_map$exposure_type[k],
          include_creatinine = exposure_map$include_creatinine[k],
          include_total_burden = exposure_map$include_total_burden[k]
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl) %>%
  group_by(sample_id, outcome_label) %>%
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

print(sensitivity_results)

# ------------------------------------------------------------
# 10. Compare sensitivity estimates with full analytic sample
# ------------------------------------------------------------

main_estimates <- sensitivity_results %>%
  filter(sample_id == "full") %>%
  select(
    outcome,
    exposure,
    main_beta = beta,
    main_effect = effect,
    main_p_value = p_value
  )

sensitivity_compared <- sensitivity_results %>%
  left_join(main_estimates, by = c("outcome", "exposure")) %>%
  mutate(
    same_direction_as_main = case_when(
      is.na(beta) | is.na(main_beta) ~ NA,
      beta == 0 | main_beta == 0 ~ NA,
      sign(beta) == sign(main_beta) ~ TRUE,
      TRUE ~ FALSE
    ),
    beta_ratio_vs_main = beta / main_beta,
    retained_80_percent_of_main = case_when(
      is.na(beta_ratio_vs_main) ~ NA,
      beta_ratio_vs_main >= 0.80 & beta_ratio_vs_main <= 1.25 ~ TRUE,
      TRUE ~ FALSE
    ),
    robustness_decision = case_when(
      sample_id == "full" ~ "Reference",
      same_direction_as_main == TRUE & p_value < 0.05 ~ "Robust positive",
      same_direction_as_main == TRUE & beta > 0 ~ "Directionally consistent",
      same_direction_as_main == FALSE ~ "Direction changed",
      TRUE ~ "Unclear"
    )
  )

# ------------------------------------------------------------
# 11. Key results for manuscript
# ------------------------------------------------------------

key_results <- sensitivity_compared %>%
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
    sample_label,
    outcome_label,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    inference,
    same_direction_as_main,
    beta_ratio_vs_main,
    robustness_decision
  ) %>%
  arrange(outcome_label, exposure_label, sample_label)

primary_sensitivity_summary <- key_results %>%
  filter(sample_label == "Exclude diagnosed diabetes or medication users")

strict_sensitivity_summary <- key_results %>%
  filter(sample_label == "Exclude diagnosed/medication/biochemical diabetes")

# ------------------------------------------------------------
# 12. Plot: forest for key oxidative indicators
# ------------------------------------------------------------

plot_forest <- sensitivity_compared %>%
  filter(
    exposure %in% c(
      "pct_oxidative_10",
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    ),
    outcome %in% c("ln_HOMA_IR", "HbA1c", "TyG_index", "ln_TG_HDL_C"),
    sample_id %in% c(
      "full",
      "no_diagnosed",
      "no_medication",
      "no_diagnosed_or_med",
      "strict_non_diabetes"
    ),
    !is.na(effect),
    !is.na(effect_low),
    !is.na(effect_high)
  ) %>%
  mutate(
    sample_label = factor(
      sample_label,
      levels = rev(c(
        "Full analytic sample",
        "Exclude diagnosed diabetes",
        "Exclude antidiabetic medication users",
        "Exclude diagnosed diabetes or medication users",
        "Exclude diagnosed/medication/biochemical diabetes"
      ))
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

if (nrow(plot_forest) > 0) {
  p_forest <- ggplot(plot_forest, aes(x = effect, y = sample_label)) +
    geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.35) +
    geom_errorbarh(
      aes(xmin = effect_low, xmax = effect_high),
      height = 0.18,
      linewidth = 0.45
    ) +
    geom_point(size = 2.2) +
    geom_text(
      aes(label = sig_label),
      nudge_y = 0.20,
      size = 3.3,
      fontface = "bold"
    ) +
    facet_grid(outcome_label ~ exposure_label, scales = "free_x") +
    labs(
      title = "Diabetes and antidiabetic medication exclusion sensitivity analyses",
      subtitle = "Survey-weighted models for DEHP oxidative metabolic indicators and metabolic outcomes",
      x = "Effect estimate",
      y = NULL,
      caption = "* nominal P < 0.05; ** FDR q < 0.05. For log-transformed outcomes, estimates represent percent differences."
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold", size = 8.3),
      strip.background = element_rect(fill = "grey90", color = "grey35"),
      panel.grid.minor = element_line(color = "grey92"),
      panel.grid.major = element_line(color = "grey86"),
      axis.text.y = element_text(size = 8.5),
      plot.caption = element_text(size = 8.3, hjust = 0)
    )
  
  print(p_forest)
  
  ggsave(
    file.path(fig_dir, "diabetes_medication_exclusion_forest_2013_2018.png"),
    p_forest,
    width = 15,
    height = 10,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "diabetes_medication_exclusion_forest_2013_2018.pdf"),
    p_forest,
    width = 15,
    height = 10
  )
  
  ggsave(
    file.path(fig_dir, "diabetes_medication_exclusion_forest_2013_2018.tiff"),
    p_forest,
    width = 15,
    height = 10,
    dpi = 600,
    compression = "lzw"
  )
}

# ------------------------------------------------------------
# 13. Plot: robustness matrix
# ------------------------------------------------------------

robustness_matrix <- sensitivity_compared %>%
  filter(
    exposure %in% c(
      "pct_oxidative_10",
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    ),
    outcome %in% c("ln_HOMA_IR", "HbA1c", "TyG_index", "ln_TG_HDL_C"),
    sample_id != "full"
  ) %>%
  mutate(
    evidence_level = case_when(
      same_direction_as_main == TRUE & q_value < 0.05 & beta > 0 ~ "FDR robust",
      same_direction_as_main == TRUE & p_value < 0.05 & beta > 0 ~ "Nominal robust",
      same_direction_as_main == TRUE & beta > 0 ~ "Direction-consistent",
      same_direction_as_main == FALSE ~ "Direction changed",
      TRUE ~ "Unclear"
    ),
    evidence_score = case_when(
      evidence_level == "FDR robust" ~ 4,
      evidence_level == "Nominal robust" ~ 3,
      evidence_level == "Direction-consistent" ~ 2,
      evidence_level == "Direction changed" ~ 1,
      TRUE ~ 0
    ),
    row_label = paste(outcome_label, exposure_label, sep = " | ")
  )

if (nrow(robustness_matrix) > 0) {
  p_matrix <- ggplot(
    robustness_matrix,
    aes(x = sample_label, y = row_label, fill = evidence_score)
  ) +
    geom_tile(color = "white", linewidth = 0.4) +
    geom_text(aes(label = evidence_level), size = 2.7) +
    scale_fill_gradient(
      low = "grey90",
      high = "darkgreen",
      limits = c(0, 4),
      breaks = 0:4
    ) +
    labs(
      title = "Robustness matrix for diabetes and medication exclusion analyses",
      subtitle = "Evidence level compared with the full analytic sample",
      x = NULL,
      y = NULL,
      fill = "Evidence score"
    ) +
    theme_bw(base_size = 10) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      axis.text.x = element_text(angle = 35, hjust = 1, size = 8),
      axis.text.y = element_text(size = 7.5),
      panel.grid = element_blank()
    )
  
  print(p_matrix)
  
  ggsave(
    file.path(fig_dir, "diabetes_medication_exclusion_robustness_matrix_2013_2018.png"),
    p_matrix,
    width = 13,
    height = 9,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "diabetes_medication_exclusion_robustness_matrix_2013_2018.pdf"),
    p_matrix,
    width = 13,
    height = 9
  )
}

# ------------------------------------------------------------
# 14. Export results
# ------------------------------------------------------------

write_xlsx(
  list(
    variable_check = tibble(
      variable = c("DIQ010", "DIQ050", "DIQ070", "HbA1c", "glucose_mgdl"),
      detected_as = c(var_diq010, var_diq050, var_diq070,
                      ifelse("HbA1c" %in% names(df_sens), "HbA1c", NA),
                      ifelse("glucose_mgdl" %in% names(df_sens), "glucose_mgdl", NA)),
      available = c(has_diagnosis_info, has_insulin_info, has_pill_info,
                    "HbA1c" %in% names(df_sens),
                    "glucose_mgdl" %in% names(df_sens))
    ),
    sample_counts = sample_counts,
    all_sensitivity_results = sensitivity_compared,
    key_results = key_results,
    primary_sensitivity = primary_sensitivity_summary,
    strict_sensitivity = strict_sensitivity_summary,
    robustness_matrix_data = robustness_matrix
  ),
  file.path(result_dir, "diabetes_medication_exclusion_sensitivity_results_2013_2018.xlsx")
)

write_csv(
  sensitivity_compared,
  file.path(result_dir, "diabetes_medication_exclusion_sensitivity_results_2013_2018.csv")
)

write_csv(
  key_results,
  file.path(result_dir, "diabetes_medication_exclusion_key_results_2013_2018.csv")
)

cat("\nDiabetes / medication exclusion sensitivity analysis completed successfully.\n")
cat("Results saved to:\n")
cat(file.path(result_dir, "diabetes_medication_exclusion_sensitivity_results_2013_2018.xlsx"), "\n")
cat(file.path(result_dir, "diabetes_medication_exclusion_sensitivity_results_2013_2018.csv"), "\n")
cat("Figures saved to:\n")
cat(file.path(fig_dir, "diabetes_medication_exclusion_forest_2013_2018.png"), "\n")
cat(file.path(fig_dir, "diabetes_medication_exclusion_robustness_matrix_2013_2018.png"), "\n")