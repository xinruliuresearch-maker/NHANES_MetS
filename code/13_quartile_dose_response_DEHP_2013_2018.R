# ============================================================
# NHANES 2013-2018
# 13_quartile_dose_response_DEHP_2013_2018.R
# Quartile dose-response analysis for DEHP metabolites
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
fig_dir <- file.path(result_dir, "figures_2013_2018")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

analysis_df <- readRDS(
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

dehp_map <- tibble::tribble(
  ~label,  ~exposure,
  "MEHP",  "ln_URXMHP",
  "MEHHP", "ln_URXMHH",
  "MEOHP", "ln_URXMOH",
  "MECPP", "ln_URXECP"
)

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

covar_vars <- c(
  "RIDAGEYR", "RIAGENDR", "RIDRETH3",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")

covar_terms <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

make_quartile <- function(x) {
  qs <- quantile(x, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
  qs <- unique(qs)
  
  if (length(qs) < 5) {
    return(rep(NA_character_, length(x)))
  }
  
  cut(
    x,
    breaks = qs,
    include.lowest = TRUE,
    labels = c("Q1", "Q2", "Q3", "Q4")
  )
}

run_quartile_model <- function(outcome, outcome_label, is_log_outcome, exposure, label) {
  
  model_vars <- c(outcome, exposure, covar_vars, design_vars)
  
  d <- analysis_df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 100) {
    return(tibble())
  }
  
  d <- d %>%
    mutate(
      exposure_q = make_quartile(.data[[exposure]]),
      exposure_q = factor(exposure_q, levels = c("Q1", "Q2", "Q3", "Q4")),
      exposure_q_score = as.integer(exposure_q)
    ) %>%
    drop_na(exposure_q, exposure_q_score)
  
  if (length(unique(d$exposure_q)) < 4) {
    return(tibble())
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  # Quartile categorical model
  f_cat <- as.formula(
    paste0(outcome, " ~ exposure_q + ", covar_terms)
  )
  
  fit_cat <- tryCatch(
    svyglm(f_cat, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit_cat)) {
    return(tibble())
  }
  
  coef_cat <- summary(fit_cat)$coefficients
  
  q_terms <- rownames(coef_cat)[grepl("^exposure_q", rownames(coef_cat))]
  
  cat_results <- map_dfr(q_terms, function(term_i) {
    
    beta <- coef_cat[term_i, "Estimate"]
    se <- coef_cat[term_i, "Std. Error"]
    p_value <- coef_cat[term_i, "Pr(>|t|)"]
    
    df_resid <- fit_cat$df.residual
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
      label = label,
      exposure = exposure,
      quartile = gsub("exposure_q", "", term_i),
      reference = "Q1",
      n = nrow(d),
      beta = beta,
      se = se,
      p_value = p_value,
      effect = effect,
      effect_low = effect_low,
      effect_high = effect_high
    )
  })
  
  # Trend model
  f_trend <- as.formula(
    paste0(outcome, " ~ exposure_q_score + ", covar_terms)
  )
  
  fit_trend <- tryCatch(
    svyglm(f_trend, design = des),
    error = function(e) NULL
  )
  
  trend_p <- NA_real_
  
  if (!is.null(fit_trend)) {
    coef_trend <- summary(fit_trend)$coefficients
    if ("exposure_q_score" %in% rownames(coef_trend)) {
      trend_p <- coef_trend["exposure_q_score", "Pr(>|t|)"]
    }
  }
  
  cat_results %>%
    mutate(
      p_trend = trend_p
    )
}

quartile_results <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(dehp_map))
) %>%
  mutate(
    result = map2(outcome_row, exposure_row, function(i, j) {
      run_quartile_model(
        outcome = outcome_map$outcome[i],
        outcome_label = outcome_map$outcome_label[i],
        is_log_outcome = outcome_map$is_log_outcome[i],
        exposure = dehp_map$exposure[j],
        label = dehp_map$label[j]
      )
    })
  ) %>%
  select(result) %>%
  unnest(result) %>%
  group_by(outcome, label) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup() %>%
  mutate(
    effect_CI = sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high),
    p_value_fmt = case_when(
      is.na(p_value) ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_value)
    ),
    p_trend_fmt = case_when(
      is.na(p_trend) ~ NA_character_,
      p_trend < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_trend)
    ),
    q_value_fmt = case_when(
      is.na(q_value) ~ NA_character_,
      q_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", q_value)
    )
  )

print(quartile_results)

write_csv(
  quartile_results,
  file.path(result_dir, "quartile_dose_response_DEHP_2013_2018.csv")
)

write_xlsx(
  list(
    quartile_dose_response = quartile_results
  ),
  file.path(result_dir, "quartile_dose_response_DEHP_2013_2018.xlsx")
)

# ------------------------------------------------------------
# 绘图
# ------------------------------------------------------------

plot_df <- quartile_results %>%
  filter(label %in% c("MEHHP", "MEOHP", "MECPP")) %>%
  mutate(
    quartile = factor(quartile, levels = c("Q2", "Q3", "Q4")),
    sig = case_when(
      q_value < 0.05 ~ "**",
      p_value < 0.05 ~ "*",
      TRUE ~ ""
    )
  )

p_quartile <- ggplot(
  plot_df,
  aes(x = quartile, y = effect, group = label)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 2.5) +
  geom_errorbar(
    aes(ymin = effect_low, ymax = effect_high),
    width = 0.15
  ) +
  geom_text(
    aes(label = sig),
    vjust = -0.8,
    size = 5
  ) +
  facet_grid(outcome_label ~ label, scales = "free_y") +
  labs(
    title = "Quartile dose-response associations of DEHP metabolites with metabolic markers",
    subtitle = "Reference group: Q1; adjusted for age, sex, race/ethnicity, income, education, energy intake, urinary creatinine, and cycle",
    x = "Exposure quartile",
    y = "Effect estimate vs Q1",
    caption = "* nominal P < 0.05; ** FDR q < 0.05"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

print(p_quartile)

ggsave(
  file.path(fig_dir, "quartile_dose_response_DEHP_2013_2018.png"),
  p_quartile,
  width = 10,
  height = 6,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "quartile_dose_response_DEHP_2013_2018.pdf"),
  p_quartile,
  width = 10,
  height = 6
)

cat("DEHP 四分位剂量反应分析完成。\n")