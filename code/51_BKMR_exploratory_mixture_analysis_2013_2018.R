# ============================================================
# NHANES 2013-2018
# 51_BKMR_exploratory_mixture_analysis_2013_2018.R
#
# Exploratory BKMR mixture analysis for oxidative DEHP metabolites
# Optimized version:
#   - DEHP_oxidative only: MEHHP + MEOHP + MECPP
#   - Weighted subsampling for computational feasibility
#   - PIP + overall mixture risk + single-variable risk
#   - No PredictorResponseUnivar in the default run
# ============================================================

# ------------------------------------------------------------
# 0. Packages
# ------------------------------------------------------------

required_packages <- c(
  "dplyr", "tidyr", "purrr", "readr", "tibble",
  "ggplot2", "writexl", "stringr", "bkmr"
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
library(ggplot2)
library(writexl)
library(stringr)
library(bkmr)

# ------------------------------------------------------------
# 1. Analysis settings
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir    <- file.path(result_dir, "figures_BKMR")
fit_dir    <- file.path(result_dir, "BKMR_fits")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fit_dir, showWarnings = FALSE, recursive = TRUE)

# -------------------------
# Recommended default run
# -------------------------
# This is the practical exploratory version.
# It is suitable for supplementary manuscript evidence.
bkmr_iter <- 3000
max_n_per_model <- 800

# Final stronger run, only after the default run succeeds:
# bkmr_iter <- 5000
# max_n_per_model <- 1000

global_seed <- 20260530
set.seed(global_seed)

# Run only the oxidative DEHP mixture by default.
run_mixture_sets <- c("DEHP_oxidative")

run_outcomes <- c(
  "ln_HOMA_IR",
  "HbA1c",
  "TyG_index",
  "ln_TG_HDL_C"
)

# Skip computationally expensive univariate response functions.
run_univariate_response <- FALSE

# Do not rerun finished models unless set TRUE.
rerun_existing <- FALSE

# ------------------------------------------------------------
# 2. Helper functions
# ------------------------------------------------------------

safe_positive <- function(x) {
  x <- as.numeric(x)
  ifelse(is.finite(x) & x > 0, x, NA_real_)
}

safe_z <- function(x) {
  x <- as.numeric(x)
  s <- sd(x, na.rm = TRUE)
  m <- mean(x, na.rm = TRUE)
  if (!is.finite(s) || s == 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - m) / s
}

format_p <- function(p) {
  ifelse(
    is.na(p),
    NA_character_,
    ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

pick_var <- function(dat, candidates) {
  nms <- names(dat)
  lower_nms <- tolower(nms)
  lower_candidates <- tolower(candidates)
  
  hit <- nms[lower_nms %in% lower_candidates]
  
  if (length(hit) > 0) {
    return(hit[1])
  }
  
  NA_character_
}

make_log_component <- function(dat, label, candidates) {
  var <- pick_var(dat, candidates)
  
  if (is.na(var)) {
    return(list(data = dat, var = NA_character_, raw_var = NA_character_))
  }
  
  # If an already log-transformed variable exists, use it directly.
  if (str_detect(tolower(var), "^ln_")) {
    return(list(data = dat, var = var, raw_var = var))
  }
  
  new_var <- paste0("ln_", label, "_BKMR")
  dat[[new_var]] <- log(safe_positive(dat[[var]]))
  
  list(data = dat, var = new_var, raw_var = var)
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
      if (sum(!is.na(x)) >= 100 && sd(as.numeric(x), na.rm = TRUE) > 0) {
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

standardize_pip <- function(pip_df, mixture_labels) {
  if (is.null(pip_df) || nrow(pip_df) == 0) {
    return(tibble())
  }
  
  out <- as_tibble(pip_df)
  
  if (!("component" %in% names(out))) {
    if ("variable" %in% names(out)) {
      out <- out %>% rename(component = variable)
    } else if ("var" %in% names(out)) {
      out <- out %>% rename(component = var)
    } else if ("z" %in% tolower(names(out))) {
      z_col <- names(out)[tolower(names(out)) == "z"][1]
      out <- out %>% rename(component = all_of(z_col))
    } else {
      out <- out %>% mutate(component = row_number(), .before = 1)
    }
  }
  
  pip_col <- names(out)[str_detect(tolower(names(out)), "pip")]
  
  if (length(pip_col) > 0 && !("PIP" %in% names(out))) {
    out <- out %>% rename(PIP = all_of(pip_col[1]))
  }
  
  if (!("PIP" %in% names(out))) {
    numeric_cols <- names(out)[map_lgl(out, is.numeric)]
    numeric_cols <- setdiff(numeric_cols, "component")
    
    if (length(numeric_cols) > 0) {
      out <- out %>% rename(PIP = all_of(numeric_cols[1]))
    }
  }
  
  # Replace numeric component IDs with actual component labels when possible.
  if ("component" %in% names(out) && nrow(out) == length(mixture_labels)) {
    comp_chr <- as.character(out$component)
    
    if (all(comp_chr %in% as.character(seq_along(mixture_labels))) || all(str_detect(comp_chr, "^\\d+$"))) {
      out$component <- mixture_labels
    }
  }
  
  if (!("component" %in% names(out))) {
    out <- out %>% mutate(component = mixture_labels[seq_len(nrow(out))], .before = 1)
  }
  
  out
}

safe_bkmr_call <- function(expr) {
  tryCatch(
    expr,
    error = function(e) {
      message("BKMR post-processing failed: ", e$message)
      NULL
    }
  )
}

standardize_overall_risk <- function(overall_df) {
  if (is.null(overall_df) || nrow(overall_df) == 0) return(tibble())
  
  out <- as_tibble(overall_df)
  
  nms_lower <- tolower(names(out))
  
  q_col <- names(out)[str_detect(nms_lower, "quantile|qs|q\\.")]
  est_col <- names(out)[nms_lower %in% c("est", "estimate", "mean")]
  sd_col <- names(out)[nms_lower %in% c("sd", "se", "stderr")]
  low_col <- names(out)[nms_lower %in% c("lower", "low", "ci.lower", "lb")]
  high_col <- names(out)[nms_lower %in% c("upper", "high", "ci.upper", "ub")]
  
  if (length(q_col) == 0) {
    q_col <- names(out)[map_lgl(out, is.numeric)][1]
  }
  
  if (length(est_col) == 0) {
    numeric_cols <- names(out)[map_lgl(out, is.numeric)]
    est_col <- setdiff(numeric_cols, q_col)[1]
  }
  
  out <- out %>%
    mutate(
      q_value_plot = as.numeric(.data[[q_col[1]]]),
      est_plot = as.numeric(.data[[est_col[1]]])
    )
  
  if (length(sd_col) > 0) {
    out <- out %>%
      mutate(
        sd_plot = as.numeric(.data[[sd_col[1]]]),
        low_plot = est_plot - 1.96 * sd_plot,
        high_plot = est_plot + 1.96 * sd_plot
      )
  } else if (length(low_col) > 0 && length(high_col) > 0) {
    out <- out %>%
      mutate(
        low_plot = as.numeric(.data[[low_col[1]]]),
        high_plot = as.numeric(.data[[high_col[1]]])
      )
  } else {
    out <- out %>%
      mutate(
        low_plot = NA_real_,
        high_plot = NA_real_
      )
  }
  
  out
}

# ------------------------------------------------------------
# 3. Read analytic dataset
# ------------------------------------------------------------

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_source_oriented_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset_with_DIQ050_DIQ070.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset_with_DIQmed.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]

if (is.na(data_file)) {
  stop("找不到当前分析数据，请检查 output 文件夹。")
}

df <- readRDS(data_file) %>% as_tibble()

cat("Using dataset:\n", data_file, "\n")
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")

# ------------------------------------------------------------
# 4. Ensure outcomes and covariates
# ------------------------------------------------------------

if (!("ln_HOMA_IR" %in% names(df)) && "HOMA_IR" %in% names(df)) {
  df <- df %>% mutate(ln_HOMA_IR = log(safe_positive(HOMA_IR)))
}

if (!("HbA1c" %in% names(df)) && "LBXGH" %in% names(df)) {
  df <- df %>% mutate(HbA1c = as.numeric(LBXGH))
}

if (!("ln_URXUCR" %in% names(df)) && "URXUCR" %in% names(df)) {
  df <- df %>% mutate(ln_URXUCR = log(safe_positive(URXUCR)))
}

if (!("cycle" %in% names(df)) && "SDDSRVYR" %in% names(df)) {
  df <- df %>% mutate(cycle = SDDSRVYR)
}

# ------------------------------------------------------------
# 5. Detect and construct DEHP component variables
# ------------------------------------------------------------

# Important:
# MEHP is not MEP. Do NOT use URXMEP as MEHP.
component_specs <- list(
  MECPP = c("ln_MECPP", "ln_URXECP", "URXECP_ln", "MECPP_ln", "MECPP", "URXECP"),
  MEHHP = c("ln_MEHHP", "ln_URXMHH", "URXMHH_ln", "MEHHP_ln", "MEHHP", "URXMHH"),
  MEOHP = c("ln_MEOHP", "ln_URXMOH", "URXMOH_ln", "MEOHP_ln", "MEOHP", "URXMOH"),
  MEHP  = c("ln_MEHP",  "ln_URXMHP", "URXMHP_ln", "MEHP_ln",  "MEHP",  "URXMHP")
)

component_map <- tibble(
  component = character(),
  selected_var = character(),
  raw_var = character()
)

for (comp in names(component_specs)) {
  res <- make_log_component(df, comp, component_specs[[comp]])
  df <- res$data
  
  component_map <- bind_rows(
    component_map,
    tibble(
      component = comp,
      selected_var = res$var,
      raw_var = res$raw_var
    )
  )
}

cat("\nDetected DEHP component variables:\n")
print(component_map)

if (any(is.na(component_map$selected_var))) {
  warning("部分 DEHP 代谢物没有识别到。脚本会只运行可用 mixture set。")
}

get_component_var <- function(comp) {
  component_map %>%
    filter(component == comp) %>%
    pull(selected_var) %>%
    first()
}

# ------------------------------------------------------------
# 6. Define mixture sets
# ------------------------------------------------------------

mixture_sets <- list(
  DEHP_oxidative = c(
    MEHHP = get_component_var("MEHHP"),
    MEOHP = get_component_var("MEOHP"),
    MECPP = get_component_var("MECPP")
  ),
  DEHP_all = c(
    MEHP  = get_component_var("MEHP"),
    MEHHP = get_component_var("MEHHP"),
    MEOHP = get_component_var("MEOHP"),
    MECPP = get_component_var("MECPP")
  )
)

mixture_sets <- mixture_sets[
  map_lgl(mixture_sets, ~ all(!is.na(.x)) && length(.x) >= 3)
]

mixture_sets <- mixture_sets[names(mixture_sets) %in% run_mixture_sets]

if (length(mixture_sets) == 0) {
  stop("没有可用的指定 BKMR mixture set。请检查 run_mixture_sets 或 DEHP 变量名。")
}

cat("\nMixture sets to run:\n")
print(mixture_sets)

# ------------------------------------------------------------
# 7. Define outcomes and covariates
# ------------------------------------------------------------

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label,
  "ln_HOMA_IR", "ln(HOMA-IR)",
  "HbA1c", "HbA1c",
  "TyG_index", "TyG index",
  "ln_TG_HDL_C", "ln(TG/HDL-C)"
) %>%
  filter(outcome %in% names(df)) %>%
  filter(outcome %in% run_outcomes)

if (nrow(outcome_map) == 0) {
  stop("没有可用结局变量。请检查 run_outcomes 或前序 TyG/TG-HDL-C 脚本。")
}

cat("\nOutcomes to run:\n")
print(outcome_map)

base_covars <- c(
  "RIDAGEYR",
  "factor(RIAGENDR)",
  "factor(RIDRETH3)",
  "INDFMPIR",
  "factor(DMDEDUC2)",
  "DR1TKCAL",
  "ln_URXUCR",
  "factor(cycle)"
)

base_vars <- c(
  "RIDAGEYR",
  "RIAGENDR",
  "RIDRETH3",
  "INDFMPIR",
  "DMDEDUC2",
  "DR1TKCAL",
  "ln_URXUCR",
  "cycle"
)

missing_base <- setdiff(base_vars, names(df))

if (length(missing_base) > 0) {
  stop(paste0("BKMR 缺少基础协变量：", paste(missing_base, collapse = ", ")))
}

# Weight is used only for weighted subsampling.
weight_var <- NA_character_

if ("WTSB6YR_MAIN" %in% names(df)) {
  weight_var <- "WTSB6YR_MAIN"
} else if ("WTSAF6YR" %in% names(df)) {
  weight_var <- "WTSAF6YR"
} else if ("WTSAF2YR" %in% names(df)) {
  df <- df %>% mutate(WTSB6YR_BKMR = WTSAF2YR / 3)
  weight_var <- "WTSB6YR_BKMR"
} else if ("WTMEC6YR" %in% names(df)) {
  weight_var <- "WTMEC6YR"
}

cat("\nWeight variable for weighted subsampling:", weight_var, "\n")

# ------------------------------------------------------------
# 8. Prepare BKMR input
# ------------------------------------------------------------

prepare_bkmr_data <- function(outcome, mixture_vars_named, sampling_seed) {
  mixture_vars <- unname(mixture_vars_named)
  mixture_labels <- names(mixture_vars_named)
  
  needed <- unique(c(outcome, mixture_vars, base_vars, weight_var))
  needed <- needed[!is.na(needed)]
  
  missing_needed <- setdiff(needed, names(df))
  
  if (length(missing_needed) > 0) {
    stop(paste0("缺少变量：", paste(missing_needed, collapse = ", ")))
  }
  
  d <- df %>%
    filter(RIDAGEYR >= 20) %>%
    select(all_of(needed)) %>%
    drop_na()
  
  if (nrow(d) < 300) {
    stop("BKMR 样本量不足：", nrow(d))
  }
  
  n_eligible_before_subsample <- nrow(d)
  
  # Weighted subsampling for computational feasibility.
  if (is.finite(max_n_per_model) && nrow(d) > max_n_per_model) {
    set.seed(sampling_seed)
    
    if (!is.na(weight_var) && weight_var %in% names(d)) {
      prob <- safe_positive(d[[weight_var]])
      prob[is.na(prob)] <- 0
      
      if (sum(prob) <= 0) {
        prob <- rep(1 / nrow(d), nrow(d))
      } else {
        prob <- prob / sum(prob)
      }
      
      idx <- sample(
        seq_len(nrow(d)),
        size = max_n_per_model,
        replace = FALSE,
        prob = prob
      )
    } else {
      idx <- sample(seq_len(nrow(d)), size = max_n_per_model, replace = FALSE)
    }
    
    d <- d[idx, , drop = FALSE]
  }
  
  # Z matrix: standardized log-DEHP components.
  Z_raw <- d %>%
    select(all_of(mixture_vars)) %>%
    as.data.frame()
  
  names(Z_raw) <- mixture_labels
  
  Z <- scale(as.matrix(Z_raw))
  colnames(Z) <- mixture_labels
  
  # X matrix: covariates.
  usable_covars <- drop_unusable_terms(d, base_covars)
  
  covar_formula <- as.formula(
    paste0("~ ", paste(usable_covars, collapse = " + "))
  )
  
  X <- model.matrix(covar_formula, data = d)
  
  # Remove zero-variance columns except intercept.
  if (ncol(X) > 1) {
    keep_cols <- apply(X, 2, function(x) sd(as.numeric(x), na.rm = TRUE) > 0)
    keep_cols[1] <- TRUE
    X <- X[, keep_cols, drop = FALSE]
  }
  
  y <- as.numeric(d[[outcome]])
  
  list(
    data = d,
    y = y,
    Z = Z,
    X = X,
    mixture_labels = mixture_labels,
    mixture_vars = mixture_vars,
    usable_covars = usable_covars,
    n_eligible_before_subsample = n_eligible_before_subsample,
    n_bkmr = length(y)
  )
}

# ------------------------------------------------------------
# 9. Run one BKMR model
# ------------------------------------------------------------

run_one_bkmr <- function(outcome, outcome_label, mixture_name, mixture_vars_named, model_index) {
  cat("\n------------------------------------------------------------\n")
  cat("Running BKMR:", mixture_name, "→", outcome_label, "\n")
  cat("------------------------------------------------------------\n")
  
  sampling_seed <- global_seed + model_index * 100
  
  fit_file <- file.path(
    fit_dir,
    paste0(
      "BKMR_fit_",
      mixture_name,
      "_",
      str_replace_all(outcome, "[^A-Za-z0-9]+", "_"),
      "_iter",
      bkmr_iter,
      "_n",
      max_n_per_model,
      "_seed",
      sampling_seed,
      ".rds"
    )
  )
  
  if (file.exists(fit_file) && !rerun_existing) {
    cat("Existing fit found. Loading:\n", fit_file, "\n")
    fit_obj <- readRDS(fit_file)
    
    fit <- fit_obj$fit
    dat <- fit_obj$dat
  } else {
    dat <- prepare_bkmr_data(
      outcome = outcome,
      mixture_vars_named = mixture_vars_named,
      sampling_seed = sampling_seed
    )
    
    cat("Eligible complete-case n before subsampling:", dat$n_eligible_before_subsample, "\n")
    cat("BKMR n:", dat$n_bkmr, "\n")
    cat("Mixture components:", paste(dat$mixture_labels, collapse = ", "), "\n")
    cat("Covariates:", paste(dat$usable_covars, collapse = " + "), "\n")
    cat("Iterations:", bkmr_iter, "\n")
    
    fit <- bkmr::kmbayes(
      y = dat$y,
      Z = dat$Z,
      X = dat$X,
      iter = bkmr_iter,
      family = "gaussian",
      varsel = TRUE,
      verbose = TRUE
    )
    
    saveRDS(
      list(
        fit = fit,
        dat = dat,
        mixture_name = mixture_name,
        outcome = outcome,
        outcome_label = outcome_label,
        iter = bkmr_iter,
        max_n_per_model = max_n_per_model,
        sampling_seed = sampling_seed
      ),
      fit_file
    )
  }
  
  # -------------------------
  # PIPs
  # -------------------------
  
  pips_raw <- safe_bkmr_call(
    bkmr::ExtractPIPs(fit)
  )
  
  pips <- standardize_pip(
    pip_df = pips_raw,
    mixture_labels = dat$mixture_labels
  ) %>%
    mutate(
      mixture_name = mixture_name,
      outcome = outcome,
      outcome_label = outcome_label,
      n_eligible_before_subsample = dat$n_eligible_before_subsample,
      n_bkmr = dat$n_bkmr,
      iter = bkmr_iter,
      max_n_per_model = max_n_per_model,
      sampling_seed = sampling_seed,
      fit_file = fit_file,
      .before = 1
    )
  
  # -------------------------
  # Overall mixture risk
  # -------------------------
  
  overall_raw <- safe_bkmr_call(
    bkmr::OverallRiskSummaries(
      fit = fit,
      qs = seq(0.25, 0.75, by = 0.05),
      q.fixed = 0.50,
      method = "exact"
    )
  )
  
  overall <- if (!is.null(overall_raw)) {
    standardize_overall_risk(overall_raw) %>%
      mutate(
        mixture_name = mixture_name,
        outcome = outcome,
        outcome_label = outcome_label,
        n_eligible_before_subsample = dat$n_eligible_before_subsample,
        n_bkmr = dat$n_bkmr,
        iter = bkmr_iter,
        max_n_per_model = max_n_per_model,
        sampling_seed = sampling_seed,
        .before = 1
      )
  } else {
    tibble()
  }
  
  # -------------------------
  # Single-variable risk summaries
  # -------------------------
  
  single_raw <- safe_bkmr_call(
    bkmr::SingVarRiskSummaries(
      fit = fit,
      qs.diff = c(0.25, 0.75),
      q.fixed = c(0.25, 0.50, 0.75),
      method = "exact"
    )
  )
  
  single <- if (!is.null(single_raw)) {
    as_tibble(single_raw) %>%
      mutate(
        mixture_name = mixture_name,
        outcome = outcome,
        outcome_label = outcome_label,
        n_eligible_before_subsample = dat$n_eligible_before_subsample,
        n_bkmr = dat$n_bkmr,
        iter = bkmr_iter,
        max_n_per_model = max_n_per_model,
        sampling_seed = sampling_seed,
        .before = 1
      )
  } else {
    tibble()
  }
  
  # -------------------------
  # Univariate predictor-response
  # skipped by default
  # -------------------------
  
  univar <- tibble()
  
  if (run_univariate_response) {
    univar_raw <- safe_bkmr_call(
      bkmr::PredictorResponseUnivar(
        fit = fit,
        q.fixed = 0.50,
        method = "exact"
      )
    )
    
    univar <- if (!is.null(univar_raw)) {
      as_tibble(univar_raw) %>%
        mutate(
          mixture_name = mixture_name,
          outcome = outcome,
          outcome_label = outcome_label,
          n_eligible_before_subsample = dat$n_eligible_before_subsample,
          n_bkmr = dat$n_bkmr,
          iter = bkmr_iter,
          max_n_per_model = max_n_per_model,
          sampling_seed = sampling_seed,
          .before = 1
        )
    } else {
      tibble()
    }
  }
  
  # -------------------------
  # Exposure correlation matrix
  # -------------------------
  
  corr <- as.data.frame(cor(dat$Z, use = "pairwise.complete.obs")) %>%
    rownames_to_column("component_1") %>%
    pivot_longer(
      cols = -component_1,
      names_to = "component_2",
      values_to = "correlation"
    ) %>%
    mutate(
      mixture_name = mixture_name,
      outcome = outcome,
      outcome_label = outcome_label,
      n_bkmr = dat$n_bkmr,
      .before = 1
    )
  
  # -------------------------
  # Sample metadata
  # -------------------------
  
  sample <- tibble(
    mixture_name = mixture_name,
    outcome = outcome,
    outcome_label = outcome_label,
    n_eligible_before_subsample = dat$n_eligible_before_subsample,
    n_bkmr = dat$n_bkmr,
    iter = bkmr_iter,
    max_n_per_model = max_n_per_model,
    sampling_seed = sampling_seed,
    fit_file = fit_file,
    mixture_components = paste(dat$mixture_labels, collapse = ", "),
    mixture_variables = paste(dat$mixture_vars, collapse = ", "),
    covariates = paste(dat$usable_covars, collapse = " + "),
    weighted_subsample = ifelse(
      is.finite(max_n_per_model) && dat$n_eligible_before_subsample > max_n_per_model,
      TRUE,
      FALSE
    ),
    weight_var_for_subsampling = weight_var
  )
  
  list(
    pips = pips,
    overall = overall,
    single = single,
    univar = univar,
    corr = corr,
    sample = sample
  )
}

# ------------------------------------------------------------
# 10. Run all selected BKMR models
# ------------------------------------------------------------

model_grid <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  mixture_name = names(mixture_sets)
) %>%
  mutate(model_index = row_number())

cat("\nBKMR model grid:\n")
print(model_grid)

bkmr_outputs <- vector("list", nrow(model_grid))

for (i in seq_len(nrow(model_grid))) {
  out_i <- outcome_map$outcome[model_grid$outcome_row[i]]
  lab_i <- outcome_map$outcome_label[model_grid$outcome_row[i]]
  mix_i <- model_grid$mixture_name[i]
  mix_vars_i <- mixture_sets[[mix_i]]
  model_index_i <- model_grid$model_index[i]
  
  bkmr_outputs[[i]] <- tryCatch(
    run_one_bkmr(
      outcome = out_i,
      outcome_label = lab_i,
      mixture_name = mix_i,
      mixture_vars_named = mix_vars_i,
      model_index = model_index_i
    ),
    error = function(e) {
      message("BKMR model failed: ", mix_i, " → ", lab_i)
      message(e$message)
      
      list(
        pips = tibble(),
        overall = tibble(),
        single = tibble(),
        univar = tibble(),
        corr = tibble(),
        sample = tibble(
          mixture_name = mix_i,
          outcome = out_i,
          outcome_label = lab_i,
          n_eligible_before_subsample = NA_integer_,
          n_bkmr = NA_integer_,
          iter = bkmr_iter,
          max_n_per_model = max_n_per_model,
          sampling_seed = global_seed + model_index_i * 100,
          fit_file = NA_character_,
          mixture_components = paste(names(mix_vars_i), collapse = ", "),
          mixture_variables = paste(unname(mix_vars_i), collapse = ", "),
          covariates = NA_character_,
          weighted_subsample = NA,
          weight_var_for_subsampling = weight_var,
          error = e$message
        )
      )
    }
  )
}

pips_all   <- bind_rows(map(bkmr_outputs, "pips"))
overall_all <- bind_rows(map(bkmr_outputs, "overall"))
single_all <- bind_rows(map(bkmr_outputs, "single"))
univar_all <- bind_rows(map(bkmr_outputs, "univar"))
corr_all   <- bind_rows(map(bkmr_outputs, "corr"))
sample_all <- bind_rows(map(bkmr_outputs, "sample"))

# ------------------------------------------------------------
# 11. Interpretive summaries
# ------------------------------------------------------------

pip_summary <- if (nrow(pips_all) > 0 && "PIP" %in% names(pips_all)) {
  pips_all %>%
    group_by(mixture_name, outcome_label) %>%
    arrange(desc(PIP), .by_group = TRUE) %>%
    mutate(
      pip_rank = row_number(),
      pip_interpretation = case_when(
        PIP >= 0.75 ~ "Strong",
        PIP >= 0.50 ~ "Moderate",
        PIP >= 0.25 ~ "Suggestive",
        TRUE ~ "Weak"
      )
    ) %>%
    ungroup()
} else {
  tibble()
}

overall_summary <- if (nrow(overall_all) > 0) {
  overall_all %>%
    group_by(mixture_name, outcome, outcome_label) %>%
    summarise(
      n_bkmr = first(n_bkmr),
      iter = first(iter),
      max_n_per_model = first(max_n_per_model),
      est_at_75 = est_plot[which.min(abs(q_value_plot - 0.75))][1],
      est_at_25 = est_plot[which.min(abs(q_value_plot - 0.25))][1],
      high_vs_low_difference = est_at_75 - est_at_25,
      direction = case_when(
        high_vs_low_difference > 0 ~ "Positive overall mixture pattern",
        high_vs_low_difference < 0 ~ "Negative overall mixture pattern",
        TRUE ~ "Null/flat pattern"
      ),
      .groups = "drop"
    )
} else {
  tibble()
}

# ------------------------------------------------------------
# 12. Plot PIP heatmap
# ------------------------------------------------------------

if (nrow(pip_summary) > 0 && "PIP" %in% names(pip_summary)) {
  pip_plot_df <- pip_summary %>%
    mutate(
      component = factor(
        as.character(component),
        levels = c("MEHHP", "MEOHP", "MECPP", "MEHP")
      ),
      outcome_label = factor(
        outcome_label,
        levels = c("ln(HOMA-IR)", "HbA1c", "TyG index", "ln(TG/HDL-C)")
      )
    )
  
  p_pip <- ggplot(
    pip_plot_df,
    aes(x = component, y = outcome_label, fill = PIP)
  ) +
    geom_tile(color = "white", linewidth = 0.35) +
    geom_text(aes(label = sprintf("%.2f", PIP)), size = 3.3) +
    facet_wrap(~ mixture_name, scales = "free_x") +
    scale_fill_gradient(
      low = "grey90",
      high = "darkgreen",
      limits = c(0, 1)
    ) +
    labs(
      title = "Exploratory BKMR posterior inclusion probabilities",
      subtitle = "Oxidative DEHP metabolite mixture models in weighted subsamples",
      x = "DEHP metabolite component",
      y = "Metabolic outcome",
      fill = "PIP",
      caption = paste0(
        "BKMR models were adjusted for age, sex, race/ethnicity, income, education, total energy intake, ",
        "urinary creatinine, and NHANES cycle. Analyses were exploratory and not fully survey-weighted."
      )
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold"),
      panel.grid = element_blank(),
      plot.caption = element_text(size = 8.2, hjust = 0)
    )
  
  print(p_pip)
  
  ggsave(
    file.path(fig_dir, "BKMR_PIP_heatmap_DEHP_oxidative_mixture_2013_2018.png"),
    p_pip,
    width = 10,
    height = 5.8,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "BKMR_PIP_heatmap_DEHP_oxidative_mixture_2013_2018.pdf"),
    p_pip,
    width = 10,
    height = 5.8
  )
}

# ------------------------------------------------------------
# 13. Plot overall mixture risk
# ------------------------------------------------------------

if (nrow(overall_all) > 0) {
  overall_plot_df <- overall_all %>%
    mutate(
      outcome_label = factor(
        outcome_label,
        levels = c("ln(HOMA-IR)", "HbA1c", "TyG index", "ln(TG/HDL-C)")
      )
    )
  
  p_overall <- ggplot(
    overall_plot_df,
    aes(x = q_value_plot, y = est_plot)
  ) +
    geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.35) +
    geom_ribbon(
      aes(ymin = low_plot, ymax = high_plot),
      alpha = 0.20,
      na.rm = TRUE
    ) +
    geom_line(linewidth = 0.65) +
    geom_point(size = 1.8) +
    facet_grid(outcome_label ~ mixture_name, scales = "free_y") +
    labs(
      title = "Exploratory BKMR overall mixture-response patterns",
      subtitle = "Difference in estimated h when all oxidative DEHP components are shifted jointly from the median",
      x = "Joint mixture quantile",
      y = "Estimated difference in h",
      caption = paste0(
        "Positive values indicate higher estimated outcome levels relative to the median mixture level. ",
        "BKMR analyses were conducted in weighted subsamples for computational feasibility."
      )
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold"),
      plot.caption = element_text(size = 8.2, hjust = 0)
    )
  
  print(p_overall)
  
  ggsave(
    file.path(fig_dir, "BKMR_overall_mixture_risk_DEHP_oxidative_2013_2018.png"),
    p_overall,
    width = 10,
    height = 8,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "BKMR_overall_mixture_risk_DEHP_oxidative_2013_2018.pdf"),
    p_overall,
    width = 10,
    height = 8
  )
}

# ------------------------------------------------------------
# 14. Plot single-variable risk summaries if available
# ------------------------------------------------------------

if (nrow(single_all) > 0) {
  single_plot_df <- single_all
  
  # Try to standardize component column.
  if (!("component" %in% names(single_plot_df))) {
    if ("variable" %in% names(single_plot_df)) {
      single_plot_df <- single_plot_df %>% rename(component = variable)
    } else if ("var" %in% names(single_plot_df)) {
      single_plot_df <- single_plot_df %>% rename(component = var)
    }
  }
  
  nms_lower <- tolower(names(single_plot_df))
  
  est_col <- names(single_plot_df)[nms_lower %in% c("est", "estimate", "mean")]
  sd_col  <- names(single_plot_df)[nms_lower %in% c("sd", "se", "stderr")]
  
  if ("component" %in% names(single_plot_df) && length(est_col) > 0) {
    single_plot_df <- single_plot_df %>%
      mutate(
        est_plot = as.numeric(.data[[est_col[1]]])
      )
    
    if (length(sd_col) > 0) {
      single_plot_df <- single_plot_df %>%
        mutate(
          sd_plot = as.numeric(.data[[sd_col[1]]]),
          low_plot = est_plot - 1.96 * sd_plot,
          high_plot = est_plot + 1.96 * sd_plot
        )
    } else {
      single_plot_df <- single_plot_df %>%
        mutate(
          low_plot = NA_real_,
          high_plot = NA_real_
        )
    }
    
    single_plot_df <- single_plot_df %>%
      mutate(
        outcome_label = factor(
          outcome_label,
          levels = c("ln(HOMA-IR)", "HbA1c", "TyG index", "ln(TG/HDL-C)")
        ),
        component = factor(
          as.character(component),
          levels = c("MEHHP", "MEOHP", "MECPP", "MEHP")
        )
      )
    
    p_single <- ggplot(
      single_plot_df,
      aes(x = est_plot, y = component)
    ) +
      geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.35) +
      geom_errorbarh(
        aes(xmin = low_plot, xmax = high_plot),
        height = 0.18,
        na.rm = TRUE
      ) +
      geom_point(size = 2) +
      facet_grid(outcome_label ~ mixture_name, scales = "free_x") +
      labs(
        title = "Exploratory BKMR single-component risk summaries",
        subtitle = "Estimated change when one DEHP component is shifted from P25 to P75 while others are fixed",
        x = "Estimated difference in h",
        y = "DEHP component"
      ) +
      theme_bw(base_size = 10.5) +
      theme(
        plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 9.5),
        strip.text = element_text(face = "bold")
      )
    
    print(p_single)
    
    ggsave(
      file.path(fig_dir, "BKMR_single_component_risk_DEHP_oxidative_2013_2018.png"),
      p_single,
      width = 10,
      height = 8,
      dpi = 300
    )
    
    ggsave(
      file.path(fig_dir, "BKMR_single_component_risk_DEHP_oxidative_2013_2018.pdf"),
      p_single,
      width = 10,
      height = 8
    )
  }
}

# ------------------------------------------------------------
# 15. Export results
# ------------------------------------------------------------

mixture_set_table <- tibble(
  mixture_name = names(mixture_sets),
  components = map_chr(mixture_sets, ~ paste(names(.x), collapse = ", ")),
  variables = map_chr(mixture_sets, ~ paste(unname(.x), collapse = ", "))
)

analysis_settings <- tibble(
  setting = c(
    "bkmr_iter",
    "max_n_per_model",
    "global_seed",
    "run_mixture_sets",
    "run_outcomes",
    "run_univariate_response",
    "weight_var_for_subsampling",
    "rerun_existing"
  ),
  value = c(
    as.character(bkmr_iter),
    as.character(max_n_per_model),
    as.character(global_seed),
    paste(run_mixture_sets, collapse = ", "),
    paste(run_outcomes, collapse = ", "),
    as.character(run_univariate_response),
    as.character(weight_var),
    as.character(rerun_existing)
  )
)

write_xlsx(
  list(
    analysis_settings = analysis_settings,
    component_variable_map = component_map,
    mixture_sets = mixture_set_table,
    model_samples = sample_all,
    PIP_summary = pip_summary,
    PIPs_raw = pips_all,
    overall_summary = overall_summary,
    overall_mixture_risk = overall_all,
    single_variable_risk = single_all,
    univariate_response = univar_all,
    exposure_correlations = corr_all
  ),
  file.path(result_dir, "BKMR_exploratory_DEHP_oxidative_mixture_results_2013_2018.xlsx")
)

write_csv(
  pip_summary,
  file.path(result_dir, "BKMR_PIP_summary_DEHP_oxidative_2013_2018.csv")
)

write_csv(
  overall_summary,
  file.path(result_dir, "BKMR_overall_summary_DEHP_oxidative_2013_2018.csv")
)

write_csv(
  overall_all,
  file.path(result_dir, "BKMR_overall_mixture_risk_DEHP_oxidative_2013_2018.csv")
)

write_csv(
  single_all,
  file.path(result_dir, "BKMR_single_variable_risk_DEHP_oxidative_2013_2018.csv")
)

write_csv(
  sample_all,
  file.path(result_dir, "BKMR_model_samples_DEHP_oxidative_2013_2018.csv")
)

cat("\nBKMR exploratory oxidative-mixture analysis completed.\n")
cat("Main result file:\n")
cat(file.path(result_dir, "BKMR_exploratory_DEHP_oxidative_mixture_results_2013_2018.xlsx"), "\n")
cat("Figures:\n")
cat(file.path(fig_dir, "BKMR_PIP_heatmap_DEHP_oxidative_mixture_2013_2018.png"), "\n")
cat(file.path(fig_dir, "BKMR_overall_mixture_risk_DEHP_oxidative_2013_2018.png"), "\n")
cat(file.path(fig_dir, "BKMR_single_component_risk_DEHP_oxidative_2013_2018.png"), "\n")
cat("Model fits saved in:\n")
cat(fit_dir, "\n")