# ============================================================
# NHANES 2013-2018
# 49_source_oriented_exposure_analysis_2013_2018.R
# Source-oriented exposure analysis:
# fast food, processed/convenience foods, diet quality, personal-care proxies
# ============================================================

required_packages <- c(
  "dplyr", "tidyr", "purrr", "readr", "tibble",
  "survey", "ggplot2", "writexl", "haven", "stringr"
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
library(haven)
library(stringr)

options(survey.lonely.psu = "adjust")

# ------------------------------------------------------------
# 0. Paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

data_dir   <- file.path(project_dir, "data")
raw_dir    <- file.path(data_dir, "raw_source_analysis")
output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir    <- file.path(result_dir, "figures_source_analysis")

dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Helper functions
# ------------------------------------------------------------

download_if_missing <- function(url, destfile) {
  if (!file.exists(destfile)) {
    message("Downloading: ", url)
    download.file(url, destfile = destfile, mode = "wb", quiet = FALSE)
  } else {
    message("File exists: ", destfile)
  }
}

safe_read_xpt <- function(url, destfile) {
  out <- tryCatch({
    download_if_missing(url, destfile)
    haven::read_xpt(destfile) %>% as_tibble()
  }, error = function(e) {
    message("Failed to read: ", url)
    message(e$message)
    NULL
  })
  out
}

format_p <- function(p) {
  ifelse(is.na(p), NA_character_,
         ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
}

zscore <- function(x) {
  x <- as.numeric(x)
  (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
}

clean_777_999 <- function(x) {
  x <- as.numeric(x)
  x[x %in% c(7777, 9999, 777, 999, 77, 99)] <- NA_real_
  x
}

effect_transform <- function(beta, low, high, outcome_type) {
  if (outcome_type == "log_ratio_outcome") {
    c(
      effect = (exp(beta) - 1) * 100,
      effect_low = (exp(low) - 1) * 100,
      effect_high = (exp(high) - 1) * 100
    )
  } else {
    c(effect = beta, effect_low = low, effect_high = high)
  }
}

# ------------------------------------------------------------
# 2. Read current analytic dataset
# ------------------------------------------------------------

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_diabetes_medication_sensitivity_dataset_with_DIQ050_DIQ070.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset_with_DIQmed.rds"),
  file.path(output_dir, "NHANES_2013_2018_TyG_TGHDL_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_logratio_composition_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]
if (is.na(data_file)) stop("找不到当前分析数据。")

df <- readRDS(data_file) %>% as_tibble()

if (!("SEQN" %in% names(df))) stop("当前分析数据缺少 SEQN，无法合并来源变量。")

cat("Using analytic dataset:\n", data_file, "\n")
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")

# ------------------------------------------------------------
# 3. Download DBQ, DR1IFF, DR1TOT files
# ------------------------------------------------------------

cycles <- tibble::tribble(
  ~cycle_label, ~year, ~suffix,
  "2013-2014", 2013, "H",
  "2015-2016", 2015, "I",
  "2017-2018", 2017, "J"
)

read_cycle_file <- function(component, suffix, year) {
  url <- paste0(
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/",
    year,
    "/DataFiles/",
    component, "_", suffix, ".XPT"
  )
  dest <- file.path(raw_dir, paste0(component, "_", suffix, ".XPT"))
  safe_read_xpt(url, dest)
}

dbq_all <- map_dfr(seq_len(nrow(cycles)), function(i) {
  dat <- read_cycle_file("DBQ", cycles$suffix[i], cycles$year[i])
  if (is.null(dat)) return(tibble())
  dat %>%
    mutate(cycle_label_source = cycles$cycle_label[i]) %>%
    select(any_of(c("SEQN", "DBD895", "DBD900", "DBD905", "DBD910", "cycle_label_source")))
})

dr1iff_all <- map_dfr(seq_len(nrow(cycles)), function(i) {
  dat <- read_cycle_file("DR1IFF", cycles$suffix[i], cycles$year[i])
  if (is.null(dat)) return(tibble())
  dat %>%
    mutate(cycle_label_source = cycles$cycle_label[i]) %>%
    select(any_of(c(
      "SEQN", "DR1FS", "DR1IKCAL", "DR1IGRMS",
      "DR1CCMTX", "DR1IFDCD", "DR1_030Z", "DR1_040Z",
      "cycle_label_source"
    )))
})

dr1tot_all <- map_dfr(seq_len(nrow(cycles)), function(i) {
  dat <- read_cycle_file("DR1TOT", cycles$suffix[i], cycles$year[i])
  if (is.null(dat)) return(tibble())
  dat %>%
    mutate(cycle_label_source = cycles$cycle_label[i]) %>%
    select(any_of(c(
      "SEQN", "DR1TKCAL", "DR1TFIBE", "DR1TSUGR",
      "DR1TSFAT", "DR1TSODI", "DR1TPROT", "DR1TCARB",
      "DR1TTFAT", "DR1TCHOL", "DR1DRSTZ",
      "cycle_label_source"
    )))
})

cat("\nDBQ rows:", nrow(dbq_all), "\n")
cat("DR1IFF rows:", nrow(dr1iff_all), "\n")
cat("DR1TOT rows:", nrow(dr1tot_all), "\n")

# ------------------------------------------------------------
# 4. Construct dietary source variables
# ------------------------------------------------------------

# 4.1 DBQ questionnaire variables
dbq_source <- dbq_all %>%
  distinct(SEQN, .keep_all = TRUE) %>%
  transmute(
    SEQN,
    meals_away_7d = if ("DBD895" %in% names(.)) clean_777_999(DBD895) else NA_real_,
    fastfood_meals_7d = if ("DBD900" %in% names(.)) clean_777_999(DBD900) else NA_real_,
    ready_to_eat_foods_30d = if ("DBD905" %in% names(.)) clean_777_999(DBD905) else NA_real_,
    frozen_pizza_30d = if ("DBD910" %in% names(.)) clean_777_999(DBD910) else NA_real_
  )

# 4.2 24h individual foods source variables
source_from_dr1iff <- dr1iff_all %>%
  mutate(
    kcal = as.numeric(DR1IKCAL),
    grams = as.numeric(DR1IGRMS),
    food_source = as.numeric(DR1FS),
    combo_type = as.numeric(DR1CCMTX),
    
    fastfood_item = food_source == 3,
    away_from_home_item = food_source %in% c(2, 3, 4, 5, 6, 14, 24, 25, 27),
    convenience_vending_item = food_source %in% c(14, 27),
    restaurant_item = food_source %in% c(2, 3, 4, 5),
    frozen_lunchkit_item = combo_type %in% c(7, 13),
    processed_proxy_item = convenience_vending_item | frozen_lunchkit_item
  ) %>%
  group_by(SEQN) %>%
  summarise(
    fastfood_kcal = sum(ifelse(fastfood_item, kcal, 0), na.rm = TRUE),
    fastfood_grams = sum(ifelse(fastfood_item, grams, 0), na.rm = TRUE),
    
    away_home_kcal = sum(ifelse(away_from_home_item, kcal, 0), na.rm = TRUE),
    away_home_grams = sum(ifelse(away_from_home_item, grams, 0), na.rm = TRUE),
    
    restaurant_kcal = sum(ifelse(restaurant_item, kcal, 0), na.rm = TRUE),
    
    convenience_vending_kcal = sum(ifelse(convenience_vending_item, kcal, 0), na.rm = TRUE),
    frozen_lunchkit_kcal = sum(ifelse(frozen_lunchkit_item, kcal, 0), na.rm = TRUE),
    processed_proxy_kcal = sum(ifelse(processed_proxy_item, kcal, 0), na.rm = TRUE),
    
    any_fastfood_24h = as.integer(any(fastfood_item, na.rm = TRUE)),
    any_away_home_24h = as.integer(any(away_from_home_item, na.rm = TRUE)),
    any_processed_proxy_24h = as.integer(any(processed_proxy_item, na.rm = TRUE)),
    
    n_food_records = n(),
    .groups = "drop"
  )

# 4.3 Total nutrient and diet-quality proxy
diet_quality <- dr1tot_all %>%
  distinct(SEQN, .keep_all = TRUE) %>%
  mutate(
    total_kcal = as.numeric(DR1TKCAL),
    fiber_g = if ("DR1TFIBE" %in% names(.)) as.numeric(DR1TFIBE) else NA_real_,
    sugar_g = if ("DR1TSUGR" %in% names(.)) as.numeric(DR1TSUGR) else NA_real_,
    satfat_g = if ("DR1TSFAT" %in% names(.)) as.numeric(DR1TSFAT) else NA_real_,
    sodium_mg = if ("DR1TSODI" %in% names(.)) as.numeric(DR1TSODI) else NA_real_,
    diet_reliable = if ("DR1DRSTZ" %in% names(.)) as.numeric(DR1DRSTZ) == 1 else TRUE,
    
    fiber_per_1000kcal = fiber_g / total_kcal * 1000,
    sugar_per_1000kcal = sugar_g / total_kcal * 1000,
    sodium_per_1000kcal = sodium_mg / total_kcal * 1000,
    satfat_pct_energy = satfat_g * 9 / total_kcal * 100,
    
    diet_quality_proxy_score =
      zscore(fiber_per_1000kcal) -
      zscore(sugar_per_1000kcal) -
      zscore(sodium_per_1000kcal) -
      zscore(satfat_pct_energy),
    
    poor_diet_score = -diet_quality_proxy_score
  ) %>%
  select(
    SEQN, total_kcal, diet_reliable,
    fiber_per_1000kcal, sugar_per_1000kcal,
    sodium_per_1000kcal, satfat_pct_energy,
    diet_quality_proxy_score, poor_diet_score
  )

# 4.4 Merge source variables
source_vars <- diet_quality %>%
  left_join(source_from_dr1iff, by = "SEQN") %>%
  left_join(dbq_source, by = "SEQN") %>%
  mutate(
    fastfood_pct_kcal = fastfood_kcal / total_kcal * 100,
    away_home_pct_kcal = away_home_kcal / total_kcal * 100,
    restaurant_pct_kcal = restaurant_kcal / total_kcal * 100,
    convenience_vending_pct_kcal = convenience_vending_kcal / total_kcal * 100,
    frozen_lunchkit_pct_kcal = frozen_lunchkit_kcal / total_kcal * 100,
    processed_proxy_pct_kcal = processed_proxy_kcal / total_kcal * 100,
    
    fastfood_pct_kcal = ifelse(is.finite(fastfood_pct_kcal), fastfood_pct_kcal, NA_real_),
    away_home_pct_kcal = ifelse(is.finite(away_home_pct_kcal), away_home_pct_kcal, NA_real_),
    processed_proxy_pct_kcal = ifelse(is.finite(processed_proxy_pct_kcal), processed_proxy_pct_kcal, NA_real_)
  )

# ------------------------------------------------------------
# 5. Personal-care / consumer-product proxy variables
# ------------------------------------------------------------

# This part uses variables already merged in the analytic dataset if available.
# Common proxies: MEP, parabens, BP3, triclosan.
pcp_candidates <- names(df)

pick_first <- function(patterns) {
  hit <- pcp_candidates[str_detect(toupper(pcp_candidates), paste(patterns, collapse = "|"))]
  if (length(hit) == 0) NA_character_ else hit[1]
}

var_mep <- pick_first(c("^URXMEP$", "MEP"))
var_bp3 <- pick_first(c("^URXBP3$", "BP3", "BENZOPHENONE"))
var_tcs <- pick_first(c("^URXTCS$", "TRICLOSAN", "TCS"))

paraben_vars <- pcp_candidates[
  str_detect(toupper(pcp_candidates), "URXMPB|URXEPB|URXPPB|URXBPB|METHYLPARABEN|ETHYLPARABEN|PROPYLPARABEN|BUTYLPARABEN")
]

pcp_proxy <- df %>%
  transmute(
    SEQN,
    ln_MEP_personalcare_proxy =
      if (!is.na(var_mep)) log(as.numeric(.data[[var_mep]]) + 0.01) else NA_real_,
    ln_BP3_proxy =
      if (!is.na(var_bp3)) log(as.numeric(.data[[var_bp3]]) + 0.01) else NA_real_,
    ln_triclosan_proxy =
      if (!is.na(var_tcs)) log(as.numeric(.data[[var_tcs]]) + 0.01) else NA_real_
  )

if (length(paraben_vars) > 0) {
  paraben_sum <- df %>%
    select(any_of(c("SEQN", paraben_vars))) %>%
    mutate(across(-SEQN, ~ as.numeric(.x))) %>%
    rowwise() %>%
    mutate(sum_parabens = sum(c_across(-SEQN), na.rm = TRUE)) %>%
    ungroup() %>%
    transmute(SEQN, ln_sum_parabens_proxy = log(sum_parabens + 0.01))
  
  pcp_proxy <- pcp_proxy %>%
    left_join(paraben_sum, by = "SEQN")
} else {
  pcp_proxy <- pcp_proxy %>%
    mutate(ln_sum_parabens_proxy = NA_real_)
}

source_vars <- source_vars %>%
  left_join(pcp_proxy, by = "SEQN")

# ------------------------------------------------------------
# 6. Merge with analytic dataset
# ------------------------------------------------------------

df_source <- df %>%
  left_join(source_vars, by = "SEQN")

write_rds(
  df_source,
  file.path(output_dir, "NHANES_2013_2018_source_oriented_dataset.rds")
)

write_csv(
  df_source,
  file.path(output_dir, "NHANES_2013_2018_source_oriented_dataset.csv")
)

# ------------------------------------------------------------
# 7. Ensure variables
# ------------------------------------------------------------

if (!("ln_HOMA_IR" %in% names(df_source)) && "HOMA_IR" %in% names(df_source)) {
  df_source <- df_source %>% mutate(ln_HOMA_IR = log(HOMA_IR))
}

if (!("HbA1c" %in% names(df_source)) && "LBXGH" %in% names(df_source)) {
  df_source <- df_source %>% mutate(HbA1c = LBXGH)
}

if (!("ln_URXUCR" %in% names(df_source)) && "URXUCR" %in% names(df_source)) {
  df_source <- df_source %>% mutate(ln_URXUCR = log(URXUCR))
}

if (!("cycle" %in% names(df_source)) && "SDDSRVYR" %in% names(df_source)) {
  df_source <- df_source %>% mutate(cycle = SDDSRVYR)
}

if (!("pct_oxidative_10" %in% names(df_source)) && "pct_oxidative" %in% names(df_source)) {
  df_source <- df_source %>% mutate(pct_oxidative_10 = pct_oxidative / 10)
}

# ------------------------------------------------------------
# 8. Survey weight
# ------------------------------------------------------------

if ("WTSB6YR_MAIN" %in% names(df_source)) {
  weight_var <- "WTSB6YR_MAIN"
} else if ("WTSAF6YR" %in% names(df_source)) {
  weight_var <- "WTSAF6YR"
} else if ("WTSAF2YR" %in% names(df_source)) {
  df_source <- df_source %>% mutate(WTSB6YR_SOURCE = WTSAF2YR / 3)
  weight_var <- "WTSB6YR_SOURCE"
} else {
  stop("找不到合适权重变量。")
}

# ------------------------------------------------------------
# 9. Model definitions
# ------------------------------------------------------------

source_map <- tibble::tribble(
  ~source_var, ~source_label, ~source_domain,
  "fastfood_pct_kcal", "Fast-food/pizza energy, % total kcal", "Fast food",
  "fastfood_meals_7d", "Fast-food/pizza meals in past 7 days", "Fast food",
  "away_home_pct_kcal", "Away-from-home energy, % total kcal", "Away from home",
  "processed_proxy_pct_kcal", "Processed/convenience proxy energy, % total kcal", "Processed proxy",
  "convenience_vending_pct_kcal", "Convenience/vending energy, % total kcal", "Processed proxy",
  "frozen_lunchkit_pct_kcal", "Frozen meal/lunch-kit energy, % total kcal", "Processed proxy",
  "poor_diet_score", "Poor diet-quality proxy score", "Diet quality",
  "diet_quality_proxy_score", "Diet-quality proxy score", "Diet quality",
  "ln_MEP_personalcare_proxy", "ln(MEP), personal-care/fragrance proxy", "Personal-care proxy",
  "ln_sum_parabens_proxy", "ln(sum parabens), personal-care proxy", "Personal-care proxy",
  "ln_BP3_proxy", "ln(BP3), sunscreen/consumer-product proxy", "Personal-care proxy",
  "ln_triclosan_proxy", "ln(triclosan), antimicrobial-product proxy", "Personal-care proxy"
) %>%
  filter(source_var %in% names(df_source))

exposure_profile_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~outcome_type, ~include_creatinine,
  "ln_Sigma_DEHP", "lnΣDEHP", "absolute_outcome", TRUE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", "absolute_outcome", FALSE,
  "ln_oxidative_MEHP_ratio", "ln[(MEHHP+MEOHP+MECPP)/MEHP]", "absolute_outcome", TRUE,
  "ilr_oxidative_vs_primary", "ILR oxidative-vs-primary balance", "absolute_outcome", TRUE
) %>%
  filter(outcome %in% names(df_source))

metabolic_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~outcome_type,
  "ln_HOMA_IR", "ln(HOMA-IR)", "log_ratio_outcome",
  "HbA1c", "HbA1c", "absolute_outcome",
  "TyG_index", "TyG index", "absolute_outcome",
  "ln_TG_HDL_C", "ln(TG/HDL-C)", "log_ratio_outcome"
) %>%
  filter(outcome %in% names(df_source))

base_covars <- c(
  "RIDAGEYR",
  "factor(RIAGENDR)",
  "factor(RIDRETH3)",
  "INDFMPIR",
  "factor(DMDEDUC2)",
  "factor(cycle)"
)

base_vars <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "cycle",
  "SDMVPSU", "SDMVSTRA", weight_var
)

# ------------------------------------------------------------
# 10. Generic survey linear model
# ------------------------------------------------------------

run_source_model <- function(outcome, outcome_label, outcome_type,
                             source_var, source_label, source_domain,
                             include_creatinine = FALSE,
                             adjust_energy = TRUE,
                             analysis_type = "source_to_exposure") {
  
  covars <- base_covars
  needed <- c(outcome, source_var, base_vars)
  
  if (include_creatinine && "ln_URXUCR" %in% names(df_source)) {
    covars <- c(covars, "ln_URXUCR")
    needed <- c(needed, "ln_URXUCR")
  }
  
  # Do not adjust energy for percent-of-energy source variables or diet score based on energy density.
  if (
    adjust_energy &&
    "DR1TKCAL" %in% names(df_source) &&
    !str_detect(source_var, "pct_kcal|diet_quality|poor_diet")
  ) {
    covars <- c(covars, "DR1TKCAL")
    needed <- c(needed, "DR1TKCAL")
  }
  
  missing_needed <- setdiff(unique(needed), names(df_source))
  if (length(missing_needed) > 0) {
    return(tibble(
      analysis_type = analysis_type,
      outcome = outcome,
      outcome_label = outcome_label,
      source_var = source_var,
      source_label = source_label,
      source_domain = source_domain,
      n = NA_integer_,
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = paste("Missing:", paste(missing_needed, collapse = ", "))
    ))
  }
  
  d <- df_source %>%
    filter(RIDAGEYR >= 20) %>%
    select(all_of(unique(needed))) %>%
    drop_na()
  
  if (nrow(d) < 300) {
    return(tibble(
      analysis_type = analysis_type,
      outcome = outcome,
      outcome_label = outcome_label,
      source_var = source_var,
      source_label = source_label,
      source_domain = source_domain,
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
    paste0(outcome, " ~ ", source_var, " + ", paste(covars, collapse = " + "))
  )
  
  fit <- tryCatch(svyglm(f, design = des), error = function(e) NULL)
  
  if (is.null(fit)) {
    return(tibble(
      analysis_type = analysis_type,
      outcome = outcome,
      outcome_label = outcome_label,
      source_var = source_var,
      source_label = source_label,
      source_domain = source_domain,
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
  if (!(source_var %in% rownames(ct))) {
    return(tibble(
      analysis_type = analysis_type,
      outcome = outcome,
      outcome_label = outcome_label,
      source_var = source_var,
      source_label = source_label,
      source_domain = source_domain,
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
  
  beta <- ct[source_var, "Estimate"]
  se <- ct[source_var, "Std. Error"]
  p <- ct[source_var, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  eff <- effect_transform(beta, low, high, outcome_type)
  
  tibble(
    analysis_type = analysis_type,
    outcome = outcome,
    outcome_label = outcome_label,
    source_var = source_var,
    source_label = source_label,
    source_domain = source_domain,
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
      TRUE ~ "Weak/no association"
    )
  )
}

# ------------------------------------------------------------
# 11. Run source -> DEHP profile
# ------------------------------------------------------------

source_to_dehp <- expand_grid(
  outcome_row = seq_len(nrow(exposure_profile_map)),
  source_row = seq_len(nrow(source_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, source_row),
      function(i, j) {
        run_source_model(
          outcome = exposure_profile_map$outcome[i],
          outcome_label = exposure_profile_map$outcome_label[i],
          outcome_type = exposure_profile_map$outcome_type[i],
          source_var = source_map$source_var[j],
          source_label = source_map$source_label[j],
          source_domain = source_map$source_domain[j],
          include_creatinine = exposure_profile_map$include_creatinine[i],
          analysis_type = "source_to_DEHP_profile"
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
    q_value_fmt = format_p(q_value)
  )

# ------------------------------------------------------------
# 12. Run source -> metabolic markers
# ------------------------------------------------------------

source_to_metabolic <- expand_grid(
  outcome_row = seq_len(nrow(metabolic_map)),
  source_row = seq_len(nrow(source_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, source_row),
      function(i, j) {
        run_source_model(
          outcome = metabolic_map$outcome[i],
          outcome_label = metabolic_map$outcome_label[i],
          outcome_type = metabolic_map$outcome_type[i],
          source_var = source_map$source_var[j],
          source_label = source_map$source_label[j],
          source_domain = source_map$source_domain[j],
          include_creatinine = FALSE,
          analysis_type = "source_to_metabolic_marker"
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
    q_value_fmt = format_p(q_value)
  )

# ------------------------------------------------------------
# 13. Source heatmap for source -> DEHP profile
# ------------------------------------------------------------

plot_dehp <- source_to_dehp %>%
  filter(!is.na(beta)) %>%
  mutate(
    sig_label = case_when(
      q_value < 0.05 ~ "**",
      p_value < 0.05 ~ "*",
      TRUE ~ ""
    )
  )

p_heat <- ggplot(plot_dehp, aes(x = outcome_label, y = source_label, fill = beta)) +
  geom_tile(color = "white", linewidth = 0.35) +
  geom_text(aes(label = sig_label), fontface = "bold", size = 4) +
  facet_grid(source_domain ~ ., scales = "free_y", space = "free_y") +
  labs(
    title = "Source-oriented predictors of DEHP exposure profiles",
    subtitle = "Survey-weighted models adjusted for age, sex, race/ethnicity, income, education, cycle, and urinary creatinine where applicable",
    x = "DEHP exposure profile",
    y = NULL,
    fill = "Beta",
    caption = "* nominal P < 0.05; ** FDR q < 0.05"
  ) +
  theme_bw(base_size = 10.5) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    strip.text.y = element_text(face = "bold", angle = 0),
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid = element_blank(),
    plot.caption = element_text(hjust = 0)
  )

print(p_heat)

ggsave(
  file.path(fig_dir, "source_to_DEHP_profile_heatmap_2013_2018.png"),
  p_heat,
  width = 11,
  height = 8,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "source_to_DEHP_profile_heatmap_2013_2018.pdf"),
  p_heat,
  width = 11,
  height = 8
)

# ------------------------------------------------------------
# 14. Export
# ------------------------------------------------------------

source_variable_check <- tibble(
  source_var = source_map$source_var,
  source_label = source_map$source_label,
  source_domain = source_map$source_domain,
  nonmissing_n = map_int(source_map$source_var, ~ sum(!is.na(df_source[[.x]]))),
  mean_value = map_dbl(source_map$source_var, ~ mean(df_source[[.x]], na.rm = TRUE)),
  sd_value = map_dbl(source_map$source_var, ~ sd(df_source[[.x]], na.rm = TRUE))
)

write_xlsx(
  list(
    source_variable_check = source_variable_check,
    source_to_DEHP_profile = source_to_dehp,
    source_to_metabolic_marker = source_to_metabolic
  ),
  file.path(result_dir, "source_oriented_exposure_analysis_2013_2018.xlsx")
)

write_csv(
  source_to_dehp,
  file.path(result_dir, "source_to_DEHP_profile_results_2013_2018.csv")
)

write_csv(
  source_to_metabolic,
  file.path(result_dir, "source_to_metabolic_marker_results_2013_2018.csv")
)

cat("\nSource-oriented exposure analysis completed successfully.\n")
cat("Main result file:\n")
cat(file.path(result_dir, "source_oriented_exposure_analysis_2013_2018.xlsx"), "\n")
cat("Figure:\n")
cat(file.path(fig_dir, "source_to_DEHP_profile_heatmap_2013_2018.png"), "\n")