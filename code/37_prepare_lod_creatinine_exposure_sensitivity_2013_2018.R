# ============================================================
# NHANES 2013-2018
# 37_prepare_lod_creatinine_exposure_sensitivity_2013_2018.R
# Prepare LOD, creatinine, and exposure-processing sensitivity dataset
# ============================================================

library(haven)
library(dplyr)
library(purrr)
library(readr)
library(tibble)
library(writexl)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

data_dir   <- file.path(project_dir, "raw_xpt")
output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Read best available 2013-2018 analysis dataset
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

read_nhanes <- function(stem) {
  f <- list.files(
    data_dir,
    pattern = paste0("^", stem, "(\\.xpt|\\.XPT)?$"),
    full.names = TRUE,
    ignore.case = TRUE
  )
  if (length(f) == 0) stop(paste("找不到文件：", stem))
  haven::read_xpt(f[1])
}

keep_existing <- function(dat, vars) {
  dplyr::select(dat, dplyr::any_of(vars))
}

ensure_cols <- function(dat, cols) {
  for (col in cols) {
    if (!col %in% names(dat)) dat[[col]] <- NA_real_
  }
  dat
}

winsorize <- function(x, probs = c(0.01, 0.99)) {
  qs <- quantile(x, probs = probs, na.rm = TRUE)
  pmin(pmax(x, qs[1]), qs[2])
}

# ------------------------------------------------------------
# 3. Read phthalate raw files for comment codes
# ------------------------------------------------------------

cycle_map <- tibble::tribble(
  ~cycle,       ~suffix, ~pht,
  "2013-2014", "H",     "PHTHTE_H",
  "2015-2016", "I",     "PHTHTE_I",
  "2017-2018", "J",     "PHTHTE_J"
)

read_one_pht_lod <- function(row_i) {
  cat("Reading PHTHTE comment codes:", row_i$cycle, "\n")
  
  read_nhanes(row_i$pht) %>%
    keep_existing(c(
      "SEQN",
      "URXMHP", "URXMHH", "URXMOH", "URXECP",
      "URDMHPLC", "URDMHHLC", "URDMOHLC", "URDECPLC"
    )) %>%
    ensure_cols(c(
      "SEQN",
      "URXMHP", "URXMHH", "URXMOH", "URXECP",
      "URDMHPLC", "URDMHHLC", "URDMOHLC", "URDECPLC"
    )) %>%
    mutate(cycle_lod = row_i$cycle)
}

pht_lod <- map_dfr(
  seq_len(nrow(cycle_map)),
  ~ read_one_pht_lod(cycle_map[.x, ])
)

# ------------------------------------------------------------
# 4. Merge comment codes and construct sensitivity variables
# ------------------------------------------------------------

df_sens <- df %>%
  left_join(
    pht_lod %>%
      select(
        SEQN,
        URDMHPLC, URDMHHLC, URDMOHLC, URDECPLC
      ),
    by = "SEQN"
  ) %>%
  mutate(
    # LOD flags
    lod_MEHP  = ifelse(!is.na(URDMHPLC), as.integer(URDMHPLC == 1), NA_integer_),
    lod_MEHHP = ifelse(!is.na(URDMHHLC), as.integer(URDMHHLC == 1), NA_integer_),
    lod_MEOHP = ifelse(!is.na(URDMOHLC), as.integer(URDMOHLC == 1), NA_integer_),
    lod_MECPP = ifelse(!is.na(URDECPLC), as.integer(URDECPLC == 1), NA_integer_),
    
    n_dehp_below_lod = rowSums(
      cbind(lod_MEHP, lod_MEHHP, lod_MEOHP, lod_MECPP),
      na.rm = TRUE
    ),
    
    any_dehp_below_lod = ifelse(
      !is.na(lod_MEHP) | !is.na(lod_MEHHP) | !is.na(lod_MEOHP) | !is.na(lod_MECPP),
      as.integer(n_dehp_below_lod > 0),
      NA_integer_
    ),
    
    any_oxidative_below_lod = ifelse(
      !is.na(lod_MEHHP) | !is.na(lod_MEOHP) | !is.na(lod_MECPP),
      as.integer((lod_MEHHP + lod_MEOHP + lod_MECPP) > 0),
      NA_integer_
    ),
    
    all_oxidative_detected = ifelse(
      !is.na(lod_MEHHP) & !is.na(lod_MEOHP) & !is.na(lod_MECPP),
      as.integer(lod_MEHHP == 0 & lod_MEOHP == 0 & lod_MECPP == 0),
      NA_integer_
    ),
    
    all_dehp_detected = ifelse(
      !is.na(lod_MEHP) & !is.na(lod_MEHHP) & !is.na(lod_MEOHP) & !is.na(lod_MECPP),
      as.integer(lod_MEHP == 0 & lod_MEHHP == 0 & lod_MEOHP == 0 & lod_MECPP == 0),
      NA_integer_
    ),
    
    # Urinary creatinine extreme flag
    urinary_creatinine_extreme_30_300 = ifelse(
      !is.na(URXUCR),
      as.integer(URXUCR < 30 | URXUCR > 300),
      NA_integer_
    ),
    
    urinary_creatinine_valid_30_300 = ifelse(
      !is.na(URXUCR),
      as.integer(URXUCR >= 30 & URXUCR <= 300),
      NA_integer_
    ),
    
    # Creatinine-standardized concentrations
    # Formula multiplier 100 converts ng/mL divided by mg/dL creatinine into approximately ug/g creatinine.
    cr_URXMHP = ifelse(!is.na(URXMHP) & !is.na(URXUCR) & URXMHP > 0 & URXUCR > 0,
                       100 * URXMHP / URXUCR, NA_real_),
    cr_URXMHH = ifelse(!is.na(URXMHH) & !is.na(URXUCR) & URXMHH > 0 & URXUCR > 0,
                       100 * URXMHH / URXUCR, NA_real_),
    cr_URXMOH = ifelse(!is.na(URXMOH) & !is.na(URXUCR) & URXMOH > 0 & URXUCR > 0,
                       100 * URXMOH / URXUCR, NA_real_),
    cr_URXECP = ifelse(!is.na(URXECP) & !is.na(URXUCR) & URXECP > 0 & URXUCR > 0,
                       100 * URXECP / URXUCR, NA_real_),
    
    ln_cr_URXMHP = ifelse(!is.na(cr_URXMHP) & cr_URXMHP > 0, log(cr_URXMHP), NA_real_),
    ln_cr_URXMHH = ifelse(!is.na(cr_URXMHH) & cr_URXMHH > 0, log(cr_URXMHH), NA_real_),
    ln_cr_URXMOH = ifelse(!is.na(cr_URXMOH) & cr_URXMOH > 0, log(cr_URXMOH), NA_real_),
    ln_cr_URXECP = ifelse(!is.na(cr_URXECP) & cr_URXECP > 0, log(cr_URXECP), NA_real_),
    
    cr_Sigma_DEHP_molar = ifelse(
      !is.na(Sigma_DEHP_molar) & !is.na(URXUCR) & Sigma_DEHP_molar > 0 & URXUCR > 0,
      Sigma_DEHP_molar / URXUCR,
      NA_real_
    ),
    
    ln_cr_Sigma_DEHP = ifelse(
      !is.na(cr_Sigma_DEHP_molar) & cr_Sigma_DEHP_molar > 0,
      log(cr_Sigma_DEHP_molar),
      NA_real_
    ),
    
    # Winsorized exposures
    ln_Sigma_DEHP_w = winsorize(ln_Sigma_DEHP),
    pct_oxidative_10_w = winsorize(pct_oxidative_10),
    ln_URXMHH_w = winsorize(ln_URXMHH),
    ln_URXMOH_w = winsorize(ln_URXMOH),
    ln_URXECP_w = winsorize(ln_URXECP)
  )

# ------------------------------------------------------------
# 5. LOD and creatinine check tables
# ------------------------------------------------------------

lod_summary <- df_sens %>%
  summarise(
    n = n(),
    MEHP_below_LOD_n = sum(lod_MEHP == 1, na.rm = TRUE),
    MEHP_below_LOD_pct = mean(lod_MEHP == 1, na.rm = TRUE) * 100,
    MEHHP_below_LOD_n = sum(lod_MEHHP == 1, na.rm = TRUE),
    MEHHP_below_LOD_pct = mean(lod_MEHHP == 1, na.rm = TRUE) * 100,
    MEOHP_below_LOD_n = sum(lod_MEOHP == 1, na.rm = TRUE),
    MEOHP_below_LOD_pct = mean(lod_MEOHP == 1, na.rm = TRUE) * 100,
    MECPP_below_LOD_n = sum(lod_MECPP == 1, na.rm = TRUE),
    MECPP_below_LOD_pct = mean(lod_MECPP == 1, na.rm = TRUE) * 100,
    any_DEHP_below_LOD_n = sum(any_dehp_below_lod == 1, na.rm = TRUE),
    any_DEHP_below_LOD_pct = mean(any_dehp_below_lod == 1, na.rm = TRUE) * 100,
    any_oxidative_below_LOD_n = sum(any_oxidative_below_lod == 1, na.rm = TRUE),
    any_oxidative_below_LOD_pct = mean(any_oxidative_below_lod == 1, na.rm = TRUE) * 100
  )

lod_by_cycle <- df_sens %>%
  group_by(cycle) %>%
  summarise(
    n = n(),
    MEHP_below_LOD_pct = mean(lod_MEHP == 1, na.rm = TRUE) * 100,
    MEHHP_below_LOD_pct = mean(lod_MEHHP == 1, na.rm = TRUE) * 100,
    MEOHP_below_LOD_pct = mean(lod_MEOHP == 1, na.rm = TRUE) * 100,
    MECPP_below_LOD_pct = mean(lod_MECPP == 1, na.rm = TRUE) * 100,
    any_DEHP_below_LOD_pct = mean(any_dehp_below_lod == 1, na.rm = TRUE) * 100,
    any_oxidative_below_LOD_pct = mean(any_oxidative_below_lod == 1, na.rm = TRUE) * 100,
    .groups = "drop"
  )

creatinine_summary <- df_sens %>%
  summarise(
    n = n(),
    URXUCR_nonmissing = sum(!is.na(URXUCR)),
    URXUCR_median = median(URXUCR, na.rm = TRUE),
    URXUCR_p25 = quantile(URXUCR, 0.25, na.rm = TRUE),
    URXUCR_p75 = quantile(URXUCR, 0.75, na.rm = TRUE),
    URXUCR_below_30_n = sum(URXUCR < 30, na.rm = TRUE),
    URXUCR_above_300_n = sum(URXUCR > 300, na.rm = TRUE),
    URXUCR_extreme_30_300_n = sum(urinary_creatinine_extreme_30_300 == 1, na.rm = TRUE),
    URXUCR_extreme_30_300_pct = mean(urinary_creatinine_extreme_30_300 == 1, na.rm = TRUE) * 100
  )

print(lod_summary)
print(lod_by_cycle)
print(creatinine_summary)

# ------------------------------------------------------------
# 6. Export
# ------------------------------------------------------------

write_rds(
  df_sens,
  file.path(output_dir, "NHANES_2013_2018_exposure_sensitivity_dataset.rds")
)

write_csv(
  df_sens,
  file.path(output_dir, "NHANES_2013_2018_exposure_sensitivity_dataset.csv")
)

write_xlsx(
  list(
    lod_summary = lod_summary,
    lod_by_cycle = lod_by_cycle,
    creatinine_summary = creatinine_summary
  ),
  file.path(result_dir, "exposure_lod_creatinine_check_2013_2018.xlsx")
)

cat("LOD, creatinine, and exposure sensitivity dataset created successfully.\n")