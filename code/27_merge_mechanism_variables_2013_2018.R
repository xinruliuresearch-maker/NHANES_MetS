# ============================================================
# NHANES 2013-2018
# 27_merge_mechanism_variables_2013_2018.R
# Add inflammation, liver, renal, and hematologic markers
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
    if (!col %in% names(dat)) {
      dat[[col]] <- NA_real_
    }
  }
  dat
}

# ------------------------------------------------------------
# 1. Read base analysis dataset
# ------------------------------------------------------------

data_file_derived <- file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds")
data_file_base <- file.path(output_dir, "NHANES_2017_2018_master_analysis.rds")

if (file.exists(data_file_derived)) {
  analysis_df <- readRDS(data_file_derived)
} else if (file.exists(data_file_base)) {
  analysis_df <- readRDS(data_file_base)
} else {
  stop("找不到 2013-2018 主分析数据，请确认 output 文件夹中已有 NHANES_2013_2018_master_analysis_DEHPderived.rds")
}

# ------------------------------------------------------------
# 2. Read mechanism files
# ------------------------------------------------------------

cycle_map <- tibble::tribble(
  ~cycle,       ~suffix, ~biopro,    ~hscrp,    ~cbc,
  "2013-2014", "H",     "BIOPRO_H", "HSCRP_H", "CBC_H",
  "2015-2016", "I",     "BIOPRO_I", "HSCRP_I", "CBC_I",
  "2017-2018", "J",     "BIOPRO_J", "HSCRP_J", "CBC_J"
)

read_one_cycle_mechanism <- function(row_i) {
  
  cat("Reading mechanism files:", row_i$cycle, "\n")
  
  biopro <- read_nhanes(row_i$biopro) %>%
    keep_existing(c(
      "SEQN",
      "LBXSATSI",  # ALT
      "LBXSASSI",  # AST
      "LBXSGTSI",  # GGT
      "LBXSAPSI",  # ALP
      "LBXSAL",    # Albumin
      "LBXSTB",    # Total bilirubin
      "LBXSCR",    # Serum creatinine, mg/dL
      "LBXSBU",    # BUN
      "LBXSUA",    # Uric acid
      "LBXSTR"     # Triglycerides in biochemistry profile
    )) %>%
    ensure_cols(c(
      "SEQN", "LBXSATSI", "LBXSASSI", "LBXSGTSI", "LBXSAPSI",
      "LBXSAL", "LBXSTB", "LBXSCR", "LBXSBU", "LBXSUA", "LBXSTR"
    ))
  
  hscrp <- read_nhanes(row_i$hscrp) %>%
    keep_existing(c(
      "SEQN",
      "LBXHSCRP"
    )) %>%
    ensure_cols(c("SEQN", "LBXHSCRP"))
  
  cbc <- read_nhanes(row_i$cbc) %>%
    keep_existing(c(
      "SEQN",
      "LBXWBCSI",
      "LBXNEPCT",
      "LBXLYPCT",
      "LBXPLTSI"
    )) %>%
    ensure_cols(c("SEQN", "LBXWBCSI", "LBXNEPCT", "LBXLYPCT", "LBXPLTSI"))
  
  list(biopro, hscrp, cbc) %>%
    reduce(left_join, by = "SEQN") %>%
    mutate(
      cycle_mechanism = row_i$cycle
    )
}

mechanism_df <- map_dfr(
  seq_len(nrow(cycle_map)),
  ~ read_one_cycle_mechanism(cycle_map[.x, ])
)

# ------------------------------------------------------------
# 3. Merge with analysis dataset
# ------------------------------------------------------------

analysis_mech <- analysis_df %>%
  left_join(mechanism_df, by = "SEQN") %>%
  ensure_cols(c(
    "LBXTR", "LBXSTR",
    "BMXBMI", "BMXWAIST",
    "RIDAGEYR", "RIAGENDR"
  ))

# ------------------------------------------------------------
# 4. Derived mechanism variables
# ------------------------------------------------------------

analysis_mech <- analysis_mech %>%
  mutate(
    # Inflammation
    hsCRP = as.numeric(LBXHSCRP),
    ln_hsCRP = ifelse(!is.na(hsCRP) & hsCRP > 0, log(hsCRP), NA_real_),
    hsCRP_high3 = ifelse(!is.na(hsCRP), as.integer(hsCRP >= 3), NA_integer_),
    hsCRP_gt10 = ifelse(!is.na(hsCRP), as.integer(hsCRP > 10), NA_integer_),
    
    WBC = as.numeric(LBXWBCSI),
    neut_pct = as.numeric(LBXNEPCT),
    lymph_pct = as.numeric(LBXLYPCT),
    platelet = as.numeric(LBXPLTSI),
    
    ln_WBC = ifelse(!is.na(WBC) & WBC > 0, log(WBC), NA_real_),
    NLR = ifelse(
      !is.na(neut_pct) & !is.na(lymph_pct) & lymph_pct > 0,
      neut_pct / lymph_pct,
      NA_real_
    ),
    ln_NLR = ifelse(!is.na(NLR) & NLR > 0, log(NLR), NA_real_),
    
    # Liver markers
    ALT = as.numeric(LBXSATSI),
    AST = as.numeric(LBXSASSI),
    GGT = as.numeric(LBXSGTSI),
    ALP = as.numeric(LBXSAPSI),
    albumin = as.numeric(LBXSAL),
    total_bilirubin = as.numeric(LBXSTB),
    
    ln_ALT = ifelse(!is.na(ALT) & ALT > 0, log(ALT), NA_real_),
    ln_AST = ifelse(!is.na(AST) & AST > 0, log(AST), NA_real_),
    ln_GGT = ifelse(!is.na(GGT) & GGT > 0, log(GGT), NA_real_),
    ln_ALP = ifelse(!is.na(ALP) & ALP > 0, log(ALP), NA_real_),
    AST_ALT_ratio = ifelse(!is.na(AST) & !is.na(ALT) & ALT > 0, AST / ALT, NA_real_),
    
    # Renal markers
    serum_creatinine = as.numeric(LBXSCR),
    BUN = as.numeric(LBXSBU),
    uric_acid = as.numeric(LBXSUA),
    
    ln_BUN = ifelse(!is.na(BUN) & BUN > 0, log(BUN), NA_real_),
    ln_uric_acid = ifelse(!is.na(uric_acid) & uric_acid > 0, log(uric_acid), NA_real_),
    
    # CKD-EPI 2021 race-free eGFR
    kappa = case_when(
      RIAGENDR == 2 ~ 0.7,
      RIAGENDR == 1 ~ 0.9,
      TRUE ~ NA_real_
    ),
    alpha = case_when(
      RIAGENDR == 2 ~ -0.241,
      RIAGENDR == 1 ~ -0.302,
      TRUE ~ NA_real_
    ),
    scr_kappa = serum_creatinine / kappa,
    eGFR_2021 = ifelse(
      !is.na(serum_creatinine) & serum_creatinine > 0 &
        !is.na(kappa) & !is.na(alpha) &
        !is.na(RIDAGEYR),
      142 *
        pmin(scr_kappa, 1)^alpha *
        pmax(scr_kappa, 1)^(-1.200) *
        0.9938^RIDAGEYR *
        ifelse(RIAGENDR == 2, 1.012, 1),
      NA_real_
    ),
    eGFR_lt60 = ifelse(!is.na(eGFR_2021), as.integer(eGFR_2021 < 60), NA_integer_),
    
    # Fatty Liver Index, exploratory
    TG_for_FLI = coalesce(as.numeric(LBXTR), as.numeric(LBXSTR)),
    FLI_linear = 0.953 * log(TG_for_FLI) +
      0.139 * BMXBMI +
      0.718 * log(GGT) +
      0.053 * BMXWAIST -
      15.745,
    FLI = ifelse(
      !is.na(TG_for_FLI) & TG_for_FLI > 0 &
        !is.na(GGT) & GGT > 0 &
        !is.na(BMXBMI) & !is.na(BMXWAIST),
      100 * exp(FLI_linear) / (1 + exp(FLI_linear)),
      NA_real_
    ),
    fatty_liver_likely = ifelse(!is.na(FLI), as.integer(FLI >= 60), NA_integer_)
  )

# ------------------------------------------------------------
# 5. Checks
# ------------------------------------------------------------

mechanism_check <- tibble(
  variable = c(
    "hsCRP", "ln_hsCRP", "WBC", "ln_WBC", "NLR", "ln_NLR",
    "ALT", "AST", "GGT", "ALP", "ln_ALT", "ln_GGT",
    "serum_creatinine", "eGFR_2021", "BUN", "uric_acid",
    "FLI"
  ),
  n_non_missing = c(
    sum(!is.na(analysis_mech$hsCRP)),
    sum(!is.na(analysis_mech$ln_hsCRP)),
    sum(!is.na(analysis_mech$WBC)),
    sum(!is.na(analysis_mech$ln_WBC)),
    sum(!is.na(analysis_mech$NLR)),
    sum(!is.na(analysis_mech$ln_NLR)),
    sum(!is.na(analysis_mech$ALT)),
    sum(!is.na(analysis_mech$AST)),
    sum(!is.na(analysis_mech$GGT)),
    sum(!is.na(analysis_mech$ALP)),
    sum(!is.na(analysis_mech$ln_ALT)),
    sum(!is.na(analysis_mech$ln_GGT)),
    sum(!is.na(analysis_mech$serum_creatinine)),
    sum(!is.na(analysis_mech$eGFR_2021)),
    sum(!is.na(analysis_mech$BUN)),
    sum(!is.na(analysis_mech$uric_acid)),
    sum(!is.na(analysis_mech$FLI))
  )
)

mechanism_summary <- analysis_mech %>%
  summarise(
    n = n(),
    hsCRP_median = median(hsCRP, na.rm = TRUE),
    hsCRP_p25 = quantile(hsCRP, 0.25, na.rm = TRUE),
    hsCRP_p75 = quantile(hsCRP, 0.75, na.rm = TRUE),
    ALT_median = median(ALT, na.rm = TRUE),
    GGT_median = median(GGT, na.rm = TRUE),
    eGFR_median = median(eGFR_2021, na.rm = TRUE),
    FLI_median = median(FLI, na.rm = TRUE),
    hsCRP_gt10_n = sum(hsCRP_gt10 == 1, na.rm = TRUE)
  )

print(mechanism_check)
print(mechanism_summary)

# ------------------------------------------------------------
# 6. Export
# ------------------------------------------------------------

write_rds(
  analysis_mech,
  file.path(output_dir, "NHANES_2013_2018_master_analysis_mechanism.rds")
)

write_csv(
  analysis_mech,
  file.path(output_dir, "NHANES_2013_2018_master_analysis_mechanism.csv")
)

write_xlsx(
  list(
    mechanism_check = mechanism_check,
    mechanism_summary = mechanism_summary
  ),
  file.path(result_dir, "mechanism_variable_check_2013_2018.xlsx")
)

cat("Mechanism variables merged and exported successfully.\n")