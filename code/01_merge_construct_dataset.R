# ============================================================
# NHANES 2017-2018
# Organic Pollutants and Obesity / Metabolic Syndrome
# 01_merge_construct_dataset.R
# ============================================================

library(haven)
library(dplyr)
library(purrr)
library(readr)
library(tibble)
library(writexl)

# ------------------------------------------------------------
# 1. 设置项目路径
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

data_dir   <- file.path(project_dir, "raw_xpt")
output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

cat("当前数据文件夹：", data_dir, "\n")
cat("文件列表：\n")
print(list.files(data_dir))

# ------------------------------------------------------------
# 2. 定义读取 NHANES XPT 的函数
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
  
  read_xpt(f[1])
}

keep_existing <- function(dat, vars) {
  dat %>% select(any_of(vars))
}

# ------------------------------------------------------------
# 3. 读取并保留主分析所需变量
# ------------------------------------------------------------

demo <- read_nhanes("DEMO_J") %>%
  keep_existing(c(
    "SEQN",
    "SDMVPSU", "SDMVSTRA",
    "WTMEC2YR", "WTINT2YR",
    "RIDAGEYR", "RIAGENDR", "RIDRETH3",
    "DMDEDUC2", "INDFMPIR",
    "RIDEXPRG"
  ))

bmx <- read_nhanes("BMX_J") %>%
  keep_existing(c(
    "SEQN",
    "BMXBMI", "BMXWAIST", "BMXWT", "BMXHT"
  ))

bpx <- read_nhanes("BPX_J") %>%
  keep_existing(c(
    "SEQN",
    "BPXSY1", "BPXSY2", "BPXSY3", "BPXSY4",
    "BPXDI1", "BPXDI2", "BPXDI3", "BPXDI4"
  ))

# 双酚类、酚类、个人护理品相关化学物
ephpp <- read_nhanes("EPHPP_J") %>%
  keep_existing(c(
    "SEQN", "WTSB2YR",
    "URXBPH", "URXBPF", "URXBPS"
  )) %>%
  rename(WTSB2YR_EPHPP = WTSB2YR)

# 邻苯二甲酸酯/塑化剂代谢物
pht <- read_nhanes("PHTHTE_J") %>%
  keep_existing(c(
    "SEQN", "WTSB2YR",
    "URXMEP", "URXMBP", "URXMIB",
    "URXMHP", "URXMHH", "URXMOH", "URXECP", "URXMZP",
    "URXCOP", "URXCNP", "URXMNP", "URXMONP"
  )) %>%
  rename(WTSB2YR_PHTHTE = WTSB2YR)

# 尿肌酐
ucr <- read_nhanes("ALB_CR_J") %>%
  keep_existing(c("SEQN", "URXUCR"))

# 血糖、胰岛素、糖化血红蛋白
glu <- read_nhanes("GLU_J") %>%
  keep_existing(c("SEQN", "LBXGLU", "WTSAF2YR"))

ins <- read_nhanes("INS_J") %>%
  keep_existing(c("SEQN", "LBXIN"))

ghb <- read_nhanes("GHB_J") %>%
  keep_existing(c("SEQN", "LBXGH"))

# 血脂
hdl <- read_nhanes("HDL_J") %>%
  keep_existing(c("SEQN", "LBDHDD"))

trig <- read_nhanes("TRIGLY_J") %>%
  keep_existing(c("SEQN", "LBXTR", "LBDLDL"))

tchol <- read_nhanes("TCHOL_J") %>%
  keep_existing(c("SEQN", "LBXTC"))

# 饮食
diet1 <- read_nhanes("DR1TOT_J") %>%
  keep_existing(c(
    "SEQN",
    "DR1TKCAL", "DR1TPROT", "DR1TCARB",
    "DR1TTFAT", "DR1TSFAT"
  ))

# 问卷：饮酒、吸烟、运动、糖尿病、高血压/胆固醇、饮食行为
alq <- read_nhanes("ALQ_J") %>%
  keep_existing(c("SEQN", "ALQ101", "ALQ121"))

smq <- read_nhanes("SMQ_J") %>%
  keep_existing(c("SEQN", "SMQ020"))

paq <- read_nhanes("PAQ_J") %>%
  keep_existing(c(
    "SEQN",
    "PAQ605", "PAQ620", "PAQ650", "PAQ665"
  ))

diq <- read_nhanes("DIQ_J") %>%
  keep_existing(c("SEQN", "DIQ010"))

bpq <- read_nhanes("BPQ_J") %>%
  keep_existing(c(
    "SEQN",
    "BPQ020", "BPQ040A",
    "BPQ080", "BPQ090D"
  ))

dbq <- read_nhanes("DBQ_J") %>%
  keep_existing(c("SEQN", "DBQ700"))

# ------------------------------------------------------------
# 4. 按 SEQN 合并
# ------------------------------------------------------------

df <- list(
  demo, bmx, bpx,
  ephpp, pht, ucr,
  glu, ins, ghb,
  hdl, trig, tchol,
  diet1,
  alq, smq, paq, diq, bpq, dbq
) %>%
  reduce(left_join, by = "SEQN")

cat("\n合并后数据维度：\n")
print(dim(df))

# ------------------------------------------------------------
# 5. 定义污染物暴露变量
# ------------------------------------------------------------

exposure_vars <- c(
  "URXBPH",   # BPA
  "URXBPF",   # BPF
  "URXBPS",   # BPS
  
  "URXMEP",
  "URXMBP",
  "URXMIB",
  "URXMHP",
  "URXMHH",
  "URXMOH",
  "URXECP",
  "URXMZP",
  "URXCOP",
  "URXCNP",
  "URXMNP",
  "URXMONP"
)

exposure_vars <- intersect(exposure_vars, names(df))

cat("\n成功识别的污染物变量：\n")
print(exposure_vars)

# ------------------------------------------------------------
# 6. 计算平均血压
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
# 7. 构建研究结局变量
# ------------------------------------------------------------

df <- df %>%
  mutate(
    # 尿液环境化学物的子样本权重
    WTSB2YR_MAIN = coalesce(WTSB2YR_EPHPP, WTSB2YR_PHTHTE),
    
    # 排除妊娠：RIDEXPRG == 1 通常表示当前妊娠
    pregnant = ifelse(!is.na(RIDEXPRG) & RIDEXPRG == 1, 1, 0),
    
    # 肥胖：BMI >= 30 kg/m2
    obesity = ifelse(!is.na(BMXBMI), as.integer(BMXBMI >= 30), NA_integer_),
    
    # 腹型肥胖：美国成人常用标准
    central_obesity = case_when(
      RIAGENDR == 1 & !is.na(BMXWAIST) ~ as.integer(BMXWAIST >= 102),
      RIAGENDR == 2 & !is.na(BMXWAIST) ~ as.integer(BMXWAIST >= 88),
      TRUE ~ NA_integer_
    ),
    
    # HOMA-IR：空腹血糖 mg/dL 转 mmol/L
    HOMA_IR = ifelse(
      !is.na(LBXGLU) & !is.na(LBXIN),
      (LBXGLU * 0.0555 * LBXIN) / 22.5,
      NA_real_
    ),
    
    ln_HOMA_IR = ifelse(!is.na(HOMA_IR) & HOMA_IR > 0, log(HOMA_IR), NA_real_),
    
    # 代谢综合征 5 个组成部分
    mets_waist = central_obesity,
    
    mets_tg = ifelse(
      !is.na(LBXTR),
      as.integer(LBXTR >= 150),
      NA_integer_
    ),
    
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
# 8. 污染物与尿肌酐 log 转换
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
# 9. 筛选成人分析样本
# ------------------------------------------------------------

analysis_df <- df %>%
  filter(
    RIDAGEYR >= 20,
    pregnant != 1,
    WTSB2YR_MAIN > 0,
    !is.na(SDMVPSU),
    !is.na(SDMVSTRA)
  )

cat("\n成人分析样本量：", nrow(analysis_df), "\n")
cat("肥胖变量非缺失人数：", sum(!is.na(analysis_df$obesity)), "\n")
cat("腹型肥胖变量非缺失人数：", sum(!is.na(analysis_df$central_obesity)), "\n")
cat("代谢综合征变量非缺失人数：", sum(!is.na(analysis_df$metabolic_syndrome)), "\n")
cat("HOMA-IR 非缺失人数：", sum(!is.na(analysis_df$HOMA_IR)), "\n")

# ------------------------------------------------------------
# 10. 输出样本流程表
# ------------------------------------------------------------

sample_flow <- tibble(
  step = c(
    "合并后总样本",
    "年龄 >= 20 岁",
    "排除妊娠后",
    "有环境化学物子样本权重",
    "肥胖结局非缺失",
    "代谢综合征结局非缺失",
    "HOMA-IR 非缺失"
  ),
  n = c(
    nrow(df),
    sum(df$RIDAGEYR >= 20, na.rm = TRUE),
    sum(df$RIDAGEYR >= 20 & df$pregnant != 1, na.rm = TRUE),
    sum(df$RIDAGEYR >= 20 & df$pregnant != 1 & df$WTSB2YR_MAIN > 0, na.rm = TRUE),
    sum(!is.na(analysis_df$obesity)),
    sum(!is.na(analysis_df$metabolic_syndrome)),
    sum(!is.na(analysis_df$HOMA_IR))
  )
)

print(sample_flow)

# ------------------------------------------------------------
# 11. 基础描述统计
# ------------------------------------------------------------

basic_summary <- analysis_df %>%
  summarise(
    n = n(),
    age_mean = mean(RIDAGEYR, na.rm = TRUE),
    age_sd = sd(RIDAGEYR, na.rm = TRUE),
    bmi_mean = mean(BMXBMI, na.rm = TRUE),
    bmi_sd = sd(BMXBMI, na.rm = TRUE),
    waist_mean = mean(BMXWAIST, na.rm = TRUE),
    waist_sd = sd(BMXWAIST, na.rm = TRUE),
    obesity_n = sum(obesity == 1, na.rm = TRUE),
    obesity_pct = mean(obesity == 1, na.rm = TRUE) * 100,
    central_obesity_n = sum(central_obesity == 1, na.rm = TRUE),
    central_obesity_pct = mean(central_obesity == 1, na.rm = TRUE) * 100,
    metabolic_syndrome_n = sum(metabolic_syndrome == 1, na.rm = TRUE),
    metabolic_syndrome_pct = mean(metabolic_syndrome == 1, na.rm = TRUE) * 100,
    homa_ir_median = median(HOMA_IR, na.rm = TRUE)
  )

print(basic_summary)

# ------------------------------------------------------------
# 12. 导出数据
# ------------------------------------------------------------

write_csv(
  analysis_df,
  file.path(output_dir, "NHANES_2017_2018_master_analysis.csv")
)

write_rds(
  analysis_df,
  file.path(output_dir, "NHANES_2017_2018_master_analysis.rds")
)

write_xlsx(
  list(
    master_data = analysis_df,
    sample_flow = sample_flow,
    basic_summary = basic_summary
  ),
  file.path(output_dir, "NHANES_2017_2018_master_analysis.xlsx")
)

cat("\n数据已经成功导出到 output 文件夹。\n")