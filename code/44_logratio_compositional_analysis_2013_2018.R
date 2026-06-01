# ============================================================
# NHANES 2013-2018
# 44_logratio_compositional_analysis_2013_2018.R
# Log-ratio / compositional analysis for DEHP metabolic profile
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
fig_dir    <- file.path(result_dir, "figures_composition")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Read best available 2013-2018 analysis dataset
# ------------------------------------------------------------

data_candidates <- c(
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

pick_var <- function(dat, candidates, label) {
  hit <- candidates[candidates %in% names(dat)]
  
  if (length(hit) == 0) {
    possible <- names(dat)[grepl(
      paste(candidates, collapse = "|"),
      names(dat),
      ignore.case = TRUE
    )]
    
    stop(
      paste0(
        "找不到变量：", label, "\n",
        "候选变量：", paste(candidates, collapse = ", "), "\n",
        "数据中可能相关变量：", paste(possible, collapse = ", ")
      )
    )
  }
  
  hit[1]
}

safe_positive <- function(x) {
  x <- as.numeric(x)
  pos_min <- suppressWarnings(min(x[x > 0], na.rm = TRUE))
  if (!is.finite(pos_min)) pos_min <- 1e-6
  x[is.na(x)] <- NA_real_
  x[x <= 0] <- pos_min / 2
  x
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

format_p <- function(p) {
  ifelse(
    is.na(p), NA_character_,
    ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

effect_transform <- function(beta, low, high, is_log_outcome) {
  if (is_log_outcome) {
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

make_weighted_quartile <- function(x, w) {
  q <- weighted_quantile(x, w, probs = c(0, 0.25, 0.50, 0.75, 1))
  q[1] <- q[1] - 1e-10
  q[5] <- q[5] + 1e-10
  
  if (length(unique(q)) < 5) {
    return(factor(dplyr::ntile(x, 4), levels = 1:4, labels = paste0("Q", 1:4)))
  }
  
  cut(
    x,
    breaks = q,
    include.lowest = TRUE,
    labels = paste0("Q", 1:4)
  )
}

# Restricted cubic spline basis
make_rcs_basis <- function(x, knots) {
  k <- sort(as.numeric(knots))
  K <- length(k)
  
  if (K < 4) {
    stop("RCS requires at least 4 knots.")
  }
  
  tp <- function(z) pmax(z, 0)^3
  
  basis <- matrix(NA_real_, nrow = length(x), ncol = K - 1)
  basis[, 1] <- x
  
  for (j in 1:(K - 2)) {
    basis[, j + 1] <-
      tp(x - k[j]) -
      tp(x - k[K - 1]) * (k[K] - k[j]) / (k[K] - k[K - 1]) +
      tp(x - k[K]) * (k[K - 1] - k[j]) / (k[K] - k[K - 1])
  }
  
  colnames(basis) <- paste0("rcs", seq_len(ncol(basis)))
  as.data.frame(basis)
}

add_rcs_to_data <- function(dat, exposure, knots, prefix = "rcs") {
  b <- make_rcs_basis(dat[[exposure]], knots)
  colnames(b) <- paste0(prefix, seq_len(ncol(b)))
  bind_cols(dat, b)
}

# ------------------------------------------------------------
# 3. Identify required variables
# ------------------------------------------------------------

# DEHP metabolite variables in NHANES usually:
# MEHP  = URXMHP
# MEHHP = URXMHH
# MEOHP = URXMOH
# MECPP = URXECP

var_MEHP <- pick_var(
  df,
  c("URXMHP", "MEHP", "mehp", "MEHP_ng_ml", "URXMHP_adj"),
  "MEHP"
)

var_MEHHP <- pick_var(
  df,
  c("URXMHH", "MEHHP", "mehhp", "MEHHP_ng_ml", "URXMHH_adj"),
  "MEHHP"
)

var_MEOHP <- pick_var(
  df,
  c("URXMOH", "MEOHP", "meohp", "MEOHP_ng_ml", "URXMOH_adj"),
  "MEOHP"
)

var_MECPP <- pick_var(
  df,
  c("URXECP", "MECPP", "mecpp", "MECPP_ng_ml", "URXECP_adj"),
  "MECPP"
)

cat("Detected DEHP variables:\n")
cat("MEHP :", var_MEHP, "\n")
cat("MEHHP:", var_MEHHP, "\n")
cat("MEOHP:", var_MEOHP, "\n")
cat("MECPP:", var_MECPP, "\n")

# Create outcomes if needed
if (!("ln_HOMA_IR" %in% names(df))) {
  if ("HOMA_IR" %in% names(df)) {
    df <- df %>% mutate(ln_HOMA_IR = log(HOMA_IR))
  } else if ("homa_ir" %in% names(df)) {
    df <- df %>% mutate(ln_HOMA_IR = log(homa_ir))
  } else {
    stop("找不到 ln_HOMA_IR 或 HOMA_IR。")
  }
}

if (!("HbA1c" %in% names(df))) {
  if ("LBXGH" %in% names(df)) {
    df <- df %>% mutate(HbA1c = LBXGH)
  } else {
    stop("找不到 HbA1c 或 LBXGH。")
  }
}

if (!("ln_URXUCR" %in% names(df))) {
  if ("URXUCR" %in% names(df)) {
    df <- df %>% mutate(ln_URXUCR = log(URXUCR))
  } else {
    stop("找不到 ln_URXUCR 或 URXUCR。")
  }
}

required_design <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")
missing_design <- setdiff(required_design, names(df))

if (length(missing_design) > 0) {
  stop(
    paste0(
      "缺少复杂抽样设计变量：",
      paste(missing_design, collapse = ", ")
    )
  )
}

# ------------------------------------------------------------
# 4. Construct molar DEHP composition variables
# ------------------------------------------------------------

# Molecular weights, g/mol
MW_MEHP  <- 278.34
MW_MEHHP <- 294.34
MW_MEOHP <- 292.33
MW_MECPP <- 308.33

df_comp <- df %>%
  mutate(
    MEHP_raw  = safe_positive(.data[[var_MEHP]]),
    MEHHP_raw = safe_positive(.data[[var_MEHHP]]),
    MEOHP_raw = safe_positive(.data[[var_MEOHP]]),
    MECPP_raw = safe_positive(.data[[var_MECPP]]),
    
    # Molar-scale composition.
    # Constant unit factors cancel in ratios; concentration / MW is sufficient.
    MEHP_mol  = MEHP_raw  / MW_MEHP,
    MEHHP_mol = MEHHP_raw / MW_MEHHP,
    MEOHP_mol = MEOHP_raw / MW_MEOHP,
    MECPP_mol = MECPP_raw / MW_MECPP,
    
    oxidative_mol = MEHHP_mol + MEOHP_mol + MECPP_mol,
    total_DEHP_mol = MEHP_mol + oxidative_mol,
    
    ln_Sigma_DEHP_comp = log(total_DEHP_mol),
    pct_oxidative_comp = 100 * oxidative_mol / total_DEHP_mol,
    
    ln_oxidative_MEHP_ratio = log(oxidative_mol / MEHP_mol),
    ln_MEHHP_MEHP_ratio = log(MEHHP_mol / MEHP_mol),
    ln_MEOHP_MEHP_ratio = log(MEOHP_mol / MEHP_mol),
    ln_MECPP_MEHP_ratio = log(MECPP_mol / MEHP_mol),
    
    gmean_DEHP = exp(
      rowMeans(
        cbind(
          log(MEHP_mol),
          log(MEHHP_mol),
          log(MEOHP_mol),
          log(MECPP_mol)
        ),
        na.rm = FALSE
      )
    ),
    
    clr_MEHP  = log(MEHP_mol / gmean_DEHP),
    clr_MEHHP = log(MEHHP_mol / gmean_DEHP),
    clr_MEOHP = log(MEOHP_mol / gmean_DEHP),
    clr_MECPP = log(MECPP_mol / gmean_DEHP),
    
    # ILR coordinates.
    # ilr_oxidative_vs_primary:
    # balance between oxidative metabolites {MEHHP, MEOHP, MECPP} and primary metabolite {MEHP}.
    ilr_oxidative_vs_primary =
      sqrt(3 * 1 / 4) *
      log(
        ((MEHHP_mol * MEOHP_mol * MECPP_mol)^(1/3)) / MEHP_mol
      ),
    
    # Balance inside oxidative metabolites
    ilr_MEHHP_vs_MEOHP_MECPP =
      sqrt(2 / 3) *
      log(MEHHP_mol / sqrt(MEOHP_mol * MECPP_mol)),
    
    ilr_MEOHP_vs_MECPP =
      sqrt(1 / 2) *
      log(MEOHP_mol / MECPP_mol)
  )

# Quartiles for interpretable dose-response
df_comp <- df_comp %>%
  mutate(
    q_ln_oxidative_MEHP_ratio =
      make_weighted_quartile(ln_oxidative_MEHP_ratio, WTSB6YR_MAIN),
    q_ilr_oxidative_vs_primary =
      make_weighted_quartile(ilr_oxidative_vs_primary, WTSB6YR_MAIN)
  )

write_rds(
  df_comp,
  file.path(output_dir, "NHANES_2013_2018_logratio_composition_dataset.rds")
)

write_csv(
  df_comp,
  file.path(output_dir, "NHANES_2013_2018_logratio_composition_dataset.csv")
)

# ------------------------------------------------------------
# 5. General model functions
# ------------------------------------------------------------

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~exposure_family,
  "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]", "Log-ratio",
  "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance", "ILR balance",
  "ln_MEHHP_MEHP_ratio", "ln(MEHHP/MEHP)", "Single log-ratio",
  "ln_MEOHP_MEHP_ratio", "ln(MEOHP/MEHP)", "Single log-ratio",
  "ln_MECPP_MEHP_ratio", "ln(MECPP/MEHP)", "Single log-ratio",
  "clr_MEHP", "clr(MEHP)", "CLR",
  "clr_MEHHP", "clr(MEHHP)", "CLR",
  "clr_MEOHP", "clr(MEOHP)", "CLR",
  "clr_MECPP", "clr(MECPP)", "CLR"
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
  "WTSB6YR_MAIN"
)

run_svy_linear <- function(outcome, outcome_label, is_log_outcome,
                           exposure, exposure_label, exposure_family,
                           model_type = c("composition_only", "composition_plus_total_burden")) {
  
  model_type <- match.arg(model_type)
  
  if (model_type == "composition_only") {
    covar_terms <- base_covars
    needed_vars <- c(outcome, exposure, base_vars)
  } else {
    covar_terms <- c(base_covars, "ln_Sigma_DEHP_comp", "ln_URXUCR")
    needed_vars <- c(outcome, exposure, "ln_Sigma_DEHP_comp", "ln_URXUCR", base_vars)
  }
  
  d <- df_comp %>%
    select(any_of(needed_vars)) %>%
    drop_na()
  
  if (nrow(d) < 300) {
    return(tibble(
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      exposure_family = exposure_family,
      model_type = model_type,
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
    weights = ~WTSB6YR_MAIN,
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
      exposure_family = exposure_family,
      model_type = model_type,
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
      exposure_family = exposure_family,
      model_type = model_type,
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
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  eff <- effect_transform(beta, low, high, is_log_outcome)
  
  tibble(
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_family = exposure_family,
    model_type = model_type,
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
# 6. Continuous log-ratio / compositional models
# ------------------------------------------------------------

linear_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map)),
  model_type = c("composition_only", "composition_plus_total_burden")
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, exposure_row, model_type),
      function(i, j, m) {
        run_svy_linear(
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          is_log_outcome = outcome_map$is_log_outcome[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          exposure_family = exposure_map$exposure_family[j],
          model_type = m
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl) %>%
  group_by(outcome_label, model_type) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    effect_CI = sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high),
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

key_linear_results <- linear_results %>%
  filter(
    exposure %in% c(
      "ln_oxidative_MEHP_ratio",
      "ilr_oxidative_vs_primary"
    )
  ) %>%
  arrange(outcome_label, exposure, model_type)

print(key_linear_results)

# ------------------------------------------------------------
# 7. Full ILR composition model
# ------------------------------------------------------------

run_full_ilr_model <- function(outcome, outcome_label, is_log_outcome,
                               model_type = c("composition_only", "composition_plus_total_burden")) {
  
  model_type <- match.arg(model_type)
  
  ilr_terms <- c(
    "ilr_oxidative_vs_primary",
    "ilr_MEHHP_vs_MEOHP_MECPP",
    "ilr_MEOHP_vs_MECPP"
  )
  
  if (model_type == "composition_only") {
    covar_terms <- base_covars
    needed_vars <- c(outcome, ilr_terms, base_vars)
  } else {
    covar_terms <- c(base_covars, "ln_Sigma_DEHP_comp", "ln_URXUCR")
    needed_vars <- c(outcome, ilr_terms, "ln_Sigma_DEHP_comp", "ln_URXUCR", base_vars)
  }
  
  d <- df_comp %>%
    select(any_of(needed_vars)) %>%
    drop_na()
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(
      outcome,
      " ~ ",
      paste(c(ilr_terms, covar_terms), collapse = " + ")
    )
  )
  
  fit <- svyglm(f, design = des)
  coef_table <- summary(fit)$coefficients
  
  map_dfr(
    ilr_terms,
    function(term) {
      beta <- coef_table[term, "Estimate"]
      se <- coef_table[term, "Std. Error"]
      p_value <- coef_table[term, "Pr(>|t|)"]
      
      df_resid <- fit$df.residual
      tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
      
      low <- beta - tcrit * se
      high <- beta + tcrit * se
      
      eff <- effect_transform(beta, low, high, is_log_outcome)
      
      tibble(
        outcome = outcome,
        outcome_label = outcome_label,
        model_type = model_type,
        n = nrow(d),
        ilr_term = term,
        beta = beta,
        se = se,
        p_value = p_value,
        effect = eff["effect"],
        effect_low = eff["effect_low"],
        effect_high = eff["effect_high"]
      )
    }
  )
}

full_ilr_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  model_type = c("composition_only", "composition_plus_total_burden")
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, model_type),
      function(i, m) {
        run_full_ilr_model(
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          is_log_outcome = outcome_map$is_log_outcome[i],
          model_type = m
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl) %>%
  group_by(outcome_label, model_type) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    effect_CI = sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high),
    p_value_fmt = format_p(p_value),
    q_value_fmt = format_p(q_value),
    interpretation = case_when(
      ilr_term == "ilr_oxidative_vs_primary" & q_value < 0.05 & beta > 0 ~
        "Oxidative-vs-primary balance positively associated after FDR correction",
      ilr_term == "ilr_oxidative_vs_primary" & p_value < 0.05 & beta > 0 ~
        "Oxidative-vs-primary balance nominally positive",
      TRUE ~ "Secondary ILR coordinate or not significant"
    )
  )

# ------------------------------------------------------------
# 8. Quartile dose-response models
# ------------------------------------------------------------

run_quartile_model <- function(outcome, outcome_label, is_log_outcome,
                               exposure_q, exposure_cont,
                               exposure_label,
                               model_type = c("composition_only", "composition_plus_total_burden")) {
  
  model_type <- match.arg(model_type)
  
  if (model_type == "composition_only") {
    covar_terms <- base_covars
    needed_vars <- c(outcome, exposure_q, exposure_cont, base_vars)
  } else {
    covar_terms <- c(base_covars, "ln_Sigma_DEHP_comp", "ln_URXUCR")
    needed_vars <- c(outcome, exposure_q, exposure_cont, "ln_Sigma_DEHP_comp", "ln_URXUCR", base_vars)
  }
  
  d <- df_comp %>%
    select(any_of(needed_vars)) %>%
    drop_na() %>%
    mutate(
      exposure_q = factor(.data[[exposure_q]], levels = paste0("Q", 1:4)),
      exposure_median_by_q = ave(
        .data[[exposure_cont]],
        exposure_q,
        FUN = median
      )
    )
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
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
  
  fit_cat <- svyglm(f_cat, design = des)
  fit_trend <- svyglm(f_trend, design = des)
  
  coef_cat <- summary(fit_cat)$coefficients
  coef_trend <- summary(fit_trend)$coefficients
  
  p_trend <- coef_trend["exposure_median_by_q", "Pr(>|t|)"]
  
  q_rows <- map_dfr(
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
      
      eff <- effect_transform(beta, low, high, is_log_outcome)
      
      tibble(
        outcome = outcome,
        outcome_label = outcome_label,
        exposure = exposure_cont,
        exposure_label = exposure_label,
        model_type = model_type,
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
  
  q_rows
}

quartile_specs <- tibble::tribble(
  ~exposure_q, ~exposure_cont, ~exposure_label,
  "q_ln_oxidative_MEHP_ratio", "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]",
  "q_ilr_oxidative_vs_primary", "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance"
)

quartile_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  quartile_row = seq_len(nrow(quartile_specs)),
  model_type = c("composition_only", "composition_plus_total_burden")
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, quartile_row, model_type),
      function(i, j, m) {
        run_quartile_model(
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          is_log_outcome = outcome_map$is_log_outcome[i],
          exposure_q = quartile_specs$exposure_q[j],
          exposure_cont = quartile_specs$exposure_cont[j],
          exposure_label = quartile_specs$exposure_label[j],
          model_type = m
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl) %>%
  group_by(outcome_label, model_type, exposure_label) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    effect_CI = sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high),
    p_value_fmt = format_p(p_value),
    q_value_fmt = format_p(q_value),
    p_trend_fmt = format_p(p_trend)
  )

# ------------------------------------------------------------
# 9. Plot quartile dose-response
# ------------------------------------------------------------

plot_q <- quartile_results %>%
  filter(
    model_type == "composition_plus_total_burden",
    exposure %in% c("ln_oxidative_MEHP_ratio", "ilr_oxidative_vs_primary")
  ) %>%
  mutate(
    exposure_label = factor(
      exposure_label,
      levels = c(
        "ln[(MEHHP+MEOHP+MECPP)/MEHP]",
        "ILR oxidative-vs-primary balance"
      )
    ),
    outcome_label = factor(outcome_label, levels = c("ln(HOMA-IR)", "HbA1c")),
    sig_label = case_when(
      q_value < 0.05 ~ "**",
      p_value < 0.05 ~ "*",
      TRUE ~ ""
    )
  )

p_quartile <- ggplot(plot_q, aes(x = quartile, y = effect)) +
  geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.35) +
  geom_errorbar(
    aes(ymin = effect_low, ymax = effect_high),
    width = 0.15,
    linewidth = 0.55
  ) +
  geom_point(size = 2.6) +
  geom_text(
    aes(label = sig_label),
    vjust = -0.8,
    size = 4,
    fontface = "bold"
  ) +
  facet_grid(outcome_label ~ exposure_label, scales = "free_y") +
  labs(
    title = "Quartile dose-response of DEHP oxidative-vs-primary metabolic balance with metabolic outcomes",
    subtitle = "Reference group: Q1; models adjusted for total DEHP burden and urinary creatinine",
    x = "Exposure quartile",
    y = "Effect estimate vs Q1",
    caption = "* nominal P < 0.05; ** FDR q < 0.05. For ln(HOMA-IR), estimates represent percent difference; for HbA1c, estimates represent absolute percentage-point difference."
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10),
    strip.text = element_text(face = "bold"),
    strip.background = element_rect(fill = "grey90", color = "grey35"),
    panel.grid.minor = element_line(color = "grey92"),
    panel.grid.major = element_line(color = "grey86"),
    plot.caption = element_text(size = 8.5, hjust = 0)
  )

print(p_quartile)

ggsave(
  file.path(fig_dir, "logratio_quartile_dose_response_2013_2018.png"),
  p_quartile,
  width = 11,
  height = 7.5,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "logratio_quartile_dose_response_2013_2018.pdf"),
  p_quartile,
  width = 11,
  height = 7.5
)

# ------------------------------------------------------------
# 10. RCS models for log-ratio / ILR
# ------------------------------------------------------------

run_rcs_model <- function(outcome, outcome_label,
                          exposure, exposure_label,
                          include_total_burden = TRUE,
                          n_grid = 120) {
  
  if (include_total_burden) {
    covar_terms <- c(base_covars, "ln_Sigma_DEHP_comp", "ln_URXUCR")
    needed_vars <- c(outcome, exposure, "ln_Sigma_DEHP_comp", "ln_URXUCR", base_vars)
  } else {
    covar_terms <- base_covars
    needed_vars <- c(outcome, exposure, base_vars)
  }
  
  d <- df_comp %>%
    select(any_of(needed_vars)) %>%
    drop_na()
  
  plot_range <- weighted_quantile(
    d[[exposure]],
    d$WTSB6YR_MAIN,
    probs = c(0.01, 0.99)
  )
  
  knots <- weighted_quantile(
    d[[exposure]],
    d$WTSB6YR_MAIN,
    probs = c(0.05, 0.35, 0.65, 0.95)
  )
  
  ref_value <- weighted_quantile(
    d[[exposure]],
    d$WTSB6YR_MAIN,
    probs = 0.50
  )
  
  cat("\nRCS:", outcome_label, "|", exposure_label, "\n")
  cat("N:", nrow(d), "\n")
  cat("Knots:", paste(round(knots, 3), collapse = ", "), "\n")
  cat("Reference:", round(ref_value, 3), "\n")
  
  d_rcs <- add_rcs_to_data(d, exposure, knots, prefix = "rcs")
  
  rcs_terms <- paste0("rcs", 1:3)
  nonlinear_terms <- paste0("rcs", 2:3)
  
  f <- as.formula(
    paste0(
      outcome,
      " ~ ",
      paste(c(rcs_terms, covar_terms), collapse = " + ")
    )
  )
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d_rcs
  )
  
  fit <- svyglm(f, design = des)
  
  overall_test <- regTermTest(
    fit,
    as.formula(paste0("~ ", paste(rcs_terms, collapse = " + ")))
  )
  
  nonlinear_test <- regTermTest(
    fit,
    as.formula(paste0("~ ", paste(nonlinear_terms, collapse = " + ")))
  )
  
  p_overall <- as.numeric(overall_test$p)
  p_nonlinear <- as.numeric(nonlinear_test$p)
  
  grid_x <- seq(plot_range[1], plot_range[2], length.out = n_grid)
  
  grid_basis <- make_rcs_basis(grid_x, knots)
  ref_basis  <- make_rcs_basis(ref_value, knots)
  
  colnames(grid_basis) <- rcs_terms
  colnames(ref_basis)  <- rcs_terms
  
  coef_fit <- coef(fit)
  vcov_fit <- vcov(fit)
  
  beta_rcs <- coef_fit[rcs_terms]
  vcov_rcs <- vcov_fit[rcs_terms, rcs_terms]
  
  diff_mat <- as.matrix(grid_basis) -
    matrix(
      as.numeric(ref_basis[1, ]),
      nrow = nrow(grid_basis),
      ncol = ncol(grid_basis),
      byrow = TRUE
    )
  
  estimate <- as.numeric(diff_mat %*% beta_rcs)
  se <- sqrt(diag(diff_mat %*% vcov_rcs %*% t(diff_mat)))
  
  low <- estimate - 1.96 * se
  high <- estimate + 1.96 * se
  
  plot_df <- tibble(
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_value = grid_x,
    estimate = estimate,
    low = low,
    high = high,
    n = nrow(d),
    ref_value = as.numeric(ref_value),
    knot_1 = knots[1],
    knot_2 = knots[2],
    knot_3 = knots[3],
    knot_4 = knots[4],
    p_overall = p_overall,
    p_nonlinear = p_nonlinear,
    p_overall_fmt = format_p(p_overall),
    p_nonlinear_fmt = format_p(p_nonlinear),
    include_total_burden = include_total_burden,
    annotation = paste0(
      "P-overall = ", format_p(p_overall),
      "\nP-nonlinear = ", format_p(p_nonlinear)
    )
  )
  
  rug_df <- d %>%
    select(all_of(exposure)) %>%
    rename(exposure_value = all_of(exposure)) %>%
    filter(
      exposure_value >= plot_range[1],
      exposure_value <= plot_range[2]
    )
  
  if (nrow(rug_df) > 600) {
    set.seed(20260527)
    rug_df <- rug_df %>% slice_sample(n = 600)
  }
  
  list(
    plot_df = plot_df,
    rug_df = rug_df,
    p_table = plot_df %>%
      slice(1) %>%
      select(
        outcome,
        outcome_label,
        exposure,
        exposure_label,
        n,
        ref_value,
        knot_1,
        knot_2,
        knot_3,
        knot_4,
        p_overall,
        p_nonlinear,
        p_overall_fmt,
        p_nonlinear_fmt,
        include_total_burden
      )
  )
}

rcs_specs <- tibble::tribble(
  ~panel, ~outcome, ~outcome_label, ~exposure, ~exposure_label,
  "A", "ln_HOMA_IR", "ln(HOMA-IR)", "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]",
  "B", "ln_HOMA_IR", "ln(HOMA-IR)", "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance",
  "C", "HbA1c", "HbA1c", "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]",
  "D", "HbA1c", "HbA1c", "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance"
)

rcs_runs <- pmap(
  rcs_specs,
  function(panel, outcome, outcome_label, exposure, exposure_label) {
    ans <- run_rcs_model(
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      include_total_burden = TRUE
    )
    ans$panel <- panel
    ans
  }
)

rcs_plot_data <- map_dfr(
  rcs_runs,
  function(model_result) {
    panel_id <- model_result$panel
    model_result$plot_df %>% mutate(panel = panel_id)
  }
)

rcs_rug_data <- map_dfr(
  rcs_runs,
  function(model_result) {
    panel_id <- model_result$panel
    model_result$rug_df %>% mutate(panel = panel_id)
  }
)

rcs_p_table <- map_dfr(
  rcs_runs,
  function(model_result) {
    panel_id <- model_result$panel
    model_result$p_table %>% mutate(panel = panel_id)
  }
)

rcs_plot_data <- rcs_plot_data %>%
  mutate(
    panel_title = case_when(
      panel == "A" ~ "A. Log-ratio and ln(HOMA-IR)",
      panel == "B" ~ "B. ILR balance and ln(HOMA-IR)",
      panel == "C" ~ "C. Log-ratio and HbA1c",
      panel == "D" ~ "D. ILR balance and HbA1c",
      TRUE ~ panel
    )
  )

rcs_rug_data <- rcs_rug_data %>%
  left_join(
    rcs_plot_data %>%
      distinct(panel, panel_title),
    by = "panel"
  )

anno_df <- rcs_plot_data %>%
  group_by(panel_title) %>%
  slice_tail(n = 1) %>%
  ungroup()

p_rcs <- ggplot(rcs_plot_data, aes(x = exposure_value, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.35) +
  geom_ribbon(
    aes(ymin = low, ymax = high),
    alpha = 0.20,
    fill = "#2C7FB8"
  ) +
  geom_line(linewidth = 0.85, color = "#075AAB") +
  geom_rug(
    data = rcs_rug_data,
    aes(x = exposure_value),
    inherit.aes = FALSE,
    sides = "b",
    alpha = 0.35,
    color = "#075AAB"
  ) +
  geom_text(
    data = anno_df,
    aes(x = Inf, y = Inf, label = annotation),
    hjust = 1.05,
    vjust = 1.25,
    size = 3.1,
    fontface = "italic",
    inherit.aes = FALSE
  ) +
  facet_wrap(~ panel_title, scales = "free", ncol = 2) +
  labs(
    title = "Restricted cubic spline associations of DEHP oxidative-vs-primary metabolic balance with metabolic outcomes",
    subtitle = "Models adjusted for total DEHP burden, urinary creatinine, age, sex, race/ethnicity, socioeconomic factors, energy intake, and NHANES cycle",
    x = NULL,
    y = "Difference relative to weighted median exposure",
    caption = "Solid lines indicate fitted restricted cubic spline functions; shaded areas indicate 95% confidence intervals. Reference values were centered at the weighted median exposure level."
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 9.5),
    strip.text = element_text(face = "bold", size = 10),
    strip.background = element_rect(fill = "grey90", color = "grey35"),
    panel.grid.minor = element_line(color = "grey92"),
    panel.grid.major = element_line(color = "grey86"),
    plot.caption = element_text(size = 8.5, hjust = 0)
  )

print(p_rcs)

ggsave(
  file.path(fig_dir, "logratio_rcs_DEHP_HOMAIR_HbA1c_2013_2018.png"),
  p_rcs,
  width = 12,
  height = 8.5,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "logratio_rcs_DEHP_HOMAIR_HbA1c_2013_2018.pdf"),
  p_rcs,
  width = 12,
  height = 8.5
)

ggsave(
  file.path(fig_dir, "logratio_rcs_DEHP_HOMAIR_HbA1c_2013_2018.tiff"),
  p_rcs,
  width = 12,
  height = 8.5,
  dpi = 600,
  compression = "lzw"
)

# ------------------------------------------------------------
# 11. Export all results
# ------------------------------------------------------------

write_csv(
  linear_results,
  file.path(result_dir, "logratio_compositional_linear_results_2013_2018.csv")
)

write_csv(
  full_ilr_results,
  file.path(result_dir, "full_ilr_compositional_results_2013_2018.csv")
)

write_csv(
  quartile_results,
  file.path(result_dir, "logratio_compositional_quartile_results_2013_2018.csv")
)

write_csv(
  rcs_plot_data,
  file.path(result_dir, "logratio_compositional_rcs_plot_source_data_2013_2018.csv")
)

write_xlsx(
  list(
    key_linear_results = key_linear_results,
    all_linear_results = linear_results,
    full_ilr_results = full_ilr_results
  ),
  file.path(result_dir, "logratio_compositional_linear_results_2013_2018.xlsx")
)

write_xlsx(
  list(
    quartile_results = quartile_results
  ),
  file.path(result_dir, "logratio_compositional_quartile_results_2013_2018.xlsx")
)

write_xlsx(
  list(
    rcs_p_values = rcs_p_table,
    rcs_plot_source_data = rcs_plot_data
  ),
  file.path(result_dir, "logratio_compositional_rcs_results_2013_2018.xlsx")
)

cat("\nLog-ratio / compositional analysis completed successfully.\n")
cat("Key results saved to:\n")
cat(file.path(result_dir, "logratio_compositional_linear_results_2013_2018.xlsx"), "\n")
cat(file.path(result_dir, "logratio_compositional_quartile_results_2013_2018.xlsx"), "\n")
cat(file.path(result_dir, "logratio_compositional_rcs_results_2013_2018.xlsx"), "\n")
cat("Figures saved to:\n")
cat(file.path(fig_dir, "logratio_quartile_dose_response_2013_2018.png"), "\n")
cat(file.path(fig_dir, "logratio_rcs_DEHP_HOMAIR_HbA1c_2013_2018.png"), "\n")