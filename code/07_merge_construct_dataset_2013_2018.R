# ============================================================
# NHANES 2013-2018
# Organic pollutants, obesity, MetS and insulin resistance
# 07_merge_construct_dataset_2013_2018.R
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
  
  if (length(f) == 0) {
    stop(paste("找不到文件：", stem))
  }
  
  haven::read_xpt(f[1])
}

keep_existing <- function(dat, vars) {
  dplyr::select(dat, dplyr::any_of(vars))
}

read_cycle <- function(suffix, cycle_label) {
  
  cat("正在读取周期：", cycle_label, " 后缀：", suffix, "\n")
  
  demo <- read_nhanes(paste0("DEMO_", suffix)) %>%
    keep_existing(c(
      "SEQN",
      "SDMVPSU", "SDMVSTRA",
      "WTMEC2YR", "WTINT2YR",
      "RIDAGEYR", "RIAGENDR", "RIDRETH3",
      "DMDEDUC2", "INDFMPIR",
      "RIDEXPRG"
    ))
  
  bmx <- read_nhanes(paste0("BMX_", suffix)) %>%
    keep_existing(c(
      "SEQN",
      "BMXBMI", "BMXWAIST", "BMXWT", "BMXHT"
    ))
  
  bpx <- read_nhanes(paste0("BPX_", suffix)) %>%
    keep_existing(c(
      "SEQN",
      "BPXSY1", "BPXSY2", "BPXSY3", "BPXSY4",
      "BPXDI1", "BPXDI2", "BPXDI3", "BPXDI4"
    ))
  
  ephpp <- read_nhanes(paste0("EPHPP_", suffix)) %>%
    keep_existing(c(
      "SEQN", "WTSB2YR",
      "URXBPH", "URXBPF", "URXBPS"
    )) %>%
    rename(WTSB2YR_EPHPP = WTSB2YR)
  
  pht <- read_nhanes(paste0("PHTHTE_", suffix)) %>%
    keep_existing(c(
      "SEQN", "WTSB2YR",
      "URXMEP", "URXMBP", "URXMIB",
      "URXMHP", "URXMHH", "URXMOH", "URXECP", "URXMZP",
      "URXCOP", "URXCNP", "URXMNP", "URXMONP"
    )) %>%
    rename(WTSB2YR_PHTHTE = WTSB2YR)
  
  ucr <- read_nhanes(paste0("ALB_CR_", suffix)) %>%
    keep_existing(c("SEQN", "URXUCR"))
  
  glu <- read_nhanes(paste0("GLU_", suffix)) %>%
    keep_existing(c("SEQN", "LBXGLU", "WTSAF2YR"))
  
  ins <- read_nhanes(paste0("INS_", suffix)) %>%
    keep_existing(c("SEQN", "LBXIN"))
  
  ghb <- read_nhanes(paste0("GHB_", suffix)) %>%
    keep_existing(c("SEQN", "LBXGH"))
  
  hdl <- read_nhanes(paste0("HDL_", suffix)) %>%
    keep_existing(c("SEQN", "LBDHDD"))
  
  trig <- read_nhanes(paste0("TRIGLY_", suffix)) %>%
    keep_existing(c("SEQN", "LBXTR", "LBDLDL"))
  
  tchol <- read_nhanes(paste0("TCHOL_", suffix)) %>%
    keep_existing(c("SEQN", "LBXTC"))
  
  diet1 <- read_nhanes(paste0("DR1TOT_", suffix)) %>%
    keep_existing(c(
      "SEQN",
      "DR1TKCAL", "DR1TPROT", "DR1TCARB",
      "DR1TTFAT", "DR1TSFAT"
    ))
  
  alq <- read_nhanes(paste0("ALQ_", suffix)) %>%
    keep_existing(c("SEQN", "ALQ101", "ALQ121"))
  
  smq <- read_nhanes(paste0("SMQ_", suffix)) %>%
    keep_existing(c("SEQN", "SMQ020"))
  
  paq <- read_nhanes(paste0("PAQ_", suffix)) %>%
    keep_existing(c(
      "SEQN",
      "PAQ605", "PAQ620", "PAQ650", "PAQ665"
    ))
  
  diq <- read_nhanes(paste0("DIQ_", suffix)) %>%
    keep_existing(c("SEQN", "DIQ010"))
  
  bpq <- read_nhanes(paste0("BPQ_", suffix)) %>%
    keep_existing(c(
      "SEQN",
      "BPQ020", "BPQ040A",
      "BPQ080", "BPQ090D"
    ))
  
  dbq <- read_nhanes(paste0("DBQ_", suffix)) %>%
    keep_existing(c("SEQN", "DBQ700"))
  
  df_cycle <- list(
    demo, bmx, bpx,
    ephpp, pht, ucr,
    glu, ins, ghb,
    hdl, trig, tchol,
    diet1,
    alq, smq, paq, diq, bpq, dbq
  ) %>%
    reduce(left_join, by = "SEQN") %>%
    mutate(
      cycle = cycle_label,
      cycle_suffix = suffix
    )
  
  return(df_cycle)
}

df_H <- read_cycle("H", "2013-2014")
df_I <- read_cycle("I", "2015-2016")
df_J <- read_cycle("J", "2017-2018")

df <- bind_rows(df_H, df_I, df_J)

cat("合并 H/I/J 后数据维度：\n")
print(dim(df))

# ------------------------------------------------------------
# 暴露变量
# ------------------------------------------------------------

exposure_vars <- c(
  "URXBPH", "URXBPF", "URXBPS",
  "URXMEP", "URXMBP", "URXMIB",
  "URXMHP", "URXMHH", "URXMOH",
  "URXECP", "URXMZP",
  "URXCOP", "URXCNP", "URXMNP", "URXMONP"
)

exposure_vars <- intersect(exposure_vars, names(df))

# ------------------------------------------------------------
# 血压
# ------------------------------------------------------------

bp_sys_vars <- intersect(c("BPXSY1", "BPXSY2", "BPXSY3", "BPXSY4"), names(df))
bp_dia_vars <- intersect(c("BPXDI1", "BPXDI2", "BPXDI3", "BPXDI4"), names(df))

df <- df %>%
  mutate(
    mean_sbp = rowMeans(across(all_of(bp_sys_vars)), na.rm = TRUE),
    mean_dbp = rowMeans(across(all_of(bp_dia_vars)), na.rm = TRUE),
    mean_sbp = ifelse(is.nan(mean_sbp), NA, mean_sbp),
    mean_dbp = ifelse(is.nan(mean_dbp), NA, mean_dbp)
  )

# ------------------------------------------------------------
# 结局、协变量、机制指标
# ------------------------------------------------------------

df <- df %>%
  mutate(
    WTSB2YR_MAIN = coalesce(WTSB2YR_EPHPP, WTSB2YR_PHTHTE),
    WTSB6YR_MAIN = WTSB2YR_MAIN / 3,
    
    pregnant = ifelse(!is.na(RIDEXPRG) & RIDEXPRG == 1, 1, 0),
    
    female = ifelse(!is.na(RIAGENDR), as.integer(RIAGENDR == 2), NA_integer_),
    
    education = DMDEDUC2,
    
    ever_smoker = case_when(
      SMQ020 == 1 ~ 1L,
      SMQ020 == 2 ~ 0L,
      TRUE ~ NA_integer_
    ),
    
    alcohol_ever = case_when(
      ALQ101 == 1 ~ 1L,
      ALQ101 == 2 ~ 0L,
      TRUE ~ NA_integer_
    ),
    
    any_physical_activity = case_when(
      PAQ605 == 1 | PAQ620 == 1 | PAQ650 == 1 | PAQ665 == 1 ~ 1L,
      PAQ605 == 2 & PAQ620 == 2 & PAQ650 == 2 & PAQ665 == 2 ~ 0L,
      TRUE ~ NA_integer_
    ),
    
    diabetes_history = case_when(
      DIQ010 == 1 ~ 1L,
      DIQ010 == 2 ~ 0L,
      TRUE ~ NA_integer_
    ),
    
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
    
    TyG = ifelse(
      !is.na(LBXTR) & !is.na(LBXGLU) & LBXTR > 0 & LBXGLU > 0,
      log((LBXTR * LBXGLU) / 2),
      NA_real_
    ),
    
    TG_HDL = ifelse(
      !is.na(LBXTR) & !is.na(LBDHDD) & LBDHDD > 0,
      LBXTR / LBDHDD,
      NA_real_
    ),
    
    ln_TG_HDL = ifelse(!is.na(TG_HDL) & TG_HDL > 0, log(TG_HDL), NA_real_),
    
    non_HDL_C = ifelse(
      !is.na(LBXTC) & !is.na(LBDHDD),
      LBXTC - LBDHDD,
      NA_real_
    ),
    
    HbA1c = LBXGH,
    
    mets_waist = central_obesity,
    
    mets_tg = ifelse(!is.na(LBXTR), as.integer(LBXTR >= 150), NA_integer_),
    
    mets_hdl = case_when(
      RIAGENDR == 1 & !is.na(LBDHDD) ~ as.integer(LBDHDD < 40),
      RIAGENDR == 2 & !is.na(LBDHDD) ~ as.integer(LBDHDD < 50),
      TRUE ~ NA_integer_
    ),
    
    mets_bp = ifelse(
      !is.na(mean_sbp) | !is.na(mean_dbp) | !is.na(BPQ040A),
      as.integer(mean_sbp >= 130 | mean_dbp >= 85 | BPQ040A == 1),
      NA_integer_
    ),
    
    mets_glu = ifelse(
      !is.na(LBXGLU) | !is.na(DIQ010),
      as.integer(LBXGLU >= 100 | DIQ010 == 1),
      NA_integer_
    )
  )

mets_components <- c("mets_waist", "mets_tg", "mets_hdl", "mets_bp", "mets_glu")

df <- df %>%
  rowwise() %>%
  mutate(
    mets_available = sum(!is.na(c_across(all_of(mets_components)))),
    mets_count = sum(c_across(all_of(mets_components)), na.rm = TRUE),
    metabolic_syndrome = ifelse(
      mets_available == 5,
      as.integer(mets_count >= 3),
      NA_integer_
    )
  ) %>%
  ungroup()

# ------------------------------------------------------------
# log 转换污染物和尿肌酐
# ------------------------------------------------------------

df <- df %>%
  mutate(
    ln_URXUCR = ifelse(!is.na(URXUCR) & URXUCR > 0, log(URXUCR), NA_real_)
  ) %>%
  mutate(
    across(
      all_of(exposure_vars),
      ~ ifelse(!is.na(.x) & .x > 0, log(.x), NA_real_),
      .names = "ln_{.col}"
    )
  )

# ------------------------------------------------------------
# 分析样本
# ------------------------------------------------------------

analysis_df_2013_2018 <- df %>%
  filter(
    RIDAGEYR >= 20,
    pregnant != 1,
    WTSB6YR_MAIN > 0,
    !is.na(SDMVPSU),
    !is.na(SDMVSTRA)
  ) %>%
  mutate(
    cycle = factor(cycle, levels = c("2013-2014", "2015-2016", "2017-2018"))
  )

sample_flow <- tibble(
  step = c(
    "合并后总样本",
    "年龄 >= 20 岁",
    "排除妊娠后",
    "有环境化学物 6 年权重",
    "肥胖结局非缺失",
    "代谢综合征结局非缺失",
    "HOMA-IR 非缺失",
    "TyG 非缺失",
    "HbA1c 非缺失"
  ),
  n = c(
    nrow(df),
    sum(df$RIDAGEYR >= 20, na.rm = TRUE),
    sum(df$RIDAGEYR >= 20 & df$pregnant != 1, na.rm = TRUE),
    nrow(analysis_df_2013_2018),
    sum(!is.na(analysis_df_2013_2018$obesity)),
    sum(!is.na(analysis_df_2013_2018$metabolic_syndrome)),
    sum(!is.na(analysis_df_2013_2018$HOMA_IR)),
    sum(!is.na(analysis_df_2013_2018$TyG)),
    sum(!is.na(analysis_df_2013_2018$HbA1c))
  )
)

print(sample_flow)

write_csv(
  analysis_df_2013_2018,
  file.path(output_dir, "NHANES_2013_2018_master_analysis.csv")
)

write_rds(
  analysis_df_2013_2018,
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

write_xlsx(
  list(
    master_data = analysis_df_2013_2018,
    sample_flow = sample_flow
  ),
  file.path(output_dir, "NHANES_2013_2018_master_analysis.xlsx")
)

cat("NHANES 2013-2018 合并数据已导出到 output 文件夹。\n")