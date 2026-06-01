# ============================================================
# NHANES 2013-2018
# 42_plot_interaction_results_2013_2018.R
# Plot interaction / stratified results
# ============================================================

library(dplyr)
library(readr)
library(writexl)
library(ggplot2)

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(result_dir, "figures_interaction")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

interaction_tests <- read_csv(
  file.path(result_dir, "interaction_tests_2013_2018.csv"),
  show_col_types = FALSE
)

stratified_results <- read_csv(
  file.path(result_dir, "interaction_stratified_results_2013_2018.csv"),
  show_col_types = FALSE
)

# ------------------------------------------------------------
# 1. Key tables
# ------------------------------------------------------------

key_interaction_tests <- interaction_tests %>%
  filter(priority == "Primary") %>%
  mutate(
    manuscript_decision = case_when(
      q_interaction < 0.05 ~ "Report as FDR-significant interaction",
      p_interaction < 0.05 ~ "Report as nominal interaction; interpret cautiously",
      p_interaction < 0.10 ~ "Mention as suggestive only if biologically plausible",
      TRUE ~ "Report as no clear evidence of effect modification"
    )
  ) %>%
  select(
    outcome_label,
    exposure_label,
    modifier_label,
    n,
    p_interaction_fmt,
    q_interaction_fmt,
    interaction_interpretation,
    manuscript_decision
  ) %>%
  arrange(outcome_label, exposure_label, modifier_label)

key_stratified_results <- stratified_results %>%
  filter(priority == "Primary") %>%
  select(
    outcome_label,
    exposure_label,
    modifier_label,
    level,
    n,
    effect_CI,
    p_value_fmt,
    p_interaction_fmt,
    q_interaction_fmt,
    interaction_interpretation
  ) %>%
  arrange(outcome_label, exposure_label, modifier_label, level)

write_xlsx(
  list(
    key_interaction_tests = key_interaction_tests,
    key_stratified_results = key_stratified_results
  ),
  file.path(result_dir, "interaction_key_results_2013_2018.xlsx")
)

print(key_interaction_tests)

# ------------------------------------------------------------
# 2. Plot primary modifiers
# ------------------------------------------------------------

plot_df <- stratified_results %>%
  filter(
    priority == "Primary",
    exposure_label %in% c("lnΣDEHP", "%Oxidative per 10 percentage points"),
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c")
  ) %>%
  mutate(
    exposure_label = factor(
      exposure_label,
      levels = c("lnΣDEHP", "%Oxidative per 10 percentage points")
    ),
    modifier_label = factor(
      modifier_label,
      levels = c("Sex", "Age group", "Obesity status")
    ),
    panel_label = paste0(exposure_label, " | ", outcome_label),
    level = factor(level, levels = unique(level))
  )

p <- ggplot(
  plot_df,
  aes(x = effect, y = level)
) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.4) +
  geom_errorbarh(
    aes(xmin = effect_low, xmax = effect_high),
    height = 0.18,
    linewidth = 0.5
  ) +
  geom_point(size = 2.2) +
  facet_grid(modifier_label ~ panel_label, scales = "free_y", space = "free_y") +
  labs(
    title = "Effect modification of DEHP-related exposure indicators by sex, age, and obesity status",
    subtitle = "Survey-weighted stratified estimates with formal interaction tests",
    x = "Effect estimate",
    y = NULL,
    caption = "For ln(HOMA-IR), estimates represent percent difference. For HbA1c, estimates represent absolute difference in percentage points. Models were adjusted for age, sex, race/ethnicity, socioeconomic factors, energy intake, urinary creatinine where applicable, and NHANES cycle; the stratifying variable was omitted where appropriate."
  ) +
  theme_bw(base_size = 10) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", size = 8),
    panel.grid.minor = element_blank()
  )

print(p)

ggsave(
  file.path(fig_dir, "interaction_forest_primary_modifiers_2013_2018.png"),
  p,
  width = 13,
  height = 8,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "interaction_forest_primary_modifiers_2013_2018.pdf"),
  p,
  width = 13,
  height = 8
)

cat("Interaction key results and figure exported successfully.\n")