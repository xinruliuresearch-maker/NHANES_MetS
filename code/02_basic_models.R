# ============================================================
# NHANES 2017-2018
# Organic Pollutants and Obesity / Metabolic Syndrome
# 02_basic_models.R
# ============================================================

library(dplyr)
library(purrr)
library(tidyr)
library(readr)
library(tibble)
library(survey)
library(broom)
library(writexl)

options(survey.lonely.psu = "adjust")

# ------------------------------------------------------------
# 1. 设置路径
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 2. 读取合并后的总数据
# ------------------------------------------------------------

analysis_df <- readRDS(
  file.path(output_dir, "NHANES_2017_2018_master_analysis.rds")
)

cat("读取分析数据成功。\n")
cat("总样本量：", nrow(analysis_df), "\n")

# ------------------------------------------------------------
# 3. 设置污染物变量
# ------------------------------------------------------------

pollutant_map <- tibble::tribble(
  ~pollutant, ~label, ~group,
  "URXBPH",   "BPA",   "Bisphenols",
  "URXBPF",   "BPF",   "Bisphenols",
  "URXBPS",   "BPS",   "Bisphenols",
  
  "URXMEP",   "MEP",   "Phthalates",
  "URXMBP",   "MBP",   "Phthalates",
  "URXMIB",   "MiBP",  "Phthalates",
  "URXMHP",   "MEHP",  "Phthalates",
  "URXMHH",   "MEHHP", "Phthalates",
  "URXMOH",   "MEOHP", "Phthalates",
  "URXECP",   "MECPP", "Phthalates",
  "URXMZP",   "MBzP",  "Phthalates",
  "URXCOP",   "MCOP",  "Plasticizers",
  "URXCNP",   "MCNP",  "Plasticizers",
  "URXMNP",   "MNP",   "Plasticizers",
  "URXMONP",  "MONP",  "Plasticizers"
)

pollutant_map <- pollutant_map %>%
  mutate(
    exposure = paste0("ln_", pollutant)
  ) %>%
  filter(exposure %in% names(analysis_df))

cat("将要分析的污染物：\n")
print(pollutant_map)

# ------------------------------------------------------------
# 4. 定义结局变量
# ------------------------------------------------------------

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label,
  "obesity", "Obesity",
  "central_obesity", "Central obesity",
  "metabolic_syndrome", "Metabolic syndrome"
)

# ------------------------------------------------------------
# 5. 单污染物加权 Logistic 回归函数
# ------------------------------------------------------------

run_svy_logistic <- function(outcome, exposure) {
  
  model_vars <- c(
    outcome,
    exposure,
    "RIDAGEYR",
    "RIAGENDR",
    "RIDRETH3",
    "INDFMPIR",
    "DR1TKCAL",
    "ln_URXUCR",
    "SDMVPSU",
    "SDMVSTRA",
    "WTSB2YR_MAIN"
  )
  
  d <- analysis_df %>%
    dplyr::select(dplyr::any_of(model_vars)) %>%
    tidyr::drop_na()
  
  # 检查样本量和结局是否同时有 0/1
  if (nrow(d) < 100 || length(unique(d[[outcome]])) < 2) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      events = ifelse(outcome %in% names(d), sum(d[[outcome]] == 1, na.rm = TRUE), NA_integer_),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      OR = NA_real_,
      OR_low = NA_real_,
      OR_high = NA_real_
    ))
  }
  
  des <- survey::svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB2YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(
      outcome, " ~ ", exposure,
      " + RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3)",
      " + INDFMPIR + DR1TKCAL + ln_URXUCR"
    )
  )
  
  fit <- tryCatch(
    survey::svyglm(
      f,
      design = des,
      family = quasibinomial()
    ),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      events = sum(d[[outcome]] == 1, na.rm = TRUE),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      OR = NA_real_,
      OR_low = NA_real_,
      OR_high = NA_real_
    ))
  }
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) {
    return(tibble(
      outcome = outcome,
      exposure = exposure,
      n = nrow(d),
      events = sum(d[[outcome]] == 1, na.rm = TRUE),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      OR = NA_real_,
      OR_low = NA_real_,
      OR_high = NA_real_
    ))
  }
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  tibble(
    outcome = outcome,
    exposure = exposure,
    n = nrow(d),
    events = sum(d[[outcome]] == 1, na.rm = TRUE),
    beta = beta,
    se = se,
    p_value = p_value,
    OR = exp(beta),
    OR_low = exp(beta - 1.96 * se),
    OR_high = exp(beta + 1.96 * se)
  )
}

# ------------------------------------------------------------
# 6. 批量运行模型
# ------------------------------------------------------------

basic_results <- tidyr::expand_grid(
  outcome = outcome_map$outcome,
  exposure = pollutant_map$exposure
) %>%
  mutate(
    result = purrr::map2(outcome, exposure, run_svy_logistic)
  ) %>%
  dplyr::select(result) %>%
  tidyr::unnest(result) %>%
  left_join(outcome_map, by = "outcome") %>%
  left_join(pollutant_map, by = "exposure") %>%
  mutate(
    OR_CI = ifelse(
      is.na(OR),
      NA_character_,
      sprintf("%.3f (%.3f, %.3f)", OR, OR_low, OR_high)
    ),
    p_value_fmt = case_when(
      is.na(p_value) ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_value)
    )
  ) %>%
  dplyr::select(
    outcome,
    outcome_label,
    group,
    pollutant,
    label,
    exposure,
    n,
    events,
    OR,
    OR_low,
    OR_high,
    OR_CI,
    p_value,
    p_value_fmt,
    beta,
    se
  )

cat("基础模型运行完成。\n")
print(basic_results)

# ------------------------------------------------------------
# 7. 导出结果表
# ------------------------------------------------------------

write_csv(
  basic_results,
  file.path(result_dir, "basic_weighted_logistic_results.csv")
)

write_xlsx(
  list(
    basic_weighted_logistic_results = basic_results
  ),
  file.path(result_dir, "basic_weighted_logistic_results.xlsx")
)

cat("结果已经导出到 result 文件夹。\n")