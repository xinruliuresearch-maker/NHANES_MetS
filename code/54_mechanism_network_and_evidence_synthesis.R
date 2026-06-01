# ============================================================
# NHANES DEHP project
# 54_mechanism_network_and_evidence_synthesis.R
#
# Purpose:
#   1. Generate mechanism network figure
#   2. Generate evidence synthesis matrix figure
#   3. Export evidence synthesis workbook
#
# Input:
#   result/mechanism_database_CTD_CompTox_ToxCast_results.xlsx
#
# Outputs:
#   result/evidence_synthesis_DEHP_metabolic_project.xlsx
#   result/figures_mechanism/DEHP_mechanism_network_synthesis.png/pdf
#   result/figures_mechanism/DEHP_evidence_synthesis_matrix.png/pdf
# ============================================================

options(timeout = 10000)

# ------------------------------------------------------------
# 0. Packages
# ------------------------------------------------------------

required_packages <- c(
  "dplyr", "tidyr", "purrr", "stringr", "tibble",
  "readxl", "writexl", "ggplot2", "scales"
)

installed_packages <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed_packages)

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(tibble)
library(readxl)
library(writexl)
library(ggplot2)
library(scales)

# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project"

result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(result_dir, "figures_mechanism")
output_dir <- file.path(project_dir, "output")

dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

mechanism_xlsx <- file.path(
  result_dir,
  "mechanism_database_CTD_CompTox_ToxCast_results.xlsx"
)

if (!file.exists(mechanism_xlsx)) {
  stop(
    "Cannot find mechanism result workbook: ",
    mechanism_xlsx,
    "\nPlease run script 53 first."
  )
}

# ------------------------------------------------------------
# 2. Helper functions
# ------------------------------------------------------------

pick_col <- function(dat, patterns) {
  nms <- names(dat)
  nms_low <- tolower(nms)
  
  for (pat in patterns) {
    hit <- nms[str_detect(nms_low, regex(pat, ignore_case = TRUE))]
    if (length(hit) > 0) return(hit[1])
  }
  
  NA_character_
}

find_sheet <- function(workbook_path, candidates) {
  sheets <- readxl::excel_sheets(workbook_path)
  hit <- sheets[tolower(sheets) %in% tolower(candidates)]
  
  if (length(hit) > 0) return(hit[1])
  
  hit2 <- sheets[
    map_lgl(
      sheets,
      ~ any(str_detect(tolower(.x), tolower(candidates)))
    )
  ]
  
  if (length(hit2) > 0) return(hit2[1])
  
  NA_character_
}

safe_read_sheet <- function(workbook_path, candidates) {
  sheet_name <- find_sheet(workbook_path, candidates)
  
  if (is.na(sheet_name)) {
    warning(
      "Could not find sheet among candidates: ",
      paste(candidates, collapse = ", ")
    )
    return(tibble())
  }
  
  readxl::read_xlsx(workbook_path, sheet = sheet_name) %>%
    as_tibble()
}

format_q <- function(q) {
  ifelse(
    is.na(q),
    NA_character_,
    ifelse(q < 0.001, "<0.001", sprintf("%.3f", q))
  )
}

score_from_q <- function(q) {
  case_when(
    is.na(q) ~ "Suggestive",
    q < 0.001 ~ "High",
    q < 0.05 ~ "Moderate",
    q < 0.10 ~ "Suggestive",
    TRUE ~ "Suggestive"
  )
}

evidence_weight <- function(level) {
  case_when(
    level == "Strong" ~ 1.30,
    level == "High" ~ 1.20,
    level == "Supportive" ~ 0.95,
    level == "Moderate" ~ 0.90,
    level == "Exploratory" ~ 0.75,
    level == "Suggestive" ~ 0.70,
    level == "Total-burden only" ~ 0.85,
    level == "No falsification signal" ~ 0.75,
    level == "Inconclusive" ~ 0.55,
    TRUE ~ 0.40
  )
}

# ------------------------------------------------------------
# 3. Read CTD mechanism outputs from script 53
# ------------------------------------------------------------

ctd_enrichment <- safe_read_sheet(
  mechanism_xlsx,
  c("CTD_gene_panel_enrichment", "gene_panel_enrichment", "panel_enrichment")
)

ctd_gene_summary <- safe_read_sheet(
  mechanism_xlsx,
  c("CTD_gene_panel_summary", "gene_panel_summary")
)

integrated_mech <- safe_read_sheet(
  mechanism_xlsx,
  c("integrated_mech_evidence", "integrated_mechanism_evidence")
)

# ------------------------------------------------------------
# 4. Clean CTD panel enrichment
# ------------------------------------------------------------

if (nrow(ctd_enrichment) == 0) {
  warning("CTD enrichment sheet is empty. Mechanism network will use predefined evidence only.")
  
  ctd_panel_clean <- tibble(
    panel_raw = c(
      "PPAR / nuclear receptor / adipogenesis",
      "Insulin / glucose signaling",
      "Oxidative stress / antioxidant response",
      "Inflammation / cytokine signaling",
      "Lipid metabolism / lipoprotein",
      "Mitochondrial / ER stress"
    ),
    q_value = NA_real_,
    overlapping_genes = NA_character_
  )
} else {
  panel_col <- pick_col(ctd_enrichment, c("^panel$", "mechanism", "domain"))
  q_col <- pick_col(ctd_enrichment, c("^q_value$", "q.value", "fdr", "adjust"))
  overlap_col <- pick_col(ctd_enrichment, c("overlapping", "overlap", "genes"))
  
  if (is.na(panel_col)) {
    stop("Cannot identify panel column in CTD_gene_panel_enrichment.")
  }
  
  ctd_panel_clean <- ctd_enrichment %>%
    transmute(
      panel_raw = as.character(.data[[panel_col]]),
      q_value = if (!is.na(q_col)) suppressWarnings(as.numeric(.data[[q_col]])) else NA_real_,
      overlapping_genes = if (!is.na(overlap_col)) as.character(.data[[overlap_col]]) else NA_character_
    )
}

mechanism_dictionary <- tibble::tribble(
  ~panel_pattern, ~mechanism_node, ~mechanism_label,
  
  "PPAR|nuclear receptor|adipogenesis",
  "mech_ppar",
  "PPAR / nuclear receptor",
  
  "Insulin|glucose",
  "mech_insulin",
  "Insulin / glucose signaling",
  
  "Oxidative",
  "mech_oxidative",
  "Oxidative stress",
  
  "Inflammation|cytokine",
  "mech_inflammation",
  "Inflammation",
  
  "Lipid|lipoprotein",
  "mech_lipid",
  "Lipid metabolism",
  
  "Mitochondrial|ER stress|endoplasmic",
  "mech_mito_er",
  "Mitochondrial / ER stress"
)

map_mechanism <- function(panel_text, return_col = "mechanism_label") {
  hit <- mechanism_dictionary %>%
    filter(str_detect(panel_text, regex(panel_pattern, ignore_case = TRUE)))
  
  if (nrow(hit) == 0) {
    return(NA_character_)
  }
  
  hit[[return_col]][1]
}

ctd_mechanism_evidence <- ctd_panel_clean %>%
  mutate(
    mechanism_node = map_chr(panel_raw, map_mechanism, return_col = "mechanism_node"),
    mechanism_label = map_chr(panel_raw, map_mechanism, return_col = "mechanism_label"),
    neg_log10_q = -log10(pmax(q_value, 1e-300)),
    ctd_evidence_level = score_from_q(q_value),
    q_value_fmt = format_q(q_value)
  ) %>%
  filter(!is.na(mechanism_node)) %>%
  group_by(mechanism_node, mechanism_label) %>%
  summarise(
    best_q_value = suppressWarnings(min(q_value, na.rm = TRUE)),
    best_neg_log10_q = suppressWarnings(max(neg_log10_q, na.rm = TRUE)),
    ctd_evidence_level = case_when(
      any(ctd_evidence_level == "High") ~ "High",
      any(ctd_evidence_level == "Moderate") ~ "Moderate",
      TRUE ~ "Suggestive"
    ),
    overlapping_genes = paste(unique(na.omit(overlapping_genes)), collapse = "; "),
    .groups = "drop"
  ) %>%
  mutate(
    best_q_value = ifelse(is.infinite(best_q_value), NA_real_, best_q_value),
    best_neg_log10_q = ifelse(is.infinite(best_neg_log10_q), NA_real_, best_neg_log10_q),
    best_q_value_fmt = format_q(best_q_value)
  )

# Ensure all six mechanism nodes exist.
ctd_mechanism_evidence <- mechanism_dictionary %>%
  distinct(mechanism_node, mechanism_label) %>%
  left_join(ctd_mechanism_evidence, by = c("mechanism_node", "mechanism_label")) %>%
  mutate(
    ctd_evidence_level = ifelse(is.na(ctd_evidence_level), "Suggestive", ctd_evidence_level),
    best_neg_log10_q = ifelse(is.na(best_neg_log10_q), 1, best_neg_log10_q),
    best_q_value_fmt = ifelse(is.na(best_q_value_fmt), "not estimated", best_q_value_fmt),
    overlapping_genes = ifelse(is.na(overlapping_genes), "", overlapping_genes)
  )

# ------------------------------------------------------------
# 5. Mechanism network data
# ------------------------------------------------------------

nodes <- tibble::tribble(
  ~node, ~label, ~node_group, ~x, ~y,
  
  "exp_total",
  "Total DEHP burden\nln(Sigma DEHP)",
  "Exposure",
  0.0, 1.3,
  
  "exp_profile",
  "Oxidative DEHP profile\n%Oxidative / log-ratio / ILR",
  "Exposure",
  0.0, -1.3,
  
  "mech_ppar",
  "PPAR / nuclear receptor",
  "Mechanism",
  1.65, 2.6,
  
  "mech_oxidative",
  "Oxidative stress",
  "Mechanism",
  1.65, 1.55,
  
  "mech_inflammation",
  "Inflammation",
  "Mechanism",
  1.65, 0.55,
  
  "mech_insulin",
  "Insulin / glucose signaling",
  "Mechanism",
  1.65, -0.55,
  
  "mech_lipid",
  "Lipid metabolism",
  "Mechanism",
  1.65, -1.55,
  
  "mech_mito_er",
  "Mitochondrial / ER stress",
  "Mechanism",
  1.65, -2.55,
  
  "out_homa",
  "ln(HOMA-IR)",
  "Metabolic outcome",
  3.45, 1.85,
  
  "out_hba1c",
  "HbA1c",
  "Metabolic outcome",
  3.45, 0.85,
  
  "out_tyg",
  "TyG index",
  "Metabolic outcome",
  3.45, -0.15,
  
  "out_tghdl",
  "ln(TG/HDL-C)",
  "Metabolic outcome",
  3.45, -1.15,
  
  "out_mortality",
  "All-cause mortality\nlinked follow-up",
  "Long-term outcome",
  3.45, -2.35
)

# CTD mechanism edges: total DEHP burden to mechanisms.
ctd_edges <- ctd_mechanism_evidence %>%
  transmute(
    from = "exp_total",
    to = mechanism_node,
    edge_type = "CTD mechanism evidence",
    evidence_level = ctd_evidence_level,
    edge_note = paste0("CTD enrichment q=", best_q_value_fmt),
    edge_weight = pmin(1.35, pmax(0.65, best_neg_log10_q / 6))
  )

# Epidemiologic edges: direct NHANES associations.
epi_edges <- tibble::tribble(
  ~from, ~to, ~edge_type, ~evidence_level, ~edge_note, ~edge_weight,
  
  "exp_profile", "out_homa",
  "NHANES epidemiologic association", "Strong",
  "Most consistent intermediate metabolic association", 1.30,
  
  "exp_profile", "out_hba1c",
  "NHANES epidemiologic association", "Supportive",
  "Positive glycemic association, generally weaker than HOMA-IR", 1.00,
  
  "exp_profile", "out_tyg",
  "NHANES epidemiologic association", "Supportive",
  "Extension to lipid-insulin metabolic marker", 0.95,
  
  "exp_profile", "out_tghdl",
  "NHANES epidemiologic association", "Supportive",
  "Extension to dyslipidemia marker", 0.95,
  
  "exp_total", "out_homa",
  "NHANES epidemiologic association", "Supportive",
  "Total burden positively associated with insulin resistance", 0.95,
  
  "exp_total", "out_hba1c",
  "NHANES epidemiologic association", "Supportive",
  "Total burden positively associated with glycemic marker", 0.90,
  
  "exp_total", "out_mortality",
  "Linked mortality extension", "Strong",
  "ln(Sigma DEHP) associated with all-cause mortality; oxidative profile not positive", 1.20
)

# Biological framework edges: mechanism to outcomes.
framework_edges <- tibble::tribble(
  ~from, ~to, ~edge_type, ~evidence_level, ~edge_note, ~edge_weight,
  
  "mech_ppar", "out_homa",
  "Biological framework link", "Supportive",
  "PPAR/adipogenesis may influence insulin sensitivity", 0.65,
  
  "mech_ppar", "out_tyg",
  "Biological framework link", "Supportive",
  "PPAR signaling links lipid and glucose metabolism", 0.65,
  
  "mech_insulin", "out_homa",
  "Biological framework link", "Supportive",
  "Direct insulin-signaling relevance", 0.75,
  
  "mech_insulin", "out_hba1c",
  "Biological framework link", "Supportive",
  "Glucose regulation relevance", 0.65,
  
  "mech_lipid", "out_tyg",
  "Biological framework link", "Supportive",
  "Triglyceride-glucose marker relevance", 0.70,
  
  "mech_lipid", "out_tghdl",
  "Biological framework link", "Supportive",
  "Lipid ratio relevance", 0.70,
  
  "mech_oxidative", "out_homa",
  "Biological framework link", "Supportive",
  "Oxidative stress may impair insulin signaling", 0.70,
  
  "mech_oxidative", "out_hba1c",
  "Biological framework link", "Supportive",
  "Oxidative stress and glycemic dysfunction", 0.60,
  
  "mech_oxidative", "out_tyg",
  "Biological framework link", "Supportive",
  "Oxidative stress and metabolic dysregulation", 0.60,
  
  "mech_inflammation", "out_homa",
  "Biological framework link", "Supportive",
  "Inflammatory signaling and insulin resistance", 0.65,
  
  "mech_inflammation", "out_hba1c",
  "Biological framework link", "Supportive",
  "Inflammation and glycemic regulation", 0.55,
  
  "mech_mito_er", "out_homa",
  "Biological framework link", "Supportive",
  "Mitochondrial/ER stress and insulin resistance", 0.60
)

# Oxidative profile to mechanistic interpretation.
profile_mech_edges <- tibble::tribble(
  ~from, ~to, ~edge_type, ~evidence_level, ~edge_note, ~edge_weight,
  
  "exp_profile", "mech_oxidative",
  "Mechanistic interpretation", "Supportive",
  "Oxidative metabolite balance plausibly reflects metabolic processing and oxidative burden", 0.90,
  
  "exp_profile", "mech_inflammation",
  "Mechanistic interpretation", "Supportive",
  "Profile associations align with inflammatory CTD evidence", 0.75,
  
  "exp_profile", "mech_mito_er",
  "Mechanistic interpretation", "Exploratory",
  "Mitochondrial/ER stress as plausible intermediate mechanism", 0.65
)

edges <- bind_rows(
  ctd_edges,
  epi_edges,
  profile_mech_edges,
  framework_edges
) %>%
  mutate(
    edge_type = factor(
      edge_type,
      levels = c(
        "NHANES epidemiologic association",
        "Linked mortality extension",
        "CTD mechanism evidence",
        "Mechanistic interpretation",
        "Biological framework link"
      )
    ),
    evidence_level = factor(
      evidence_level,
      levels = c(
        "Strong", "High", "Supportive", "Moderate",
        "Exploratory", "Suggestive", "Inconclusive"
      )
    )
  )

edges_plot <- edges %>%
  left_join(
    nodes %>% select(from = node, x_from = x, y_from = y),
    by = "from"
  ) %>%
  left_join(
    nodes %>% select(to = node, x_to = x, y_to = y),
    by = "to"
  )

# ------------------------------------------------------------
# 6. Plot mechanism network
# ------------------------------------------------------------

network_caption <- paste0(
  "Solid direct links represent NHANES epidemiologic or linked-mortality evidence. ",
  "CTD links represent database-derived mechanistic plausibility. ",
  "Framework links are biological interpretation links and should not be read as experimental validation."
)

p_network <- ggplot() +
  geom_segment(
    data = edges_plot,
    aes(
      x = x_from,
      y = y_from,
      xend = x_to,
      yend = y_to,
      color = edge_type,
      linewidth = edge_weight,
      alpha = edge_type
    ),
    arrow = grid::arrow(length = grid::unit(0.16, "inches"), type = "closed"),
    lineend = "round"
  ) +
  geom_label(
    data = nodes,
    aes(x = x, y = y, label = label, fill = node_group),
    size = 4.1,
    fontface = "bold",
    color = "black",
    label.size = 0.35,
    label.r = grid::unit(0.15, "lines"),
    label.padding = grid::unit(0.22, "lines")
  ) +
  annotate(
    "text",
    x = 0,
    y = 3.35,
    label = "Exposure indicators",
    fontface = "bold",
    size = 4.2
  ) +
  annotate(
    "text",
    x = 1.65,
    y = 3.35,
    label = "Mechanistic domains",
    fontface = "bold",
    size = 4.2
  ) +
  annotate(
    "text",
    x = 3.45,
    y = 3.35,
    label = "Metabolic and long-term outcomes",
    fontface = "bold",
    size = 4.2
  ) +
  scale_fill_manual(
    values = c(
      "Exposure" = "#D9EAF7",
      "Mechanism" = "#E6F2DD",
      "Metabolic outcome" = "#F8E6D9",
      "Long-term outcome" = "#EFE6F8"
    )
  ) +
  scale_color_manual(
    values = c(
      "NHANES epidemiologic association" = "#0B559F",
      "Linked mortality extension" = "#6A3D9A",
      "CTD mechanism evidence" = "#2E7D32",
      "Mechanistic interpretation" = "#00897B",
      "Biological framework link" = "#777777"
    )
  ) +
  scale_alpha_manual(
    values = c(
      "NHANES epidemiologic association" = 0.95,
      "Linked mortality extension" = 0.95,
      "CTD mechanism evidence" = 0.90,
      "Mechanistic interpretation" = 0.82,
      "Biological framework link" = 0.45
    )
  ) +
  scale_linewidth(range = c(0.35, 1.2), guide = "none") +
  coord_cartesian(xlim = c(-0.45, 4.05), ylim = c(-3.05, 3.6), clip = "off") +
  labs(
    title = "Mechanistic evidence network for DEHP exposure profiles and metabolic dysfunction",
    subtitle = "Integration of NHANES epidemiologic associations, linked mortality extension, and CTD mechanistic database evidence",
    color = "Evidence layer",
    alpha = "Evidence layer",
    fill = "Node type",
    caption = network_caption
  ) +
  theme_void(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0),
    plot.subtitle = element_text(size = 10.5, hjust = 0),
    plot.caption = element_text(size = 8.5, hjust = 0),
    legend.position = "bottom",
    legend.box = "vertical",
    legend.title = element_text(face = "bold"),
    plot.margin = margin(15, 20, 15, 20)
  )

print(p_network)

ggsave(
  filename = file.path(fig_dir, "DEHP_mechanism_network_synthesis.png"),
  plot = p_network,
  width = 15,
  height = 9,
  dpi = 300
)

ggsave(
  filename = file.path(fig_dir, "DEHP_mechanism_network_synthesis.pdf"),
  plot = p_network,
  width = 15,
  height = 9
)

# ------------------------------------------------------------
# 7. Evidence synthesis matrix
# ------------------------------------------------------------

module_order <- c(
  "Main survey-weighted models",
  "Quartile and RCS dose-response",
  "Mixture models: qgcomp-like / WQS",
  "Compositional log-ratio / ILR",
  "TyG and TG/HDL-C extension",
  "Source-oriented and source-adjusted models",
  "Diabetes / medication exclusion",
  "IPW and multiple imputation",
  "BKMR exploratory mixture analysis",
  "Linked mortality analysis",
  "Negative-control / permutation analyses",
  "CTD / CompTox / ToxCast mechanism triangulation"
)

domain_order <- c(
  "HOMA-IR / insulin resistance",
  "HbA1c / glycemic marker",
  "TyG / lipid-insulin marker",
  "TG/HDL-C / dyslipidemia marker",
  "Long-term mortality relevance",
  "Mechanistic plausibility"
)

evidence_records <- tibble::tribble(
  ~analysis_module, ~evidence_domain, ~evidence_level, ~cell_text, ~interpretation,
  
  "Main survey-weighted models", "HOMA-IR / insulin resistance",
  "Strong", "Strong", "Consistent positive association with insulin resistance marker",
  
  "Main survey-weighted models", "HbA1c / glycemic marker",
  "Supportive", "Supportive", "Positive glycemic association, generally weaker than HOMA-IR",
  
  "Quartile and RCS dose-response", "HOMA-IR / insulin resistance",
  "Strong", "Strong", "Dose-response evidence supports non-linear/monotonic positive pattern",
  
  "Quartile and RCS dose-response", "HbA1c / glycemic marker",
  "Supportive", "Supportive", "Dose-response evidence present but weaker than HOMA-IR",
  
  "Mixture models: qgcomp-like / WQS", "HOMA-IR / insulin resistance",
  "Strong", "Strong", "Oxidative DEHP mixture repeatedly supported",
  
  "Mixture models: qgcomp-like / WQS", "HbA1c / glycemic marker",
  "Supportive", "Supportive", "Mixture evidence directionally consistent",
  
  "Mixture models: qgcomp-like / WQS", "TyG / lipid-insulin marker",
  "Supportive", "Supportive", "Mixture extension supports broader metabolic disruption",
  
  "Mixture models: qgcomp-like / WQS", "TG/HDL-C / dyslipidemia marker",
  "Supportive", "Supportive", "Mixture extension supports lipid-metabolic disruption",
  
  "Compositional log-ratio / ILR", "HOMA-IR / insulin resistance",
  "Supportive", "Supportive", "Oxidative-vs-primary balance supports metabolic-processing interpretation",
  
  "Compositional log-ratio / ILR", "HbA1c / glycemic marker",
  "Supportive", "Supportive", "Composition signal supports glycemic relevance but not as primary evidence",
  
  "TyG and TG/HDL-C extension", "TyG / lipid-insulin marker",
  "Strong", "Strong", "Additional metabolic marker extension is consistent with DEHP profile signal",
  
  "TyG and TG/HDL-C extension", "TG/HDL-C / dyslipidemia marker",
  "Strong", "Strong", "Additional lipid-ratio marker extension is consistent with DEHP profile signal",
  
  "Source-oriented and source-adjusted models", "HOMA-IR / insulin resistance",
  "Supportive", "Supportive", "DEHP associations not fully explained by measured exposure-source proxies",
  
  "Source-oriented and source-adjusted models", "HbA1c / glycemic marker",
  "Supportive", "Supportive", "Source adjustment supports robustness but remains observational",
  
  "Source-oriented and source-adjusted models", "TyG / lipid-insulin marker",
  "Supportive", "Supportive", "Directionally supports extended metabolic marker interpretation",
  
  "Source-oriented and source-adjusted models", "TG/HDL-C / dyslipidemia marker",
  "Supportive", "Supportive", "Directionally supports dyslipidemia marker interpretation",
  
  "Diabetes / medication exclusion", "HOMA-IR / insulin resistance",
  "Supportive", "Supportive", "Medication/diabetes exclusion did not remove key signal",
  
  "Diabetes / medication exclusion", "HbA1c / glycemic marker",
  "Supportive", "Supportive", "Medication/diabetes exclusion supports robustness",
  
  "IPW and multiple imputation", "HOMA-IR / insulin resistance",
  "Strong", "Strong", "Missing-data sensitivity supports complete-case estimates",
  
  "IPW and multiple imputation", "HbA1c / glycemic marker",
  "Strong", "Strong", "Missing-data sensitivity supports complete-case estimates",
  
  "IPW and multiple imputation", "TyG / lipid-insulin marker",
  "Strong", "Strong", "IPW/MI results remain directionally consistent",
  
  "IPW and multiple imputation", "TG/HDL-C / dyslipidemia marker",
  "Strong", "Strong", "IPW/MI results remain directionally consistent",
  
  "BKMR exploratory mixture analysis", "HOMA-IR / insulin resistance",
  "Supportive", "Supportive", "Exploratory BKMR showed positive mixture-response and high PIPs for oxidative components",
  
  "BKMR exploratory mixture analysis", "HbA1c / glycemic marker",
  "Supportive", "Supportive", "Exploratory BKMR directionally consistent",
  
  "BKMR exploratory mixture analysis", "TyG / lipid-insulin marker",
  "Supportive", "Supportive", "Exploratory BKMR directionally consistent",
  
  "BKMR exploratory mixture analysis", "TG/HDL-C / dyslipidemia marker",
  "Supportive", "Supportive", "Exploratory BKMR directionally consistent",
  
  "Linked mortality analysis", "Long-term mortality relevance",
  "Total-burden only", "Total burden only", "ln(Sigma DEHP), but not oxidative composition, was associated with all-cause mortality",
  
  "Negative-control / permutation analyses", "HOMA-IR / insulin resistance",
  "No falsification signal", "No falsification", "Adult-height negative control and permutation analyses did not suggest major spurious findings",
  
  "Negative-control / permutation analyses", "HbA1c / glycemic marker",
  "No falsification signal", "No falsification", "Adult-height negative control and permutation analyses did not suggest major spurious findings",
  
  "CTD / CompTox / ToxCast mechanism triangulation", "Mechanistic plausibility",
  "Supportive", "Supportive", "CTD evidence supports PPAR/nuclear receptor, oxidative stress, inflammation, insulin/glucose, lipid metabolism, and mitochondrial/ER stress pathways",
  
  "CTD / CompTox / ToxCast mechanism triangulation", "HOMA-IR / insulin resistance",
  "Supportive", "Supportive", "Mechanism domains are biologically consistent with insulin resistance",
  
  "CTD / CompTox / ToxCast mechanism triangulation", "HbA1c / glycemic marker",
  "Supportive", "Supportive", "Mechanism domains are biologically consistent with glycemic dysfunction",
  
  "CTD / CompTox / ToxCast mechanism triangulation", "TyG / lipid-insulin marker",
  "Supportive", "Supportive", "Mechanism domains are biologically consistent with lipid-insulin disruption",
  
  "CTD / CompTox / ToxCast mechanism triangulation", "TG/HDL-C / dyslipidemia marker",
  "Supportive", "Supportive", "Mechanism domains are biologically consistent with lipid dysregulation"
)

evidence_matrix <- tidyr::expand_grid(
  analysis_module = module_order,
  evidence_domain = domain_order
) %>%
  left_join(
    evidence_records,
    by = c("analysis_module", "evidence_domain")
  ) %>%
  mutate(
    evidence_level = replace_na(evidence_level, "N/A"),
    cell_text = replace_na(cell_text, ""),
    interpretation = replace_na(interpretation, ""),
    analysis_module = factor(analysis_module, levels = rev(module_order)),
    evidence_domain = factor(evidence_domain, levels = domain_order),
    evidence_score = case_when(
      evidence_level == "Strong" ~ 6,
      evidence_level == "Supportive" ~ 5,
      evidence_level == "Total-burden only" ~ 4,
      evidence_level == "No falsification signal" ~ 3,
      evidence_level == "Exploratory" ~ 2,
      evidence_level == "Inconclusive" ~ 1,
      TRUE ~ 0
    )
  )

evidence_colors <- c(
  "Strong" = "#0B7A3B",
  "Supportive" = "#8BCF70",
  "Total-burden only" = "#6A3D9A",
  "No falsification signal" = "#9EC3E6",
  "Exploratory" = "#D7BDE2",
  "Inconclusive" = "#F7C6C7",
  "N/A" = "#EFEFEF"
)

p_matrix <- ggplot(
  evidence_matrix,
  aes(x = evidence_domain, y = analysis_module, fill = evidence_level)
) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(
    aes(label = str_wrap(cell_text, width = 14)),
    size = 3.05,
    fontface = "bold",
    lineheight = 0.9
  ) +
  scale_fill_manual(values = evidence_colors, drop = FALSE) +
  labs(
    title = "Evidence synthesis matrix for DEHP exposure profiles and metabolic dysfunction",
    subtitle = "Cells summarize the direction, robustness, and interpretive role of each analysis module",
    x = NULL,
    y = NULL,
    fill = "Evidence level",
    caption = paste0(
      "Strong = repeated direct statistical support; Supportive = directionally consistent or complementary evidence; ",
      "Total-burden only = supports total DEHP burden rather than oxidative composition; ",
      "No falsification = negative-control/permutation analyses did not suggest major spurious findings. ",
      "Mechanistic triangulation is hypothesis-supporting and not experimental validation."
    )
  ) +
  theme_minimal(base_size = 10.5) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(size = 10),
    plot.caption = element_text(size = 8.3, hjust = 0),
    axis.text.x = element_text(angle = 35, hjust = 1, face = "bold"),
    axis.text.y = element_text(face = "bold"),
    panel.grid = element_blank(),
    legend.position = "bottom"
  )

print(p_matrix)

ggsave(
  filename = file.path(fig_dir, "DEHP_evidence_synthesis_matrix.png"),
  plot = p_matrix,
  width = 15,
  height = 8.5,
  dpi = 300
)

ggsave(
  filename = file.path(fig_dir, "DEHP_evidence_synthesis_matrix.pdf"),
  plot = p_matrix,
  width = 15,
  height = 8.5
)

# ------------------------------------------------------------
# 8. Claim-level synthesis table
# ------------------------------------------------------------

claim_synthesis <- tibble::tribble(
  ~claim_id, ~claim, ~overall_support, ~supporting_evidence, ~main_caveat,
  
  "Claim 1",
  "Oxidative DEHP metabolic profile is associated with intermediate metabolic dysfunction, especially insulin resistance.",
  "Strong",
  "Main survey-weighted models, dose-response/RCS, mixture models, compositional analyses, IPW/MI, BKMR exploratory analysis.",
  "Observational cross-sectional biomarker analysis; residual confounding and temporal ambiguity remain possible.",
  
  "Claim 2",
  "The metabolic signal is broader than HOMA-IR and extends to glycemic-lipid markers.",
  "Supportive to strong",
  "HbA1c, TyG index, and TG/HDL-C extensions; mixture and missing-data sensitivity analyses.",
  "Effect sizes and precision vary across outcomes; HOMA-IR is the most consistent endpoint.",
  
  "Claim 3",
  "Total DEHP burden has long-term public-health relevance.",
  "Supportive",
  "Linked mortality analysis showed ln(Sigma DEHP) associated with all-cause mortality.",
  "Mortality association was observed for total burden, not oxidative composition; cause-specific mortality was event-limited.",
  
  "Claim 4",
  "Mechanistic plausibility is supported by toxicogenomic database evidence.",
  "Supportive",
  "CTD enrichment in PPAR/nuclear receptor, insulin/glucose, oxidative stress, inflammation, lipid metabolism, and mitochondrial/ER stress panels.",
  "CTD/CompTox/ToxCast database evidence is hypothesis-supporting, not experimental validation.",
  
  "Claim 5",
  "Major spurious association patterns were not suggested by falsification analyses.",
  "Supportive",
  "Negative-control outcome and exposure-permutation analyses.",
  "Falsification analyses cannot eliminate all forms of residual confounding."
)

# ------------------------------------------------------------
# 9. Manuscript-ready captions and text blocks
# ------------------------------------------------------------

figure_captions <- tibble::tribble(
  ~item, ~caption,
  
  "Mechanism network figure",
  "Figure X. Mechanistic evidence network linking DEHP exposure profiles to metabolic dysfunction. The network integrates NHANES epidemiologic associations, linked mortality extension, CTD toxicogenomic evidence, and biologically plausible pathway links. Direct epidemiologic edges represent observed associations in survey-weighted NHANES analyses. CTD mechanism edges represent database-derived support for PPAR/nuclear receptor signaling, oxidative stress, inflammation, insulin/glucose regulation, lipid metabolism, and mitochondrial/endoplasmic-reticulum stress. Framework edges indicate mechanistic interpretation and should not be read as experimental validation.",
  
  "Evidence synthesis matrix",
  "Figure Y. Evidence synthesis matrix summarizing support across analysis modules. Strong evidence denotes repeated direct statistical support across primary and sensitivity analyses. Supportive evidence denotes directionally consistent or complementary evidence. The linked mortality analysis supports long-term relevance of total DEHP burden but does not support oxidative composition as a mortality predictor. CTD/CompTox/ToxCast evidence provides mechanistic triangulation rather than causal validation."
)

manuscript_results_text <- tibble::tribble(
  ~section, ~text,
  
  "Results - evidence synthesis",
  "To integrate findings across statistical, sensitivity, mortality, and mechanistic analyses, we constructed a mechanism network and an evidence synthesis matrix. The synthesis indicated that the strongest and most consistent evidence supported associations of oxidative DEHP metabolic profile with intermediate metabolic dysfunction, particularly ln(HOMA-IR). Supportive evidence extended to HbA1c, TyG index, and ln(TG/HDL-C), although the strength and precision of associations varied across outcomes. Linked mortality analyses suggested long-term public-health relevance for total DEHP burden, whereas oxidative composition indicators were not positively associated with all-cause mortality. CTD-based mechanistic triangulation supported biological plausibility through PPAR/nuclear receptor signaling, oxidative stress, inflammation, insulin/glucose signaling, lipid metabolism, and mitochondrial/endoplasmic-reticulum stress pathways.",
  
  "Discussion - evidence synthesis interpretation",
  "The integrated evidence framework suggests a distinction between intermediate metabolic perturbation and distal survival outcomes. Oxidative DEHP metabolic profile appeared more informative for insulin-resistance and glycemic-lipid markers, whereas total DEHP burden was more relevant to all-cause mortality. This pattern is biologically plausible because oxidative metabolic composition may reflect metabolic processing and intermediate toxicodynamic response, while total burden may better capture cumulative exposure relevant to long-term mortality risk. Mechanistic database evidence further supports pathways involving nuclear receptor activation, oxidative stress, inflammatory signaling, lipid regulation, and insulin/glucose homeostasis. These convergent findings strengthen plausibility but do not establish causality, given the observational design and reliance on database-derived mechanistic evidence."
)

# ------------------------------------------------------------
# 10. Export workbook and CSVs
# ------------------------------------------------------------

write_xlsx(
  list(
    network_nodes = nodes,
    network_edges = edges,
    ctd_mechanism_evidence_clean = ctd_mechanism_evidence,
    evidence_synthesis_matrix = evidence_matrix %>%
      mutate(
        analysis_module = as.character(analysis_module),
        evidence_domain = as.character(evidence_domain)
      ),
    claim_synthesis = claim_synthesis,
    figure_captions = figure_captions,
    manuscript_text = manuscript_results_text
  ),
  file.path(result_dir, "evidence_synthesis_DEHP_metabolic_project.xlsx")
)

write.csv(
  edges,
  file.path(result_dir, "DEHP_mechanism_network_edges.csv"),
  row.names = FALSE
)

write.csv(
  evidence_matrix %>%
    mutate(
      analysis_module = as.character(analysis_module),
      evidence_domain = as.character(evidence_domain)
    ),
  file.path(result_dir, "DEHP_evidence_synthesis_matrix.csv"),
  row.names = FALSE
)

cat("\nMechanism network and evidence synthesis completed successfully.\n")
cat("Workbook saved to:\n")
cat(file.path(result_dir, "evidence_synthesis_DEHP_metabolic_project.xlsx"), "\n")
cat("Figures saved to:\n")
cat(file.path(fig_dir, "DEHP_mechanism_network_synthesis.png"), "\n")
cat(file.path(fig_dir, "DEHP_evidence_synthesis_matrix.png"), "\n")