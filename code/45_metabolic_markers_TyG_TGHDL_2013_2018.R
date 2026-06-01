# ============================================================
# NHANES 2013-2018
# 45_metabolic_markers_TyG_TGHDL_2013_2018.R
# Add TyG index and TG/HDL-C as secondary metabolic markers
# Fixed version: no .data[[NA_character_]] inside case_when()
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
fig_dir    <- file.path(result_dir, "figures_metabolic_markers")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Read best available dataset
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

# ------------------------------------------------------------
# 3. Identify glucose, triglycerides, HDL-C variables
# ------------------------------------------------------------

var_glucose_mg <- find_var_safe(
  df,
  exact_candidates = c(
    "LBXGLU", "glucose", "fasting_glucose", "fasting_glucose_mgdl",
    "glucose_mgdl", "glucose_mg_dL", "GLU"
  ),
  pattern_candidates = c("^LBXGLU$", "fast.*glucose", "glucose.*mg")
)

var_glucose_si <- find_var_safe(
  df,
  exact_candidates = c(
    "LBDGLUSI", "glucose_mmol", "glucose_mmol_l", "fasting_glucose_mmol"
  ),
  pattern_candidates = c("glucose.*mmol", "LBDGLUSI")
)

var_trig_mg <- find_var_safe(
  df,
  exact_candidates = c(
    "LBXTR", "triglycerides", "triglyceride", "trig", "TG",
    "triglycerides_mgdl", "trig_mgdl", "LBXTR_mg_dL"
  ),
  pattern_candidates = c("^LBXTR$", "trig.*mg", "triglycer")
)

var_trig_si <- find_var_safe(
  df,
  exact_candidates = c(
    "LBDTRSI", "triglycerides_mmol", "trig_mmol", "tg_mmol"
  ),
  pattern_candidates = c("trig.*mmol", "LBDTRSI")
)

var_hdl_mg <- find_var_safe(
  df,
  exact_candidates = c(
    "LBDHDD", "HDL", "hdl", "hdl_c", "HDL_C", "hdl_cholesterol",
    "hdl_mgdl", "hdl_c_mgdl", "LBDHDD_mg_dL"
  ),
  pattern_candidates = c("^LBDHDD$", "hdl.*mg", "hdl.*chol")
)

var_hdl_si <- find_var_safe(
  df,
  exact_candidates = c(
    "LBDHDDSI", "hdl_mmol", "hdl_c_mmol"
  ),
  pattern_candidates = c("hdl.*mmol", "LBDHDDSI")
)

cat("\nDetected metabolic-marker variables:\n")
cat("Glucose mg/dL:", var_glucose_mg, "\n")
cat("Glucose SI   :", var_glucose_si, "\n")
cat("TG mg/dL     :", var_trig_mg, "\n")
cat("TG SI        :", var_trig_si, "\n")
cat("HDL mg/dL    :", var_hdl_mg, "\n")
cat("HDL SI       :", var_hdl_si, "\n")

if (is.na(var_glucose_mg) && is.na(var_glucose_si)) {
  stop("找不到空腹血糖变量。请确认是否已下载 GLU 文件，常见变量名为 LBXGLU 或 LBDGLUSI。")
}

if (is.na(var_trig_mg) && is.na(var_trig_si)) {
  stop("找不到甘油三酯变量。请确认是否已下载 TRIGLY 文件，常见变量名为 LBXTR 或 LBDTRSI。")
}

if (is.na(var_hdl_mg) && is.na(var_hdl_si)) {
  stop("找不到 HDL-C 变量。请确认是否已下载 TCHOL/HDL 文件，常见变量名为 LBDHDD 或 LBDHDDSI。")
}

# ------------------------------------------------------------
# 4. Survey weights
# ------------------------------------------------------------

if ("WTSB6YR_MAIN" %in% names(df)) {
  weight_var <- "WTSB6YR_MAIN"
} else if ("WTSB6YR_FAST" %in% names(df)) {
  weight_var <- "WTSB6YR_FAST"
} else if ("WTSAF6YR" %in% names(df)) {
  weight_var <- "WTSAF6YR"
} else if ("WTSAF2YR" %in% names(df)) {
  df <- df %>%
    mutate(WTSB6YR_TyG = WTSAF2YR / 3)
  weight_var <- "WTSB6YR_TyG"
  message("Using WTSAF2YR / 3 as 6-year fasting subsample weight.")
} else if ("WTMEC6YR" %in% names(df)) {
  weight_var <- "WTMEC6YR"
} else if ("WTMEC2YR" %in% names(df)) {
  df <- df %>%
    mutate(WTMEC6YR_TyG = WTMEC2YR / 3)
  weight_var <- "WTMEC6YR_TyG"
  message("Using WTMEC2YR / 3 as 6-year MEC weight. Check whether fasting weights are available.")
} else {
  stop("找不到合适的 NHANES 权重变量。")
}

cat("\nUsing survey weight:", weight_var, "\n")

# ------------------------------------------------------------
# 5. Construct TyG and TG/HDL-C safely
# ------------------------------------------------------------

glucose_mgdl_vec <- if (!is.na(var_glucose_mg)) {
  get_numeric_var(df, var_glucose_mg)
} else {
  get_numeric_var(df, var_glucose_si) * 18.0182
}

triglycerides_mgdl_vec <- if (!is.na(var_trig_mg)) {
  get_numeric_var(df, var_trig_mg)
} else {
  get_numeric_var(df, var_trig_si) * 88.57
}

hdl_c_mgdl_vec <- if (!is.na(var_hdl_mg)) {
  get_numeric_var(df, var_hdl_mg)
} else {
  get_numeric_var(df, var_hdl_si) * 38.67
}

glucose_mgdl_vec <- ifelse(glucose_mgdl_vec > 0, glucose_mgdl_vec, NA_real_)
triglycerides_mgdl_vec <- ifelse(triglycerides_mgdl_vec > 0, triglycerides_mgdl_vec, NA_real_)
hdl_c_mgdl_vec <- ifelse(hdl_c_mgdl_vec > 0, hdl_c_mgdl_vec, NA_real_)

df_markers <- df %>%
  mutate(
    glucose_mgdl = glucose_mgdl_vec,
    triglycerides_mgdl = triglycerides_mgdl_vec,
    hdl_c_mgdl = hdl_c_mgdl_vec,
    TyG_index = log(triglycerides_mgdl * glucose_mgdl / 2),
    TG_HDL_C = triglycerides_mgdl / hdl_c_mgdl,
    ln_TG_HDL_C = log(TG_HDL_C)
  )

# Create pct_oxidative_10 if needed
if (!("pct_oxidative_10" %in% names(df_markers))) {
  if ("pct_oxidative" %in% names(df_markers)) {
    df_markers <- df_markers %>%
      mutate(pct_oxidative_10 = pct_oxidative / 10)
  }
}

# Create ln_URXUCR if needed
if (!("ln_URXUCR" %in% names(df_markers))) {
  if ("URXUCR" %in% names(df_markers)) {
    df_markers <- df_markers %>%
      mutate(ln_URXUCR = log(URXUCR))
  }
}

# Create cycle if needed
if (!("cycle" %in% names(df_markers))) {
  if ("SDDSRVYR" %in% names(df_markers)) {
    df_markers <- df_markers %>%
      mutate(cycle = SDDSRVYR)
  } else {
    stop("找不到 cycle 或 SDDSRVYR。")
  }
}

# ------------------------------------------------------------
# 6. Sample flow
# ------------------------------------------------------------

sample_flow <- tibble(
  step = c(
    "Initial analysis dataset",
    "Adults aged >=20 years",
    "Non-missing fasting glucose",
    "Non-missing triglycerides",
    "Non-missing HDL-C",
    "Available TyG index",
    "Available ln(TG/HDL-C)"
  ),
  n = c(
    nrow(df_markers),
    sum(df_markers$RIDAGEYR >= 20, na.rm = TRUE),
    sum(df_markers$RIDAGEYR >= 20 & !is.na(df_markers$glucose_mgdl), na.rm = TRUE),
    sum(df_markers$RIDAGEYR >= 20 & !is.na(df_markers$triglycerides_mgdl), na.rm = TRUE),
    sum(df_markers$RIDAGEYR >= 20 & !is.na(df_markers$hdl_c_mgdl), na.rm = TRUE),
    sum(df_markers$RIDAGEYR >= 20 & !is.na(df_markers$TyG_index), na.rm = TRUE),
    sum(df_markers$RIDAGEYR >= 20 & !is.na(df_markers$ln_TG_HDL_C), na.rm = TRUE)
  )
)

print(sample_flow)

write_rds(
  df_markers,
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset.rds")
)

write_csv(
  df_markers,
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset.csv")
)

# ------------------------------------------------------------
# 7. Model specifications
# ------------------------------------------------------------

required_design <- c("SDMVPSU", "SDMVSTRA", weight_var)
missing_design <- setdiff(required_design, names(df_markers))

if (length(missing_design) > 0) {
  stop(paste0("缺少复杂抽样变量：", paste(missing_design, collapse = ", ")))
}

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

base_covars <- c(
  "RIDAGEYR",
  "factor(RIAGENDR)",
  "factor(RIDRETH3)",
  "INDFMPIR",
  "factor(DMDEDUC2)",
  "DR1TKCAL",
  "factor(cycle)"
)

missing_covars <- setdiff(
  c("RIDAGEYR", "RIAGENDR", "RIDRETH3", "INDFMPIR", "DMDEDUC2", "DR1TKCAL", "cycle"),
  names(df_markers)
)

if (length(missing_covars) > 0) {
  stop(paste0("缺少协变量：", paste(missing_covars, collapse = ", ")))
}

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~outcome_type,
  "TyG_index", "TyG index", "absolute_outcome",
  "ln_TG_HDL_C", "ln(TG/HDL-C)", "log_ratio_outcome"
)

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~exposure_type, ~include_creatinine, ~include_total_burden,
  "ln_Sigma_DEHP", "lnΣDEHP", "concentration", TRUE, FALSE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", "metabolic_fraction", FALSE, FALSE,
  "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]", "logratio", TRUE, TRUE,
  "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance", "ilr", TRUE, TRUE
)

exposure_map <- exposure_map %>%
  filter(exposure %in% names(df_markers))

if (nrow(exposure_map) == 0) {
  stop("没有找到可用的 DEHP 暴露变量。")
}

cat("\nExposure variables to be modeled:\n")
print(exposure_map)

# ------------------------------------------------------------
# 8. Continuous survey-weighted models
# ------------------------------------------------------------

run_continuous_model <- function(outcome, outcome_label, outcome_type,
                                 exposure, exposure_label,
                                 exposure_type,
                                 include_creatinine,
                                 include_total_burden) {
  
  covar_terms <- base_covars
  needed_vars <- c(outcome, exposure, base_vars)
  
  if (include_creatinine) {
    covar_terms <- c(covar_terms, "ln_URXUCR")
    needed_vars <- c(needed_vars, "ln_URXUCR")
  }
  
  if (include_total_burden) {
    if ("ln_Sigma_DEHP_comp" %in% names(df_markers)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP_comp")
      needed_vars <- c(needed_vars, "ln_Sigma_DEHP_comp")
    } else if ("ln_Sigma_DEHP" %in% names(df_markers)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP")
      needed_vars <- c(needed_vars, "ln_Sigma_DEHP")
    } else {
      stop("需要调整总 DEHP burden，但找不到 ln_Sigma_DEHP_comp 或 ln_Sigma_DEHP。")
    }
  }
  
  missing_needed <- setdiff(unique(needed_vars), names(df_markers))
  if (length(missing_needed) > 0) {
    return(tibble(
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      include_creatinine = include_creatinine,
      include_total_burden = include_total_burden,
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
  
  d <- df_markers %>%
    filter(RIDAGEYR >= 20) %>%
    select(all_of(unique(needed_vars))) %>%
    drop_na()
  
  if (nrow(d) < 300) {
    return(tibble(
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      include_creatinine = include_creatinine,
      include_total_burden = include_total_burden,
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
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      include_creatinine = include_creatinine,
      include_total_burden = include_total_burden,
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
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_type = exposure_type,
      include_creatinine = include_creatinine,
      include_total_burden = include_total_burden,
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

linear_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, exposure_row),
      function(i, j) {
        run_continuous_model(
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
  unnest(result_tbl) %>%
  group_by(outcome_label) %>%
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

print(linear_results)

# ------------------------------------------------------------
# 9. Quartile models
# ------------------------------------------------------------

run_quartile_model <- function(outcome, outcome_label, outcome_type,
                               exposure, exposure_label,
                               exposure_type,
                               include_creatinine,
                               include_total_burden) {
  
  covar_terms <- base_covars
  needed_vars <- c(outcome, exposure, base_vars)
  
  if (include_creatinine) {
    covar_terms <- c(covar_terms, "ln_URXUCR")
    needed_vars <- c(needed_vars, "ln_URXUCR")
  }
  
  if (include_total_burden) {
    if ("ln_Sigma_DEHP_comp" %in% names(df_markers)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP_comp")
      needed_vars <- c(needed_vars, "ln_Sigma_DEHP_comp")
    } else if ("ln_Sigma_DEHP" %in% names(df_markers)) {
      covar_terms <- c(covar_terms, "ln_Sigma_DEHP")
      needed_vars <- c(needed_vars, "ln_Sigma_DEHP")
    }
  }
  
  missing_needed <- setdiff(unique(needed_vars), names(df_markers))
  if (length(missing_needed) > 0) {
    return(tibble())
  }
  
  d0 <- df_markers %>%
    filter(RIDAGEYR >= 20) %>%
    select(all_of(unique(needed_vars))) %>%
    drop_na()
  
  if (nrow(d0) < 300) {
    return(tibble())
  }
  
  d <- d0 %>%
    mutate(
      exposure_q = make_weighted_quartile(.data[[exposure]], .data[[weight_var]]),
      exposure_median_by_q = ave(.data[[exposure]], exposure_q, FUN = median)
    ) %>%
    filter(!is.na(exposure_q)) %>%
    mutate(exposure_q = factor(exposure_q, levels = paste0("Q", 1:4)))
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = as.formula(paste0("~", weight_var)),
    nest = TRUE,
    data = d
  )
  
  f_cat <- as.formula(
    paste0(
      outcome,
      " ~ exposure_q + ",
      paste(covar_terms, collapse = " + ")
    )
  )
  
  f_trend <- as.formula(
    paste0(
      outcome,
      " ~ exposure_median_by_q + ",
      paste(covar_terms, collapse = " + ")
    )
  )
  
  fit_cat <- tryCatch(svyglm(f_cat, design = des), error = function(e) NULL)
  fit_trend <- tryCatch(svyglm(f_trend, design = des), error = function(e) NULL)
  
  if (is.null(fit_cat) || is.null(fit_trend)) {
    return(tibble())
  }
  
  coef_cat <- summary(fit_cat)$coefficients
  coef_trend <- summary(fit_trend)$coefficients
  
  p_trend <- if ("exposure_median_by_q" %in% rownames(coef_trend)) {
    coef_trend["exposure_median_by_q", "Pr(>|t|)"]
  } else {
    NA_real_
  }
  
  map_dfr(
    paste0("Q", 2:4),
    function(q_level) {
      term <- paste0("exposure_q", q_level)
      
      if (!(term %in% rownames(coef_cat))) {
        return(tibble())
      }
      
      beta <- coef_cat[term, "Estimate"]
      se <- coef_cat[term, "Std. Error"]
      p_value <- coef_cat[term, "Pr(>|t|)"]
      
      df_resid <- fit_cat$df.residual
      tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
      
      low <- beta - tcrit * se
      high <- beta + tcrit * se
      
      eff <- effect_transform(beta, low, high, outcome_type)
      
      tibble(
        outcome = outcome,
        outcome_label = outcome_label,
        exposure = exposure,
        exposure_label = exposure_label,
        exposure_type = exposure_type,
        include_creatinine = include_creatinine,
        include_total_burden = include_total_burden,
        n = nrow(d),
        quartile = q_level,
        beta = beta,
        se = se,
        p_value = p_value,
        effect = eff["effect"],
        effect_low = eff["effect_low"],
        effect_high = eff["effect_high"],
        p_trend = p_trend
      )
    }
  )
}

quartile_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, exposure_row),
      function(i, j) {
        run_quartile_model(
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
  unnest(result_tbl) %>%
  group_by(outcome_label, exposure_label) %>%
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
    p_trend_fmt = format_p(p_trend)
  )

print(quartile_results)

# ------------------------------------------------------------
# 10. Forest plot
# ------------------------------------------------------------

plot_linear <- linear_results %>%
  filter(!is.na(effect), !is.na(effect_low), !is.na(effect_high)) %>%
  mutate(
    outcome_label = factor(outcome_label, levels = c("TyG index", "ln(TG/HDL-C)")),
    exposure_label = factor(
      exposure_label,
      levels = rev(c(
        "lnΣDEHP",
        "%Oxidative per 10 percentage points",
        "ln[(MEHHP+MEOHP+MECPP)/MEHP]",
        "ILR oxidative-vs-primary balance"
      ))
    ),
    sig_label = case_when(
      q_value < 0.05 ~ "**",
      p_value < 0.05 ~ "*",
      TRUE ~ ""
    )
  )

if (nrow(plot_linear) > 0) {
  p_forest <- ggplot(plot_linear, aes(x = effect, y = exposure_label)) +
    geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.35) +
    geom_errorbarh(
      aes(xmin = effect_low, xmax = effect_high),
      height = 0.18,
      linewidth = 0.55
    ) +
    geom_point(size = 2.8) +
    geom_text(
      aes(label = sig_label),
      nudge_y = 0.22,
      size = 4,
      fontface = "bold"
    ) +
    facet_wrap(~ outcome_label, scales = "free_x", ncol = 2) +
    labs(
      title = "Associations of DEHP exposure indicators with TyG index and TG/HDL-C",
      subtitle = "Survey-weighted models adjusted for age, sex, race/ethnicity, socioeconomic factors, energy intake, urinary creatinine where applicable, and NHANES cycle",
      x = "Effect estimate",
      y = "Exposure indicator",
      caption = "* nominal P < 0.05; ** FDR q < 0.05. TyG estimates are absolute differences; ln(TG/HDL-C) estimates are percent differences."
    ) +
    theme_bw(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold"),
      strip.background = element_rect(fill = "grey90", color = "grey35"),
      panel.grid.minor = element_line(color = "grey92"),
      panel.grid.major = element_line(color = "grey86"),
      plot.caption = element_text(size = 8.5, hjust = 0)
    )
  
  print(p_forest)
  
  ggsave(
    file.path(fig_dir, "TyG_TGHDL_forest_2013_2018.png"),
    p_forest,
    width = 11,
    height = 6.5,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "TyG_TGHDL_forest_2013_2018.pdf"),
    p_forest,
    width = 11,
    height = 6.5
  )
  
  ggsave(
    file.path(fig_dir, "TyG_TGHDL_forest_2013_2018.tiff"),
    p_forest,
    width = 11,
    height = 6.5,
    dpi = 600,
    compression = "lzw"
  )
}

# ------------------------------------------------------------
# 11. Quartile plot
# ------------------------------------------------------------

plot_q <- quartile_results %>%
  filter(!is.na(effect), !is.na(effect_low), !is.na(effect_high)) %>%
  mutate(
    outcome_label = factor(outcome_label, levels = c("TyG index", "ln(TG/HDL-C)")),
    exposure_label = factor(
      exposure_label,
      levels = c(
        "lnΣDEHP",
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

if (nrow(plot_q) > 0) {
  p_quartile <- ggplot(plot_q, aes(x = quartile, y = effect)) +
    geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.35) +
    geom_errorbar(
      aes(ymin = effect_low, ymax = effect_high),
      width = 0.15,
      linewidth = 0.50
    ) +
    geom_point(size = 2.5) +
    geom_text(
      aes(label = sig_label),
      vjust = -0.8,
      size = 3.8,
      fontface = "bold"
    ) +
    facet_grid(outcome_label ~ exposure_label, scales = "free_y") +
    labs(
      title = "Quartile associations of DEHP exposure indicators with TyG index and TG/HDL-C",
      subtitle = "Reference group: Q1",
      x = "Exposure quartile",
      y = "Effect estimate vs Q1",
      caption = "* nominal P < 0.05; ** FDR q < 0.05. TyG estimates are absolute differences; ln(TG/HDL-C) estimates are percent differences."
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold", size = 8.5),
      strip.background = element_rect(fill = "grey90", color = "grey35"),
      axis.text.x = element_text(angle = 0, hjust = 0.5),
      panel.grid.minor = element_line(color = "grey92"),
      panel.grid.major = element_line(color = "grey86"),
      plot.caption = element_text(size = 8.5, hjust = 0)
    )
  
  print(p_quartile)
  
  ggsave(
    file.path(fig_dir, "TyG_TGHDL_quartile_2013_2018.png"),
    p_quartile,
    width = 13,
    height = 7.5,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "TyG_TGHDL_quartile_2013_2018.pdf"),
    p_quartile,
    width = 13,
    height = 7.5
  )
  
  ggsave(
    file.path(fig_dir, "TyG_TGHDL_quartile_2013_2018.tiff"),
    p_quartile,
    width = 13,
    height = 7.5,
    dpi = 600,
    compression = "lzw"
  )
}

# ------------------------------------------------------------
# 12. Export results
# ------------------------------------------------------------

key_results <- linear_results %>%
  filter(
    exposure %in% c(
      "ln_Sigma_DEHP",
      "pct_oxidative_10",
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    )
  ) %>%
  select(
    outcome_label,
    exposure_label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    inference
  ) %>%
  arrange(outcome_label, exposure_label)

quartile_key <- quartile_results %>%
  filter(
    quartile == "Q4",
    exposure %in% c(
      "ln_Sigma_DEHP",
      "pct_oxidative_10",
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    )
  ) %>%
  select(
    outcome_label,
    exposure_label,
    n,
    quartile,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    p_trend_fmt
  ) %>%
  arrange(outcome_label, exposure_label)

write_xlsx(
  list(
    sample_flow = sample_flow,
    key_continuous_results = key_results,
    Q4_vs_Q1_results = quartile_key
  ),
  file.path(result_dir, "metabolic_markers_TyG_TGHDL_key_results_2013_2018.xlsx")
)

write_xlsx(
  list(
    linear_results = linear_results
  ),
  file.path(result_dir, "metabolic_markers_TyG_TGHDL_linear_results_2013_2018.xlsx")
)

write_xlsx(
  list(
    quartile_results = quartile_results
  ),
  file.path(result_dir, "metabolic_markers_TyG_TGHDL_quartile_results_2013_2018.xlsx")
)

write_csv(
  linear_results,
  file.path(result_dir, "metabolic_markers_TyG_TGHDL_linear_results_2013_2018.csv")
)

write_csv(
  quartile_results,
  file.path(result_dir, "metabolic_markers_TyG_TGHDL_quartile_results_2013_2018.csv")
)

cat("\nTyG and TG/HDL-C metabolic-marker analysis completed successfully.\n")
cat("Key results saved to:\n")
cat(file.path(result_dir, "metabolic_markers_TyG_TGHDL_key_results_2013_2018.xlsx"), "\n")
cat(file.path(result_dir, "metabolic_markers_TyG_TGHDL_linear_results_2013_2018.xlsx"), "\n")
cat(file.path(result_dir, "metabolic_markers_TyG_TGHDL_quartile_results_2013_2018.xlsx"), "\n")
cat("Figures saved to:\n")
cat(file.path(fig_dir, "TyG_TGHDL_forest_2013_2018.png"), "\n")
cat(file.path(fig_dir, "TyG_TGHDL_quartile_2013_2018.png"), "\n")