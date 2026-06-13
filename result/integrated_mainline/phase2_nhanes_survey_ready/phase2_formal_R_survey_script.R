# Formal NHANES survey script for final manuscript rerun.
# Generated on 2026-06-10. This workstation currently has no Rscript, so this
# script is prepared for execution in an R environment with survey installed.

library(survey)
options(survey.lonely.psu = "adjust")

nh <- read.csv("C:/Users/liu12/OneDrive/Desktop/ShiYiSiNan_CGMacros/outputs/integrated_mainline/phase2_nhanes_survey_ready/phase2_python_analysis_dataset.csv")
nh$cluster <- interaction(nh$SDMVSTRA, nh$SDMVPSU, drop = TRUE)
des <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTSB6YR_MAIN,
  nest = TRUE,
  data = nh
)

main_covars <- "RIDAGEYR + factor(RIAGENDR) + factor(RIDRETH3) + factor(DMDEDUC2) + INDFMPIR + DR1TKCAL + ever_smoker + alcohol_ever + any_physical_activity + ln_URXUCR + factor(cycle)"
outcomes <- c("msi_core_partial", "msi_no_bmi", "msi_pca", "ln_HOMA_IR", "HbA1c", "TyG", "ln_TG_HDL")
exposures <- c("pct_oxidative_10", "ln_oxidative_to_MEHP", "ln_Sigma_DEHP")

rows <- list()
k <- 1
for (y in outcomes) {
  for (x in exposures) {
    f <- as.formula(paste(y, "~", x, "+", main_covars))
    m <- svyglm(f, design = des)
    co <- coef(summary(m))[x, ]
    rows[[k]] <- data.frame(outcome = y, exposure = x, beta = co[1], se = co[2], t = co[3], p = co[4])
    k <- k + 1
  }
}
res <- do.call(rbind, rows)
res$q <- p.adjust(res$p, method = "BH")
write.csv(res, "C:/Users/liu12/OneDrive/Desktop/ShiYiSiNan_CGMacros/outputs/integrated_mainline/phase2_nhanes_survey_ready/phase2_R_survey_main_results.csv", row.names = FALSE)
