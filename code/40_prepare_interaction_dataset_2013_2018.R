# ============================================================
# NHANES 2013-2018
# 40_prepare_interaction_dataset_2013_2018.R
# Prepare interaction / effect modification dataset
# ============================================================

library(dplyr)
library(readr)
library(tibble)
library(writexl)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Read best available dataset
# ------------------------------------------------------------

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_exposure_sensitivity_dataset.rds"),
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
# 2. Create effect modifiers
# ------------------------------------------------------------
# eGFR_2021 is optional. It may not exist in the exposure-sensitivity dataset.
has_eGFR_2021 <- "eGFR_2021" %in% names(df)

if (!has_eGFR_2021) {
  message("eGFR_2021 not found. eGFR exploratory interaction will be skipped.")
  df$eGFR_2021 <- NA_real_
}
df_int <- df %>%
  mutate(
    sex_group = case_when(
      RIAGENDR == 1 ~ "Male",
      RIAGENDR == 2 ~ "Female",
      TRUE ~ NA_character_
    ),
    sex_group = factor(sex_group, levels = c("Male", "Female")),
    
    age_group = case_when(
      RIDAGEYR >= 20 & RIDAGEYR < 40 ~ "20-39",
      RIDAGEYR >= 40 & RIDAGEYR < 60 ~ "40-59",
      RIDAGEYR >= 60 ~ ">=60",
      TRUE ~ NA_character_
    ),
    age_group = factor(age_group, levels = c("20-39", "40-59", ">=60")),
    
    obesity_status = case_when(
      !is.na(BMXBMI) & BMXBMI < 30 ~ "Non-obese",
      !is.na(BMXBMI) & BMXBMI >= 30 ~ "Obese",
      TRUE ~ NA_character_
    ),
    obesity_status = factor(obesity_status, levels = c("Non-obese", "Obese")),
    
    race_group = case_when(
      RIDRETH3 == 1 ~ "Mexican American",
      RIDRETH3 == 2 ~ "Other Hispanic",
      RIDRETH3 == 3 ~ "Non-Hispanic White",
      RIDRETH3 == 4 ~ "Non-Hispanic Black",
      RIDRETH3 == 6 ~ "Non-Hispanic Asian",
      RIDRETH3 == 7 ~ "Other/Multi-racial",
      TRUE ~ NA_character_
    ),
    race_group = factor(
      race_group,
      levels = c(
        "Non-Hispanic White",
        "Mexican American",
        "Other Hispanic",
        "Non-Hispanic Black",
        "Non-Hispanic Asian",
        "Other/Multi-racial"
      )
    ),
    
    eGFR_group2 = case_when(
      !is.na(eGFR_2021) & eGFR_2021 >= 90 ~ "eGFR >=90",
      !is.na(eGFR_2021) & eGFR_2021 < 90 ~ "eGFR <90",
      TRUE ~ NA_character_
    ),
    eGFR_group2 = factor(eGFR_group2, levels = c("eGFR >=90", "eGFR <90"))
  )

# ------------------------------------------------------------
# 3. Modifier count table
# ------------------------------------------------------------

make_count_table <- function(dat, var, label) {
  dat %>%
    filter(!is.na(.data[[var]])) %>%
    count(.data[[var]], name = "n") %>%
    mutate(
      modifier = label,
      level = as.character(.data[[var]]),
      percent = 100 * n / sum(n)
    ) %>%
    select(modifier, level, n, percent)
}

modifier_counts <- bind_rows(
  make_count_table(df_int, "sex_group", "Sex"),
  make_count_table(df_int, "age_group", "Age group"),
  make_count_table(df_int, "obesity_status", "Obesity status"),
  make_count_table(df_int, "race_group", "Race/ethnicity")
)

if (has_eGFR_2021) {
  modifier_counts <- bind_rows(
    modifier_counts,
    make_count_table(df_int, "eGFR_group2", "eGFR group")
  )
}

print(modifier_counts)

# ------------------------------------------------------------
# 4. Export
# ------------------------------------------------------------

write_rds(
  df_int,
  file.path(output_dir, "NHANES_2013_2018_interaction_dataset.rds")
)

write_csv(
  df_int,
  file.path(output_dir, "NHANES_2013_2018_interaction_dataset.csv")
)

write_xlsx(
  list(
    modifier_counts = modifier_counts
  ),
  file.path(result_dir, "interaction_modifier_counts_2013_2018.xlsx")
)

cat("Interaction dataset prepared successfully.\n")