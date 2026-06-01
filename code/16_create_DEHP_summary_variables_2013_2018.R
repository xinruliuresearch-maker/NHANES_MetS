# ============================================================
# NHANES 2013-2018
# 16_create_DEHP_summary_variables_2013_2018.R
# Create ΣDEHP and DEHP metabolism profile variables
# ============================================================

library(dplyr)
library(readr)
library(writexl)
library(tibble)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

analysis_df <- readRDS(
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

# ------------------------------------------------------------
# 1. Molecular weights
# ------------------------------------------------------------

MW_MEHP  <- 278.34
MW_MEHHP <- 294.34
MW_MEOHP <- 292.33
MW_MECPP <- 308.33

# ------------------------------------------------------------
# 2. Convert individual DEHP metabolites to molar units
# 原始 NHANES 尿液浓度通常可按 ng/mL 或 μg/L 理解；
# 1 ng/mL = 1 μg/L。
# 这里计算相对摩尔浓度，比例和 log 模型不受统一比例常数影响。
# ------------------------------------------------------------

analysis_df_dehp <- analysis_df %>%
  mutate(
    MEHP_molar  = ifelse(!is.na(URXMHP) & URXMHP > 0, URXMHP / MW_MEHP, NA_real_),
    MEHHP_molar = ifelse(!is.na(URXMHH) & URXMHH > 0, URXMHH / MW_MEHHP, NA_real_),
    MEOHP_molar = ifelse(!is.na(URXMOH) & URXMOH > 0, URXMOH / MW_MEOHP, NA_real_),
    MECPP_molar = ifelse(!is.na(URXECP) & URXECP > 0, URXECP / MW_MECPP, NA_real_),
    
    Sigma_DEHP_molar = MEHP_molar + MEHHP_molar + MEOHP_molar + MECPP_molar,
    
    Oxidative_DEHP_molar = MEHHP_molar + MEOHP_molar + MECPP_molar,
    
    # log total DEHP exposure
    ln_Sigma_DEHP = ifelse(!is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
                           log(Sigma_DEHP_molar), NA_real_),
    
    # 为了便于和部分文献比较，也可转换成 MECPP-equivalent
    Sigma_DEHP_MECPP_equiv = Sigma_DEHP_molar * MW_MECPP,
    ln_Sigma_DEHP_MECPP_equiv = ifelse(
      !is.na(Sigma_DEHP_MECPP_equiv) & Sigma_DEHP_MECPP_equiv > 0,
      log(Sigma_DEHP_MECPP_equiv),
      NA_real_
    ),
    
    # metabolism profile
    pct_MEHP = ifelse(!is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
                      100 * MEHP_molar / Sigma_DEHP_molar, NA_real_),
    
    pct_oxidative = ifelse(!is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
                           100 * Oxidative_DEHP_molar / Sigma_DEHP_molar, NA_real_),
    
    pct_MEHHP = ifelse(!is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
                       100 * MEHHP_molar / Sigma_DEHP_molar, NA_real_),
    
    pct_MEOHP = ifelse(!is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
                       100 * MEOHP_molar / Sigma_DEHP_molar, NA_real_),
    
    pct_MECPP = ifelse(!is.na(Sigma_DEHP_molar) & Sigma_DEHP_molar > 0,
                       100 * MECPP_molar / Sigma_DEHP_molar, NA_real_),
    
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
    
    # per 10 percentage-point scale for interpretation
    pct_MEHP_10 = pct_MEHP / 10,
    pct_oxidative_10 = pct_oxidative / 10
  )

# ------------------------------------------------------------
# 3. Quality check
# ------------------------------------------------------------

dehp_variable_check <- analysis_df_dehp %>%
  summarise(
    n_total = n(),
    
    n_Sigma_DEHP = sum(!is.na(Sigma_DEHP_molar)),
    n_ln_Sigma_DEHP = sum(!is.na(ln_Sigma_DEHP)),
    n_pct_MEHP = sum(!is.na(pct_MEHP)),
    n_pct_oxidative = sum(!is.na(pct_oxidative)),
    n_oxidative_to_MEHP = sum(!is.na(ln_oxidative_to_MEHP)),
    
    median_Sigma_DEHP = median(Sigma_DEHP_molar, na.rm = TRUE),
    p25_Sigma_DEHP = quantile(Sigma_DEHP_molar, 0.25, na.rm = TRUE),
    p75_Sigma_DEHP = quantile(Sigma_DEHP_molar, 0.75, na.rm = TRUE),
    
    mean_pct_MEHP = mean(pct_MEHP, na.rm = TRUE),
    mean_pct_oxidative = mean(pct_oxidative, na.rm = TRUE),
    
    median_pct_MEHP = median(pct_MEHP, na.rm = TRUE),
    median_pct_oxidative = median(pct_oxidative, na.rm = TRUE),
    
    median_oxidative_to_MEHP = median(oxidative_to_MEHP, na.rm = TRUE)
  )

print(dehp_variable_check)

# ------------------------------------------------------------
# 4. Correlation check
# ------------------------------------------------------------

dehp_corr_data <- analysis_df_dehp %>%
  select(
    ln_URXMHP, ln_URXMHH, ln_URXMOH, ln_URXECP,
    ln_Sigma_DEHP,
    pct_MEHP,
    pct_oxidative,
    ln_oxidative_to_MEHP
  ) %>%
  na.omit()

dehp_correlation <- as.data.frame(
  round(cor(dehp_corr_data, use = "pairwise.complete.obs"), 3)
) %>%
  tibble::rownames_to_column("variable")

print(dehp_correlation)

# ------------------------------------------------------------
# 5. Export updated dataset and checks
# ------------------------------------------------------------

write_rds(
  analysis_df_dehp,
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds")
)

write_csv(
  analysis_df_dehp,
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.csv")
)

write_xlsx(
  list(
    dehp_variable_check = dehp_variable_check,
    dehp_correlation = dehp_correlation
  ),
  file.path(result_dir, "DEHP_derived_variable_check_2013_2018.xlsx")
)

cat("DEHP 衍生变量已生成并导出。\n")