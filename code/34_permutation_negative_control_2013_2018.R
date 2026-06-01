# ============================================================
# NHANES 2013-2018
# 34_permutation_negative_control_2013_2018.R
# Permutation negative-control analysis
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
fig_dir <- file.path(result_dir, "figures_causal")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

set.seed(20260527)

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_master_analysis_mechanism.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]

if (is.na(data_file)) {
  stop("找不到 2013-2018 分析数据。")
}

df <- readRDS(data_file)

# ------------------------------------------------------------
# 1. Settings
# ------------------------------------------------------------

n_perm <- 1000

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~include_creatinine,
  "ln_Sigma_DEHP", "ln(Sigma DEHP)", TRUE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE
)

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

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
# 2. Model function
# ------------------------------------------------------------

fit_svy_linear <- function(data, outcome, outcome_label, is_log_outcome,
                           exposure, exposure_label, include_creatinine,
                           permuted = FALSE, perm_id = 0) {
  
  exposure_model <- ifelse(permuted, paste0(exposure, "_perm"), exposure)
  
  covar_vars <- if (include_creatinine) covars_with_creatinine else covars_without_creatinine
  covar_terms <- if (include_creatinine) terms_with_creatinine else terms_without_creatinine
  
  model_vars <- c(outcome, exposure_model, covar_vars, design_vars)
  
  d <- data %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 200) return(tibble())
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(outcome, " ~ ", exposure_model, " + ", covar_terms)
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit)) return(tibble())
  
  coef_table <- summary(fit)$coefficients
  
  if (!(exposure_model %in% rownames(coef_table))) return(tibble())
  
  beta <- coef_table[exposure_model, "Estimate"]
  se <- coef_table[exposure_model, "Std. Error"]
  p_value <- coef_table[exposure_model, "Pr(>|t|)"]
  
  if (is_log_outcome) {
    effect <- (exp(beta) - 1) * 100
  } else {
    effect <- beta
  }
  
  tibble(
    analysis = ifelse(permuted, "Permuted exposure", "Observed exposure"),
    perm_id = perm_id,
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = effect
  )
}

permute_within_strata <- function(data, exposure) {
  perm_col <- paste0(exposure, "_perm")
  
  data %>%
    group_by(cycle, RIAGENDR) %>%
    mutate(
      "{perm_col}" := sample(.data[[exposure]], size = n(), replace = FALSE)
    ) %>%
    ungroup()
}

# ------------------------------------------------------------
# 3. Observed results
# ------------------------------------------------------------

observed_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map))
) %>%
  mutate(
    result = map2(outcome_row, exposure_row, function(i, j) {
      fit_svy_linear(
        data = df,
        outcome = outcome_map$outcome[i],
        outcome_label = outcome_map$outcome_label[i],
        is_log_outcome = outcome_map$is_log_outcome[i],
        exposure = exposure_map$exposure[j],
        exposure_label = exposure_map$exposure_label[j],
        include_creatinine = exposure_map$include_creatinine[j],
        permuted = FALSE,
        perm_id = 0
      )
    })
  ) %>%
  select(result) %>%
  unnest(result)

# ------------------------------------------------------------
# 4. Permutation loop
# ------------------------------------------------------------

permutation_results_list <- list()

for (b in seq_len(n_perm)) {
  if (b %% 20 == 0) cat("Permutation:", b, "of", n_perm, "\n")
  
  df_perm <- df
  
  for (exp_i in exposure_map$exposure) {
    df_perm <- permute_within_strata(df_perm, exp_i)
  }
  
  res_b <- expand_grid(
    outcome_row = seq_len(nrow(outcome_map)),
    exposure_row = seq_len(nrow(exposure_map))
  ) %>%
    mutate(
      result = map2(outcome_row, exposure_row, function(i, j) {
        fit_svy_linear(
          data = df_perm,
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          is_log_outcome = outcome_map$is_log_outcome[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          include_creatinine = exposure_map$include_creatinine[j],
          permuted = TRUE,
          perm_id = b
        )
      })
    ) %>%
    select(result) %>%
    unnest(result)
  
  permutation_results_list[[b]] <- res_b
}

permutation_results <- bind_rows(permutation_results_list)

# ------------------------------------------------------------
# 5. Summary
# ------------------------------------------------------------

permutation_summary <- permutation_results %>%
  group_by(outcome_label, exposure_label) %>%
  summarise(
    n_perm_success = n(),
    perm_beta_mean = mean(beta, na.rm = TRUE),
    perm_beta_sd = sd(beta, na.rm = TRUE),
    perm_beta_p025 = quantile(beta, 0.025, na.rm = TRUE),
    perm_beta_p975 = quantile(beta, 0.975, na.rm = TRUE),
    perm_p_lt_005_rate = mean(p_value < 0.05, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    observed_results %>%
      select(
        outcome_label,
        exposure_label,
        observed_beta = beta,
        observed_effect = effect,
        observed_p_value = p_value
      ),
    by = c("outcome_label", "exposure_label")
  ) %>%
  mutate(
    empirical_p_two_sided = map2_dbl(outcome_label, exposure_label, function(out_i, exp_i) {
      obs_beta <- observed_results %>%
        filter(outcome_label == out_i, exposure_label == exp_i) %>%
        pull(beta)
      
      perm_beta <- permutation_results %>%
        filter(outcome_label == out_i, exposure_label == exp_i) %>%
        pull(beta)
      
      if (length(obs_beta) == 0 || length(perm_beta) == 0) return(NA_real_)
      
      mean(abs(perm_beta) >= abs(obs_beta), na.rm = TRUE)
    }),
    interpretation = case_when(
      observed_p_value < 0.05 & empirical_p_two_sided < 0.05 & perm_p_lt_005_rate <= 0.10 ~
        "Observed association exceeds permutation null",
      observed_p_value < 0.05 & empirical_p_two_sided >= 0.05 ~
        "Observed association not clearly separated from permutation null",
      TRUE ~
        "Limited observed association"
    )
  )

print(permutation_summary)

# ------------------------------------------------------------
# 6. Export
# ------------------------------------------------------------

write_csv(
  observed_results,
  file.path(result_dir, "permutation_observed_results_2013_2018.csv")
)

write_csv(
  permutation_results,
  file.path(result_dir, "permutation_null_results_2013_2018.csv")
)

write_xlsx(
  list(
    observed_results = observed_results,
    permutation_summary = permutation_summary,
    permutation_null_results = permutation_results
  ),
  file.path(result_dir, "permutation_negative_control_2013_2018.xlsx")
)

# ------------------------------------------------------------
# 7. Plot
# ------------------------------------------------------------

plot_df <- permutation_results %>%
  mutate(panel = paste(outcome_label, exposure_label, sep = " | "))

obs_df <- observed_results %>%
  mutate(panel = paste(outcome_label, exposure_label, sep = " | "))

p <- ggplot(plot_df, aes(x = beta)) +
  geom_histogram(bins = 30) +
  geom_vline(
    data = obs_df,
    aes(xintercept = beta),
    linetype = "dashed",
    linewidth = 0.8
  ) +
  facet_wrap(~ panel, scales = "free") +
  labs(
    title = "Permutation negative-control analysis",
    subtitle = "Dashed line indicates observed beta; histograms show permuted exposure null distribution",
    x = "Beta estimate",
    y = "Permutation count",
    caption = "Exposure was permuted within sex and NHANES cycle strata."
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(size = 8)
  )

print(p)

ggsave(
  file.path(fig_dir, "permutation_negative_control_2013_2018.png"),
  p,
  width = 11,
  height = 7,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "permutation_negative_control_2013_2018.pdf"),
  p,
  width = 11,
  height = 7
)

cat("Permutation negative-control analysis completed successfully.\n")