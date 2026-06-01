# ============================================================
# NHANES 2003-2018
# 24_survey_qgcomp_DEHP_2003_2018.R
# Long-cycle survey-weighted qgcomp-like validation
# ============================================================

library(dplyr)
library(tidyr)
library(readr)
library(tibble)
library(purrr)
library(survey)
library(writexl)
library(ggplot2)

options(survey.lonely.psu = "adjust")

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(result_dir, "figures_mixture")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(
  file.path(output_dir, "NHANES_2003_2018_DEHP_only_master.rds")
)

mixture_sets <- list(
  DEHP_all = c("ln_URXMHP", "ln_URXMHH", "ln_URXMOH", "ln_URXECP"),
  DEHP_oxidative = c("ln_URXMHH", "ln_URXMOH", "ln_URXECP")
)

component_labels <- tibble::tribble(
  ~variable, ~component,
  "ln_URXMHP", "MEHP",
  "ln_URXMHH", "MEHHP",
  "ln_URXMOH", "MEOHP",
  "ln_URXECP", "MECPP"
)

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

covars <- c(
  "RIDAGEYR", "RIAGENDR", "race_eth",
  "INDFMPIR", "DMDEDUC2", "DR1TKCAL",
  "ln_URXUCR", "cycle"
)

covar_terms <- paste0(
  "RIDAGEYR + factor(RIAGENDR) + factor(race_eth) + ",
  "INDFMPIR + factor(DMDEDUC2) + DR1TKCAL + ln_URXUCR + factor(cycle)"
)

weighted_quantile <- function(x, w, probs) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  
  x <- x[ok]
  w <- w[ok]
  
  if (length(x) == 0) {
    return(rep(NA_real_, length(probs)))
  }
  
  ord <- order(x)
  x <- x[ord]
  w <- w[ord]
  w <- w / sum(w)
  cw <- cumsum(w)
  
  sapply(probs, function(p) {
    x[which(cw >= p)[1]]
  })
}

make_weighted_qscore <- function(x, w, q = 4) {
  out <- rep(NA_integer_, length(x))
  ok <- !is.na(x) & !is.na(w) & w > 0
  
  if (sum(ok) < 50) {
    return(out)
  }
  
  probs <- seq(0, 1, length.out = q + 1)
  breaks <- weighted_quantile(x[ok], w[ok], probs)
  
  breaks[1] <- -Inf
  breaks[length(breaks)] <- Inf
  breaks <- unique(breaks)
  
  if (length(breaks) < 3) {
    return(out)
  }
  
  out[ok] <- as.integer(
    cut(
      x[ok],
      breaks = breaks,
      include.lowest = TRUE,
      labels = FALSE
    )
  ) - 1
  
  out
}

run_survey_qgcomp <- function(data, mixture_name, exposure_vars,
                              outcome, outcome_label, is_log_outcome,
                              weight_var,
                              dataset_label,
                              period_label = "Overall_2003_2018") {
  
  q_vars <- paste0("q_", exposure_vars)
  
  design_vars <- c("SDMVPSU", "SDMVSTRA", weight_var)
  
  model_vars <- c(
    outcome, exposure_vars, covars, design_vars
  )
  
  d <- data %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 200) {
    return(list(
      mixture_result = tibble(),
      weight_result = tibble()
    ))
  }
  
  for (i in seq_along(exposure_vars)) {
    d[[q_vars[i]]] <- make_weighted_qscore(
      d[[exposure_vars[i]]],
      d[[weight_var]],
      q = 4
    )
  }
  
  d <- d %>%
    drop_na(any_of(q_vars))
  
  if (nrow(d) < 200) {
    return(list(
      mixture_result = tibble(),
      weight_result = tibble()
    ))
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = as.formula(paste0("~", weight_var)),
    nest = TRUE,
    data = d
  )
  
  f <- as.formula(
    paste0(outcome, " ~ ", paste(q_vars, collapse = " + "), " + ", covar_terms)
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(list(
      mixture_result = tibble(),
      weight_result = tibble()
    ))
  }
  
  coef_table <- summary(fit)$coefficients
  available_q_vars <- intersect(q_vars, rownames(coef_table))
  
  if (length(available_q_vars) == 0) {
    return(list(
      mixture_result = tibble(),
      weight_result = tibble()
    ))
  }
  
  beta_vec <- coef(fit)[available_q_vars]
  vc <- vcov(fit)[available_q_vars, available_q_vars, drop = FALSE]
  
  psi <- sum(beta_vec)
  psi_se <- sqrt(sum(vc))
  
  df_resid <- fit$df.residual
  tcrit <- ifelse(is.na(df_resid) || df_resid <= 0, 1.96, qt(0.975, df = df_resid))
  
  psi_low <- psi - tcrit * psi_se
  psi_high <- psi + tcrit * psi_se
  
  p_value <- 2 * pt(abs(psi / psi_se), df = df_resid, lower.tail = FALSE)
  
  if (is_log_outcome) {
    effect <- (exp(psi) - 1) * 100
    effect_low <- (exp(psi_low) - 1) * 100
    effect_high <- (exp(psi_high) - 1) * 100
  } else {
    effect <- psi
    effect_low <- psi_low
    effect_high <- psi_high
  }
  
  mixture_result <- tibble(
    dataset = dataset_label,
    period = period_label,
    mixture = mixture_name,
    outcome = outcome,
    outcome_label = outcome_label,
    n = nrow(d),
    psi = psi,
    psi_se = psi_se,
    p_value = p_value,
    effect = effect,
    effect_low = effect_low,
    effect_high = effect_high
  )
  
  component_betas <- beta_vec
  pos_sum <- sum(component_betas[component_betas > 0])
  neg_sum <- sum(abs(component_betas[component_betas < 0]))
  
  weight_result <- tibble(
    dataset = dataset_label,
    period = period_label,
    mixture = mixture_name,
    outcome = outcome,
    outcome_label = outcome_label,
    q_variable = names(component_betas),
    variable = gsub("^q_", "", names(component_betas)),
    beta_component = as.numeric(component_betas)
  ) %>%
    left_join(component_labels, by = "variable") %>%
    mutate(
      positive_weight = ifelse(
        beta_component > 0 & pos_sum > 0,
        beta_component / pos_sum,
        0
      ),
      negative_weight = ifelse(
        beta_component < 0 & neg_sum > 0,
        abs(beta_component) / neg_sum,
        0
      ),
      direction = case_when(
        beta_component > 0 ~ "positive",
        beta_component < 0 ~ "negative",
        TRUE ~ "null"
      )
    )
  
  list(
    mixture_result = mixture_result,
    weight_result = weight_result
  )
}

# ------------------------------------------------------------
# 1. Overall 2003-2018
# ------------------------------------------------------------

overall_results_list <- list()

for (mix_name in names(mixture_sets)) {
  exposure_vars <- mixture_sets[[mix_name]]
  
  for (i in seq_len(nrow(outcome_map))) {
    res <- run_survey_qgcomp(
      data = df,
      mixture_name = mix_name,
      exposure_vars = exposure_vars,
      outcome = outcome_map$outcome[i],
      outcome_label = outcome_map$outcome_label[i],
      is_log_outcome = outcome_map$is_log_outcome[i],
      weight_var = "WTSDEHP16YR",
      dataset_label = "NHANES 2003-2018",
      period_label = "Overall_2003_2018"
    )
    
    overall_results_list[[length(overall_results_list) + 1]] <- res
  }
}

overall_mixture_results <- bind_rows(map(overall_results_list, "mixture_result")) %>%
  group_by(outcome_label) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup()

overall_weight_results <- bind_rows(map(overall_results_list, "weight_result"))

# ------------------------------------------------------------
# 2. Period-specific 2003-2008 / 2009-2012 / 2013-2018
# ------------------------------------------------------------

period_results_list <- list()

for (period_i in levels(df$period)) {
  df_p <- df %>% filter(period == period_i)
  
  for (mix_name in names(mixture_sets)) {
    exposure_vars <- mixture_sets[[mix_name]]
    
    for (i in seq_len(nrow(outcome_map))) {
      res <- run_survey_qgcomp(
        data = df_p,
        mixture_name = mix_name,
        exposure_vars = exposure_vars,
        outcome = outcome_map$outcome[i],
        outcome_label = outcome_map$outcome_label[i],
        is_log_outcome = outcome_map$is_log_outcome[i],
        weight_var = "WTSDEHP_PERIOD",
        dataset_label = "NHANES 2003-2018",
        period_label = period_i
      )
      
      period_results_list[[length(period_results_list) + 1]] <- res
    }
  }
}

period_mixture_results <- bind_rows(map(period_results_list, "mixture_result")) %>%
  group_by(period, outcome_label) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  ungroup()

period_weight_results <- bind_rows(map(period_results_list, "weight_result"))

# ------------------------------------------------------------
# 3. Format and summary
# ------------------------------------------------------------

format_results <- function(dat) {
  dat %>%
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
        psi > 0 ~ "positive",
        psi < 0 ~ "negative",
        TRUE ~ "null"
      ),
      evidence_level = case_when(
        q_value < 0.05 ~ "FDR-significant",
        p_value < 0.05 ~ "Nominally significant",
        psi > 0 ~ "Positive direction only",
        TRUE ~ "Weak/no support"
      )
    )
}

overall_mixture_results <- format_results(overall_mixture_results)
period_mixture_results <- format_results(period_mixture_results)

period_summary <- period_mixture_results %>%
  group_by(outcome_label, mixture) %>%
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

print(overall_mixture_results)
print(period_mixture_results)
print(period_summary)

# ------------------------------------------------------------
# 4. Export
# ------------------------------------------------------------

write_csv(
  overall_mixture_results,
  file.path(result_dir, "survey_qgcomp_DEHP_2003_2018_overall_results.csv")
)

write_csv(
  period_mixture_results,
  file.path(result_dir, "survey_qgcomp_DEHP_2003_2018_period_results.csv")
)

write_csv(
  overall_weight_results,
  file.path(result_dir, "survey_qgcomp_DEHP_2003_2018_overall_weights.csv")
)

write_csv(
  period_weight_results,
  file.path(result_dir, "survey_qgcomp_DEHP_2003_2018_period_weights.csv")
)

write_xlsx(
  list(
    overall_mixture_results = overall_mixture_results,
    period_mixture_results = period_mixture_results,
    period_summary = period_summary,
    overall_component_weights = overall_weight_results,
    period_component_weights = period_weight_results
  ),
  file.path(result_dir, "survey_qgcomp_DEHP_2003_2018.xlsx")
)

# ------------------------------------------------------------
# 5. Plot period effects
# ------------------------------------------------------------

p_period <- ggplot(
  period_mixture_results,
  aes(x = period, y = effect, group = mixture)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 2.5) +
  geom_errorbar(
    aes(ymin = effect_low, ymax = effect_high),
    width = 0.12
  ) +
  facet_grid(outcome_label ~ mixture, scales = "free_y") +
  labs(
    title = "Period-specific survey-weighted qgcomp-like DEHP mixture effects, NHANES 2003-2018",
    subtitle = "Effect estimates represent joint one-quantile increase in all mixture components",
    x = "NHANES period",
    y = "Mixture effect estimate",
    caption = "Models adjusted for age, sex, race/ethnicity, income, education, energy intake, urinary creatinine, and cycle."
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_text(angle = 30, hjust = 1)
  )

print(p_period)

ggsave(
  file.path(fig_dir, "qgcomp_period_effects_2003_2018.png"),
  p_period,
  width = 10,
  height = 6,
  dpi = 300
)

ggsave(
  file.path(fig_dir, "qgcomp_period_effects_2003_2018.pdf"),
  p_period,
  width = 10,
  height = 6
)

cat("Survey-weighted qgcomp-like long-cycle validation completed.\n")