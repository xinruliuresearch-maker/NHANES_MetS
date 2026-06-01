# ============================================================
# NHANES 2017-2018
# 03_forest_plot_tCI.R
# Forest plots using t-based CI results
# ============================================================

library(dplyr)
library(readr)
library(ggplot2)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(project_dir, "result", "figures_tCI")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

basic_results <- read_csv(
  file.path(result_dir, "basic_weighted_logistic_results_tCI.csv"),
  show_col_types = FALSE
)

plot_df <- basic_results %>%
  filter(!is.na(OR), !is.na(OR_low), !is.na(OR_high)) %>%
  mutate(
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

p_all <- ggplot(
  plot_df,
  aes(
    x = OR,
    y = reorder(label_with_p, OR)
  )
) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  geom_errorbarh(
    aes(xmin = OR_low, xmax = OR_high),
    height = 0.2
  ) +
  geom_point(size = 2) +
  scale_x_log10(
    breaks = c(0.5, 0.7, 1, 1.5, 2, 3, 5, 10, 20)
  ) +
  facet_wrap(~ outcome_label, scales = "free_y") +
  labs(
    title = "Associations of urinary organic pollutants with obesity-related outcomes",
    subtitle = "Survey-weighted logistic regression with t-based 95% confidence intervals",
    x = "Odds ratio per ln-unit increase in pollutant concentration",
    y = "Pollutant",
    caption = "Adjusted for age, sex, race/ethnicity, income, energy intake, and urinary creatinine"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

print(p_all)

ggsave(
  filename = file.path(fig_dir, "forest_plot_all_outcomes_tCI.png"),
  plot = p_all,
  width = 12,
  height = 7,
  dpi = 300
)

ggsave(
  filename = file.path(fig_dir, "forest_plot_all_outcomes_tCI.pdf"),
  plot = p_all,
  width = 12,
  height = 7
)

outcomes <- unique(plot_df$outcome_label)

for (oc in outcomes) {
  
  d <- plot_df %>%
    filter(outcome_label == oc) %>%
    arrange(OR)
  
  p <- ggplot(
    d,
    aes(
      x = OR,
      y = reorder(label_with_p, OR)
    )
  ) +
    geom_vline(xintercept = 1, linetype = "dashed") +
    geom_errorbarh(
      aes(xmin = OR_low, xmax = OR_high),
      height = 0.2
    ) +
    geom_point(size = 2.5) +
    scale_x_log10(
      breaks = c(0.5, 0.7, 1, 1.5, 2, 3, 5, 10, 20)
    ) +
    labs(
      title = paste0("Organic pollutants and ", oc),
      subtitle = "Survey-weighted logistic regression with t-based 95% CI",
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
  
  file_stub <- tolower(as.character(oc))
  file_stub <- gsub(" ", "_", file_stub)
  
  ggsave(
    filename = file.path(fig_dir, paste0("forest_plot_", file_stub, "_tCI.png")),
    plot = p,
    width = 8,
    height = 6,
    dpi = 300
  )
  
  ggsave(
    filename = file.path(fig_dir, paste0("forest_plot_", file_stub, "_tCI.pdf")),
    plot = p,
    width = 8,
    height = 6
  )
}
