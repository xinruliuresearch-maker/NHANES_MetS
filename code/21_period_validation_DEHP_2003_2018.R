# ============================================================
# NHANES 2003-2018
# 21_period_validation_DEHP_2003_2018.R
# Period-specific validation
# ============================================================

library(dplyr)
library(purrr)
library(tidyr)
library(readr)
library(tibble)
library(survey)
library(writexl)
library(ggplot2)

options(survey.lonely.psu = "adjust")

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(result_dir, "figures_2003_2018")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(
  file.path(output_dir, "NHANES_2003_2018_DEHP_only_master.rds")
)

# ------------------------------------------------------------
# 1. Exposures and outcomes
# ------------------------------------------------------------

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~include_creatinine,
  "ln_Sigma_DEHP", "ln(Sigma DEHP)", TRUE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE,
  "ln_URXMHH", "MEHHP", TRUE,
  "ln_URXMOH", "MEOHP", TRUE,
  "ln_URXECP", "MECPP", TRUE
)

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSDEHP_PERIOD")

covars_with_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "race_eth",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

covars_without_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "race_eth",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "cycle"
)

terms_with_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(race_eth) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

terms_without_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(race_eth) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + factor(cycle)"
)

# ------------------------------------------------------------
# 2. Period model function
# ------------------------------------------------------------

run_period_model <- function(period_value, outcome, outcome_label, is_log_outcome,
                             exposure, exposure_label, include_creatinine) {
  
  data_p <- df %>% filter(period == period_value)
  
  covar_vars <- if (include_creatinine) covars_with_creatinine else covars_without_creatinine
  covar_terms <- if (include_creatinine) terms_with_creatinine else terms_without_creatinine
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars)
  
  d <- data_p %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100) {
    return(tibble(
      period = as.character(period_value),
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_
    ))
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSDEHP_PERIOD,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(outcome, " ~ ", exposure, " + ", covar_terms)
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble())
  }
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) {
    return(tibble())
  }
  
  beta <- coef_table[exposure, "Estimate"]
  se <- coef_table[exposure, "Std. Error"]
  p_value <- coef_table[exposure, "Pr(>|t|)"]
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  low <- beta - tcrit * se
  high <- beta + tcrit * se
  
  if (is_log_outcome) {
    effect <- (exp(beta) - 1) * 100
    effect_low <- (exp(low) - 1) * 100
    effect_high <- (exp(high) - 1) * 100
  } else {
    effect <- beta
    effect_low <- low
    effect_high <- high
  }
  
  tibble(
    period = as.character(period_value),
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = effect,
    effect_low = effect_low,
    effect_high = effect_high
  )
}

# ------------------------------------------------------------
# 3. Batch run
# ------------------------------------------------------------

period_results <- expand_grid(
  period_value = levels(df$period),
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result = pmap(
      list(period_value, outcome_row, exposure_row),
      function(period_value, i, j) {
        run_period_model(
          period_value = period_value,
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          is_log_outcome = outcome_map$is_log_outcome[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          include_creatinine = exposure_map$include_creatinine[j]
        )
      }
    )
  ) %>%
  select(result) %>%
  unnest(result) %>%
  group_by(period, outcome) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    effect_CI = sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high),
    p_value_fmt = case_when(
      is.na(p_value) ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_value)
    ),
    q_value_fmt = case_when(
      is.na(q_value) ~ NA_character_,
      q_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", q_value)
    ),
    direction = case_when(
      is.na(beta) ~ NA_character_,
      beta > 0 ~ "positive",
      beta < 0 ~ "negative",
      TRUE ~ "null"
    )
  )

period_summary <- period_results %>%
  group_by(outcome_label, exposure_label) %>%
  summarise(
    n_periods = n(),
    positive_periods = sum(direction == "positive", na.rm = TRUE),
    nominal_sig_periods = sum(p_value < 0.05, na.rm = TRUE),
    fdr_sig_periods = sum(q_value < 0.05, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    consistency = case_when(
      positive_periods == n_periods & nominal_sig_periods >= 2 ~ "strong",
      positive_periods == n_periods ~ "direction-consistent",
      positive_periods >= 2 ~ "partial",
      TRUE ~ "weak"
    )
  )

print(period_results)
print(period_summary)

# ------------------------------------------------------------
# 4. Export tables
# ------------------------------------------------------------

write_csv(
  period_results,
  file.path(result_dir, "DEHP_only_2003_2018_period_results.csv")
)

write_xlsx(
  list(
    period_results = period_results,
    period_summary = period_summary
  ),
  file.path(result_dir, "DEHP_only_2003_2018_period_validation.xlsx")
)

# ------------------------------------------------------------
# 5. Plot
# ------------------------------------------------------------

plot_df <- period_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    exposure_label %in% c(
      "ln(Sigma DEHP)",
      "%Oxidative per 10 percentage points",
      "MEHHP", "MEOHP", "MECPP"
    )
  )

p <- ggplot(
  plot_df,
  aes(x = period, y = effect, group = exposure_label)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 2.3) +
  geom_errorbar(
    aes(ymin = effect_low, ymax = effect_high),
    width = 0.12
  ) +
  facet_grid(outcome_label ~ exposure_label, scales = "free_y") +
  labs(
    title = "Period-specific validation of DEHP associations with metabolic markers, NHANES 2003-2018",
    x = "NHANES period",
    y = "Effect estimate",
    caption = "Adjusted for age, sex, race/ethnicity, income, education, energy intake, urinary creatinine when applicable, and cycle."
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_text(angle = 30, hjust = 1)
  )

print(p)

ggsave(
  file.path(fig_dir, "DEHP_period_validation_2003_2018.png"),
  p,
  width = 12,
  height = 7,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "DEHP_period_validation_2003_2018.pdf"),
  p,
  width = 12,
  height = 7
)

cat("Period-specific validation completed successfully.\n")