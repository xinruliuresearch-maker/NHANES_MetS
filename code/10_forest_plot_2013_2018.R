library(dplyr)
library(readr)
library(ggplot2)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(result_dir, "figures_2013_2018")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

logistic_results <- read_csv(
  file.path(result_dir, "logistic_results_2013_2018_Model2.csv"),
  show_col_types = FALSE
)

plot_df <- logistic_results %>%
  filter(!is.na(OR), !is.na(OR_low), !is.na(OR_high)) %>%
  mutate(
    significance = case_when(
      q_value < 0.05 ~ "**",
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
    breaks = c(0.5, 0.7, 1, 1.5, 2, 3, 5)
  ) +
  facet_wrap(~ outcome_label, scales = "free_y") +
  labs(
    title = "Urinary organic pollutants and obesity-related outcomes, NHANES 2013–2018",
    subtitle = "Survey-weighted logistic regression adjusted for age, sex, race/ethnicity, income, education, energy intake, urinary creatinine, and cycle",
    x = "Odds ratio per ln-unit increase",
    y = "Pollutant",
    caption = "* nominal P < 0.05; ** FDR q < 0.05"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

print(p_all)

ggsave(
  file.path(fig_dir, "forest_plot_logistic_2013_2018.png"),
  p_all,
  width = 12,
  height = 7,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "forest_plot_logistic_2013_2018.pdf"),
  p_all,
  width = 12,
  height = 7
)

cat("2013–2018 Logistic 森林图已生成。\n")