# ============================================================
# NHANES 2013-2018
# 50_source_adjusted_DEHP_metabolic_models_2013_2018.R
# Source-adjusted DEHP-metabolic models
# ============================================================

required_packages <- c(
  "dplyr", "tidyr", "purrr", "readr", "tibble",
  "survey", "ggplot2", "writexl", "stringr"
)

installed <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed)
if (length(missing_packages) > 0) install.packages(missing_packages)

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(tibble)
library(survey)
library(ggplot2)
library(writexl)
library(stringr)

options(survey.lonely.psu = "adjust")

# ------------------------------------------------------------
# 0. Paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir    <- file.path(result_dir, "figures_source_analysis")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Helper functions
# ------------------------------------------------------------

format_p <- function(p) {
  ifelse(
    is.na(p),
    NA_character_,
    ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

safe_z <- function(x) {
  x <- as.numeric(x)
  s <- sd(x, na.rm = TRUE)
  m <- mean(x, na.rm = TRUE)
  if (!is.finite(s) || s == 0) return(rep(NA_real_, length(x)))
  (x - m) / s
}

safe_positive <- function(x) {
  x <- as.numeric(x)
  ifelse(is.finite(x) & x > 0, x, NA_real_)
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

drop_unusable_terms <- function(dat, terms) {
  usable <- c()
  
  for (term in terms) {
    var_name <- term
    
    if (str_detect(term, "^factor\\(")) {
      var_name <- str_replace_all(term, "^factor\\(|\\)$", "")
    }
    
    if (!(var_name %in% names(dat))) next
    
    x <- dat[[var_name]]
    
    if (all(is.na(x))) next
    
    if (is.numeric(x) || is.integer(x)) {
      if (sum(!is.na(x)) >= 300 && sd(as.numeric(x), na.rm = TRUE) > 0) {
        usable <- c(usable, term)
      }
    } else {
      if (length(unique(na.omit(x))) >= 2) {
        usable <- c(usable, term)
      }
    }
  }
  
  usable
}

# ------------------------------------------------------------
# 2. Read source-oriented dataset
# ------------------------------------------------------------

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_source_oriented_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset_with_DIQ050_DIQ070.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset_with_DIQmed.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]

if (is.na(data_file)) {
  stop("找不到 source-oriented dataset。请先确认 49 脚本已经成功生成 NHANES_2013_2018_source_oriented_dataset.rds。")
}

df <- readRDS(data_file) %>%
  as_tibble()

cat("Using dataset:\n", data_file, "\n")
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")

# ------------------------------------------------------------
# 3. Ensure core variables
# ------------------------------------------------------------

if (!("ln_HOMA_IR" %in% names(df)) && "HOMA_IR" %in% names(df)) {
  df <- df %>% mutate(ln_HOMA_IR = log(HOMA_IR))
}

if (!("HbA1c" %in% names(df)) && "LBXGH" %in% names(df)) {
  df <- df %>% mutate(HbA1c = LBXGH)
}

if (!("ln_URXUCR" %in% names(df)) && "URXUCR" %in% names(df)) {
  df <- df %>% mutate(ln_URXUCR = log(safe_positive(URXUCR)))
}

if (!("cycle" %in% names(df)) && "SDDSRVYR" %in% names(df)) {
  df <- df %>% mutate(cycle = SDDSRVYR)
}

if (!("pct_oxidative_10" %in% names(df)) && "pct_oxidative" %in% names(df)) {
  df <- df %>% mutate(pct_oxidative_10 = pct_oxidative / 10)
}

# ------------------------------------------------------------
# 4. Construct source-adjustment covariates
# ------------------------------------------------------------

df <- df %>%
  mutate(
    # Avoid overlap: away-home excluding fast food.
    away_nonfastfood_pct_kcal = case_when(
      !is.na(away_home_pct_kcal) & !is.na(fastfood_pct_kcal) ~
        pmax(away_home_pct_kcal - fastfood_pct_kcal, 0),
      !is.na(away_home_pct_kcal) & is.na(fastfood_pct_kcal) ~
        away_home_pct_kcal,
      TRUE ~ NA_real_
    ),
    
    # Scale percent-of-energy source variables per 10 percentage points.
    fastfood_pct_kcal_10 =
      if ("fastfood_pct_kcal" %in% names(.)) fastfood_pct_kcal / 10 else NA_real_,
    
    away_nonfastfood_pct_kcal_10 =
      away_nonfastfood_pct_kcal / 10,
    
    processed_proxy_pct_kcal_10 =
      if ("processed_proxy_pct_kcal" %in% names(.)) processed_proxy_pct_kcal / 10 else NA_real_,
    
    convenience_vending_pct_kcal_10 =
      if ("convenience_vending_pct_kcal" %in% names(.)) convenience_vending_pct_kcal / 10 else NA_real_,
    
    frozen_lunchkit_pct_kcal_10 =
      if ("frozen_lunchkit_pct_kcal" %in% names(.)) frozen_lunchkit_pct_kcal / 10 else NA_real_,
    
    fastfood_meals_7d_z =
      if ("fastfood_meals_7d" %in% names(.)) safe_z(fastfood_meals_7d) else NA_real_,
    
    poor_diet_score_z =
      if ("poor_diet_score" %in% names(.)) safe_z(poor_diet_score) else NA_real_,
    
    diet_quality_proxy_score_z =
      if ("diet_quality_proxy_score" %in% names(.)) safe_z(diet_quality_proxy_score) else NA_real_,
    
    ln_MEP_z =
      if ("ln_MEP_personalcare_proxy" %in% names(.)) safe_z(ln_MEP_personalcare_proxy) else NA_real_
  )

# ------------------------------------------------------------
# 5. Survey weight
# ------------------------------------------------------------

if ("WTSB6YR_MAIN" %in% names(df)) {
  weight_var <- "WTSB6YR_MAIN"
} else if ("WTSAF6YR" %in% names(df)) {
  weight_var <- "WTSAF6YR"
} else if ("WTSAF2YR" %in% names(df)) {
  df <- df %>% mutate(WTSB6YR_SOURCE_ADJ = WTSAF2YR / 3)
  weight_var <- "WTSB6YR_SOURCE_ADJ"
} else if ("WTMEC6YR" %in% names(df)) {
  weight_var <- "WTMEC6YR"
} else {
  stop("找不到合适权重变量。")
}

required_design <- c("SDMVPSU", "SDMVSTRA", weight_var)
missing_design <- setdiff(required_design, names(df))

if (length(missing_design) > 0) {
  stop(paste0("缺少复杂抽样设计变量：", paste(missing_design, collapse = ", ")))
}

cat("Using weight:", weight_var, "\n")

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

if (nrow(outcome_map) == 0) stop("没有可用代谢结局变量。")
if (nrow(exposure_map) == 0) stop("没有可用 DEHP 暴露变量。")

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
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "cycle", "SDMVPSU", "SDMVSTRA", weight_var
)

# Source-adjustment model sets.
# M1 avoids away_home overlap by using away_nonfastfood_pct_kcal_10.
model_sets <- tibble::tribble(
  ~model_id, ~model_label, ~source_terms, ~model_role,
  "M0", "Main model", "", "Reference",
  "M1", "Diet-source adjusted", "fastfood_pct_kcal_10 + away_nonfastfood_pct_kcal_10 + poor_diet_score_z", "Dietary source context",
  "M2", "MEP co-exposure adjusted", "ln_MEP_z", "Personal-care/fragrance co-exposure proxy",
  "M3", "Primary source-adjusted", "fastfood_pct_kcal_10 + away_nonfastfood_pct_kcal_10 + poor_diet_score_z + ln_MEP_z", "Primary source-adjusted sensitivity",
  "M4", "Extended source-adjusted", "fastfood_pct_kcal_10 + away_nonfastfood_pct_kcal_10 + poor_diet_score_z + ln_MEP_z + processed_proxy_pct_kcal_10 + convenience_vending_pct_kcal_10 + frozen_lunchkit_pct_kcal_10", "Extended source context"
)

parse_terms <- function(x) {
  if (is.na(x) || x == "") return(character())
  str_split(x, "\\+")[[1]] %>%
    str_trim() %>%
    discard(~ .x == "")
}

# ------------------------------------------------------------
# 7. Variable diagnostics
# ------------------------------------------------------------

source_covariates_to_check <- unique(unlist(map(model_sets$source_terms, parse_terms)))

source_covariate_check <- tibble(
  variable = source_covariates_to_check,
  available = variable %in% names(df),
  nonmissing_n = map_int(
    source_covariates_to_check,
    ~ if (.x %in% names(df)) sum(!is.na(df[[.x]])) else 0
  ),
  mean = map_dbl(
    source_covariates_to_check,
    ~ if (.x %in% names(df)) mean(df[[.x]], na.rm = TRUE) else NA_real_
  ),
  sd = map_dbl(
    source_covariates_to_check,
    ~ if (.x %in% names(df)) sd(df[[.x]], na.rm = TRUE) else NA_real_
  )
)

print(source_covariate_check)

# ------------------------------------------------------------
# 8. Core model runner
# ------------------------------------------------------------

run_dehp_metabolic_model <- function(outcome, outcome_label, outcome_type,
                                     exposure, exposure_label, exposure_type,
                                     include_creatinine, include_total_burden,
                                     model_id, model_label, source_terms, model_role) {
  
  source_terms_vec <- parse_terms(source_terms)
  
  covar_terms <- base_covars
  needed_vars <- c(outcome, exposure, base_vars)
  
  if (include_creatinine) {
    covar_terms <- c(covar_terms, "ln_URXUCR")
    needed_vars <- c(needed_vars, "ln_URXUCR")
  }
  
  total_burden_term <- NA_character_
  
  if (include_total_burden) {
    if ("ln_Sigma_DEHP_comp" %in% names(df)) {
      total_burden_term <- "ln_Sigma_DEHP_comp"
    } else if ("ln_Sigma_DEHP" %in% names(df)) {
      total_burden_term <- "ln_Sigma_DEHP"
    }
    
    if (!is.na(total_burden_term) && total_burden_term != exposure) {
      covar_terms <- c(covar_terms, total_burden_term)
      needed_vars <- c(needed_vars, total_burden_term)
    }
  }
  
  # Keep only source covariates that exist and have enough variation.
  source_terms_usable <- drop_unusable_terms(df, source_terms_vec)
  
  if (length(source_terms_vec) > 0 && length(source_terms_usable) == 0) {
    return(tibble(
      model_id = model_id,
      model_label = model_label,
      model_role = model_role,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      source_terms_requested = paste(source_terms_vec, collapse = " + "),
      source_terms_used = NA_character_,
      n = NA_integer_,
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "No usable source covariates"
    ))
  }
  
  covar_terms <- c(covar_terms, source_terms_usable)
  needed_vars <- c(needed_vars, source_terms_usable)
  
  missing_needed <- setdiff(unique(needed_vars), names(df))
  
  if (length(missing_needed) > 0) {
    return(tibble(
      model_id = model_id,
      model_label = model_label,
      model_role = model_role,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      source_terms_requested = paste(source_terms_vec, collapse = " + "),
      source_terms_used = paste(source_terms_usable, collapse = " + "),
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
  
  d <- df %>%
    filter(RIDAGEYR >= 20) %>%
    select(all_of(unique(needed_vars))) %>%
    drop_na()
  
  if (nrow(d) < 300) {
    return(tibble(
      model_id = model_id,
      model_label = model_label,
      model_role = model_role,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      source_terms_requested = paste(source_terms_vec, collapse = " + "),
      source_terms_used = paste(source_terms_usable, collapse = " + "),
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
  
  # Drop terms that become unusable after complete-case filtering.
  covar_terms_final <- drop_unusable_terms(d, covar_terms)
  
  f <- as.formula(
    paste0(
      outcome,
      " ~ ",
      exposure,
      " + ",
      paste(covar_terms_final, collapse = " + ")
    )
  )
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = as.formula(paste0("~", weight_var)),
    nest = TRUE,
    data = d
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) {
      message("Model failed: ", outcome, " ~ ", exposure, " | ", model_label)
      message(e$message)
      NULL
    }
  )
  
  if (is.null(fit)) {
    return(tibble(
      model_id = model_id,
      model_label = model_label,
      model_role = model_role,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      source_terms_requested = paste(source_terms_vec, collapse = " + "),
      source_terms_used = paste(source_terms_usable, collapse = " + "),
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
  
  ct <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(ct))) {
    return(tibble(
      model_id = model_id,
      model_label = model_label,
      model_role = model_role,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      source_terms_requested = paste(source_terms_vec, collapse = " + "),
      source_terms_used = paste(source_terms_usable, collapse = " + "),
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Exposure coefficient unavailable"
    ))
  }
  
  beta <- ct[exposure, "Estimate"]
  se <- ct[exposure, "Std. Error"]
  p <- ct[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  eff <- effect_transform(beta, low, high, outcome_type)
  
  tibble(
    model_id = model_id,
    model_label = model_label,
    model_role = model_role,
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_type = exposure_type,
    source_terms_requested = paste(source_terms_vec, collapse = " + "),
    source_terms_used = paste(source_terms_usable, collapse = " + "),
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p,
    effect = eff["effect"],
    effect_low = eff["effect_low"],
    effect_high = eff["effect_high"],
    result = case_when(
      is.na(p) ~ "Unavailable",
      p < 0.05 & beta > 0 ~ "Nominal positive",
      p < 0.05 & beta < 0 ~ "Nominal negative",
      beta > 0 ~ "Positive direction",
      beta < 0 ~ "Negative direction",
      TRUE ~ "Weak/no support"
    )
  )
}

# ------------------------------------------------------------
# 9. Run all models
# ------------------------------------------------------------

source_adjusted_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map)),
  model_row = seq_len(nrow(model_sets))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, exposure_row, model_row),
      function(i, j, k) {
        run_dehp_metabolic_model(
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          outcome_type = outcome_map$outcome_type[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          exposure_type = exposure_map$exposure_type[j],
          include_creatinine = exposure_map$include_creatinine[j],
          include_total_burden = exposure_map$include_total_burden[j],
          model_id = model_sets$model_id[k],
          model_label = model_sets$model_label[k],
          source_terms = model_sets$source_terms[k],
          model_role = model_sets$model_role[k]
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl) %>%
  group_by(model_id, outcome_label) %>%
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

print(source_adjusted_results)

# ------------------------------------------------------------
# 10. Attenuation comparison versus main model
# ------------------------------------------------------------

main_reference <- source_adjusted_results %>%
  filter(model_id == "M0") %>%
  select(
    outcome,
    exposure,
    beta_main = beta,
    effect_main = effect,
    p_main = p_value,
    q_main = q_value,
    n_main = n
  )

source_adjusted_compared <- source_adjusted_results %>%
  left_join(main_reference, by = c("outcome", "exposure")) %>%
  mutate(
    same_direction_as_main = case_when(
      is.na(beta) | is.na(beta_main) ~ NA,
      beta == 0 | beta_main == 0 ~ NA,
      sign(beta) == sign(beta_main) ~ TRUE,
      TRUE ~ FALSE
    ),
    beta_ratio_vs_main = beta / beta_main,
    attenuation_percent = (1 - beta / beta_main) * 100,
    sample_ratio_vs_main = n / n_main,
    source_adjusted_decision = case_when(
      model_id == "M0" ~ "Reference",
      same_direction_as_main == TRUE & q_value < 0.05 & beta > 0 & beta_ratio_vs_main >= 0.70 ~ "Robust after source adjustment",
      same_direction_as_main == TRUE & p_value < 0.05 & beta > 0 & beta_ratio_vs_main >= 0.70 ~ "Nominally robust after source adjustment",
      same_direction_as_main == TRUE & beta > 0 & beta_ratio_vs_main >= 0.50 ~ "Directionally consistent with moderate attenuation",
      same_direction_as_main == TRUE & beta > 0 & beta_ratio_vs_main < 0.50 ~ "Strongly attenuated but same direction",
      same_direction_as_main == FALSE ~ "Direction changed",
      TRUE ~ "Unclear"
    )
  )

key_results <- source_adjusted_compared %>%
  filter(
    exposure %in% c(
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
    model_id,
    model_label,
    outcome_label,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    beta_ratio_vs_main,
    attenuation_percent,
    sample_ratio_vs_main,
    same_direction_as_main,
    source_adjusted_decision,
    source_terms_used
  ) %>%
  arrange(outcome_label, exposure_label, model_id)

primary_source_adjusted <- key_results %>%
  filter(model_id == "M3")

extended_source_adjusted <- key_results %>%
  filter(model_id == "M4")

# ------------------------------------------------------------
# 11. Sample-size table
# ------------------------------------------------------------

sample_size_summary <- source_adjusted_compared %>%
  group_by(model_id, model_label, outcome_label, exposure_label) %>%
  summarise(
    n = first(n),
    n_main = first(n_main),
    sample_ratio_vs_main = first(sample_ratio_vs_main),
    .groups = "drop"
  )

# ------------------------------------------------------------
# 12. Plot 1: forest plot for key oxidative indicators
# ------------------------------------------------------------

plot_df <- source_adjusted_compared %>%
  filter(
    exposure %in% c(
      "pct_oxidative_10",
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    ),
    outcome %in% c("ln_HOMA_IR", "HbA1c", "TyG_index", "ln_TG_HDL_C"),
    model_id %in% c("M0", "M1", "M2", "M3", "M4"),
    !is.na(effect),
    !is.na(effect_low),
    !is.na(effect_high)
  ) %>%
  mutate(
    model_label = factor(
      model_label,
      levels = rev(c(
        "Main model",
        "Diet-source adjusted",
        "MEP co-exposure adjusted",
        "Primary source-adjusted",
        "Extended source-adjusted"
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

if (nrow(plot_df) > 0) {
  p_forest <- ggplot(plot_df, aes(x = effect, y = model_label)) +
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
      size = 3.2,
      fontface = "bold"
    ) +
    facet_grid(outcome_label ~ exposure_label, scales = "free_x") +
    labs(
      title = "Source-adjusted DEHP–metabolic associations",
      subtitle = "Comparison of main and source-context-adjusted survey-weighted models",
      x = "Effect estimate",
      y = NULL,
      caption = paste0(
        "* nominal P < 0.05; ** FDR q < 0.05. ",
        "For log-transformed outcomes, estimates represent percent differences. ",
        "Primary source-adjusted model includes fast-food energy, non-fast-food away-from-home energy, poor diet score, and ln(MEP)."
      )
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
      plot.caption = element_text(size = 8.1, hjust = 0)
    )
  
  print(p_forest)
  
  ggsave(
    file.path(fig_dir, "source_adjusted_DEHP_metabolic_forest_2013_2018.png"),
    p_forest,
    width = 15,
    height = 10,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "source_adjusted_DEHP_metabolic_forest_2013_2018.pdf"),
    p_forest,
    width = 15,
    height = 10
  )
  
  ggsave(
    file.path(fig_dir, "source_adjusted_DEHP_metabolic_forest_2013_2018.tiff"),
    p_forest,
    width = 15,
    height = 10,
    dpi = 600,
    compression = "lzw"
  )
}

# ------------------------------------------------------------
# 13. Plot 2: attenuation heatmap
# ------------------------------------------------------------

attenuation_df <- source_adjusted_compared %>%
  filter(
    model_id != "M0",
    exposure %in% c(
      "pct_oxidative_10",
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    ),
    outcome %in% c("ln_HOMA_IR", "HbA1c", "TyG_index", "ln_TG_HDL_C"),
    !is.na(beta_ratio_vs_main)
  ) %>%
  mutate(
    row_label = paste(outcome_label, exposure_label, sep = " | "),
    beta_ratio_capped = pmax(pmin(beta_ratio_vs_main, 1.5), 0),
    label_text = sprintf("%.2f", beta_ratio_vs_main)
  )

if (nrow(attenuation_df) > 0) {
  p_heat <- ggplot(
    attenuation_df,
    aes(x = model_label, y = row_label, fill = beta_ratio_capped)
  ) +
    geom_tile(color = "white", linewidth = 0.35) +
    geom_text(aes(label = label_text), size = 3) +
    scale_fill_gradient(
      low = "grey90",
      high = "darkgreen",
      limits = c(0, 1.5),
      breaks = c(0, 0.5, 1.0, 1.5)
    ) +
    labs(
      title = "Effect retention after source-context adjustment",
      subtitle = "Cell values represent beta ratio versus the main model",
      x = NULL,
      y = NULL,
      fill = "Beta ratio"
    ) +
    theme_bw(base_size = 10) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      axis.text.x = element_text(angle = 35, hjust = 1),
      axis.text.y = element_text(size = 7.5),
      panel.grid = element_blank()
    )
  
  print(p_heat)
  
  ggsave(
    file.path(fig_dir, "source_adjusted_effect_retention_heatmap_2013_2018.png"),
    p_heat,
    width = 13,
    height = 9,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "source_adjusted_effect_retention_heatmap_2013_2018.pdf"),
    p_heat,
    width = 13,
    height = 9
  )
}

# ------------------------------------------------------------
# 14. Export
# ------------------------------------------------------------

write_xlsx(
  list(
    source_covariate_check = source_covariate_check,
    model_sets = model_sets,
    all_source_adjusted_results = source_adjusted_compared,
    key_results = key_results,
    primary_source_adjusted = primary_source_adjusted,
    extended_source_adjusted = extended_source_adjusted,
    sample_size_summary = sample_size_summary
  ),
  file.path(result_dir, "source_adjusted_DEHP_metabolic_models_2013_2018.xlsx")
)

write_csv(
  source_adjusted_compared,
  file.path(result_dir, "source_adjusted_DEHP_metabolic_models_2013_2018.csv")
)

write_csv(
  key_results,
  file.path(result_dir, "source_adjusted_DEHP_metabolic_key_results_2013_2018.csv")
)

cat("\nSource-adjusted DEHP-metabolic models completed successfully.\n")
cat("Results saved to:\n")
cat(file.path(result_dir, "source_adjusted_DEHP_metabolic_models_2013_2018.xlsx"), "\n")
cat("Figures saved to:\n")
cat(file.path(fig_dir, "source_adjusted_DEHP_metabolic_forest_2013_2018.png"), "\n")
cat(file.path(fig_dir, "source_adjusted_effect_retention_heatmap_2013_2018.png"), "\n")