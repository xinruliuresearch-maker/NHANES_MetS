# ============================================================
# NHANES 2017-2018
# 04_table1_by_obesity.R
# Baseline characteristics by obesity status
# ============================================================

library(dplyr)
library(readr)
library(tibble)
library(survey)
library(writexl)

options(survey.lonely.psu = "adjust")

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

analysis_df <- readRDS(
  file.path(output_dir, "NHANES_2017_2018_master_analysis.rds")
)

table_df <- analysis_df %>%
  filter(
    !is.na(obesity),
    WTSB2YR_MAIN > 0,
    !is.na(SDMVPSU),
    !is.na(SDMVSTRA)
  ) %>%
  mutate(
    female = as.integer(RIAGENDR == 2),
    ever_smoker = ifelse(!is.na(SMQ020), as.integer(SMQ020 == 1), NA_integer_),
    diabetes_history = ifelse(!is.na(DIQ010), as.integer(DIQ010 == 1), NA_integer_)
  )

design_tbl <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTSB2YR_MAIN,
  nest = TRUE,
  data = table_df
)

fmt_mean_sd <- function(mean, sd) {
  sprintf("%.2f ± %.2f", mean, sd)
}

weighted_mean_sd <- function(var, group_value) {
  
  dsgn <- subset(design_tbl, obesity == group_value)
  f <- as.formula(paste0("~", var))
  
  m <- tryCatch(
    as.numeric(svymean(f, dsgn, na.rm = TRUE)),
    error = function(e) NA_real_
  )
  
  v <- tryCatch(
    as.numeric(svyvar(f, dsgn, na.rm = TRUE)),
    error = function(e) NA_real_
  )
  
  s <- sqrt(v)
  
  fmt_mean_sd(m, s)
}

weighted_geom_mean <- function(lnvar, group_value) {
  
  dsgn <- subset(design_tbl, obesity == group_value)
  f <- as.formula(paste0("~", lnvar))
  
  m <- tryCatch(
    as.numeric(svymean(f, dsgn, na.rm = TRUE)),
    error = function(e) NA_real_
  )
  
  ifelse(is.na(m), NA_character_, sprintf("%.3f", exp(m)))
}

weighted_percent <- function(var, group_value) {
  
  dsgn <- subset(design_tbl, obesity == group_value)
  f <- as.formula(paste0("~", var))
  
  p <- tryCatch(
    as.numeric(svymean(f, dsgn, na.rm = TRUE)) * 100,
    error = function(e) NA_real_
  )
  
  ifelse(is.na(p), NA_character_, sprintf("%.1f%%", p))
}

p_continuous <- function(var) {
  f <- as.formula(paste0(var, " ~ obesity"))
  p <- tryCatch(
    svyttest(f, design_tbl)$p.value,
    error = function(e) NA_real_
  )
  ifelse(is.na(p), NA_character_, ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
}

p_categorical <- function(var) {
  f <- as.formula(paste0("~", var, " + obesity"))
  p <- tryCatch(
    svychisq(f, design_tbl, statistic = "F")$p.value,
    error = function(e) NA_real_
  )
  ifelse(is.na(p), NA_character_, ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
}

continuous_vars <- tibble::tribble(
  ~var, ~label,
  "RIDAGEYR", "Age, years",
  "BMXBMI", "BMI, kg/m²",
  "BMXWAIST", "Waist circumference, cm",
  "DR1TKCAL", "Total energy intake, kcal",
  "URXUCR", "Urinary creatinine"
)

continuous_table <- continuous_vars %>%
  rowwise() %>%
  mutate(
    Non_obese = weighted_mean_sd(var, 0),
    Obese = weighted_mean_sd(var, 1),
    P_value = p_continuous(var)
  ) %>%
  ungroup() %>%
  select(Variable = label, Non_obese, Obese, P_value)

categorical_vars <- tibble::tribble(
  ~var, ~label,
  "female", "Female, %",
  "ever_smoker", "Ever smoker, %",
  "diabetes_history", "Diabetes history, %",
  "metabolic_syndrome", "Metabolic syndrome, %"
)

categorical_table <- categorical_vars %>%
  rowwise() %>%
  mutate(
    Non_obese = weighted_percent(var, 0),
    Obese = weighted_percent(var, 1),
    P_value = p_categorical(var)
  ) %>%
  ungroup() %>%
  select(Variable = label, Non_obese, Obese, P_value)

pollutant_ln_vars <- tibble::tribble(
  ~lnvar, ~label,
  "ln_URXBPH", "BPA, geometric mean",
  "ln_URXBPF", "BPF, geometric mean",
  "ln_URXBPS", "BPS, geometric mean",
  "ln_URXMEP", "MEP, geometric mean",
  "ln_URXMBP", "MBP, geometric mean",
  "ln_URXMIB", "MiBP, geometric mean",
  "ln_URXMHP", "MEHP, geometric mean",
  "ln_URXMHH", "MEHHP, geometric mean",
  "ln_URXMOH", "MEOHP, geometric mean",
  "ln_URXECP", "MECPP, geometric mean",
  "ln_URXMZP", "MBzP, geometric mean",
  "ln_URXCOP", "MCOP, geometric mean",
  "ln_URXCNP", "MCNP, geometric mean",
  "ln_URXMNP", "MNP, geometric mean",
  "ln_URXMONP", "MONP, geometric mean"
) %>%
  filter(lnvar %in% names(table_df))

pollutant_table <- pollutant_ln_vars %>%
  rowwise() %>%
  mutate(
    Non_obese = weighted_geom_mean(lnvar, 0),
    Obese = weighted_geom_mean(lnvar, 1),
    P_value = p_continuous(lnvar)
  ) %>%
  ungroup() %>%
  select(Variable = label, Non_obese, Obese, P_value)

table1 <- bind_rows(
  tibble(Variable = "Continuous variables", Non_obese = "", Obese = "", P_value = ""),
  continuous_table,
  tibble(Variable = "Categorical variables", Non_obese = "", Obese = "", P_value = ""),
  categorical_table,
  tibble(Variable = "Urinary pollutants", Non_obese = "", Obese = "", P_value = ""),
  pollutant_table
)

print(table1)

write_xlsx(
  list(
    Table1_by_obesity = table1,
    Continuous = continuous_table,
    Categorical = categorical_table,
    Pollutants = pollutant_table
  ),
  file.path(result_dir, "Table1_baseline_by_obesity.xlsx")
)

cat("Table 1 已经导出到 result/Table1_baseline_by_obesity.xlsx\n")