# ============================================================
# NHANES 2003-2018 / 2013-2018
# 52_linked_mortality_analysis_2003_2018.R
#
# Linked mortality analysis using NHANES public-use LMF 2019
# Purpose:
#   Explore whether DEHP exposure profiles are associated with
#   all-cause and cause-specific mortality.
#
# Interpretation:
#   Supplementary / exploratory long-term outcome analysis.
# ============================================================

# ------------------------------------------------------------
# 0. Packages
# ------------------------------------------------------------

required_packages <- c(
  "dplyr", "tidyr", "purrr", "readr", "tibble",
  "survey", "survival", "ggplot2", "writexl", "stringr"
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
library(survival)
library(ggplot2)
library(writexl)
library(stringr)

options(survey.lonely.psu = "adjust")
options(timeout = 1000)

# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project"

data_dir   <- file.path(project_dir, "data")
raw_dir    <- file.path(data_dir, "raw_mortality")
output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir    <- file.path(result_dir, "figures_mortality")

dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 2. Helper functions
# ------------------------------------------------------------

download_if_missing <- function(url, destfile, min_size_kb = 20, max_attempts = 5) {
  dir.create(dirname(destfile), showWarnings = FALSE, recursive = TRUE)
  
  file_ok <- function(path) {
    file.exists(path) && file.info(path)$size > min_size_kb * 1024
  }
  
  if (file_ok(destfile)) {
    message("File exists: ", destfile)
    return(invisible(TRUE))
  }
  
  if (file.exists(destfile)) {
    message("Existing file appears incomplete; deleting: ", destfile)
    unlink(destfile)
  }
  
  for (i in seq_len(max_attempts)) {
    message("Downloading attempt ", i, "/", max_attempts, ": ", url)
    
    ok <- tryCatch({
      download.file(
        url = url,
        destfile = destfile,
        mode = "wb",
        method = "libcurl",
        quiet = FALSE
      )
      TRUE
    }, error = function(e) {
      message("Download failed: ", e$message)
      FALSE
    })
    
    if (ok && file_ok(destfile)) {
      return(invisible(TRUE))
    }
    
    if (file.exists(destfile)) unlink(destfile)
    Sys.sleep(2)
  }
  
  stop("下载失败：", url)
}

safe_positive <- function(x) {
  x <- as.numeric(x)
  ifelse(is.finite(x) & x > 0, x, NA_real_)
}

clean_num <- function(x) {
  x <- stringr::str_trim(as.character(x))
  x[x == ""] <- NA_character_
  suppressWarnings(as.numeric(x))
}

clean_ucod <- function(x) {
  x <- stringr::str_trim(as.character(x))
  x[x == ""] <- NA_character_
  ifelse(
    is.na(x),
    NA_character_,
    stringr::str_pad(x, width = 3, side = "left", pad = "0")
  )
}

format_p <- function(p) {
  ifelse(
    is.na(p),
    NA_character_,
    ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

format_hr <- function(hr, low, high) {
  ifelse(
    is.na(hr),
    NA_character_,
    sprintf("%.2f (%.2f, %.2f)", hr, low, high)
  )
}

pick_var <- function(dat, candidates) {
  nms <- names(dat)
  hit <- nms[tolower(nms) %in% tolower(candidates)]
  if (length(hit) > 0) return(hit[1])
  NA_character_
}

make_log_component <- function(dat, label, candidates) {
  var <- pick_var(dat, candidates)
  
  if (is.na(var)) {
    return(list(data = dat, var = NA_character_, raw_var = NA_character_))
  }
  
  if (str_detect(tolower(var), "^ln_")) {
    return(list(data = dat, var = var, raw_var = var))
  }
  
  new_var <- paste0("ln_", label, "_mort")
  dat[[new_var]] <- log(safe_positive(dat[[var]]))
  
  list(data = dat, var = new_var, raw_var = var)
}

term_to_var <- function(term) {
  term <- as.character(term)
  
  out <- term
  is_factor_term <- stringr::str_detect(term, "^factor\\(")
  
  out[is_factor_term] <- stringr::str_replace_all(
    out[is_factor_term],
    "^factor\\(|\\)$",
    ""
  )
  
  out
}

drop_unusable_terms <- function(dat, terms) {
  usable <- c()
  
  for (term in terms) {
    var_name <- term_to_var(term)
    
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

# ------------------------------------------------------------
# 3. Read analytic dataset
# ------------------------------------------------------------

data_candidates <- c(
  file.path(output_dir, "NHANES_2003_2018_DEHP_only_master.rds"),
  file.path(output_dir, "NHANES_2003_2018_DEHP_only_master.csv"),
  file.path(output_dir, "NHANES_2003_2018_DEHP_only_master_analysis.rds"),
  file.path(output_dir, "NHANES_2003_2018_mortality_candidate_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_source_oriented_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset_with_DIQ050_DIQ070.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset_with_DIQmed.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]

if (length(data_file) == 0 || is.na(data_file)) {
  stop("找不到可用于 mortality analysis 的分析数据。请检查 output 文件夹。")
}

if (str_detect(data_file, "\\.csv$")) {
  df <- read_csv(data_file, show_col_types = FALSE) %>% as_tibble()
} else {
  df <- readRDS(data_file) %>% as_tibble()
}

if (!("SEQN" %in% names(df))) {
  stop("分析数据缺少 SEQN，无法合并 linked mortality file。")
}

cat("Using analytic dataset:\n", data_file, "\n")
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")

# ------------------------------------------------------------
# 4. Harmonize variables
# ------------------------------------------------------------

if (!("cycle" %in% names(df)) && "SDDSRVYR" %in% names(df)) {
  df <- df %>% mutate(cycle = SDDSRVYR)
}

if (!("RIDRETH3" %in% names(df)) && "RIDRETH1" %in% names(df)) {
  df <- df %>% mutate(RIDRETH3 = RIDRETH1)
}

if (!("ln_URXUCR" %in% names(df)) && "URXUCR" %in% names(df)) {
  df <- df %>% mutate(ln_URXUCR = log(safe_positive(URXUCR)))
}

# ------------------------------------------------------------
# 5. Ensure DEHP exposure variables
# ------------------------------------------------------------

component_specs <- list(
  MECPP = c("ln_MECPP", "ln_URXECP", "MECPP_ln", "URXECP_ln", "MECPP", "URXECP"),
  MEHHP = c("ln_MEHHP", "ln_URXMHH", "MEHHP_ln", "URXMHH_ln", "MEHHP", "URXMHH"),
  MEOHP = c("ln_MEOHP", "ln_URXMOH", "MEOHP_ln", "URXMOH_ln", "MEOHP", "URXMOH"),
  MEHP  = c("ln_MEHP",  "ln_URXMHP", "MEHP_ln",  "URXMHP_ln", "MEHP",  "URXMHP")
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

cat("\nDEHP component map:\n")
print(component_map)

get_component_var <- function(comp) {
  component_map %>%
    filter(component == comp) %>%
    pull(selected_var) %>%
    first()
}

ln_mehp  <- get_component_var("MEHP")
ln_mehhp <- get_component_var("MEHHP")
ln_meohp <- get_component_var("MEOHP")
ln_mecpp <- get_component_var("MECPP")

has_all_dehp <- all(!is.na(c(ln_mehp, ln_mehhp, ln_meohp, ln_mecpp)))

if (!has_all_dehp) {
  warning("未识别完整 MEHP/MEHHP/MEOHP/MECPP，部分 DEHP derived indicators 可能不可用。")
}

if (!("ln_Sigma_DEHP" %in% names(df)) && has_all_dehp) {
  df <- df %>%
    mutate(
      Sigma_DEHP_mort =
        exp(.data[[ln_mehp]]) +
        exp(.data[[ln_mehhp]]) +
        exp(.data[[ln_meohp]]) +
        exp(.data[[ln_mecpp]]),
      ln_Sigma_DEHP = log(safe_positive(Sigma_DEHP_mort))
    )
}

if (!("pct_oxidative" %in% names(df)) && has_all_dehp) {
  df <- df %>%
    mutate(
      oxidative_sum_mort =
        exp(.data[[ln_mehhp]]) +
        exp(.data[[ln_meohp]]) +
        exp(.data[[ln_mecpp]]),
      primary_sum_mort = exp(.data[[ln_mehp]]),
      pct_oxidative =
        oxidative_sum_mort /
        (oxidative_sum_mort + primary_sum_mort) * 100
    )
}

if (!("pct_oxidative_10" %in% names(df)) && "pct_oxidative" %in% names(df)) {
  df <- df %>% mutate(pct_oxidative_10 = pct_oxidative / 10)
}

if (!("ln_oxidative_MEHP_ratio" %in% names(df)) && has_all_dehp) {
  df <- df %>%
    mutate(
      oxidative_sum_ratio_mort =
        exp(.data[[ln_mehhp]]) +
        exp(.data[[ln_meohp]]) +
        exp(.data[[ln_mecpp]]),
      primary_sum_ratio_mort = exp(.data[[ln_mehp]]),
      ln_oxidative_MEHP_ratio =
        log(safe_positive(oxidative_sum_ratio_mort / primary_sum_ratio_mort))
    )
}

if (!("ilr_oxidative_vs_primary" %in% names(df)) && has_all_dehp) {
  df <- df %>%
    mutate(
      gm_oxidative_mort =
        exp((.data[[ln_mehhp]] + .data[[ln_meohp]] + .data[[ln_mecpp]]) / 3),
      ilr_oxidative_vs_primary =
        sqrt(3 / 4) *
        log(safe_positive(gm_oxidative_mort / exp(.data[[ln_mehp]])))
    )
}

# ------------------------------------------------------------
# 6. Download and read NHANES 2019 public-use LMF
# ------------------------------------------------------------

mort_cycles <- tibble::tribble(
  ~cycle_label, ~year_start, ~file_stub,
  "2003-2004", 2003, "NHANES_2003_2004_MORT_2019_PUBLIC.dat",
  "2005-2006", 2005, "NHANES_2005_2006_MORT_2019_PUBLIC.dat",
  "2007-2008", 2007, "NHANES_2007_2008_MORT_2019_PUBLIC.dat",
  "2009-2010", 2009, "NHANES_2009_2010_MORT_2019_PUBLIC.dat",
  "2011-2012", 2011, "NHANES_2011_2012_MORT_2019_PUBLIC.dat",
  "2013-2014", 2013, "NHANES_2013_2014_MORT_2019_PUBLIC.dat",
  "2015-2016", 2015, "NHANES_2015_2016_MORT_2019_PUBLIC.dat",
  "2017-2018", 2017, "NHANES_2017_2018_MORT_2019_PUBLIC.dat"
)

read_nhanes_mort_dat <- function(file_path, cycle_label, year_start) {
  readr::read_fwf(
    file = file_path,
    col_positions = readr::fwf_positions(
      start = c(1, 15, 16, 17, 20, 21, 43, 46),
      end   = c(6, 15, 16, 19, 20, 21, 45, 48),
      col_names = c(
        "SEQN", "ELIGSTAT", "MORTSTAT", "UCOD_LEADING",
        "DIABETES_MORT", "HYPERTEN_MORT",
        "PERMTH_INT", "PERMTH_EXM"
      )
    ),
    col_types = readr::cols(.default = readr::col_character()),
    trim_ws = TRUE,
    show_col_types = FALSE
  ) %>%
    mutate(
      SEQN = clean_num(SEQN),
      ELIGSTAT = clean_num(ELIGSTAT),
      MORTSTAT = clean_num(MORTSTAT),
      UCOD_LEADING = clean_ucod(UCOD_LEADING),
      DIABETES_MORT = clean_num(DIABETES_MORT),
      HYPERTEN_MORT = clean_num(HYPERTEN_MORT),
      PERMTH_INT = clean_num(PERMTH_INT),
      PERMTH_EXM = clean_num(PERMTH_EXM),
      mort_cycle_label = cycle_label,
      mort_cycle_start = year_start
    )
}

mort_all <- map_dfr(seq_len(nrow(mort_cycles)), function(i) {
  file_stub <- mort_cycles$file_stub[i]
  url <- paste0(
    "https://ftp.cdc.gov/pub/Health_Statistics/NCHS/datalinkage/linked_mortality/",
    file_stub
  )
  dest <- file.path(raw_dir, file_stub)
  
  download_if_missing(url, dest, min_size_kb = 50)
  
  read_nhanes_mort_dat(
    file_path = dest,
    cycle_label = mort_cycles$cycle_label[i],
    year_start = mort_cycles$year_start[i]
  )
})

cat("\nMortality rows:", nrow(mort_all), "\n")
print(mort_all %>% count(mort_cycle_label, ELIGSTAT, MORTSTAT))

# ------------------------------------------------------------
# 7. Merge mortality data and create survival outcomes
# ------------------------------------------------------------

df_mort <- df %>%
  left_join(mort_all, by = "SEQN") %>%
  mutate(
    mortality_eligible = ELIGSTAT == 1,
    followup_years_exm = PERMTH_EXM / 12,
    followup_years_int = PERMTH_INT / 12,
    
    death_allcause = case_when(
      MORTSTAT == 1 ~ 1,
      MORTSTAT == 0 ~ 0,
      TRUE ~ NA_real_
    ),
    
    death_cvd = case_when(
      MORTSTAT == 1 & UCOD_LEADING %in% c("001", "005") ~ 1,
      MORTSTAT == 1 ~ 0,
      MORTSTAT == 0 ~ 0,
      TRUE ~ NA_real_
    ),
    
    death_heart = case_when(
      MORTSTAT == 1 & UCOD_LEADING == "001" ~ 1,
      MORTSTAT == 1 ~ 0,
      MORTSTAT == 0 ~ 0,
      TRUE ~ NA_real_
    ),
    
    death_cancer = case_when(
      MORTSTAT == 1 & UCOD_LEADING == "002" ~ 1,
      MORTSTAT == 1 ~ 0,
      MORTSTAT == 0 ~ 0,
      TRUE ~ NA_real_
    ),
    
    death_diabetes = case_when(
      MORTSTAT == 1 & UCOD_LEADING == "007" ~ 1,
      MORTSTAT == 1 ~ 0,
      MORTSTAT == 0 ~ 0,
      TRUE ~ NA_real_
    )
  )

write_rds(
  df_mort,
  file.path(output_dir, "NHANES_linked_mortality_analysis_dataset_2003_2018.rds")
)

write_csv(
  df_mort,
  file.path(output_dir, "NHANES_linked_mortality_analysis_dataset_2003_2018.csv")
)

# ------------------------------------------------------------
# 8. Survey weight selection
# ------------------------------------------------------------

candidate_weights <- c(
  "WTSB16YR_MAIN",
  "WTSB16YR",
  "WTSAF16YR",
  "WTSPH16YR",
  "WTSB12YR_MAIN",
  "WTSB6YR_MAIN",
  "WTSAF6YR",
  "WTMEC16YR",
  "WTMEC6YR",
  "WTSB2YR",
  "WTSAF2YR",
  "WTSPH2YR",
  "WTMEC2YR"
)

weight_candidates_available <- candidate_weights[candidate_weights %in% names(df_mort)]
weight_var <- weight_candidates_available[1]

if (length(weight_var) == 0 || is.na(weight_var)) {
  stop("找不到可用的 NHANES survey weight。")
}

if (weight_var %in% c("WTSB2YR", "WTSAF2YR", "WTSPH2YR", "WTMEC2YR")) {
  n_cycles <- df_mort %>%
    filter(!is.na(cycle)) %>%
    distinct(cycle) %>%
    nrow()
  
  if (!is.finite(n_cycles) || n_cycles <= 0) {
    n_cycles <- 3
  }
  
  df_mort <- df_mort %>%
    mutate(WT_MORT_MULTI = .data[[weight_var]] / n_cycles)
  
  weight_var <- "WT_MORT_MULTI"
}

cat("\nUsing survey weight:", weight_var, "\n")

required_design <- c("SDMVPSU", "SDMVSTRA", weight_var)
missing_design <- setdiff(required_design, names(df_mort))

if (length(missing_design) > 0) {
  stop("缺少复杂抽样设计变量：", paste(missing_design, collapse = ", "))
}

# ------------------------------------------------------------
# 9. Define exposures, outcomes, and covariates
# ------------------------------------------------------------

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~include_creatinine, ~include_total_burden,
  "ln_Sigma_DEHP", "lnΣDEHP", TRUE, FALSE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE, FALSE,
  "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]", TRUE, TRUE,
  "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance", TRUE, TRUE
) %>%
  filter(exposure %in% names(df_mort))

if (nrow(exposure_map) == 0) {
  stop("没有可用 DEHP exposure variables。")
}

mortality_outcome_map <- tibble::tribble(
  ~event_var, ~outcome_label, ~outcome_role,
  "death_allcause", "All-cause mortality", "Primary",
  "death_cvd", "Cardiovascular mortality", "Exploratory",
  "death_heart", "Heart-disease mortality", "Exploratory",
  "death_cancer", "Cancer mortality", "Exploratory",
  "death_diabetes", "Diabetes mortality", "Exploratory"
)

candidate_base_covars <- c(
  "RIDAGEYR",
  "factor(RIAGENDR)",
  "factor(RIDRETH3)",
  "INDFMPIR",
  "factor(DMDEDUC2)",
  "DR1TKCAL",
  "factor(cycle)"
)

base_covars <- candidate_base_covars[
  term_to_var(candidate_base_covars) %in% names(df_mort)
]

base_vars <- unique(term_to_var(base_covars))
base_vars <- c(base_vars, "SDMVPSU", "SDMVSTRA", weight_var)

cat("\nBase covariates used:\n")
print(base_covars)

cat("\nExposures:\n")
print(exposure_map)

# ------------------------------------------------------------
# 10. Event count diagnostics
# ------------------------------------------------------------

count_events_for_pair <- function(event_var_i, exposure_i) {
  if (!(event_var_i %in% names(df_mort))) {
    return(tibble(
      analytic_n = NA_integer_,
      event_count = NA_integer_,
      note = paste0("Missing event variable: ", event_var_i)
    ))
  }
  
  if (!(exposure_i %in% names(df_mort))) {
    return(tibble(
      analytic_n = NA_integer_,
      event_count = NA_integer_,
      note = paste0("Missing exposure variable: ", exposure_i)
    ))
  }
  
  d <- df_mort %>%
    filter(
      RIDAGEYR >= 20,
      mortality_eligible,
      !is.na(followup_years_exm),
      followup_years_exm > 0,
      !is.na(.data[[event_var_i]]),
      !is.na(.data[[exposure_i]])
    )
  
  tibble(
    analytic_n = nrow(d),
    event_count = sum(d[[event_var_i]] == 1, na.rm = TRUE),
    note = "OK"
  )
}

mortality_feasibility <- expand_grid(
  event_var = mortality_outcome_map$event_var,
  exposure = exposure_map$exposure
) %>%
  mutate(
    count_tbl = map2(event_var, exposure, count_events_for_pair)
  ) %>%
  unnest(count_tbl) %>%
  left_join(mortality_outcome_map, by = "event_var") %>%
  left_join(exposure_map, by = "exposure") %>%
  mutate(
    feasibility = case_when(
      is.na(event_count) ~ "Unavailable",
      event_count >= 50 ~ "Adequate for primary/supplementary Cox model",
      event_count >= 20 ~ "Exploratory only",
      TRUE ~ "Too sparse; descriptive only"
    )
  ) %>%
  select(
    outcome_label,
    outcome_role,
    event_var,
    exposure_label,
    exposure,
    analytic_n,
    event_count,
    feasibility,
    note
  )

cat("\nMortality feasibility:\n")
print(mortality_feasibility)

# ------------------------------------------------------------
# 11. Survey Cox model runner
# ------------------------------------------------------------

extract_svycox_result <- function(fit, target_terms, metadata) {
  ct <- summary(fit)$coefficients
  ci <- tryCatch(confint(fit), error = function(e) NULL)
  
  if (is.null(dim(ct))) {
    ct <- matrix(ct, nrow = 1)
  }
  
  ct_colnames <- colnames(ct)
  coef_names <- rownames(ct)
  
  if (is.null(ct_colnames)) {
    stop("summary(fit)$coefficients has no column names.")
  }
  
  ct_colnames_lower <- tolower(ct_colnames)
  
  coef_col <- ct_colnames[ct_colnames_lower %in% c("coef", "coefficient", "estimate")]
  if (length(coef_col) == 0) {
    coef_col <- ct_colnames[1]
  } else {
    coef_col <- coef_col[1]
  }
  
  se_col <- ct_colnames[
    str_detect(ct_colnames_lower, "se") |
      str_detect(ct_colnames_lower, "std")
  ]
  
  if (length(se_col) == 0) {
    se_col <- NA_character_
  } else {
    robust_se_col <- se_col[str_detect(tolower(se_col), "robust")]
    if (length(robust_se_col) > 0) {
      se_col <- robust_se_col[1]
    } else {
      se_col <- se_col[1]
    }
  }
  
  p_col <- ct_colnames[
    str_detect(ct_colnames, "^Pr\\(") |
      str_detect(ct_colnames_lower, "p.value") |
      str_detect(ct_colnames_lower, "p_value") |
      str_detect(ct_colnames_lower, "pvalue")
  ]
  
  if (length(p_col) == 0) {
    p_col <- NA_character_
  } else {
    p_col <- p_col[1]
  }
  
  target_terms <- target_terms[target_terms %in% coef_names]
  
  if (length(target_terms) == 0) {
    return(as_tibble(metadata) %>%
             mutate(
               term = NA_character_,
               beta = NA_real_,
               se = NA_real_,
               hr = NA_real_,
               hr_low = NA_real_,
               hr_high = NA_real_,
               p_value = NA_real_,
               result = "Exposure coefficient unavailable"
             ))
  }
  
  map_dfr(target_terms, function(term_i) {
    beta <- as.numeric(ct[term_i, coef_col])
    
    se <- if (!is.na(se_col) && se_col %in% ct_colnames) {
      as.numeric(ct[term_i, se_col])
    } else {
      NA_real_
    }
    
    p <- if (!is.na(p_col) && p_col %in% ct_colnames) {
      as.numeric(ct[term_i, p_col])
    } else {
      NA_real_
    }
    
    if (!is.null(ci) && term_i %in% rownames(ci)) {
      low <- as.numeric(ci[term_i, 1])
      high <- as.numeric(ci[term_i, 2])
    } else if (!is.na(se)) {
      low <- beta - 1.96 * se
      high <- beta + 1.96 * se
    } else {
      low <- NA_real_
      high <- NA_real_
    }
    
    as_tibble(metadata) %>%
      mutate(
        term = term_i,
        beta = beta,
        se = se,
        hr = exp(beta),
        hr_low = exp(low),
        hr_high = exp(high),
        p_value = p,
        result = case_when(
          is.na(p) ~ "Unavailable",
          p < 0.05 & beta > 0 ~ "Nominal positive mortality association",
          p < 0.05 & beta < 0 ~ "Nominal inverse mortality association",
          beta > 0 ~ "Positive direction",
          beta < 0 ~ "Inverse direction",
          TRUE ~ "Weak/no association"
        )
      )
  })
}

run_svy_cox <- function(event_var,
                        outcome_label,
                        outcome_role,
                        exposure,
                        exposure_label,
                        include_creatinine,
                        include_total_burden,
                        model_type = "continuous") {
  
  covars <- base_covars
  needed <- c(
    event_var,
    "followup_years_exm",
    exposure,
    base_vars,
    "mortality_eligible"
  )
  
  if (include_creatinine && "ln_URXUCR" %in% names(df_mort)) {
    covars <- c(covars, "ln_URXUCR")
    needed <- c(needed, "ln_URXUCR")
  }
  
  if (include_total_burden &&
      "ln_Sigma_DEHP" %in% names(df_mort) &&
      exposure != "ln_Sigma_DEHP") {
    covars <- c(covars, "ln_Sigma_DEHP")
    needed <- c(needed, "ln_Sigma_DEHP")
  }
  
  missing_needed <- setdiff(unique(needed), names(df_mort))
  
  base_metadata <- tibble(
    outcome_label = outcome_label,
    outcome_role = outcome_role,
    event_var = event_var,
    exposure_label = exposure_label,
    exposure = exposure,
    model_type = model_type
  )
  
  if (length(missing_needed) > 0) {
    return(base_metadata %>%
             mutate(
               n = NA_integer_,
               events = NA_integer_,
               term = exposure,
               beta = NA_real_,
               se = NA_real_,
               hr = NA_real_,
               hr_low = NA_real_,
               hr_high = NA_real_,
               p_value = NA_real_,
               result = paste0("Missing variables: ", paste(missing_needed, collapse = ", "))
             ))
  }
  
  d <- df_mort %>%
    filter(
      RIDAGEYR >= 20,
      mortality_eligible,
      !is.na(followup_years_exm),
      followup_years_exm > 0
    ) %>%
    select(all_of(unique(needed))) %>%
    drop_na()
  
  events <- sum(d[[event_var]] == 1, na.rm = TRUE)
  
  metadata <- base_metadata %>%
    mutate(
      n = nrow(d),
      events = events
    )
  
  if (nrow(d) < 300) {
    return(metadata %>%
             mutate(
               term = exposure,
               beta = NA_real_,
               se = NA_real_,
               hr = NA_real_,
               hr_low = NA_real_,
               hr_high = NA_real_,
               p_value = NA_real_,
               result = "Insufficient sample"
             ))
  }
  
  if (events < 20) {
    return(metadata %>%
             mutate(
               term = exposure,
               beta = NA_real_,
               se = NA_real_,
               hr = NA_real_,
               hr_low = NA_real_,
               hr_high = NA_real_,
               p_value = NA_real_,
               result = "Too few events for stable Cox model"
             ))
  }
  
  if (model_type == "quartile") {
    q <- quantile(
      d[[exposure]],
      probs = c(0, 0.25, 0.50, 0.75, 1),
      na.rm = TRUE
    )
    
    if (length(unique(q)) < 5) {
      return(metadata %>%
               mutate(
                 term = exposure,
                 beta = NA_real_,
                 se = NA_real_,
                 hr = NA_real_,
                 hr_low = NA_real_,
                 hr_high = NA_real_,
                 p_value = NA_real_,
                 result = "Cannot create quartiles"
               ))
    }
    
    d <- d %>%
      mutate(
        exposure_q = cut(
          .data[[exposure]],
          breaks = q,
          include.lowest = TRUE,
          labels = c("Q1", "Q2", "Q3", "Q4")
        )
      )
    
    exposure_term <- "factor(exposure_q)"
  } else {
    exposure_term <- exposure
  }
  
  covars_final <- drop_unusable_terms(d, covars)
  
  if (length(covars_final) == 0) {
    rhs <- exposure_term
  } else {
    rhs <- paste(c(exposure_term, covars_final), collapse = " + ")
  }
  
  f <- as.formula(
    paste0(
      "Surv(followup_years_exm, ", event_var, ") ~ ",
      rhs
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
    svycoxph(f, design = des),
    error = function(e) {
      message("svycoxph failed: ", outcome_label, " | ", exposure_label, " | ", model_type)
      message(e$message)
      NULL
    }
  )
  
  if (is.null(fit)) {
    return(metadata %>%
             mutate(
               term = exposure,
               beta = NA_real_,
               se = NA_real_,
               hr = NA_real_,
               hr_low = NA_real_,
               hr_high = NA_real_,
               p_value = NA_real_,
               result = "Model failed"
             ))
  }
  
  coef_names <- rownames(summary(fit)$coefficients)
  
  if (model_type == "continuous") {
    target_terms <- exposure
  } else {
    target_terms <- coef_names[str_detect(coef_names, "^factor\\(exposure_q\\)")]
  }
  
  extract_svycox_result(
    fit = fit,
    target_terms = target_terms,
    metadata = metadata
  )
}

# ------------------------------------------------------------
# 12. Run mortality models
# ------------------------------------------------------------

continuous_results <- expand_grid(
  outcome_row = seq_len(nrow(mortality_outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = map2(
      outcome_row,
      exposure_row,
      function(i, j) {
        run_svy_cox(
          event_var = mortality_outcome_map$event_var[i],
          outcome_label = mortality_outcome_map$outcome_label[i],
          outcome_role = mortality_outcome_map$outcome_role[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          include_creatinine = exposure_map$include_creatinine[j],
          include_total_burden = exposure_map$include_total_burden[j],
          model_type = "continuous"
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
    hr_CI = format_hr(hr, hr_low, hr_high),
    p_value_fmt = format_p(p_value),
    q_value_fmt = format_p(q_value)
  )

quartile_results <- expand_grid(
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = map(
      exposure_row,
      function(j) {
        run_svy_cox(
          event_var = "death_allcause",
          outcome_label = "All-cause mortality",
          outcome_role = "Primary",
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          include_creatinine = exposure_map$include_creatinine[j],
          include_total_burden = exposure_map$include_total_burden[j],
          model_type = "quartile"
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl) %>%
  group_by(exposure_label) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    hr_CI = format_hr(hr, hr_low, hr_high),
    p_value_fmt = format_p(p_value),
    q_value_fmt = format_p(q_value)
  )

# ------------------------------------------------------------
# 13. PH diagnostic, exploratory
# ------------------------------------------------------------

run_ph_diagnostic <- function(event_var, exposure, include_creatinine, include_total_burden) {
  covars <- base_covars
  needed <- c(event_var, "followup_years_exm", exposure, base_vars, "mortality_eligible")
  
  if (include_creatinine && "ln_URXUCR" %in% names(df_mort)) {
    covars <- c(covars, "ln_URXUCR")
    needed <- c(needed, "ln_URXUCR")
  }
  
  if (include_total_burden &&
      "ln_Sigma_DEHP" %in% names(df_mort) &&
      exposure != "ln_Sigma_DEHP") {
    covars <- c(covars, "ln_Sigma_DEHP")
    needed <- c(needed, "ln_Sigma_DEHP")
  }
  
  d <- df_mort %>%
    filter(
      RIDAGEYR >= 20,
      mortality_eligible,
      !is.na(followup_years_exm),
      followup_years_exm > 0
    ) %>%
    select(all_of(unique(needed))) %>%
    drop_na()
  
  if (nrow(d) < 300 || sum(d[[event_var]] == 1, na.rm = TRUE) < 20) {
    return(tibble(
      event_var = event_var,
      exposure = exposure,
      ph_global_p = NA_real_,
      ph_exposure_p = NA_real_,
      note = "Insufficient sample/events"
    ))
  }
  
  covars_final <- drop_unusable_terms(d, covars)
  
  rhs <- paste(c(exposure, covars_final, "cluster(SDMVPSU)"), collapse = " + ")
  
  f <- as.formula(
    paste0(
      "Surv(followup_years_exm, ", event_var, ") ~ ",
      rhs
    )
  )
  
  fit <- tryCatch(
    coxph(f, data = d, weights = d[[weight_var]], robust = TRUE),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble(
      event_var = event_var,
      exposure = exposure,
      ph_global_p = NA_real_,
      ph_exposure_p = NA_real_,
      note = "coxph failed"
    ))
  }
  
  zph <- tryCatch(cox.zph(fit), error = function(e) NULL)
  
  if (is.null(zph)) {
    return(tibble(
      event_var = event_var,
      exposure = exposure,
      ph_global_p = NA_real_,
      ph_exposure_p = NA_real_,
      note = "cox.zph failed"
    ))
  }
  
  ztab <- as.data.frame(zph$table) %>%
    rownames_to_column("term")
  
  tibble(
    event_var = event_var,
    exposure = exposure,
    ph_global_p = ztab %>% filter(term == "GLOBAL") %>% pull(p) %>% first(),
    ph_exposure_p = ztab %>% filter(term == exposure) %>% pull(p) %>% first(),
    note = "Exploratory PH diagnostic based on coxph"
  )
}

ph_diagnostics <- expand_grid(
  event_var = c("death_allcause", "death_cvd"),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result_tbl = map2(
      event_var,
      exposure_row,
      function(ev, j) {
        run_ph_diagnostic(
          event_var = ev,
          exposure = exposure_map$exposure[j],
          include_creatinine = exposure_map$include_creatinine[j],
          include_total_burden = exposure_map$include_total_burden[j]
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl) %>%
  left_join(exposure_map, by = "exposure")

# ------------------------------------------------------------
# 14. Plots
# ------------------------------------------------------------

plot_df <- continuous_results %>%
  filter(
    outcome_label %in% c("All-cause mortality", "Cardiovascular mortality"),
    !is.na(hr),
    model_type == "continuous"
  ) %>%
  mutate(
    outcome_label = factor(
      outcome_label,
      levels = c("All-cause mortality", "Cardiovascular mortality")
    ),
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

if (nrow(plot_df) > 0) {
  p_forest <- ggplot(plot_df, aes(x = hr, y = exposure_label)) +
    geom_vline(xintercept = 1, linetype = "dashed", linewidth = 0.35) +
    geom_errorbarh(
      aes(xmin = hr_low, xmax = hr_high),
      height = 0.18,
      linewidth = 0.45
    ) +
    geom_point(size = 2.4) +
    geom_text(
      aes(label = sig_label),
      nudge_y = 0.22,
      size = 3.5,
      fontface = "bold"
    ) +
    facet_wrap(~ outcome_label, scales = "free_x") +
    scale_x_log10() +
    labs(
      title = "Linked mortality analysis of DEHP exposure profiles",
      subtitle = "Survey-weighted Cox models using NHANES public-use linked mortality follow-up through 2019",
      x = "Hazard ratio",
      y = NULL,
      caption = paste0(
        "* nominal P < 0.05; ** FDR q < 0.05. ",
        "Models adjusted for age, sex, race/ethnicity, income, education, energy intake, urinary creatinine where applicable, and cycle."
      )
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold"),
      plot.caption = element_text(size = 8.2, hjust = 0)
    )
  
  print(p_forest)
  
  ggsave(
    file.path(fig_dir, "DEHP_linked_mortality_forest_2003_2018.png"),
    p_forest,
    width = 11,
    height = 6,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "DEHP_linked_mortality_forest_2003_2018.pdf"),
    p_forest,
    width = 11,
    height = 6
  )
}

quartile_plot_df <- quartile_results %>%
  filter(!is.na(hr)) %>%
  mutate(
    quartile = str_replace(term, "factor\\(exposure_q\\)", ""),
    quartile = factor(quartile, levels = c("Q2", "Q3", "Q4")),
    exposure_label = factor(
      exposure_label,
      levels = c(
        "lnΣDEHP",
        "%Oxidative per 10 percentage points",
        "ln[(MEHHP+MEOHP+MECPP)/MEHP]",
        "ILR oxidative-vs-primary balance"
      )
    )
  )

if (nrow(quartile_plot_df) > 0) {
  p_quartile <- ggplot(quartile_plot_df, aes(x = quartile, y = hr)) +
    geom_hline(yintercept = 1, linetype = "dashed", linewidth = 0.35) +
    geom_errorbar(
      aes(ymin = hr_low, ymax = hr_high),
      width = 0.15,
      linewidth = 0.45
    ) +
    geom_point(size = 2.2) +
    facet_wrap(~ exposure_label, scales = "free_y") +
    scale_y_log10() +
    labs(
      title = "Quartile associations of DEHP exposure profiles with all-cause mortality",
      subtitle = "Reference group: Q1",
      x = "Exposure quartile",
      y = "Hazard ratio"
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold")
    )
  
  print(p_quartile)
  
  ggsave(
    file.path(fig_dir, "DEHP_allcause_mortality_quartile_2003_2018.png"),
    p_quartile,
    width = 11,
    height = 7,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "DEHP_allcause_mortality_quartile_2003_2018.pdf"),
    p_quartile,
    width = 11,
    height = 7
  )
}

# ------------------------------------------------------------
# 15. Export results
# ------------------------------------------------------------

mortality_sample_summary <- df_mort %>%
  filter(
    RIDAGEYR >= 20,
    mortality_eligible,
    !is.na(followup_years_exm),
    followup_years_exm > 0
  ) %>%
  summarise(
    analytic_n_linked = n(),
    allcause_deaths = sum(death_allcause == 1, na.rm = TRUE),
    cvd_deaths = sum(death_cvd == 1, na.rm = TRUE),
    heart_deaths = sum(death_heart == 1, na.rm = TRUE),
    cancer_deaths = sum(death_cancer == 1, na.rm = TRUE),
    diabetes_deaths = sum(death_diabetes == 1, na.rm = TRUE),
    median_followup_years = median(followup_years_exm, na.rm = TRUE),
    max_followup_years = max(followup_years_exm, na.rm = TRUE)
  )

write_xlsx(
  list(
    mortality_sample_summary = mortality_sample_summary,
    mortality_feasibility = mortality_feasibility,
    component_variable_map = component_map,
    exposure_map = exposure_map,
    base_covariates_used = tibble(base_covariate = base_covars),
    continuous_cox_results = continuous_results,
    allcause_quartile_results = quartile_results,
    ph_diagnostics = ph_diagnostics,
    mortality_file_cycle_counts = mort_all %>% count(mort_cycle_label, ELIGSTAT, MORTSTAT)
  ),
  file.path(result_dir, "linked_mortality_DEHP_results_2003_2018.xlsx")
)

write_csv(
  continuous_results,
  file.path(result_dir, "linked_mortality_DEHP_continuous_cox_results_2003_2018.csv")
)

write_csv(
  quartile_results,
  file.path(result_dir, "linked_mortality_DEHP_allcause_quartile_results_2003_2018.csv")
)

cat("\nLinked mortality analysis completed successfully.\n")
cat("Results saved to:\n")
cat(file.path(result_dir, "linked_mortality_DEHP_results_2003_2018.xlsx"), "\n")
cat("Figures saved to:\n")
cat(file.path(fig_dir, "DEHP_linked_mortality_forest_2003_2018.png"), "\n")
cat(file.path(fig_dir, "DEHP_allcause_mortality_quartile_2003_2018.png"), "\n")