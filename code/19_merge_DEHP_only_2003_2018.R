# ============================================================
# NHANES 2003-2018
# 19_merge_DEHP_only_2003_2018.R
# DEHP-only long-cycle validation dataset
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
# 1. Helper functions
# ------------------------------------------------------------

read_nhanes <- function(stem) {
  f <- list.files(
    data_dir,
    pattern = paste0("^", stem, "(\\.xpt|\\.XPT)?$"),
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  if (length(f) == 0) {
    stop(paste("找不到文件：", stem))
  }
  
  haven::read_xpt(f[1])
}

keep_existing <- function(dat, vars) {
  dplyr::select(dat, dplyr::any_of(vars))
}

ensure_cols <- function(dat, cols) {
  for (col in cols) {
    if (!col %in% names(dat)) {
      dat[[col]] <- NA_real_
    }
  }
  dat
}

standardize_phthalate_weight <- function(pht) {
  weight_candidates <- intersect(c("WTSB2YR", "WTSA2YR"), names(pht))
  
  if (length(weight_candidates) == 0) {
    stop("Phthalate file has no WTSB2YR or WTSA2YR.")
  }
  
  pht %>%
    mutate(WTSDEHP2YR = as.numeric(.data[[weight_candidates[1]]]))
}

read_optional_ins <- function(stem) {
  if (is.na(stem) || stem == "") {
    return(tibble(SEQN = numeric(), LBXIN_INS = numeric()))
  }
  
  dat <- read_nhanes(stem) %>%
    keep_existing(c("SEQN", "LBXIN")) %>%
    ensure_cols(c("SEQN", "LBXIN")) %>%
    rename(LBXIN_INS = LBXIN)
  
  dat
}

# ------------------------------------------------------------
# 2. Cycle map
# ------------------------------------------------------------

cycle_map <- tibble::tribble(
  ~suffix, ~cycle,       ~demo,    ~bmx,    ~pht,        ~ucr,       ~glu,       ~ins,     ~ghb,     ~diet,
  "C",     "2003-2004",  "DEMO_C", "BMX_C", "L24PH_C",   "L16_C",    "L10AM_C",  NA,       "L10_C",  "DR1TOT_C",
  "D",     "2005-2006",  "DEMO_D", "BMX_D", "PHTHTE_D",  "ALB_CR_D", "GLU_D",    NA,       "GHB_D",  "DR1TOT_D",
  "E",     "2007-2008",  "DEMO_E", "BMX_E", "PHTHTE_E",  "ALB_CR_E", "GLU_E",    NA,       "GHB_E",  "DR1TOT_E",
  "F",     "2009-2010",  "DEMO_F", "BMX_F", "PHTHTE_F",  "ALB_CR_F", "GLU_F",    NA,       "GHB_F",  "DR1TOT_F",
  "G",     "2011-2012",  "DEMO_G", "BMX_G", "PHTHTE_G",  "ALB_CR_G", "GLU_G",    NA,       "GHB_G",  "DR1TOT_G",
  "H",     "2013-2014",  "DEMO_H", "BMX_H", "PHTHTE_H",  "ALB_CR_H", "GLU_H",    "INS_H",  "GHB_H",  "DR1TOT_H",
  "I",     "2015-2016",  "DEMO_I", "BMX_I", "PHTHTE_I",  "ALB_CR_I", "GLU_I",    "INS_I",  "GHB_I",  "DR1TOT_I",
  "J",     "2017-2018",  "DEMO_J", "BMX_J", "PHTHTE_J",  "ALB_CR_J", "GLU_J",    "INS_J",  "GHB_J",  "DR1TOT_J"
)

# ------------------------------------------------------------
# 3. Read one cycle
# ------------------------------------------------------------

read_one_cycle <- function(row_i) {
  
  suffix_i <- row_i$suffix
  cycle_i  <- row_i$cycle
  
  cat("Reading cycle:", cycle_i, "\n")
  
  demo <- read_nhanes(row_i$demo) %>%
    keep_existing(c(
      "SEQN",
      "SDMVPSU", "SDMVSTRA",
      "WTMEC2YR", "WTINT2YR",
      "RIDAGEYR", "RIAGENDR",
      "RIDRETH1", "RIDRETH3",
      "DMDEDUC2", "INDFMPIR",
      "RIDEXPRG"
    )) %>%
    ensure_cols(c(
      "SEQN",
      "SDMVPSU", "SDMVSTRA",
      "RIDAGEYR", "RIAGENDR",
      "RIDRETH1", "RIDRETH3",
      "DMDEDUC2", "INDFMPIR",
      "RIDEXPRG"
    ))
  
  bmx <- read_nhanes(row_i$bmx) %>%
    keep_existing(c(
      "SEQN",
      "BMXBMI", "BMXWAIST", "BMXWT", "BMXHT"
    )) %>%
    ensure_cols(c("SEQN", "BMXBMI", "BMXWAIST", "BMXWT", "BMXHT"))
  
  pht <- read_nhanes(row_i$pht) %>%
    standardize_phthalate_weight() %>%
    keep_existing(c(
      "SEQN",
      "WTSDEHP2YR",
      "URXMHP", "URXMHH", "URXMOH", "URXECP",
      "URXUCR"
    )) %>%
    ensure_cols(c(
      "SEQN",
      "WTSDEHP2YR",
      "URXMHP", "URXMHH", "URXMOH", "URXECP",
      "URXUCR"
    )) %>%
    rename(URXUCR_PHT = URXUCR)
  
  ucr <- read_nhanes(row_i$ucr) %>%
    keep_existing(c("SEQN", "URXUCR")) %>%
    ensure_cols(c("SEQN", "URXUCR")) %>%
    rename(URXUCR_ALB = URXUCR)
  
  glu <- read_nhanes(row_i$glu) %>%
    keep_existing(c("SEQN", "LBXGLU", "LBXIN", "WTSAF2YR")) %>%
    ensure_cols(c("SEQN", "LBXGLU", "LBXIN", "WTSAF2YR")) %>%
    rename(LBXIN_GLU = LBXIN)
  
  ins <- read_optional_ins(row_i$ins)
  
  ghb <- read_nhanes(row_i$ghb) %>%
    keep_existing(c("SEQN", "LBXGH")) %>%
    ensure_cols(c("SEQN", "LBXGH"))
  
  diet <- read_nhanes(row_i$diet) %>%
    keep_existing(c(
      "SEQN",
      "DR1TKCAL", "DR1TPROT", "DR1TCARB", "DR1TTFAT", "DR1TSFAT"
    )) %>%
    ensure_cols(c("SEQN", "DR1TKCAL", "DR1TPROT", "DR1TCARB", "DR1TTFAT", "DR1TSFAT"))
  
  df_cycle <- list(
    demo, bmx, pht, ucr, glu, ins, ghb, diet
  ) %>%
    reduce(left_join, by = "SEQN") %>%
    ensure_cols(c(
      "RIDRETH1", "RIDRETH3",
      "URXUCR_ALB", "URXUCR_PHT",
      "LBXIN_GLU", "LBXIN_INS"
    )) %>%
    mutate(
      cycle = cycle_i,
      cycle_suffix = suffix_i,
      race_eth = coalesce(as.numeric(RIDRETH3), as.numeric(RIDRETH1)),
      URXUCR = coalesce(as.numeric(URXUCR_ALB), as.numeric(URXUCR_PHT)),
      LBXIN = coalesce(as.numeric(LBXIN_INS), as.numeric(LBXIN_GLU))
    )
  
  return(df_cycle)
}

# ------------------------------------------------------------
# 4. Merge all cycles
# ------------------------------------------------------------

df_all <- map_dfr(
  seq_len(nrow(cycle_map)),
  ~ read_one_cycle(cycle_map[.x, ])
)

cat("Raw combined dimension:\n")
print(dim(df_all))

# ------------------------------------------------------------
# 5. Derived DEHP variables
# ------------------------------------------------------------

MW_MEHP  <- 278.34
MW_MEHHP <- 294.34
MW_MEOHP <- 292.33
MW_MECPP <- 308.33

df_all <- df_all %>%
  mutate(
    WTSDEHP16YR = WTSDEHP2YR / 8,
    
    pregnant = ifelse(!is.na(RIDEXPRG) & RIDEXPRG == 1, 1, 0),
    
    obesity = ifelse(!is.na(BMXBMI), as.integer(BMXBMI >= 30), NA_integer_),
    
    central_obesity = case_when(
      RIAGENDR == 1 & !is.na(BMXWAIST) ~ as.integer(BMXWAIST >= 102),
      RIAGENDR == 2 & !is.na(BMXWAIST) ~ as.integer(BMXWAIST >= 88),
      TRUE ~ NA_integer_
    ),
    
    HOMA_IR = ifelse(
      !is.na(LBXGLU) & !is.na(LBXIN) & LBXGLU > 0 & LBXIN > 0,
      (LBXGLU * 0.0555 * LBXIN) / 22.5,
      NA_real_
    ),
    
    ln_HOMA_IR = ifelse(!is.na(HOMA_IR) & HOMA_IR > 0, log(HOMA_IR), NA_real_),
    
    HbA1c = LBXGH,
    
    ln_URXUCR = ifelse(!is.na(URXUCR) & URXUCR > 0, log(URXUCR), NA_real_),
    
    ln_URXMHP = ifelse(!is.na(URXMHP) & URXMHP > 0, log(URXMHP), NA_real_),
    ln_URXMHH = ifelse(!is.na(URXMHH) & URXMHH > 0, log(URXMHH), NA_real_),
    ln_URXMOH = ifelse(!is.na(URXMOH) & URXMOH > 0, log(URXMOH), NA_real_),
    ln_URXECP = ifelse(!is.na(URXECP) & URXECP > 0, log(URXECP), NA_real_),
    
    MEHP_molar  = ifelse(!is.na(URXMHP) & URXMHP > 0, URXMHP / MW_MEHP, NA_real_),
    MEHHP_molar = ifelse(!is.na(URXMHH) & URXMHH > 0, URXMHH / MW_MEHHP, NA_real_),
    MEOHP_molar = ifelse(!is.na(URXMOH) & URXMOH > 0, URXMOH / MW_MEOHP, NA_real_),
    MECPP_molar = ifelse(!is.na(URXECP) & URXECP > 0, URXECP / MW_MECPP, NA_real_),
    
    Sigma_DEHP_molar = MEHP_molar + MEHHP_molar + MEOHP_molar + MECPP_molar,
    Oxidative_DEHP_molar = MEHHP_molar + MEOHP_molar + MECPP_molar,
    
    ln_Sigma_DEHP = ifelse(
      !is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
      log(Sigma_DEHP_molar),
      NA_real_
    ),
    
    pct_MEHP = ifelse(
      !is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
      100 * MEHP_molar / Sigma_DEHP_molar,
      NA_real_
    ),
    
    pct_oxidative = ifelse(
      !is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
      100 * Oxidative_DEHP_molar / Sigma_DEHP_molar,
      NA_real_
    ),
    
    oxidative_to_MEHP = ifelse(
      !is.na(Oxidative_DEHP_molar) & !is.na(MEHP_molar) &
        Oxidative_DEHP_molar > 0 & MEHP_molar > 0,
      Oxidative_DEHP_molar / MEHP_molar,
      NA_real_
    ),
    
    ln_oxidative_to_MEHP = ifelse(
      !is.na(oxidative_to_MEHP) & oxidative_to_MEHP > 0,
      log(oxidative_to_MEHP),
      NA_real_
    ),
    
    pct_oxidative_10 = pct_oxidative / 10,
    pct_MEHP_10 = pct_MEHP / 10
  )

# ------------------------------------------------------------
# 6. Analysis sample
# ------------------------------------------------------------

analysis_2003_2018 <- df_all %>%
  filter(
    RIDAGEYR >= 20,
    pregnant != 1,
    WTSDEHP16YR > 0,
    !is.na(SDMVPSU),
    !is.na(SDMVSTRA)
  ) %>%
  mutate(
    cycle = factor(cycle, levels = cycle_map$cycle),
    period = case_when(
      cycle %in% c("2003-2004", "2005-2006", "2007-2008") ~ "2003-2008",
      cycle %in% c("2009-2010", "2011-2012") ~ "2009-2012",
      cycle %in% c("2013-2014", "2015-2016", "2017-2018") ~ "2013-2018",
      TRUE ~ NA_character_
    ),
    period = factor(period, levels = c("2003-2008", "2009-2012", "2013-2018")),
    WTSDEHP_PERIOD = case_when(
      period == "2003-2008" ~ WTSDEHP2YR / 3,
      period == "2009-2012" ~ WTSDEHP2YR / 2,
      period == "2013-2018" ~ WTSDEHP2YR / 3,
      TRUE ~ WTSDEHP16YR
    )
  )

# ------------------------------------------------------------
# 7. Checks
# ------------------------------------------------------------

sample_flow <- tibble(
  step = c(
    "Raw merged sample",
    "Age >= 20",
    "Non-pregnant adults",
    "DEHP subsample weight available",
    "ln(Sigma DEHP) available",
    "ln(HOMA-IR) available",
    "HbA1c available"
  ),
  n = c(
    nrow(df_all),
    sum(df_all$RIDAGEYR >= 20, na.rm = TRUE),
    sum(df_all$RIDAGEYR >= 20 & df_all$pregnant != 1, na.rm = TRUE),
    nrow(analysis_2003_2018),
    sum(!is.na(analysis_2003_2018$ln_Sigma_DEHP)),
    sum(!is.na(analysis_2003_2018$ln_HOMA_IR)),
    sum(!is.na(analysis_2003_2018$HbA1c))
  )
)

cycle_counts <- analysis_2003_2018 %>%
  count(cycle, name = "n")

period_counts <- analysis_2003_2018 %>%
  count(period, name = "n")

dehp_summary_check <- analysis_2003_2018 %>%
  summarise(
    n = n(),
    n_ln_Sigma_DEHP = sum(!is.na(ln_Sigma_DEHP)),
    n_pct_oxidative = sum(!is.na(pct_oxidative)),
    n_ln_HOMA_IR = sum(!is.na(ln_HOMA_IR)),
    n_HbA1c = sum(!is.na(HbA1c)),
    mean_pct_MEHP = mean(pct_MEHP, na.rm = TRUE),
    mean_pct_oxidative = mean(pct_oxidative, na.rm = TRUE),
    median_pct_MEHP = median(pct_MEHP, na.rm = TRUE),
    median_pct_oxidative = median(pct_oxidative, na.rm = TRUE),
    median_oxidative_to_MEHP = median(oxidative_to_MEHP, na.rm = TRUE)
  )

print(sample_flow)
print(cycle_counts)
print(period_counts)
print(dehp_summary_check)

# ------------------------------------------------------------
# 8. Export
# ------------------------------------------------------------

write_rds(
  analysis_2003_2018,
  file.path(output_dir, "NHANES_2003_2018_DEHP_only_master.rds")
)

write_csv(
  analysis_2003_2018,
  file.path(output_dir, "NHANES_2003_2018_DEHP_only_master.csv")
)

write_xlsx(
  list(
    sample_flow = sample_flow,
    cycle_counts = cycle_counts,
    period_counts = period_counts,
    dehp_summary_check = dehp_summary_check
  ),
  file.path(result_dir, "DEHP_only_2003_2018_dataset_check.xlsx")
)

cat("NHANES 2003-2018 DEHP-only dataset created successfully.\n")