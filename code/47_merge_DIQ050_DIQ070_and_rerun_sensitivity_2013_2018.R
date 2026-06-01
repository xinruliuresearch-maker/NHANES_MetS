# ============================================================
# NHANES 2013-2018
# 47_merge_DIQ050_DIQ070_and_rerun_sensitivity_2013_2018.R
# Merge DIQ050 / DIQ070 and rerun diabetes / medication exclusion sensitivity
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

data_dir   <- file.path(project_dir, "data")
raw_dir    <- file.path(data_dir, "raw_DIQ")
output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir    <- file.path(result_dir, "figures_diabetes_medication_sensitivity")

dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Package check
# ------------------------------------------------------------

if (!requireNamespace("haven", quietly = TRUE)) {
  stop("缺少 haven 包。请先运行 install.packages('haven')，然后重新运行本脚本。")
}

# ------------------------------------------------------------
# 2. Helper functions
# ------------------------------------------------------------

download_if_missing <- function(url, destfile) {
  if (!file.exists(destfile)) {
    message("Downloading: ", url)
    download.file(url, destfile = destfile, mode = "wb", quiet = FALSE)
  } else {
    message("File already exists: ", destfile)
  }
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

get_numeric_var <- function(dat, var_name) {
  if (is.na(var_name) || length(var_name) == 0 || !(var_name %in% names(dat))) {
    return(rep(NA_real_, nrow(dat)))
  }
  as.numeric(dat[[var_name]])
}

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

# ------------------------------------------------------------
# 3. Download and read DIQ_H / DIQ_I / DIQ_J
# ------------------------------------------------------------

diq_files <- tibble::tribble(
  ~cycle_label, ~begin_year, ~suffix, ~url,
  "2013-2014", 2013, "H", "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2013/DataFiles/DIQ_H.XPT",
  "2015-2016", 2015, "I", "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2015/DataFiles/DIQ_I.XPT",
  "2017-2018", 2017, "J", "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/DIQ_J.XPT"
)

diq_all <- map_dfr(
  seq_len(nrow(diq_files)),
  function(i) {
    dest <- file.path(raw_dir, paste0("DIQ_", diq_files$suffix[i], ".XPT"))
    download_if_missing(diq_files$url[i], dest)
    
    dat <- haven::read_xpt(dest) %>%
      as_tibble()
    
    needed <- c("SEQN", "DIQ010", "DIQ050", "DIQ070")
    missing_needed <- setdiff(needed, names(dat))
    
    if (length(missing_needed) > 0) {
      stop(
        paste0(
          "文件 ", basename(dest), " 缺少变量：",
          paste(missing_needed, collapse = ", ")
        )
      )
    }
    
    dat %>%
      select(SEQN, DIQ010, DIQ050, DIQ070) %>%
      mutate(
        cycle_label_DIQ = diq_files$cycle_label[i],
        DIQ_cycle_begin_year = diq_files$begin_year[i]
      )
  }
)

diq_check <- diq_all %>%
  summarise(
    n = n(),
    unique_SEQN = n_distinct(SEQN),
    DIQ010_nonmissing = sum(!is.na(DIQ010)),
    DIQ050_nonmissing = sum(!is.na(DIQ050)),
    DIQ070_nonmissing = sum(!is.na(DIQ070)),
    DIQ050_yes = sum(DIQ050 == 1, na.rm = TRUE),
    DIQ070_yes = sum(DIQ070 == 1, na.rm = TRUE)
  )

print(diq_check)

if (nrow(diq_all) != n_distinct(diq_all$SEQN)) {
  stop("DIQ 合并数据中 SEQN 不唯一，请检查。")
}

# ------------------------------------------------------------
# 4. Read current best analytic dataset
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

df0 <- readRDS(data_file) %>%
  as_tibble()

cat("\nUsing base analytic dataset:\n", data_file, "\n")
cat("Dataset dimensions before DIQ merge:", nrow(df0), "rows,", ncol(df0), "columns\n")

if (!("SEQN" %in% names(df0))) {
  stop("当前分析数据没有 SEQN，无法合并 DIQ 文件。")
}

# ------------------------------------------------------------
# 5. Merge DIQ variables
# ------------------------------------------------------------

df_merged <- df0 %>%
  select(-any_of(c("DIQ010", "DIQ050", "DIQ070", "cycle_label_DIQ", "DIQ_cycle_begin_year"))) %>%
  left_join(diq_all, by = "SEQN")

merge_check <- tibble(
  item = c(
    "Base analytic rows",
    "Rows after DIQ merge",
    "Matched DIQ010",
    "Matched DIQ050",
    "Matched DIQ070",
    "DIQ010 yes",
    "DIQ050 insulin yes",
    "DIQ070 pills yes"
  ),
  n = c(
    nrow(df0),
    nrow(df_merged),
    sum(!is.na(df_merged$DIQ010)),
    sum(!is.na(df_merged$DIQ050)),
    sum(!is.na(df_merged$DIQ070)),
    sum(df_merged$DIQ010 == 1, na.rm = TRUE),
    sum(df_merged$DIQ050 == 1, na.rm = TRUE),
    sum(df_merged$DIQ070 == 1, na.rm = TRUE)
  )
)

print(merge_check)

if (nrow(df_merged) != nrow(df0)) {
  stop("合并后行数改变，说明 SEQN merge 出现问题。")
}

write_rds(
  df_merged,
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset_with_DIQmed.rds")
)

write_csv(
  df_merged,
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset_with_DIQmed.csv")
)

# ------------------------------------------------------------
# 6. Ensure derived variables exist
# ------------------------------------------------------------

df <- df_merged

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

if (!("ln_URXUCR" %in% names(df))) {
  if ("URXUCR" %in% names(df)) {
    df <- df %>% mutate(ln_URXUCR = log(URXUCR))
  }
}

if (!("cycle" %in% names(df))) {
  if ("SDDSRVYR" %in% names(df)) {
    df <- df %>% mutate(cycle = SDDSRVYR)
  }
}

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
# 7. Correct diabetes / medication flags
# ------------------------------------------------------------

df_sens <- df %>%
  mutate(
    # NHANES coding:
    # 1 = Yes, 2 = No, 3 = Borderline for DIQ010, 7 = Refused, 9 = Don't know
    diagnosed_diabetes = DIQ010 == 1,
    borderline_diabetes = DIQ010 == 3,
    
    # DIQ050 / DIQ070 are often missing because of skip patterns.
    # For medication exclusion, exclude only confirmed medication users.
    insulin_use = DIQ050 == 1,
    diabetes_pill_use = DIQ070 == 1,
    diabetes_medication_use = (DIQ050 == 1) | (DIQ070 == 1),
    
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
    
    # Exclude only confirmed cases; keep skip/missing unless explicitly positive.
    flag_no_diagnosed_diabetes =
      !(diagnosed_diabetes %in% TRUE),
    
    flag_no_diabetes_medication =
      !(diabetes_medication_use %in% TRUE),
    
    flag_no_diagnosed_or_medication =
      !(diagnosed_diabetes %in% TRUE) &
      !(diabetes_medication_use %in% TRUE),
    
    flag_strict_non_diabetes =
      !(diagnosed_diabetes %in% TRUE) &
      !(diabetes_medication_use %in% TRUE) &
      !(biochemical_diabetes %in% TRUE),
    
    flag_strict_normoglycemia =
      !(diagnosed_diabetes %in% TRUE) &
      !(borderline_diabetes %in% TRUE) &
      !(diabetes_medication_use %in% TRUE) &
      !(biochemical_prediabetes_or_diabetes %in% TRUE)
  )

write_rds(
  df_sens,
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset_with_DIQ050_DIQ070.rds")
)

write_csv(
  df_sens,
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset_with_DIQ050_DIQ070.csv")
)

# ------------------------------------------------------------
# 8. Sensitivity sample definitions
# ------------------------------------------------------------

sample_defs <- tibble::tribble(
  ~sample_id, ~sample_label, ~flag_var, ~primary_use,
  "full", "Full analytic sample", "flag_full", "Reference",
  "no_diagnosed", "Exclude diagnosed diabetes", "flag_no_diagnosed_diabetes", "Sensitivity",
  "no_medication", "Exclude antidiabetic medication users", "flag_no_diabetes_medication", "Medication sensitivity",
  "no_diagnosed_or_med", "Exclude diagnosed diabetes or medication users", "flag_no_diagnosed_or_medication", "Primary sensitivity",
  "strict_non_diabetes", "Exclude diagnosed/medication/biochemical diabetes", "flag_strict_non_diabetes", "Strict sensitivity",
  "strict_normoglycemia", "Strict normoglycemia only", "flag_strict_normoglycemia", "Exploratory"
)

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
# 9. Survey design and model specs
# ------------------------------------------------------------

if ("WTSB6YR_MAIN" %in% names(df_sens)) {
  weight_var <- "WTSB6YR_MAIN"
} else if ("WTSB6YR_FAST" %in% names(df_sens)) {
  weight_var <- "WTSB6YR_FAST"
} else if ("WTSAF6YR" %in% names(df_sens)) {
  weight_var <- "WTSAF6YR"
} else if ("WTSAF2YR" %in% names(df_sens)) {
  df_sens <- df_sens %>%
    mutate(WTSB6YR_DIAB_MED = WTSAF2YR / 3)
  weight_var <- "WTSB6YR_DIAB_MED"
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

if (nrow(outcome_map) == 0) stop("没有可用结局变量。")
if (nrow(exposure_map) == 0) stop("没有可用暴露变量。")

cat("\nOutcomes to be modeled:\n")
print(outcome_map)

cat("\nExposures to be modeled:\n")
print(exposure_map)

# ------------------------------------------------------------
# 10. Model runner
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
# 11. Run all sensitivity models
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
# 12. Compare with full sample
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
    robustness_decision = case_when(
      sample_id == "full" ~ "Reference",
      same_direction_as_main == TRUE & q_value < 0.05 & beta > 0 ~ "FDR robust positive",
      same_direction_as_main == TRUE & p_value < 0.05 & beta > 0 ~ "Nominal robust positive",
      same_direction_as_main == TRUE & beta > 0 ~ "Directionally consistent",
      same_direction_as_main == FALSE ~ "Direction changed",
      TRUE ~ "Unclear"
    )
  )

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

medication_sensitivity_summary <- key_results %>%
  filter(sample_label == "Exclude antidiabetic medication users")

strict_sensitivity_summary <- key_results %>%
  filter(sample_label == "Exclude diagnosed/medication/biochemical diabetes")

# ------------------------------------------------------------
# 13. Forest plot
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
    file.path(fig_dir, "diabetes_medication_exclusion_forest_WITH_DIQ050_DIQ070_2013_2018.png"),
    p_forest,
    width = 15,
    height = 10,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "diabetes_medication_exclusion_forest_WITH_DIQ050_DIQ070_2013_2018.pdf"),
    p_forest,
    width = 15,
    height = 10
  )
  
  ggsave(
    file.path(fig_dir, "diabetes_medication_exclusion_forest_WITH_DIQ050_DIQ070_2013_2018.tiff"),
    p_forest,
    width = 15,
    height = 10,
    dpi = 600,
    compression = "lzw"
  )
}

# ------------------------------------------------------------
# 14. Robustness matrix
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
    file.path(fig_dir, "diabetes_medication_exclusion_robustness_matrix_WITH_DIQ050_DIQ070_2013_2018.png"),
    p_matrix,
    width = 13,
    height = 9,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "diabetes_medication_exclusion_robustness_matrix_WITH_DIQ050_DIQ070_2013_2018.pdf"),
    p_matrix,
    width = 13,
    height = 9
  )
}

# ------------------------------------------------------------
# 15. Export results
# ------------------------------------------------------------

write_xlsx(
  list(
    DIQ_download_check = diq_check,
    DIQ_merge_check = merge_check,
    sample_counts = sample_counts,
    all_sensitivity_results = sensitivity_compared,
    key_results = key_results,
    medication_sensitivity = medication_sensitivity_summary,
    primary_sensitivity = primary_sensitivity_summary,
    strict_sensitivity = strict_sensitivity_summary,
    robustness_matrix_data = robustness_matrix
  ),
  file.path(result_dir, "diabetes_medication_exclusion_sensitivity_WITH_DIQ050_DIQ070_2013_2018.xlsx")
)

write_csv(
  sensitivity_compared,
  file.path(result_dir, "diabetes_medication_exclusion_sensitivity_WITH_DIQ050_DIQ070_2013_2018.csv")
)

write_csv(
  key_results,
  file.path(result_dir, "diabetes_medication_exclusion_key_results_WITH_DIQ050_DIQ070_2013_2018.csv")
)

cat("\nDIQ050 / DIQ070 merge and diabetes-medication sensitivity analysis completed successfully.\n")
cat("Merged dataset saved to:\n")
cat(file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset_with_DIQmed.rds"), "\n")
cat(file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset_with_DIQ050_DIQ070.rds"), "\n")
cat("Results saved to:\n")
cat(file.path(result_dir, "diabetes_medication_exclusion_sensitivity_WITH_DIQ050_DIQ070_2013_2018.xlsx"), "\n")
cat("Figures saved to:\n")
cat(file.path(fig_dir, "diabetes_medication_exclusion_forest_WITH_DIQ050_DIQ070_2013_2018.png"), "\n")
cat(file.path(fig_dir, "diabetes_medication_exclusion_robustness_matrix_WITH_DIQ050_DIQ070_2013_2018.png"), "\n")