# ============================================================
# NHANES 2013-2018
# 43_true_rcs_dose_response_2013_2018.R
# True survey-weighted restricted cubic spline dose-response plots
# Fixed version: avoids mutate() scoping conflict with column named x
# ============================================================

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(tibble)
library(survey)
library(ggplot2)
library(writexl)

options(survey.lonely.psu = "adjust")

# ------------------------------------------------------------
# 0. Project paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_MetS_Project"

output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir    <- file.path(result_dir, "figures_rcs")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Read best available 2013-2018 analysis dataset
# ------------------------------------------------------------

data_candidates <- c(
  file.path(output_dir, "NHANES_2013_2018_exposure_sensitivity_dataset.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_mechanism.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis_DEHPderived.rds"),
  file.path(output_dir, "NHANES_2013_2018_master_analysis.rds")
)

data_file <- data_candidates[file.exists(data_candidates)][1]

if (is.na(data_file)) {
  stop("找不到 2013-2018 分析数据，请检查 output 文件夹。")
}

df <- readRDS(data_file)

cat("Using data file:\n", data_file, "\n")
cat("Dataset dimensions:", nrow(df), "rows,", ncol(df), "columns\n")

# ------------------------------------------------------------
# 2. Check and construct required variables
# ------------------------------------------------------------

# %Oxidative on percentage scale
if (!("pct_oxidative" %in% names(df))) {
  if ("pct_oxidative_10" %in% names(df)) {
    df <- df %>%
      mutate(pct_oxidative = pct_oxidative_10 * 10)
    message("pct_oxidative not found; created pct_oxidative = pct_oxidative_10 * 10.")
  } else {
    stop("找不到 pct_oxidative 或 pct_oxidative_10。请检查前面 DEHP 衍生变量脚本。")
  }
}

# HOMA-IR log outcome
if (!("ln_HOMA_IR" %in% names(df))) {
  if ("HOMA_IR" %in% names(df)) {
    df <- df %>%
      mutate(ln_HOMA_IR = log(HOMA_IR))
    message("ln_HOMA_IR not found; created ln_HOMA_IR = log(HOMA_IR).")
  } else if ("homa_ir" %in% names(df)) {
    df <- df %>%
      mutate(ln_HOMA_IR = log(homa_ir))
    message("ln_HOMA_IR not found; created ln_HOMA_IR = log(homa_ir).")
  } else {
    stop("找不到 ln_HOMA_IR 或 HOMA_IR。")
  }
}

# HbA1c
if (!("HbA1c" %in% names(df))) {
  if ("LBXGH" %in% names(df)) {
    df <- df %>%
      mutate(HbA1c = LBXGH)
    message("HbA1c not found; created HbA1c = LBXGH.")
  } else {
    stop("找不到 HbA1c 或 LBXGH。")
  }
}

# lnΣDEHP
if (!("ln_Sigma_DEHP" %in% names(df))) {
  possible_dehp <- names(df)[grepl("sigma.*dehp|dehp.*sigma|sum.*dehp", names(df), ignore.case = TRUE)]
  stop(
    paste0(
      "找不到 ln_Sigma_DEHP。请检查变量名。可能相关变量包括：\n",
      paste(possible_dehp, collapse = ", ")
    )
  )
}

# urinary creatinine
if (!("ln_URXUCR" %in% names(df))) {
  if ("URXUCR" %in% names(df)) {
    df <- df %>%
      mutate(ln_URXUCR = log(URXUCR))
    message("ln_URXUCR not found; created ln_URXUCR = log(URXUCR).")
  } else {
    stop("找不到 ln_URXUCR 或 URXUCR。")
  }
}

# survey design variables
required_design <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")
missing_design <- setdiff(required_design, names(df))

if (length(missing_design) > 0) {
  stop(
    paste0(
      "缺少复杂抽样设计变量：",
      paste(missing_design, collapse = ", ")
    )
  )
}

# ------------------------------------------------------------
# 3. Helper functions
# ------------------------------------------------------------

weighted_quantile <- function(x, w, probs) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]
  w <- w[ok]
  
  if (length(x) < 10) {
    return(rep(NA_real_, length(probs)))
  }
  
  o <- order(x)
  x <- x[o]
  w <- w[o]
  cw <- cumsum(w) / sum(w)
  
  approx(cw, x, xout = probs, ties = "ordered", rule = 2)$y
}

format_p <- function(p) {
  ifelse(
    is.na(p), NA_character_,
    ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

# Restricted cubic spline basis
# 4 knots -> 3 basis columns: one linear + two nonlinear terms
make_rcs_basis <- function(x, knots) {
  k <- sort(as.numeric(knots))
  K <- length(k)
  
  if (K < 4) {
    stop("RCS requires at least 4 knots.")
  }
  
  tp <- function(z) pmax(z, 0)^3
  
  basis <- matrix(NA_real_, nrow = length(x), ncol = K - 1)
  basis[, 1] <- x
  
  for (j in 1:(K - 2)) {
    basis[, j + 1] <-
      tp(x - k[j]) -
      tp(x - k[K - 1]) * (k[K] - k[j]) / (k[K] - k[K - 1]) +
      tp(x - k[K]) * (k[K - 1] - k[j]) / (k[K] - k[K - 1])
  }
  
  colnames(basis) <- paste0("rcs", seq_len(ncol(basis)))
  as.data.frame(basis)
}

add_rcs_to_data <- function(dat, exposure, knots, prefix = "rcs") {
  b <- make_rcs_basis(dat[[exposure]], knots)
  colnames(b) <- paste0(prefix, seq_len(ncol(b)))
  bind_cols(dat, b)
}

# ------------------------------------------------------------
# 4. RCS model runner
# ------------------------------------------------------------

run_rcs_model <- function(outcome, outcome_label,
                          exposure, exposure_label,
                          include_creatinine = TRUE,
                          x_label = NULL,
                          y_label = NULL,
                          n_grid = 120) {
  
  design_vars <- c("SDMVPSU", "SDMVSTRA", "WTSB6YR_MAIN")
  
  covar_vars <- c(
    "RIDAGEYR",
    "RIAGENDR",
    "RIDRETH3",
    "INDFMPIR",
    "DMDEDUC2",
    "DR1TKCAL",
    "cycle"
  )
  
  if (include_creatinine) {
    covar_vars <- c(covar_vars, "ln_URXUCR")
  }
  
  needed_vars <- c(outcome, exposure, covar_vars, design_vars)
  missing_vars <- setdiff(needed_vars, names(df))
  
  if (length(missing_vars) > 0) {
    stop(
      paste0(
        "模型缺少变量：",
        paste(missing_vars, collapse = ", ")
      )
    )
  }
  
  d <- df %>%
    select(all_of(needed_vars)) %>%
    drop_na()
  
  if (nrow(d) < 300) {
    stop(
      paste0(
        "模型样本量过小：", outcome_label, " | ", exposure_label,
        "，N = ", nrow(d)
      )
    )
  }
  
  plot_range <- weighted_quantile(
    d[[exposure]],
    d$WTSB6YR_MAIN,
    probs = c(0.01, 0.99)
  )
  
  knots <- weighted_quantile(
    d[[exposure]],
    d$WTSB6YR_MAIN,
    probs = c(0.05, 0.35, 0.65, 0.95)
  )
  
  ref_value <- weighted_quantile(
    d[[exposure]],
    d$WTSB6YR_MAIN,
    probs = 0.50
  )
  
  if (any(is.na(knots)) || any(is.na(plot_range)) || is.na(ref_value)) {
    stop(
      paste0(
        "无法计算加权分位数：", outcome_label, " | ", exposure_label
      )
    )
  }
  
  cat("\n--------------------------------------------\n")
  cat("Outcome:", outcome_label, "\n")
  cat("Exposure:", exposure_label, "\n")
  cat("N:", nrow(d), "\n")
  cat("Knots:", paste(round(knots, 3), collapse = ", "), "\n")
  cat("Reference:", round(ref_value, 3), "\n")
  
  d_rcs <- add_rcs_to_data(d, exposure, knots, prefix = "rcs")
  
  rcs_terms <- paste0("rcs", 1:3)
  nonlinear_terms <- paste0("rcs", 2:3)
  
  covar_terms <- c(
    "RIDAGEYR",
    "factor(RIAGENDR)",
    "factor(RIDRETH3)",
    "INDFMPIR",
    "factor(DMDEDUC2)",
    "DR1TKCAL",
    "factor(cycle)"
  )
  
  if (include_creatinine) {
    covar_terms <- c(covar_terms, "ln_URXUCR")
  }
  
  f <- as.formula(
    paste0(
      outcome,
      " ~ ",
      paste(c(rcs_terms, covar_terms), collapse = " + ")
    )
  )
  
  des <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTSB6YR_MAIN,
    nest = TRUE,
    data = d_rcs
  )
  
  fit <- svyglm(f, design = des)
  
  overall_test <- regTermTest(
    fit,
    as.formula(paste0("~ ", paste(rcs_terms, collapse = " + ")))
  )
  
  nonlinear_test <- regTermTest(
    fit,
    as.formula(paste0("~ ", paste(nonlinear_terms, collapse = " + ")))
  )
  
  p_overall <- as.numeric(overall_test$p)
  p_nonlinear <- as.numeric(nonlinear_test$p)
  
  grid_x <- seq(plot_range[1], plot_range[2], length.out = n_grid)
  
  grid_basis <- make_rcs_basis(grid_x, knots)
  ref_basis  <- make_rcs_basis(ref_value, knots)
  
  colnames(grid_basis) <- rcs_terms
  colnames(ref_basis)  <- rcs_terms
  
  coef_fit <- coef(fit)
  vcov_fit <- vcov(fit)
  
  beta_rcs <- coef_fit[rcs_terms]
  vcov_rcs <- vcov_fit[rcs_terms, rcs_terms]
  
  diff_mat <- as.matrix(grid_basis) -
    matrix(
      as.numeric(ref_basis[1, ]),
      nrow = nrow(grid_basis),
      ncol = ncol(grid_basis),
      byrow = TRUE
    )
  
  estimate <- as.numeric(diff_mat %*% beta_rcs)
  se <- sqrt(diag(diff_mat %*% vcov_rcs %*% t(diff_mat)))
  
  low <- estimate - 1.96 * se
  high <- estimate + 1.96 * se
  
  plot_df <- tibble(
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    exposure_value = grid_x,
    estimate = estimate,
    low = low,
    high = high,
    n = nrow(d),
    ref_value = as.numeric(ref_value),
    knot_1 = knots[1],
    knot_2 = knots[2],
    knot_3 = knots[3],
    knot_4 = knots[4],
    p_overall = p_overall,
    p_nonlinear = p_nonlinear,
    p_overall_fmt = format_p(p_overall),
    p_nonlinear_fmt = format_p(p_nonlinear),
    include_creatinine = include_creatinine,
    x_label = ifelse(is.null(x_label), exposure_label, x_label),
    y_label = ifelse(is.null(y_label), paste0("Difference in ", outcome_label), y_label)
  )
  
  rug_df <- d %>%
    select(all_of(exposure)) %>%
    rename(exposure_value = all_of(exposure)) %>%
    filter(
      exposure_value >= plot_range[1],
      exposure_value <= plot_range[2]
    )
  
  if (nrow(rug_df) > 600) {
    set.seed(20260527)
    rug_df <- rug_df %>% slice_sample(n = 600)
  }
  
  p_table <- tibble(
    outcome = outcome,
    outcome_label = outcome_label,
    exposure = exposure,
    exposure_label = exposure_label,
    n = nrow(d),
    ref_value = as.numeric(ref_value),
    knot_1 = knots[1],
    knot_2 = knots[2],
    knot_3 = knots[3],
    knot_4 = knots[4],
    p_overall = p_overall,
    p_nonlinear = p_nonlinear,
    p_overall_fmt = format_p(p_overall),
    p_nonlinear_fmt = format_p(p_nonlinear),
    include_creatinine = include_creatinine
  )
  
  list(
    fit = fit,
    plot_df = plot_df,
    rug_df = rug_df,
    p_table = p_table
  )
}

# ------------------------------------------------------------
# 5. Run four RCS models
# ------------------------------------------------------------

model_specs <- tibble::tribble(
  ~panel, ~outcome, ~outcome_label, ~exposure, ~exposure_label, ~include_creatinine, ~x_label, ~y_label,
  "A", "ln_HOMA_IR", "ln(HOMA-IR)", "ln_Sigma_DEHP", "lnΣDEHP", TRUE, "lnΣDEHP", "Difference in ln(HOMA-IR)",
  "B", "ln_HOMA_IR", "ln(HOMA-IR)", "pct_oxidative", "%Oxidative metabolites", FALSE, "%Oxidative metabolites", "Difference in ln(HOMA-IR)",
  "C", "HbA1c", "HbA1c", "ln_Sigma_DEHP", "lnΣDEHP", TRUE, "lnΣDEHP", "Difference in HbA1c (%)",
  "D", "HbA1c", "HbA1c", "pct_oxidative", "%Oxidative metabolites", FALSE, "%Oxidative metabolites", "Difference in HbA1c (%)"
)

rcs_runs <- pmap(
  model_specs,
  function(panel, outcome, outcome_label, exposure, exposure_label,
           include_creatinine, x_label, y_label) {
    
    model_result <- run_rcs_model(
      outcome = outcome,
      outcome_label = outcome_label,
      exposure = exposure,
      exposure_label = exposure_label,
      include_creatinine = include_creatinine,
      x_label = x_label,
      y_label = y_label
    )
    
    model_result$panel <- panel
    model_result
  }
)

# ------------------------------------------------------------
# 6. Combine plot data
# Important fix:
# Do not use mutate(panel = x$panel) because plot_df has a column named x
# Use object names that do not conflict with data-frame column names.
# ------------------------------------------------------------

plot_data <- map_dfr(
  rcs_runs,
  function(model_result) {
    panel_id <- model_result$panel
    
    model_result$plot_df %>%
      mutate(panel = panel_id)
  }
)

rug_data <- map_dfr(
  rcs_runs,
  function(model_result) {
    panel_id <- model_result$panel
    
    model_result$rug_df %>%
      mutate(panel = panel_id)
  }
)

p_table <- map_dfr(
  rcs_runs,
  function(model_result) {
    panel_id <- model_result$panel
    
    model_result$p_table %>%
      mutate(panel = panel_id)
  }
)

plot_data <- plot_data %>%
  mutate(
    panel_title = case_when(
      panel == "A" ~ "A. lnΣDEHP and ln(HOMA-IR)",
      panel == "B" ~ "B. %Oxidative metabolites and ln(HOMA-IR)",
      panel == "C" ~ "C. lnΣDEHP and HbA1c",
      panel == "D" ~ "D. %Oxidative metabolites and HbA1c",
      TRUE ~ panel
    ),
    annotation = paste0(
      "P-overall = ", p_overall_fmt,
      "\nP-nonlinear = ", p_nonlinear_fmt
    )
  )

rug_data <- rug_data %>%
  left_join(
    plot_data %>%
      distinct(panel, panel_title, x_label, y_label),
    by = "panel"
  )

# ------------------------------------------------------------
# 7. Plot
# ------------------------------------------------------------

anno_df <- plot_data %>%
  group_by(panel_title) %>%
  slice_tail(n = 1) %>%
  ungroup()

p <- ggplot(plot_data, aes(x = exposure_value, y = estimate)) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    linewidth = 0.35
  ) +
  geom_ribbon(
    aes(ymin = low, ymax = high),
    alpha = 0.20,
    fill = "#2C7FB8"
  ) +
  geom_line(
    linewidth = 0.85,
    color = "#075AAB"
  ) +
  geom_rug(
    data = rug_data,
    aes(x = exposure_value),
    inherit.aes = FALSE,
    sides = "b",
    alpha = 0.35,
    color = "#075AAB"
  ) +
  geom_text(
    data = anno_df,
    aes(
      x = Inf,
      y = Inf,
      label = annotation
    ),
    hjust = 1.05,
    vjust = 1.25,
    size = 3.1,
    fontface = "italic",
    inherit.aes = FALSE
  ) +
  facet_wrap(
    ~ panel_title,
    scales = "free",
    ncol = 2
  ) +
  labs(
    title = "Restricted cubic spline dose-response associations of DEHP exposure indicators with metabolic outcomes",
    subtitle = "Survey-weighted restricted cubic spline models adjusted for age, sex, race/ethnicity, socioeconomic factors, energy intake, urinary creatinine where applicable, and NHANES cycle",
    x = NULL,
    y = NULL,
    caption = "Solid lines indicate fitted restricted cubic spline functions; shaded areas indicate 95% confidence intervals. Reference values were centered at the weighted median exposure level. Rug marks indicate observed exposure distributions."
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0),
    plot.subtitle = element_text(size = 9.5, hjust = 0),
    strip.text = element_text(face = "bold", size = 10, hjust = 0),
    strip.background = element_rect(fill = "grey90", color = "grey35"),
    panel.grid.minor = element_line(color = "grey92", linewidth = 0.25),
    panel.grid.major = element_line(color = "grey86", linewidth = 0.35),
    axis.title = element_text(face = "bold"),
    plot.caption = element_text(size = 8.5, hjust = 0)
  )

print(p)

# ------------------------------------------------------------
# 8. Export figures and source data
# ------------------------------------------------------------

ggsave(
  filename = file.path(fig_dir, "rcs_DEHP_HOMAIR_HbA1c_2013_2018.png"),
  plot = p,
  width = 12,
  height = 8,
  dpi = 300
)

ggsave(
  filename = file.path(fig_dir, "rcs_DEHP_HOMAIR_HbA1c_2013_2018.pdf"),
  plot = p,
  width = 12,
  height = 8
)

ggsave(
  filename = file.path(fig_dir, "rcs_DEHP_HOMAIR_HbA1c_2013_2018.tiff"),
  plot = p,
  width = 12,
  height = 8,
  dpi = 600,
  compression = "lzw"
)

write_csv(
  plot_data,
  file.path(result_dir, "rcs_plot_source_data_2013_2018.csv")
)

write_xlsx(
  list(
    rcs_p_values = p_table,
    rcs_plot_source_data = plot_data
  ),
  file.path(result_dir, "rcs_results_2013_2018.xlsx")
)

cat("\nRCS dose-response analysis completed successfully.\n")
cat("Figure saved to:\n")
cat(file.path(fig_dir, "rcs_DEHP_HOMAIR_HbA1c_2013_2018.png"), "\n")
cat(file.path(fig_dir, "rcs_DEHP_HOMAIR_HbA1c_2013_2018.pdf"), "\n")
cat(file.path(fig_dir, "rcs_DEHP_HOMAIR_HbA1c_2013_2018.tiff"), "\n")
cat("Results saved to:\n")
cat(file.path(result_dir, "rcs_results_2013_2018.xlsx"), "\n")