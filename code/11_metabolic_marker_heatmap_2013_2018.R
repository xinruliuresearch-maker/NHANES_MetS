library(dplyr)
library(readr)
library(ggplot2)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(result_dir, "figures_2013_2018")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

continuous_results <- read_csv(
  file.path(result_dir, "continuous_results_2013_2018_Model2.csv"),
  show_col_types = FALSE
)

heat_df <- continuous_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "TyG index", "ln(TG/HDL-C)", "HbA1c"),
    label %in% c("BPA", "BPF", "BPS", "MEP", "MBP", "MiBP", "MEHP", "MEHHP", "MEOHP", "MECPP", "MBzP", "MCOP", "MCNP", "MNP", "MONP")
  ) %>%
  mutate(
    sig_label = case_when(
      q_value < 0.05 ~ "**",
      p_value < 0.05 ~ "*",
      TRUE ~ ""
    ),
    outcome_label = factor(
      outcome_label,
      levels = c("ln(HOMA-IR)", "TyG index", "ln(TG/HDL-C)", "HbA1c")
    )
  )

p_heat <- ggplot(
  heat_df,
  aes(
    x = outcome_label,
    y = label,
    fill = beta
  )
) +
  geom_tile(color = "white") +
  geom_text(aes(label = sig_label), size = 5) +
  scale_fill_gradient2(
    low = "steelblue",
    mid = "white",
    high = "firebrick",
    midpoint = 0
  ) +
  labs(
    title = "Associations between urinary pollutants and metabolic markers",
    subtitle = "Color represents regression coefficient; * nominal P < 0.05; ** FDR q < 0.05",
    x = "Metabolic marker",
    y = "Pollutant",
    fill = "Beta"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 30, hjust = 1)
  )

print(p_heat)

ggsave(
  file.path(fig_dir, "metabolic_marker_heatmap_2013_2018.png"),
  p_heat,
  width = 8,
  height = 7,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "metabolic_marker_heatmap_2013_2018.pdf"),
  p_heat,
  width = 8,
  height = 7
)

cat("代谢机制热图已生成。\n")library(readr)
library(dplyr)
library(writexl)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"
result_dir <- file.path(project_dir, "result")

logistic_results <- read_csv(
  file.path(result_dir, "logistic_results_2013_2018_Model2.csv"),
  show_col_types = FALSE
)

continuous_results <- read_csv(
  file.path(result_dir, "continuous_results_2013_2018_Model2.csv"),
  show_col_types = FALSE
)

# 1. DEHP 相关代谢物与机制性代谢指标
DEHP_mechanism_results <- continuous_results %>%
  filter(
    label %in% c("MEHP", "MEHHP", "MEOHP", "MECPP"),
    outcome_label %in% c("ln(HOMA-IR)", "TyG index", "ln(TG/HDL-C)", "HbA1c")
  ) %>%
  select(
    outcome_label,
    group,
    label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt,
    beta,
    se
  ) %>%
  arrange(outcome_label, label)

print(DEHP_mechanism_results)

# 2. 代谢综合征重点污染物结果
MetS_key_results <- logistic_results %>%
  filter(
    outcome_label == "Metabolic syndrome",
    label %in% c("MEHP", "MEHHP", "MEOHP", "MECPP", "MBzP", "MCOP", "MCNP", "MNP", "MONP")
  ) %>%
  select(
    outcome_label,
    group,
    label,
    n,
    events,
    OR_CI,
    p_value_fmt,
    q_value_fmt,
    beta,
    se
  ) %>%
  arrange(label)

print(MetS_key_results)

# 3. 所有连续代谢指标中 nominal P < 0.05 的结果
continuous_nominal_sig <- continuous_results %>%
  filter(!is.na(p_value), p_value < 0.05) %>%
  select(
    outcome_label,
    group,
    label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt
  ) %>%
  arrange(outcome_label, p_value)

print(continuous_nominal_sig)

# 4. 所有 Logistic 结局中 nominal P < 0.05 的结果
logistic_nominal_sig <- logistic_results %>%
  filter(!is.na(p_value), p_value < 0.05) %>%
  select(
    outcome_label,
    group,
    label,
    n,
    events,
    OR_CI,
    p_value_fmt,
    q_value_fmt
  ) %>%
  arrange(outcome_label, p_value)

print(logistic_nominal_sig)

# 5. FDR q < 0.10 的结果
continuous_fdr_010 <- continuous_results %>%
  filter(!is.na(q_value), q_value < 0.10) %>%
  select(
    outcome_label,
    group,
    label,
    n,
    effect_CI,
    p_value_fmt,
    q_value_fmt
  ) %>%
  arrange(outcome_label, q_value)

logistic_fdr_010 <- logistic_results %>%
  filter(!is.na(q_value), q_value < 0.10) %>%
  select(
    outcome_label,
    group,
    label,
    n,
    events,
    OR_CI,
    p_value_fmt,
    q_value_fmt
  ) %>%
  arrange(outcome_label, q_value)

print(continuous_fdr_010)
print(logistic_fdr_010)

# 6. 导出关键结果
write_xlsx(
  list(
    DEHP_mechanism_results = DEHP_mechanism_results,
    MetS_key_results = MetS_key_results,
    continuous_nominal_sig = continuous_nominal_sig,
    logistic_nominal_sig = logistic_nominal_sig,
    continuous_fdr_010 = continuous_fdr_010,
    logistic_fdr_010 = logistic_fdr_010
  ),
  file.path(result_dir, "key_results_extract_2013_2018.xlsx")
)

cat("关键结果已经导出到 result/key_results_extract_2013_2018.xlsx\n")