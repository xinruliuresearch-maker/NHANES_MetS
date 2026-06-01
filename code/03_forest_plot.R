# ============================================================
# NHANES 2017-2018
# Organic Pollutants and Obesity / Metabolic Syndrome
# 03_forest_plot.R
# ============================================================

library(dplyr)
library(readr)
library(ggplot2)
library(stringr)
library(forcats)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(project_dir, "result", "figures")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. 读取基础模型结果
# ------------------------------------------------------------

basic_results <- read_csv(
  file.path(result_dir, "basic_weighted_logistic_results.csv"),
  show_col_types = FALSE
)

# ------------------------------------------------------------
# 2. 整理绘图数据
# ------------------------------------------------------------

plot_df <- basic_results %>%
  filter(!is.na(OR), !is.na(OR_low), !is.na(OR_high)) %>%
  mutate(
    label_group = paste0(label, "  [", group, "]"),
    significance = case_when(
      p_value < 0.001 ~ "***",
      p_value < 0.01 ~ "**",
      p_value < 0.05 ~ "*",
      TRUE ~ ""
    ),
    label_with_p = paste0(label, significance),
    outcome_label = factor(
      outcome_label,
      levels = c("Obesity", "Central obesity", "Metabolic syndrome")
    )
  )

# ------------------------------------------------------------
# 3. 生成一个总森林图
# ------------------------------------------------------------

p_all <- ggplot(
  plot_df,
  aes(
    x = OR,
    y = fct_reorder(label_with_p, OR)
  )
) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  geom_errorbarh(
    aes(xmin = OR_low, xmax = OR_high),
    height = 0.2
  ) +
  geom_point(size = 2) +
  scale_x_log10() +
  facet_wrap(~ outcome_label, scales = "free_y") +
  labs(
    title = "Associations of urinary organic pollutants with obesity-related outcomes",
    subtitle = "Weighted logistic regression adjusted for age, sex, race/ethnicity, income, energy intake, and urinary creatinine",
    x = "Odds ratio per ln-unit increase in pollutant concentration",
    y = "Pollutant",
    caption = "* P < 0.05; ** P < 0.01; *** P < 0.001"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

print(p_all)

ggsave(
  filename = file.path(fig_dir, "forest_plot_all_outcomes.png"),
  plot = p_all,
  width = 12,
  height = 7,
  dpi = 300
)

ggsave(
  filename = file.path(fig_dir, "forest_plot_all_outcomes.pdf"),
  plot = p_all,
  width = 12,
  height = 7
)

# ------------------------------------------------------------
# 4. 为每个结局单独生成森林图
# ------------------------------------------------------------

outcomes <- unique(plot_df$outcome_label)

for (oc in outcomes) {
  
  d <- plot_df %>%
    filter(outcome_label == oc) %>%
    arrange(OR)
  
  p <- ggplot(
    d,
    aes(
      x = OR,
      y = fct_reorder(label_with_p, OR)
    )
  ) +
    geom_vline(xintercept = 1, linetype = "dashed") +
    geom_errorbarh(
      aes(xmin = OR_low, xmax = OR_high),
      height = 0.2
    ) +
    geom_point(size = 2.5) +
    scale_x_log10() +
    labs(
      title = paste0("Organic pollutants and ", oc),
      subtitle = "Weighted logistic regression model",
      x = "Odds ratio per ln-unit increase",
      y = "Pollutant",
      caption = "Adjusted for age, sex, race/ethnicity, income, energy intake, and urinary creatinine"
    ) +
    theme_bw(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
  
  print(p)
  
  file_stub <- str_replace_all(tolower(as.character(oc)), " ", "_")
  
  ggsave(
    filename = file.path(fig_dir, paste0("forest_plot_", file_stub, ".png")),
    plot = p,
    width = 8,
    height = 6,
    dpi = 300
  )
  
  ggsave(
    filename = file.path(fig_dir, paste0("forest_plot_", file_stub, ".pdf")),
    plot = p,
    width = 8,
    height = 6
  )
}

cat("森林图已经生成到 result/figures 文件夹。\n")