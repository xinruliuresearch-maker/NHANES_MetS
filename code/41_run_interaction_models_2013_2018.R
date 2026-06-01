# ============================================================
# NHANES 2013-2018
# 41_run_interaction_models_2013_2018.R
# Survey-weighted interaction and stratified analyses
# ============================================================

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(tibble)
library(survey)
library(writexl)

options(survey.lonely.psu = "adjust")

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(
  file.path(output_dir, "NHANES_2013_2018_interaction_dataset.rds")
)

# ------------------------------------------------------------
# 1. Analysis maps
# ------------------------------------------------------------

outcome_map <- tibble::tribble(
  ~outcome, ~outcome_label, ~is_log_outcome,
  "ln_HOMA_IR", "ln(HOMA-IR)", TRUE,
  "HbA1c", "HbA1c", FALSE
)

exposure_map <- tibble::tribble(
  ~exposure, ~exposure_label, ~include_creatinine,
  "ln_Sigma_DEHP", "lnΣDEHP", TRUE,
  "pct_oxidative_10", "%Oxidative per 10 percentage points", FALSE
)

modifier_map <- tibble::tribble(
  ~modifier, ~modifier_label, ~underlying_covariate, ~priority,
  "sex_group", "Sex", "sex", "Primary",
  "age_group", "Age group", "", "Primary",
  "obesity_status", "Obesity status", "", "Primary",
  "race_group", "Race/ethnicity", "race", "Exploratory"
)

design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")

covar_table <- tibble::tribble(
  ~tag, ~term, ~vars,
  "age", "RIDAGEYR", "RIDAGEYR",
  "sex", "factor(RIAGENDR)", "RIAGENDR",
  "race", "factor(RIDRETH3)", "RIDRETH3",
  "income", "INDFMPIR", "INDFMPIR",
  "education", "factor(DMDEDUC2)", "DMDEDUC2",
  "energy", "DR1TKCAL", "DR1TKCAL",
  "creatinine", "ln_URXUCR", "ln_URXUCR",
  "cycle", "factor(cycle)", "cycle"
)

make_covars <- function(include_creatinine, remove_tag = "") {
  covars <- covar_table
  
  if (!include_creatinine) {
    covars <- covars %>% filter(tag != "creatinine")
  }
  
  if (!is.na(remove_tag) && remove_tag != "") {
    covars <- covars %>% filter(tag != remove_tag)
  }
  
  covars
}

effect_transform <- function(beta, low, high, is_log_outcome) {
  if (is_log_outcome) {
    return(c(
      effect = (exp(beta) - 1) * 100,
      effect_low = (exp(low) - 1) * 100,
      effect_high = (exp(high) - 1) * 100
    ))
  } else {
    return(c(
      effect = beta,
      effect_low = low,
      effect_high = high
    ))
  }
}

# ------------------------------------------------------------
# 2. Interaction model
# ------------------------------------------------------------

run_interaction_test <- function(outcome, outcome_label, is_log_outcome,
                                 exposure, exposure_label, include_creatinine,
                                 modifier, modifier_label, underlying_covariate,
                                 priority) {
  
  covars <- make_covars(
    include_creatinine = include_creatinine,
    remove_tag = underlying_covariate
  )
  
  model_vars <- c(
    outcome,
    exposure,
    modifier,
    unlist(strsplit(paste(covars$vars, collapse = ","), ",")),
    design_vars
  )
  
  d <- df %>%
    select(any_of(model_vars)) %>%
    drop_na()
  
  if (nrow(d) < 300 || length(unique(d[[modifier]])) < 2) {
    return(tibble(
      priority = priority,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      modifier = modifier,
      modifier_label = modifier_label,
      n = nrow(d),
      p_interaction = NA_real_,
      test_df = NA_real_,
      result = "Insufficient sample or levels"
    ))
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  covar_terms <- paste(covars$term, collapse = " + ")
  
  f <- as.formula(
    paste0(
      outcome, " ~ ",
      exposure, " * factor(", modifier, ")",
      ifelse(covar_terms == "", "", paste0(" + ", covar_terms))
    )
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble(
      priority = priority,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      modifier = modifier,
      modifier_label = modifier_label,
      n = nrow(d),
      p_interaction = NA_real_,
      test_df = NA_real_,
      result = "Model failed"
    ))
  }
  
  interaction_term <- as.formula(
    paste0("~ ", exposure, ":factor(", modifier, ")")
  )
  
  test <- tryCatch(
    regTermTest(fit, interaction_term),
    error = function(e) NULL
  )
  
  if (is.null(test)) {
    p_int <- NA_real_
    test_df <- NA_real_
  } else {
    p_int <- as.numeric(test$p)
    test_df <- as.numeric(test$df)
  }
  
  tibble(
    priority = priority,
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    modifier = modifier,
    modifier_label = modifier_label,
    n = nrow(d),
    p_interaction = p_int,
    test_df = test_df,
    result = case_when(
      is.na(p_int) ~ "Interaction test unavailable",
      p_int < 0.05 ~ "Evidence of interaction",
      p_int < 0.10 ~ "Suggestive interaction",
      TRUE ~ "No clear interaction"
    )
  )
}

# ------------------------------------------------------------
# 3. Stratified model
# ------------------------------------------------------------

run_stratified_model <- function(outcome, outcome_label, is_log_outcome,
                                 exposure, exposure_label, include_creatinine,
                                 modifier, modifier_label, underlying_covariate,
                                 priority, level_value) {
  
  covars <- make_covars(
    include_creatinine = include_creatinine,
    remove_tag = underlying_covariate
  )
  
  model_vars <- c(
    outcome,
    exposure,
    modifier,
    unlist(strsplit(paste(covars$vars, collapse = ","), ",")),
    design_vars
  )
  
  d <- df %>%
    select(any_of(model_vars)) %>%
    filter(.data[[modifier]] == level_value) %>%
    drop_na()
  
  if (nrow(d) < 150) {
    return(tibble(
      priority = priority,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      modifier = modifier,
      modifier_label = modifier_label,
      level = as.character(level_value),
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Insufficient sample"
    ))
  }
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d
  )
  
  covar_terms <- paste(covars$term, collapse = " + ")
  
  f <- as.formula(
    paste0(
      outcome, " ~ ",
      exposure,
      ifelse(covar_terms == "", "", paste0(" + ", covar_terms))
    )
  )
  
  fit <- tryCatch(
    svyglm(f, design = des),
    error = function(e) NULL
  )
  
  if (is.null(fit)) {
    return(tibble(
      priority = priority,
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      modifier = modifier,
      modifier_label = modifier_label,
      level = as.character(level_value),
      n = nrow(d),
      beta = NA_real_,
      se = NA_real_,
      p_value = NA_real_,
      effect = NA_real_,
      effect_low = NA_real_,
      effect_high = NA_real_,
      result = "Model failed"
    ))
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
  
  eff <- effect_transform(beta, low, high, is_log_outcome)
  
  tibble(
    priority = priority,
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    modifier = modifier,
    modifier_label = modifier_label,
    level = as.character(level_value),
    n = nrow(d),
    beta = beta,
    se = se,
    p_value = p_value,
    effect = eff["effect"],
    effect_low = eff["effect_low"],
    effect_high = eff["effect_high"],
    result = case_when(
      is.na(p_value) ~ "Unavailable",
      p_value < 0.05 & beta > 0 ~ "Nominal positive",
      beta > 0 ~ "Positive direction",
      beta < 0 ~ "Negative direction",
      TRUE ~ "Weak/no support"
    )
  )
}

# ------------------------------------------------------------
# 4. Run all interaction tests
# ------------------------------------------------------------

interaction_tests <- expand_grid(
  outcome_row = seq_len(nrow(outcome_map)),
  exposure_row = seq_len(nrow(exposure_map)),
  modifier_row = seq_len(nrow(modifier_map))
) %>%
  mutate(
    result_tbl = pmap(
      list(outcome_row, exposure_row, modifier_row),
      function(i, j, k) {
        run_interaction_test(
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          is_log_outcome = outcome_map$is_log_outcome[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          include_creatinine = exposure_map$include_creatinine[j],
          modifier = modifier_map$modifier[k],
          modifier_label = modifier_map$modifier_label[k],
          underlying_covariate = modifier_map$underlying_covariate[k],
          priority = modifier_map$priority[k]
        )
      }
    )
  ) %>%
  select(result_tbl) %>%
  unnest(result_tbl) %>%
  group_by(priority, outcome_label) %>%
  mutate(q_interaction = p.adjust(p_interaction, method = "BH")) %>%
  ungroup() %>%
  mutate(
    p_interaction_fmt = case_when(
      is.na(p_interaction) ~ NA_character_,
      p_interaction < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_interaction)
    ),
    q_interaction_fmt = case_when(
      is.na(q_interaction) ~ NA_character_,
      q_interaction < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", q_interaction)
    ),
    interaction_interpretation = case_when(
      q_interaction < 0.05 ~ "FDR-significant interaction",
      p_interaction < 0.05 ~ "Nominal interaction",
      p_interaction < 0.10 ~ "Suggestive interaction",
      TRUE ~ "No clear interaction"
    )
  )

# ------------------------------------------------------------
# 5. Run stratified models
# ------------------------------------------------------------

stratified_results_list <- list()

row_id <- 1

for (i in seq_len(nrow(outcome_map))) {
  for (j in seq_len(nrow(exposure_map))) {
    for (k in seq_len(nrow(modifier_map))) {
      
      modifier_var <- modifier_map$modifier[k]
      levels_k <- levels(df[[modifier_var]])
      levels_k <- levels_k[!is.na(levels_k)]
      
      for (lv in levels_k) {
        stratified_results_list[[row_id]] <- run_stratified_model(
          outcome = outcome_map$outcome[i],
          outcome_label = outcome_map$outcome_label[i],
          is_log_outcome = outcome_map$is_log_outcome[i],
          exposure = exposure_map$exposure[j],
          exposure_label = exposure_map$exposure_label[j],
          include_creatinine = exposure_map$include_creatinine[j],
          modifier = modifier_map$modifier[k],
          modifier_label = modifier_map$modifier_label[k],
          underlying_covariate = modifier_map$underlying_covariate[k],
          priority = modifier_map$priority[k],
          level_value = lv
        )
        row_id <- row_id + 1
      }
    }
  }
}

stratified_results <- bind_rows(stratified_results_list) %>%
  left_join(
    interaction_tests %>%
      select(
        outcome_label,
        exposure_label,
        modifier_label,
        p_interaction,
        q_interaction,
        p_interaction_fmt,
        q_interaction_fmt,
        interaction_interpretation
      ),
    by = c("outcome_label", "exposure_label", "modifier_label")
  ) %>%
  mutate(
    effect_CI = sprintf("%.3f (%.3f, %.3f)", effect, effect_low, effect_high),
    p_value_fmt = case_when(
      is.na(p_value) ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE ~ sprintf("%.3f", p_value)
    )
  )

# ------------------------------------------------------------
# 6. Key result tables
# ------------------------------------------------------------

primary_interaction_tests <- interaction_tests %>%
  filter(priority == "Primary") %>%
  arrange(outcome_label, exposure_label, modifier_label)

exploratory_interaction_tests <- interaction_tests %>%
  filter(priority == "Exploratory") %>%
  arrange(outcome_label, exposure_label, modifier_label)

primary_stratified_results <- stratified_results %>%
  filter(priority == "Primary") %>%
  arrange(outcome_label, exposure_label, modifier_label, level)

print(primary_interaction_tests)
print(primary_stratified_results)

# ------------------------------------------------------------
# 7. Export
# ------------------------------------------------------------

write_csv(
  interaction_tests,
  file.path(result_dir, "interaction_tests_2013_2018.csv")
)

write_csv(
  stratified_results,
  file.path(result_dir, "interaction_stratified_results_2013_2018.csv")
)

write_xlsx(
  list(
    interaction_tests = interaction_tests,
    stratified_results = stratified_results,
    primary_interaction_tests = primary_interaction_tests,
    primary_stratified_results = primary_stratified_results,
    exploratory_interaction_tests = exploratory_interaction_tests
  ),
  file.path(result_dir, "interaction_results_2013_2018.xlsx")
)

cat("Interaction and stratified analyses completed successfully.\n")