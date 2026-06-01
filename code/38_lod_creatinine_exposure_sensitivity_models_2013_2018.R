# ============================================================
# NHANES 2013-2018
# 38_lod_creatinine_exposure_sensitivity_models_2013_2018.R
# LOD, creatinine, and exposure-processing sensitivity models
# ============================================================

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(tibble)
library(survey)
library(writexl)
library(ggplot2)

options(survey.lonely.psu = "adjust")

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(result_dir, "figures_exposure_sensitivity")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(
  file.path(output_dir, "NHANES_2013_2018_exposure_sensitivity_dataset.rds")
)

# ------------------------------------------------------------
# 1. Outcomes
# ------------------------------------------------------------

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

# ------------------------------------------------------------
# 2. Exposure model scenarios
# ------------------------------------------------------------

scenario_map <- tibble::tribble(
  ~scenario, ~exposure, ~exposure_label, ~include_creatinine, ~restriction,
  
  "Main model, creatinine-adjusted",
  "ln_Sigma_DEHP", "ln(Sigma DEHP)", TRUE, "none",
  
  "Main model, creatinine-adjusted",
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE, "none",
  
  "Main model, creatinine-adjusted",
  "ln_URXMHH", "MEHHP", TRUE, "none",
  
  "Main model, creatinine-adjusted",
  "ln_URXMOH", "MEOHP", TRUE, "none",
  
  "Main model, creatinine-adjusted",
  "ln_URXECP", "MECPP", TRUE, "none",
  
  "Exclude urinary creatinine <30 or >300 mg/dL",
  "ln_Sigma_DEHP", "ln(Sigma DEHP)", TRUE, "valid_creatinine",
  
  "Exclude urinary creatinine <30 or >300 mg/dL",
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE, "valid_creatinine",
  
  "Creatinine-standardized exposure, no creatinine covariate",
  "ln_cr_Sigma_DEHP", "ln(creatinine-standardized Sigma DEHP)", FALSE, "none",
  
  "Creatinine-standardized exposure, no creatinine covariate",
  "ln_cr_URXMHH", "creatinine-standardized MEHHP", FALSE, "none",
  
  "Creatinine-standardized exposure, no creatinine covariate",
  "ln_cr_URXMOH", "creatinine-standardized MEOHP", FALSE, "none",
  
  "Creatinine-standardized exposure, no creatinine covariate",
  "ln_cr_URXECP", "creatinine-standardized MECPP", FALSE, "none",
  
  "Exclude any DEHP component below LOD",
  "ln_Sigma_DEHP", "ln(Sigma DEHP)", TRUE, "all_dehp_detected",
  
  "Exclude oxidative components below LOD",
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE, "all_oxidative_detected",
  
  "Exclude oxidative components below LOD",
  "ln_URXMHH", "MEHHP", TRUE, "all_oxidative_detected",
  
  "Exclude oxidative components below LOD",
  "ln_URXMOH", "MEOHP", TRUE, "all_oxidative_detected",
  
  "Exclude oxidative components below LOD",
  "ln_URXECP", "MECPP", TRUE, "all_oxidative_detected",
  
  "Winsorized exposure, 1st-99th percentile",
  "ln_Sigma_DEHP_w", "winsorized ln(Sigma DEHP)", TRUE, "none",
  
  "Winsorized exposure, 1st-99th percentile",
  "pct_oxidative_10_w", "winsorized %Oxidative per 10 percentage points", FALSE, "none",
  
  "Winsorized exposure, 1st-99th percentile",
  "ln_URXMHH_w", "winsorized MEHHP", TRUE, "none",
  
  "Winsorized exposure, 1st-99th percentile",
  "ln_URXMOH_w", "winsorized MEOHP", TRUE, "none",
  
  "Winsorized exposure, 1st-99th percentile",
  "ln_URXECP_w", "winsorized MECPP", TRUE, "none"
)

# ------------------------------------------------------------
# 3. Model settings
# ------------------------------------------------------------

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")

covars_with_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

covars_without_creatinine <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "cycle"
)

terms_with_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

terms_without_creatinine <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + factor(cycle)"
)

# ------------------------------------------------------------
# 4. Restriction helper
# ------------------------------------------------------------

apply_restriction <- function(dat, restriction) {
  if (restriction == "none") {
    return(dat)
  }
  
  if (restriction == "valid_creatinine") {
    return(dat %>% filter(urinary_creatinine_valid_30_300 == 1))
  }
  
  if (restriction == "all_dehp_detected") {
    return(dat %>% filter(all_dehp_detected == 1))
  }
  
  if (restriction == "all_oxidative_detected") {
    return(dat %>% filter(all_oxidative_detected == 1))
  }
  
  dat
}

# ------------------------------------------------------------
# 5. Survey model function
# ------------------------------------------------------------

run_sensitivity_model <- function(outcome, outcome_label, is_log_outcome,
                                  scenario, exposure, exposure_label,
                                  include_creatinine, restriction) {
  
  covar_vars <- if (include_creatinine) covars_with_creatinine else covars_without_creatinine
  covar_terms <- if (include_creatinine) terms_with_creatinine else terms_without_creatinine
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars,
                  "urinary_creatinine_valid_30_300",
                  "all_dehp_detected",
                  "all_oxidative_detected")
  
  d <- df %>%
    select(any_of(model_vars)) %>%
    apply_restriction(restriction) %>%
    drop_na()
  
  if (nrow(d) < 200) {
    return(tibble(
      outcome = outcome,
      outcome_label = outcome_label,
      scenario = scenario,
      exposure = exposure,
      exposure_label = exposure_label,
      restriction = restriction,
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
    weights = ~WTSB6YR_MAIN,
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
  
  if (is.null(fit)) return(tibble())
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure %in% rownames(coef_table))) return(tibble())
  
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
    outcome = outcome,
    outcome_label = outcome_label,
    scenario = scenario,
    exposure = exposure,
    exposure_label = exposure_label,
    restriction = restriction,
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
# 6. Batch run
# ------------------------------------------------------------

sensitivity_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  scenario_row = seq_len(nrow(scenario_map))
) %>%
  mutate(
    result = map2(outcome_row, scenario_row, function(i, j) {
      run_sensitivity_model(
        outcome = outcome_map$outcome[i],
        outcome_label = outcome_map$outcome_label[i],
        is_log_outcome = outcome_map$is_log_outcome[i],
        scenario = scenario_map$scenario[j],
        exposure = scenario_map$exposure[j],
        exposure_label = scenario_map$exposure_label[j],
        include_creatinine = scenario_map$include_creatinine[j],
        restriction = scenario_map$restriction[j]
      )
    })
  ) %>%
  select(result) %>%
  unnest(result) %>%
  group_by(outcome_label, scenario) %>%
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
      beta > 0 ~ "positive",
      beta < 0 ~ "negative",
      TRUE ~ "null"
    )
  )

# ------------------------------------------------------------
# 7. Key summary
# ------------------------------------------------------------

key_sensitivity <- sensitivity_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    grepl("Sigma|Oxidative|MEHHP|MEOHP|MECPP", exposure_label)
  ) %>%
  arrange(outcome_label, scenario, exposure_label)

scenario_summary <- sensitivity_results %>%
  group_by(outcome_label, scenario) %>%
  summarise(
    n_models = n(),
    positive_models = sum(direction == "positive", na.rm = TRUE),
    nominal_sig_models = sum(p_value < 0.05, na.rm = TRUE),
    fdr_sig_models = sum(q_value < 0.05, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    robustness = case_when(
      positive_models == n_models & nominal_sig_models >= ceiling(n_models / 2) ~ "strong",
      positive_models == n_models ~ "direction-consistent",
      positive_models >= ceiling(n_models / 2) ~ "partial",
      TRUE ~ "weak"
    )
  )

print(key_sensitivity)
print(scenario_summary)

# ------------------------------------------------------------
# 8. Export
# ------------------------------------------------------------

write_csv(
  sensitivity_results,
  file.path(result_dir, "lod_creatinine_exposure_sensitivity_models_2013_2018.csv")
)

write_xlsx(
  list(
    all_sensitivity_results = sensitivity_results,
    key_sensitivity = key_sensitivity,
    scenario_summary = scenario_summary
  ),
  file.path(result_dir, "lod_creatinine_exposure_sensitivity_models_2013_2018.xlsx")
)

# ------------------------------------------------------------
# 9. Plot key exposures
# ------------------------------------------------------------

plot_df <- sensitivity_results %>%
  filter(
    outcome_label %in% c("ln(HOMA-IR)", "HbA1c"),
    exposure_label %in% c(
      "ln(Sigma DEHP)",
      "%Oxidative per 10 percentage points",
      "ln(creatinine-standardized Sigma DEHP)",
      "winsorized ln(Sigma DEHP)",
      "winsorized %Oxidative per 10 percentage points"
    )
  ) %>%
  mutate(
    label_short = case_when(
      exposure_label == "ln(Sigma DEHP)" ~ "Main Sigma",
      exposure_label == "%Oxidative per 10 percentage points" ~ "Main %Oxidative",
      exposure_label == "ln(creatinine-standardized Sigma DEHP)" ~ "Cr-standardized Sigma",
      exposure_label == "winsorized ln(Sigma DEHP)" ~ "Winsorized Sigma",
      exposure_label == "winsorized %Oxidative per 10 percentage points" ~ "Winsorized %Oxidative",
      TRUE ~ exposure_label
    )
  )

p <- ggplot(
  plot_df,
  aes(x = label_short, y = effect)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 2.5) +
  geom_errorbar(
    aes(ymin = effect_low, ymax = effect_high),
    width = 0.15
  ) +
  facet_grid(outcome_label ~ scenario, scales = "free_y") +
  labs(
    title = "LOD, creatinine, and exposure-processing sensitivity analyses",
    subtitle = "NHANES 2013-2018 survey-weighted models",
    x = "Exposure specification",
    y = "Effect estimate",
    caption = "Main model adjusted for urinary creatinine; creatinine-standardized models do not include urinary creatinine as covariate."
  ) +
  theme_bw(base_size = 10) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", size = 8),
    axis.text.x = element_text(angle = 35, hjust = 1)
  )

print(p)

ggsave(
  file.path(fig_dir, "lod_creatinine_exposure_sensitivity_2013_2018.png"),
  p,
  width = 13,
  height = 7,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "lod_creatinine_exposure_sensitivity_2013_2018.pdf"),
  p,
  width = 13,
  height = 7
)

cat("LOD, creatinine, and exposure-processing sensitivity models completed successfully.\n")