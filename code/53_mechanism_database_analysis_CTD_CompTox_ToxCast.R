# ============================================================
# NHANES DEHP project
# 53_mechanism_database_analysis_CTD_CompTox_ToxCast.R
#
# Mechanistic database analysis using:
#   1. CTD chemical-gene evidence
#   2. CTD chemical-disease evidence
#   3. CTD chemical-phenotype evidence
#   4. CompTox / DSSTox chemical identifiers
#   5. Optional ToxCast / CTX Bioactivity API if CTX_API_KEY exists
#
# This script assumes CTD files have already been downloaded by:
#   53A_download_CTD_files_robust.R
# ============================================================

options(timeout = 10000)

# ------------------------------------------------------------
# 0. Packages
# ------------------------------------------------------------

required_packages <- c(
  "dplyr", "tidyr", "purrr", "readr", "stringr",
  "tibble", "ggplot2", "writexl", "httr", "jsonlite"
)

installed_packages <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed_packages)

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(stringr)
library(tibble)
library(ggplot2)
library(writexl)
library(httr)
library(jsonlite)

# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project"

data_dir <- file.path(project_dir, "data")
raw_dir <- file.path(data_dir, "raw_mechanism_databases")
ctd_dir <- file.path(raw_dir, "CTD")
output_dir <- file.path(project_dir, "output")
result_dir <- file.path(project_dir, "result")
fig_dir <- file.path(result_dir, "figures_mechanism")

dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(ctd_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(result_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 2. Helper functions
# ------------------------------------------------------------

is_valid_gzip_full <- function(path, min_size_mb = 1) {
  if (!file.exists(path)) {
    return(FALSE)
  }
  
  file_size_mb <- file.info(path)$size / 1024 / 1024
  
  if (!is.finite(file_size_mb) || file_size_mb < min_size_mb) {
    return(FALSE)
  }
  
  con <- NULL
  
  ok <- tryCatch(
    {
      con <- gzfile(path, open = "rb")
      
      repeat {
        chunk <- readBin(con, what = "raw", n = 1024 * 1024)
        if (length(chunk) == 0) {
          break
        }
      }
      
      TRUE
    },
    error = function(e) {
      message("Invalid gzip file: ", basename(path), " | ", e$message)
      FALSE
    },
    finally = {
      if (!is.null(con)) {
        try(close(con), silent = TRUE)
      }
    }
  )
  
  return(ok)
}

download_if_missing <- function(urls, destfile, min_size_mb = 1, max_attempts = 5) {
  dir.create(dirname(destfile), showWarnings = FALSE, recursive = TRUE)
  
  if (is_valid_gzip_full(destfile, min_size_mb = min_size_mb)) {
    message("File exists and gzip is valid: ", destfile)
    return(invisible(TRUE))
  }
  
  if (file.exists(destfile)) {
    message("Existing file is incomplete or invalid; deleting: ", destfile)
    unlink(destfile)
  }
  
  tmpfile <- paste0(destfile, ".part")
  
  if (file.exists(tmpfile)) {
    unlink(tmpfile)
  }
  
  for (url in urls) {
    for (attempt in seq_len(max_attempts)) {
      message("Downloading attempt ", attempt, "/", max_attempts, ": ", url)
      
      ok <- tryCatch(
        {
          download.file(
            url = url,
            destfile = tmpfile,
            mode = "wb",
            method = "libcurl",
            quiet = FALSE
          )
          
          TRUE
        },
        error = function(e) {
          message("download.file failed: ", e$message)
          FALSE
        }
      )
      
      if (ok && file.exists(tmpfile)) {
        file.rename(tmpfile, destfile)
        
        if (is_valid_gzip_full(destfile, min_size_mb = min_size_mb)) {
          message("Download completed and validated: ", destfile)
          return(invisible(TRUE))
        } else {
          message("Downloaded file failed gzip validation; retrying.")
          unlink(destfile)
        }
      }
      
      Sys.sleep(3)
    }
  }
  
  stop("下载失败或文件不完整：", destfile)
}

ensure_cols <- function(dat, cols) {
  for (col in cols) {
    if (!(col %in% names(dat))) {
      dat[[col]] <- NA_character_
    }
  }
  
  dat
}

count_pmids <- function(x) {
  x <- as.character(x)
  
  ifelse(
    is.na(x) | x == "",
    0L,
    stringr::str_count(x, "\\|") + 1L
  )
}

score_level <- function(n) {
  dplyr::case_when(
    is.na(n) ~ "None",
    n >= 10 ~ "High",
    n >= 3 ~ "Moderate",
    n >= 1 ~ "Suggestive",
    TRUE ~ "None"
  )
}

safe_lower <- function(x) {
  tolower(ifelse(is.na(x), "", as.character(x)))
}

match_keyword_panel <- function(text, keyword_tbl) {
  text_low <- safe_lower(text)
  
  hits <- keyword_tbl %>%
    mutate(hit = stringr::str_detect(text_low, stringr::regex(pattern, ignore_case = TRUE))) %>%
    filter(hit) %>%
    pull(panel)
  
  if (length(hits) == 0) {
    return("Other / not mapped")
  }
  
  paste(unique(hits), collapse = "; ")
}

safe_fisher <- function(a, b, c, d) {
  mat <- matrix(c(a, b, c, d), nrow = 2)
  
  out <- tryCatch(
    fisher.test(mat),
    error = function(e) NULL
  )
  
  if (is.null(out)) {
    return(tibble(
      odds_ratio = NA_real_,
      p_value = NA_real_
    ))
  }
  
  tibble(
    odds_ratio = unname(out$estimate),
    p_value = out$p.value
  )
}

pick_col <- function(dat, patterns) {
  nms <- names(dat)
  nms_low <- tolower(nms)
  
  for (pat in patterns) {
    hit <- nms[stringr::str_detect(nms_low, stringr::regex(pat, ignore_case = TRUE))]
    
    if (length(hit) > 0) {
      return(hit[1])
    }
  }
  
  NA_character_
}

get_col_or_na <- function(dat, col) {
  if (is.na(col) || !(col %in% names(dat))) {
    return(rep(NA_character_, nrow(dat)))
  }
  
  as.character(dat[[col]])
}

# ------------------------------------------------------------
# 3. Robust CTD reader
# ------------------------------------------------------------

read_ctd_tsv_gz <- function(path, dataset = NULL) {
  if (!file.exists(path)) {
    stop("CTD file not found: ", path)
  }
  
  infer_dataset <- function(path) {
    bn <- basename(path)
    
    if (bn == "CTD_chemicals.tsv.gz") return("chemicals")
    if (bn == "CTD_chem_gene_ixns.tsv.gz") return("chemical_gene")
    if (bn == "CTD_chemicals_diseases.tsv.gz") return("chemical_disease")
    if (bn == "CTD_pheno_term_ixns.tsv.gz") return("chemical_phenotype")
    
    "unknown"
  }
  
  if (is.null(dataset)) {
    dataset <- infer_dataset(path)
  }
  
  fallback_cols <- switch(
    dataset,
    
    chemicals = c(
      "ChemicalName", "ChemicalID", "CasRN", "Definition",
      "ParentIDs", "TreeNumbers", "ParentTreeNumbers",
      "Synonyms", "DrugBankIDs"
    ),
    
    chemical_gene = c(
      "ChemicalName", "ChemicalID", "CasRN",
      "GeneSymbol", "GeneID", "GeneForms",
      "Organism", "OrganismID",
      "Interaction", "InteractionActions",
      "PubMedIDs"
    ),
    
    chemical_disease = c(
      "ChemicalName", "ChemicalID", "CasRN",
      "DiseaseName", "DiseaseID",
      "DirectEvidence", "InferenceGeneSymbol",
      "InferenceScore", "OmimIDs", "PubMedIDs"
    ),
    
    chemical_phenotype = c(
      "ChemicalName", "ChemicalID", "CasRN",
      "GeneSymbol", "GeneID", "GeneForms",
      "Organism", "OrganismID",
      "Interaction", "InteractionActions",
      "AnatomyTerms", "PhenotypeID",
      "PhenotypeName", "PubMedIDs"
    ),
    
    c()
  )
  
  header_cols <- NULL
  
  header_lines <- tryCatch(
    {
      con_header <- gzfile(path, open = "rt")
      on.exit(try(close(con_header), silent = TRUE), add = TRUE)
      readLines(con_header, n = 10000, warn = FALSE)
    },
    error = function(e) {
      character()
    }
  )
  
  if (length(header_lines) > 0) {
    possible_headers <- header_lines[
      stringr::str_detect(header_lines, "^#") &
        stringr::str_detect(header_lines, "ChemicalName") &
        stringr::str_detect(header_lines, "\t")
    ]
    
    if (length(possible_headers) > 0) {
      header_line <- tail(possible_headers, 1)
      
      header_cols <- header_line %>%
        stringr::str_replace("^#\\s*", "") %>%
        stringr::str_split("\t") %>%
        .[[1]]
    }
  }
  
  con_data <- NULL
  
  dat <- tryCatch(
    {
      con_data <- gzfile(path, open = "rt")
      
      utils::read.delim(
        file = con_data,
        sep = "\t",
        header = FALSE,
        comment.char = "#",
        quote = "",
        fill = TRUE,
        stringsAsFactors = FALSE,
        check.names = FALSE,
        na.strings = c("", "NA")
      )
    },
    error = function(e) {
      stop("Failed to read CTD file: ", path, " | ", e$message)
    },
    finally = {
      if (!is.null(con_data)) {
        try(close(con_data), silent = TRUE)
      }
    }
  )
  
  if (nrow(dat) == 0) {
    stop("CTD file was read but contains no data rows: ", path)
  }
  
  assign_colnames <- function(dat, cols) {
    if (length(cols) == 0) {
      names(dat) <- paste0("V", seq_len(ncol(dat)))
      return(dat)
    }
    
    if (length(cols) < ncol(dat)) {
      cols <- c(cols, paste0("Extra", seq_len(ncol(dat) - length(cols))))
    }
    
    if (length(cols) > ncol(dat)) {
      cols <- cols[seq_len(ncol(dat))]
    }
    
    names(dat) <- make.names(cols, unique = TRUE)
    
    dat
  }
  
  if (!is.null(header_cols) && length(header_cols) > 0) {
    dat <- assign_colnames(dat, header_cols)
  } else {
    dat <- assign_colnames(dat, fallback_cols)
  }
  
  if (dataset == "chemical_phenotype") {
    if (!("ChemicalName" %in% names(dat)) && ncol(dat) >= 1) names(dat)[1] <- "ChemicalName"
    if (!("ChemicalID" %in% names(dat)) && ncol(dat) >= 2) names(dat)[2] <- "ChemicalID"
    if (!("CasRN" %in% names(dat)) && ncol(dat) >= 3) names(dat)[3] <- "CasRN"
    if (!("GeneSymbol" %in% names(dat)) && ncol(dat) >= 4) names(dat)[4] <- "GeneSymbol"
    if (!("GeneID" %in% names(dat)) && ncol(dat) >= 5) names(dat)[5] <- "GeneID"
    if (!("Interaction" %in% names(dat)) && ncol(dat) >= 9) names(dat)[9] <- "Interaction"
    if (!("InteractionActions" %in% names(dat)) && ncol(dat) >= 10) names(dat)[10] <- "InteractionActions"
    if (!("AnatomyTerms" %in% names(dat)) && ncol(dat) >= 11) names(dat)[11] <- "AnatomyTerms"
    
    if (!("PubMedIDs" %in% names(dat))) {
      names(dat)[ncol(dat)] <- "PubMedIDs"
    }
    
    if (!("PhenotypeName" %in% names(dat))) {
      pubmed_pos <- which(names(dat) == "PubMedIDs")[1]
      
      if (!is.na(pubmed_pos) && pubmed_pos > 1) {
        candidate_pos <- pubmed_pos - 1
        names(dat)[candidate_pos] <- "PhenotypeName"
      }
    }
    
    if (!("PhenotypeID" %in% names(dat))) {
      dat$PhenotypeID <- NA_character_
    }
  }
  
  dat <- dat %>%
    mutate(across(everything(), ~ as.character(.x)))
  
  dat
}

# ------------------------------------------------------------
# 4. Chemical target definitions
# ------------------------------------------------------------

chemical_targets <- tibble::tribble(
  ~chemical_label, ~role, ~casrn, ~dtxsid, ~ctd_pattern,
  
  "DEHP",
  "Parent compound / total burden anchor",
  "117-81-7",
  "DTXSID5020607",
  "di\\(2-ethylhexyl\\) phthalate|bis\\(2-ethylhexyl\\) phthalate|diethylhexyl phthalate|DEHP|117-81-7",
  
  "MEHP",
  "Primary monoester metabolite",
  "4376-20-9",
  "DTXSID2025680",
  "mono\\(2-ethylhexyl\\) phthalate|mono-2-ethylhexyl phthalate|MEHP|4376-20-9",
  
  "MEHHP",
  "Oxidative metabolite",
  NA_character_,
  NA_character_,
  "MEHHP|mono\\(2-ethyl-5-hydroxyhexyl\\) phthalate|5-hydroxyhexyl",
  
  "MEOHP",
  "Oxidative metabolite",
  NA_character_,
  NA_character_,
  "MEOHP|mono\\(2-ethyl-5-oxohexyl\\) phthalate|5-oxohexyl",
  
  "MECPP",
  "Oxidative metabolite",
  NA_character_,
  NA_character_,
  "MECPP|mono\\(2-ethyl-5-carboxypentyl\\) phthalate|carboxypentyl"
)

write_csv(
  chemical_targets,
  file.path(output_dir, "mechanism_chemical_targets_DEHP.csv")
)

# ------------------------------------------------------------
# 5. Mechanism gene panels
# ------------------------------------------------------------

mechanism_gene_panels <- tibble::tribble(
  ~panel, ~gene_symbol,
  
  "PPAR / nuclear receptor / adipogenesis", "PPARA",
  "PPAR / nuclear receptor / adipogenesis", "PPARD",
  "PPAR / nuclear receptor / adipogenesis", "PPARG",
  "PPAR / nuclear receptor / adipogenesis", "RXRA",
  "PPAR / nuclear receptor / adipogenesis", "RXRB",
  "PPAR / nuclear receptor / adipogenesis", "NR1H3",
  "PPAR / nuclear receptor / adipogenesis", "NR1H2",
  "PPAR / nuclear receptor / adipogenesis", "FABP4",
  "PPAR / nuclear receptor / adipogenesis", "ADIPOQ",
  "PPAR / nuclear receptor / adipogenesis", "LEP",
  
  "Insulin / glucose signaling", "INS",
  "Insulin / glucose signaling", "INSR",
  "Insulin / glucose signaling", "IRS1",
  "Insulin / glucose signaling", "IRS2",
  "Insulin / glucose signaling", "AKT1",
  "Insulin / glucose signaling", "AKT2",
  "Insulin / glucose signaling", "SLC2A4",
  "Insulin / glucose signaling", "GCK",
  "Insulin / glucose signaling", "PCK1",
  "Insulin / glucose signaling", "G6PC",
  "Insulin / glucose signaling", "GSK3B",
  "Insulin / glucose signaling", "FOXO1",
  
  "Lipid metabolism / lipoprotein", "LPL",
  "Lipid metabolism / lipoprotein", "APOA1",
  "Lipid metabolism / lipoprotein", "APOB",
  "Lipid metabolism / lipoprotein", "APOE",
  "Lipid metabolism / lipoprotein", "SREBF1",
  "Lipid metabolism / lipoprotein", "SREBF2",
  "Lipid metabolism / lipoprotein", "FASN",
  "Lipid metabolism / lipoprotein", "ACACA",
  "Lipid metabolism / lipoprotein", "CD36",
  "Lipid metabolism / lipoprotein", "CPT1A",
  "Lipid metabolism / lipoprotein", "ACOX1",
  
  "Oxidative stress / antioxidant response", "NFE2L2",
  "Oxidative stress / antioxidant response", "KEAP1",
  "Oxidative stress / antioxidant response", "HMOX1",
  "Oxidative stress / antioxidant response", "NQO1",
  "Oxidative stress / antioxidant response", "SOD1",
  "Oxidative stress / antioxidant response", "SOD2",
  "Oxidative stress / antioxidant response", "CAT",
  "Oxidative stress / antioxidant response", "GPX1",
  "Oxidative stress / antioxidant response", "GCLC",
  "Oxidative stress / antioxidant response", "GCLM",
  "Oxidative stress / antioxidant response", "NOS2",
  "Oxidative stress / antioxidant response", "NOX4",
  
  "Inflammation / cytokine signaling", "TNF",
  "Inflammation / cytokine signaling", "IL6",
  "Inflammation / cytokine signaling", "IL1B",
  "Inflammation / cytokine signaling", "NFKB1",
  "Inflammation / cytokine signaling", "RELA",
  "Inflammation / cytokine signaling", "CCL2",
  "Inflammation / cytokine signaling", "TLR4",
  "Inflammation / cytokine signaling", "PTGS2",
  "Inflammation / cytokine signaling", "CRP",
  
  "Mitochondrial / ER stress", "PPARGC1A",
  "Mitochondrial / ER stress", "UCP2",
  "Mitochondrial / ER stress", "HSPA5",
  "Mitochondrial / ER stress", "ATF4",
  "Mitochondrial / ER stress", "DDIT3",
  "Mitochondrial / ER stress", "XBP1",
  "Mitochondrial / ER stress", "EIF2AK3"
) %>%
  distinct()

mechanism_keyword_panels <- tibble::tribble(
  ~panel, ~pattern,
  "Insulin / glucose / diabetes", "insulin|glucose|glycemic|glycaemic|hyperglycemia|hypoglycemia|diabetes|pancreatic beta|beta cell",
  "Obesity / adiposity / body weight", "obesity|adipose|adipocyte|body weight|weight gain|fat mass|adipogenesis",
  "Lipid metabolism / dyslipidemia", "lipid|triglyceride|cholesterol|lipoprotein|fatty acid|steatosis|fatty liver|HDL|LDL",
  "Oxidative stress", "oxidative|reactive oxygen|ROS|glutathione|antioxidant|superoxide|peroxide|oxidation",
  "Inflammation / immune", "inflamm|cytokine|interleukin|tumor necrosis|NF-kappa|macrophage|immune",
  "Mitochondrial / ER stress", "mitochond|endoplasmic reticulum|ER stress|unfolded protein|apoptosis",
  "Endocrine / nuclear receptor", "PPAR|peroxisome proliferator|estrogen|androgen|thyroid|nuclear receptor|hormone"
)

# ------------------------------------------------------------
# 6. CTD file list and validation
# ------------------------------------------------------------

ctd_files <- tibble::tribble(
  ~dataset, ~file_name, ~min_size_mb,
  "chemicals", "CTD_chemicals.tsv.gz", 1,
  "chemical_gene", "CTD_chem_gene_ixns.tsv.gz", 35,
  "chemical_disease", "CTD_chemicals_diseases.tsv.gz", 20,
  "chemical_phenotype", "CTD_pheno_term_ixns.tsv.gz", 5
) %>%
  mutate(
    destfile = file.path(ctd_dir, file_name),
    url_https = paste0("https://ctdbase.org/reports/", file_name),
    url_http = paste0("http://ctdbase.org/reports/", file_name)
  )

for (i in seq_len(nrow(ctd_files))) {
  download_if_missing(
    urls = c(ctd_files$url_https[i], ctd_files$url_http[i]),
    destfile = ctd_files$destfile[i],
    min_size_mb = ctd_files$min_size_mb[i]
  )
}

cat("\nCTD file validation:\n")
ctd_validation <- ctd_files %>%
  mutate(
    exists = file.exists(destfile),
    size_mb = ifelse(exists, round(file.info(destfile)$size / 1024 / 1024, 2), NA_real_),
    gzip_valid = purrr::map2_lgl(
      destfile,
      min_size_mb,
      ~ is_valid_gzip_full(path = .x, min_size_mb = .y)
    )
  )

print(ctd_validation)

if (!all(ctd_validation$exists & ctd_validation$gzip_valid)) {
  stop("Some CTD files are missing or invalid. Run 53A_download_CTD_files_robust.R first.")
}

# ------------------------------------------------------------
# 7. Read CTD datasets
# ------------------------------------------------------------

ctd_chemicals <- read_ctd_tsv_gz(
  ctd_files$destfile[ctd_files$dataset == "chemicals"],
  dataset = "chemicals"
)

ctd_chem_gene <- read_ctd_tsv_gz(
  ctd_files$destfile[ctd_files$dataset == "chemical_gene"],
  dataset = "chemical_gene"
)

ctd_chem_disease <- read_ctd_tsv_gz(
  ctd_files$destfile[ctd_files$dataset == "chemical_disease"],
  dataset = "chemical_disease"
)

ctd_chem_pheno <- read_ctd_tsv_gz(
  ctd_files$destfile[ctd_files$dataset == "chemical_phenotype"],
  dataset = "chemical_phenotype"
)

ctd_chemicals <- ensure_cols(
  ctd_chemicals,
  c("ChemicalName", "ChemicalID", "CasRN", "Synonyms")
)

ctd_chem_gene <- ensure_cols(
  ctd_chem_gene,
  c(
    "ChemicalName", "ChemicalID", "CasRN", "GeneSymbol", "GeneID",
    "Organism", "Interaction", "InteractionActions", "PubMedIDs"
  )
)

ctd_chem_disease <- ensure_cols(
  ctd_chem_disease,
  c(
    "ChemicalName", "ChemicalID", "CasRN", "DiseaseName", "DiseaseID",
    "DirectEvidence", "InferenceGeneSymbol", "InferenceScore", "OmimIDs", "PubMedIDs"
  )
)

ctd_chem_pheno <- ensure_cols(
  ctd_chem_pheno,
  c(
    "ChemicalName", "ChemicalID", "CasRN", "GeneSymbol", "GeneID",
    "Interaction", "InteractionActions", "AnatomyTerms",
    "PhenotypeID", "PhenotypeName", "PubMedIDs"
  )
)

cat("\nCTD phenotype columns:\n")
print(names(ctd_chem_pheno))
cat("CTD phenotype rows:", nrow(ctd_chem_pheno), "\n")

# ------------------------------------------------------------
# 8. Match CTD chemicals
# ------------------------------------------------------------

ctd_chemicals_search <- ctd_chemicals %>%
  mutate(
    search_text = paste(
      ChemicalName,
      ChemicalID,
      CasRN,
      Synonyms,
      sep = " | "
    )
  )

matched_chemicals <- chemical_targets %>%
  mutate(
    matched_tbl = map2(
      ctd_pattern,
      casrn,
      function(pattern_i, cas_i) {
        ctd_chemicals_search %>%
          filter(
            stringr::str_detect(search_text, stringr::regex(pattern_i, ignore_case = TRUE)) |
              (!is.na(cas_i) & CasRN == cas_i)
          ) %>%
          mutate(match_pattern = pattern_i)
      }
    )
  ) %>%
  select(chemical_label, role, casrn, dtxsid, matched_tbl) %>%
  unnest(matched_tbl) %>%
  distinct(
    chemical_label,
    role,
    casrn_query = casrn,
    dtxsid_query = dtxsid,
    ChemicalName,
    ChemicalID,
    CasRN,
    Synonyms,
    .keep_all = TRUE
  )

if (nrow(matched_chemicals) == 0) {
  stop("CTD 中没有匹配到 DEHP / metabolites。")
}

cat("\nMatched CTD chemicals:\n")
print(
  matched_chemicals %>%
    select(chemical_label, ChemicalName, ChemicalID, CasRN) %>%
    distinct()
)

selected_ctd_ids <- unique(matched_chemicals$ChemicalID)
selected_ctd_names <- unique(matched_chemicals$ChemicalName)

# ------------------------------------------------------------
# 9. CTD chemical-gene evidence
# ------------------------------------------------------------

ctd_gene_evidence <- ctd_chem_gene %>%
  filter(ChemicalID %in% selected_ctd_ids | ChemicalName %in% selected_ctd_names) %>%
  left_join(
    matched_chemicals %>%
      select(chemical_label, ChemicalName, ChemicalID) %>%
      distinct(),
    by = c("ChemicalName", "ChemicalID")
  ) %>%
  mutate(
    chemical_label = ifelse(is.na(chemical_label), ChemicalName, chemical_label),
    n_pmids = count_pmids(PubMedIDs),
    interaction_text = paste(Interaction, InteractionActions, sep = " | ")
  ) %>%
  left_join(
    mechanism_gene_panels %>%
      distinct(gene_symbol, panel),
    by = c("GeneSymbol" = "gene_symbol")
  ) %>%
  mutate(
    mechanism_panel = ifelse(is.na(panel), "Other CTD gene", panel),
    interaction_direction = case_when(
      str_detect(interaction_text, regex("increase|upregulat|activat", ignore_case = TRUE)) ~ "increase / activation",
      str_detect(interaction_text, regex("decrease|downregulat|inhibit|suppress", ignore_case = TRUE)) ~ "decrease / inhibition",
      TRUE ~ "other / unspecified"
    )
  ) %>%
  select(-panel)

ctd_gene_key <- ctd_gene_evidence %>%
  group_by(
    chemical_label,
    GeneSymbol,
    GeneID,
    mechanism_panel
  ) %>%
  summarise(
    n_interactions = n(),
    n_pubmed_total = sum(n_pmids, na.rm = TRUE),
    organisms = paste(sort(unique(na.omit(Organism))), collapse = "; "),
    interaction_directions = paste(sort(unique(interaction_direction)), collapse = "; "),
    example_interactions = paste(head(unique(Interaction), 3), collapse = " | "),
    pubmed_ids = paste(unique(unlist(str_split(na.omit(PubMedIDs), "\\|"))), collapse = "|"),
    .groups = "drop"
  ) %>%
  arrange(chemical_label, desc(n_pubmed_total), desc(n_interactions))

ctd_mechanism_gene_summary <- ctd_gene_key %>%
  group_by(chemical_label, mechanism_panel) %>%
  summarise(
    n_genes = n_distinct(GeneSymbol),
    n_interactions = sum(n_interactions, na.rm = TRUE),
    n_pubmed_total = sum(n_pubmed_total, na.rm = TRUE),
    evidence_level = score_level(n_pubmed_total),
    top_genes = paste(head(GeneSymbol[order(-n_pubmed_total)], 10), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(chemical_label, desc(n_pubmed_total))

# ------------------------------------------------------------
# 10. CTD gene-panel enrichment
# ------------------------------------------------------------

gene_universe <- ctd_chem_gene %>%
  filter(!is.na(GeneSymbol), GeneSymbol != "") %>%
  pull(GeneSymbol) %>%
  unique()

selected_genes_all <- ctd_gene_evidence %>%
  filter(!is.na(GeneSymbol), GeneSymbol != "") %>%
  pull(GeneSymbol) %>%
  unique()

panel_enrichment <- mechanism_gene_panels %>%
  group_by(panel) %>%
  summarise(panel_genes = list(unique(gene_symbol)), .groups = "drop") %>%
  mutate(
    fisher_tbl = map(
      panel_genes,
      function(panel_gene_vec) {
        panel_gene_vec <- intersect(panel_gene_vec, gene_universe)
        
        a <- length(intersect(selected_genes_all, panel_gene_vec))
        b <- length(setdiff(selected_genes_all, panel_gene_vec))
        c <- length(setdiff(panel_gene_vec, selected_genes_all))
        d <- length(setdiff(gene_universe, union(selected_genes_all, panel_gene_vec)))
        
        safe_fisher(a, b, c, d) %>%
          mutate(
            selected_panel_genes = a,
            selected_nonpanel_genes = b,
            background_panel_genes = length(panel_gene_vec),
            background_total_genes = length(gene_universe),
            overlapping_genes = paste(intersect(selected_genes_all, panel_gene_vec), collapse = ", ")
          )
      }
    )
  ) %>%
  select(-panel_genes) %>%
  unnest(fisher_tbl) %>%
  mutate(q_value = p.adjust(p_value, method = "BH")) %>%
  arrange(q_value, desc(odds_ratio))

# ------------------------------------------------------------
# 11. CTD disease evidence
# ------------------------------------------------------------

ctd_disease_evidence <- ctd_chem_disease %>%
  filter(ChemicalID %in% selected_ctd_ids | ChemicalName %in% selected_ctd_names) %>%
  left_join(
    matched_chemicals %>%
      select(chemical_label, ChemicalName, ChemicalID) %>%
      distinct(),
    by = c("ChemicalName", "ChemicalID")
  ) %>%
  mutate(
    chemical_label = ifelse(is.na(chemical_label), ChemicalName, chemical_label),
    n_pmids = count_pmids(PubMedIDs),
    mechanism_panel = map_chr(
      DiseaseName,
      match_keyword_panel,
      keyword_tbl = mechanism_keyword_panels
    ),
    direct_or_inferred = case_when(
      !is.na(DirectEvidence) & DirectEvidence != "" ~ "Direct evidence",
      !is.na(InferenceGeneSymbol) & InferenceGeneSymbol != "" ~ "Gene-inferred",
      TRUE ~ "Other / unspecified"
    )
  )

ctd_disease_summary <- ctd_disease_evidence %>%
  group_by(chemical_label, mechanism_panel, DiseaseName, DiseaseID, direct_or_inferred) %>%
  summarise(
    n_rows = n(),
    n_pubmed_total = sum(n_pmids, na.rm = TRUE),
    inference_genes = paste(head(sort(unique(na.omit(InferenceGeneSymbol))), 20), collapse = ", "),
    pubmed_ids = paste(unique(unlist(str_split(na.omit(PubMedIDs), "\\|"))), collapse = "|"),
    .groups = "drop"
  ) %>%
  arrange(chemical_label, mechanism_panel, desc(n_pubmed_total))

ctd_disease_panel_summary <- ctd_disease_summary %>%
  group_by(chemical_label, mechanism_panel) %>%
  summarise(
    n_disease_terms = n_distinct(DiseaseName),
    n_pubmed_total = sum(n_pubmed_total, na.rm = TRUE),
    evidence_level = score_level(n_pubmed_total),
    top_diseases = paste(head(DiseaseName[order(-n_pubmed_total)], 8), collapse = "; "),
    .groups = "drop"
  ) %>%
  arrange(chemical_label, desc(n_pubmed_total))

# ------------------------------------------------------------
# 12. CTD phenotype evidence
# ------------------------------------------------------------

phenotype_name_col <- pick_col(
  ctd_chem_pheno,
  c(
    "^PhenotypeName$",
    "Phenotype.Name",
    "Phenotype",
    "PhenotypeTerm",
    "InferencePhenotype",
    "GOName",
    "Ontology"
  )
)

phenotype_id_col <- pick_col(
  ctd_chem_pheno,
  c(
    "^PhenotypeID$",
    "Phenotype.ID",
    "GOID",
    "OntologyID"
  )
)

chemical_name_col <- pick_col(ctd_chem_pheno, c("^ChemicalName$"))
chemical_id_col <- pick_col(ctd_chem_pheno, c("^ChemicalID$"))
pmid_col <- pick_col(ctd_chem_pheno, c("PubMed"))

if (is.na(chemical_name_col) || is.na(chemical_id_col)) {
  stop("CTD phenotype file lacks ChemicalName or ChemicalID columns after parsing.")
}

if (is.na(phenotype_name_col)) {
  warning("PhenotypeName column not detected. Creating phenotype text from interaction fields.")
  
  interaction_col <- pick_col(ctd_chem_pheno, c("^Interaction$"))
  action_col <- pick_col(ctd_chem_pheno, c("^InteractionActions$"))
  anatomy_col <- pick_col(ctd_chem_pheno, c("^AnatomyTerms$"))
  
  ctd_chem_pheno <- ctd_chem_pheno %>%
    mutate(
      PhenotypeName_fallback = paste(
        get_col_or_na(ctd_chem_pheno, interaction_col),
        get_col_or_na(ctd_chem_pheno, action_col),
        get_col_or_na(ctd_chem_pheno, anatomy_col),
        sep = " | "
      )
    )
  
  phenotype_name_col <- "PhenotypeName_fallback"
}

if (is.na(phenotype_id_col)) {
  ctd_chem_pheno$PhenotypeID_fallback <- NA_character_
  phenotype_id_col <- "PhenotypeID_fallback"
}

if (is.na(pmid_col)) {
  ctd_chem_pheno$PubMedIDs_fallback <- NA_character_
  pmid_col <- "PubMedIDs_fallback"
}

ctd_pheno_standard <- ctd_chem_pheno %>%
  mutate(
    ChemicalName_std = get_col_or_na(ctd_chem_pheno, chemical_name_col),
    ChemicalID_std = get_col_or_na(ctd_chem_pheno, chemical_id_col),
    PhenotypeName_std = get_col_or_na(ctd_chem_pheno, phenotype_name_col),
    PhenotypeID_std = get_col_or_na(ctd_chem_pheno, phenotype_id_col),
    PubMedIDs_std = get_col_or_na(ctd_chem_pheno, pmid_col)
  )

ctd_pheno_evidence <- ctd_pheno_standard %>%
  filter(
    ChemicalID_std %in% selected_ctd_ids |
      ChemicalName_std %in% selected_ctd_names
  ) %>%
  transmute(
    ChemicalName = ChemicalName_std,
    ChemicalID = ChemicalID_std,
    PhenotypeName = PhenotypeName_std,
    PhenotypeID = PhenotypeID_std,
    PubMedIDs = PubMedIDs_std
  ) %>%
  left_join(
    matched_chemicals %>%
      select(chemical_label, ChemicalName, ChemicalID) %>%
      distinct(),
    by = c("ChemicalName", "ChemicalID")
  ) %>%
  mutate(
    chemical_label = ifelse(is.na(chemical_label), ChemicalName, chemical_label),
    n_pmids = count_pmids(PubMedIDs),
    mechanism_panel = map_chr(
      PhenotypeName,
      match_keyword_panel,
      keyword_tbl = mechanism_keyword_panels
    )
  )

ctd_pheno_summary <- ctd_pheno_evidence %>%
  group_by(chemical_label, mechanism_panel, PhenotypeName, PhenotypeID) %>%
  summarise(
    n_rows = n(),
    n_pubmed_total = sum(n_pmids, na.rm = TRUE),
    pubmed_ids = paste(unique(unlist(str_split(na.omit(PubMedIDs), "\\|"))), collapse = "|"),
    .groups = "drop"
  ) %>%
  arrange(chemical_label, mechanism_panel, desc(n_pubmed_total))

ctd_pheno_panel_summary <- ctd_pheno_summary %>%
  group_by(chemical_label, mechanism_panel) %>%
  summarise(
    n_phenotype_terms = n_distinct(PhenotypeName),
    n_pubmed_total = sum(n_pubmed_total, na.rm = TRUE),
    evidence_level = score_level(n_pubmed_total),
    top_phenotypes = paste(head(PhenotypeName[order(-n_pubmed_total)], 8), collapse = "; "),
    .groups = "drop"
  ) %>%
  arrange(chemical_label, desc(n_pubmed_total))

# ------------------------------------------------------------
# 13. Optional CompTox / ToxCast API section
# ------------------------------------------------------------

api_key <- Sys.getenv("CTX_API_KEY")

toxcast_status <- tibble(
  api_key_available = api_key != "",
  ccdR_available = FALSE,
  toxcast_run = FALSE,
  note = "ToxCast API not run. Set CTX_API_KEY and install ccdR from USEPA R-universe to enable."
)

comptox_chemical_details <- tibble()
toxcast_mechanism_summary <- tibble()

if (api_key != "") {
  if (!("ccdR" %in% rownames(installed.packages()))) {
    tryCatch(
      {
        install.packages(
          "ccdR",
          repos = c("https://usepa.r-universe.dev", "https://cloud.r-project.org")
        )
      },
      error = function(e) {
        message("ccdR installation failed: ", e$message)
      }
    )
  }
  
  if ("ccdR" %in% rownames(installed.packages())) {
    library(ccdR)
    
    toxcast_status <- toxcast_status %>%
      mutate(
        ccdR_available = TRUE,
        note = "ccdR available; CompTox/ToxCast API can be queried if functions are available."
      )
    
    dtxsid_tbl <- chemical_targets %>%
      filter(!is.na(dtxsid), dtxsid != "")
    
    if ("get_chemical_details" %in% getNamespaceExports("ccdR")) {
      comptox_chemical_details <- map_dfr(seq_len(nrow(dtxsid_tbl)), function(i) {
        dtx <- dtxsid_tbl$dtxsid[i]
        lab <- dtxsid_tbl$chemical_label[i]
        
        out <- tryCatch(
          ccdR::get_chemical_details(DTXSID = dtx, API_key = api_key),
          error = function(e) {
            message("Chemical details failed for ", lab, ": ", e$message)
            NULL
          }
        )
        
        if (is.null(out)) {
          return(tibble())
        }
        
        as_tibble(out) %>%
          mutate(chemical_label = lab, dtxsid = dtx, .before = 1)
      })
    }
    
    toxcast_status <- toxcast_status %>%
      mutate(
        toxcast_run = FALSE,
        note = "CompTox chemical identity section attempted. ToxCast bioactivity API was not required for CTD mechanism triangulation."
      )
  }
}

# ------------------------------------------------------------
# 14. Integrated mechanism evidence
# ------------------------------------------------------------

ctd_gene_integrated <- ctd_mechanism_gene_summary %>%
  transmute(
    chemical_label,
    mechanism_panel,
    evidence_source = "CTD chemical-gene",
    evidence_metric = n_pubmed_total,
    evidence_level,
    top_evidence = top_genes
  )

ctd_disease_integrated <- ctd_disease_panel_summary %>%
  transmute(
    chemical_label,
    mechanism_panel,
    evidence_source = "CTD chemical-disease",
    evidence_metric = n_pubmed_total,
    evidence_level,
    top_evidence = top_diseases
  )

ctd_pheno_integrated <- ctd_pheno_panel_summary %>%
  transmute(
    chemical_label,
    mechanism_panel,
    evidence_source = "CTD chemical-phenotype",
    evidence_metric = n_pubmed_total,
    evidence_level,
    top_evidence = top_phenotypes
  )

toxcast_integrated <- if (nrow(toxcast_mechanism_summary) > 0) {
  toxcast_mechanism_summary %>%
    transmute(
      chemical_label,
      mechanism_panel,
      evidence_source = "ToxCast / CTX Bioactivity",
      evidence_metric = n_active_rows,
      evidence_level = toxcast_evidence,
      top_evidence = top_genes_or_targets
    )
} else {
  tibble()
}

integrated_mechanism_evidence <- bind_rows(
  ctd_gene_integrated,
  ctd_disease_integrated,
  ctd_pheno_integrated,
  toxcast_integrated
) %>%
  group_by(chemical_label, mechanism_panel) %>%
  summarise(
    evidence_sources = paste(sort(unique(evidence_source)), collapse = "; "),
    total_evidence_metric = sum(evidence_metric, na.rm = TRUE),
    strongest_evidence_level = case_when(
      any(evidence_level == "High") ~ "High",
      any(evidence_level == "Moderate") ~ "Moderate",
      any(evidence_level == "Suggestive") ~ "Suggestive",
      TRUE ~ "None"
    ),
    top_evidence = paste(head(unique(top_evidence[top_evidence != ""]), 5), collapse = " || "),
    .groups = "drop"
  ) %>%
  arrange(chemical_label, desc(total_evidence_metric))

# ------------------------------------------------------------
# 15. Figures
# ------------------------------------------------------------

plot_gene <- ctd_mechanism_gene_summary %>%
  filter(mechanism_panel != "Other CTD gene") %>%
  mutate(
    chemical_label = factor(
      chemical_label,
      levels = c("DEHP", "MEHP", "MEHHP", "MEOHP", "MECPP")
    )
  )

if (nrow(plot_gene) > 0) {
  p_gene <- ggplot(
    plot_gene,
    aes(x = reorder(mechanism_panel, n_pubmed_total), y = n_pubmed_total)
  ) +
    geom_col() +
    coord_flip() +
    facet_wrap(~ chemical_label, scales = "free_y") +
    labs(
      title = "CTD chemical-gene evidence for DEHP-related mechanisms",
      subtitle = "Evidence metric: total PubMed-supported CTD chemical-gene interaction counts",
      x = NULL,
      y = "CTD PubMed-supported interaction count"
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      strip.text = element_text(face = "bold")
    )
  
  print(p_gene)
  
  ggsave(
    file.path(fig_dir, "CTD_DEHP_mechanism_gene_evidence.png"),
    p_gene,
    width = 12,
    height = 7,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "CTD_DEHP_mechanism_gene_evidence.pdf"),
    p_gene,
    width = 12,
    height = 7
  )
}

plot_enrich <- panel_enrichment %>%
  filter(!is.na(odds_ratio), is.finite(odds_ratio)) %>%
  mutate(
    neg_log10_q = -log10(pmax(q_value, 1e-300)),
    panel = reorder(panel, neg_log10_q)
  )

if (nrow(plot_enrich) > 0) {
  p_enrich <- ggplot(plot_enrich, aes(x = panel, y = neg_log10_q)) +
    geom_col() +
    coord_flip() +
    labs(
      title = "Mechanism-panel enrichment among CTD DEHP-related genes",
      subtitle = "Fisher enrichment of DEHP-related CTD genes in predefined metabolic/toxicological gene panels",
      x = NULL,
      y = "-log10(FDR q)"
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5)
    )
  
  print(p_enrich)
  
  ggsave(
    file.path(fig_dir, "CTD_DEHP_mechanism_panel_enrichment.png"),
    p_enrich,
    width = 10,
    height = 6,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "CTD_DEHP_mechanism_panel_enrichment.pdf"),
    p_enrich,
    width = 10,
    height = 6
  )
}

plot_integrated <- integrated_mechanism_evidence %>%
  filter(mechanism_panel != "Other / not mapped") %>%
  mutate(
    chemical_label = factor(
      chemical_label,
      levels = c("DEHP", "MEHP", "MEHHP", "MEOHP", "MECPP")
    ),
    evidence_score = case_when(
      strongest_evidence_level == "High" ~ 3,
      strongest_evidence_level == "Moderate" ~ 2,
      strongest_evidence_level == "Suggestive" ~ 1,
      TRUE ~ 0
    )
  )

if (nrow(plot_integrated) > 0) {
  p_heat <- ggplot(
    plot_integrated,
    aes(x = mechanism_panel, y = chemical_label, fill = evidence_score)
  ) +
    geom_tile(color = "white", linewidth = 0.35) +
    geom_text(aes(label = strongest_evidence_level), size = 3) +
    scale_fill_gradient(
      low = "grey95",
      high = "darkgreen",
      breaks = c(0, 1, 2, 3),
      labels = c("None", "Suggestive", "Moderate", "High")
    ) +
    labs(
      title = "Integrated CTD mechanism evidence matrix",
      subtitle = "Evidence levels summarize CTD chemical-gene, disease, and phenotype evidence",
      x = "Mechanistic domain",
      y = "Chemical",
      fill = "Evidence"
    ) +
    theme_bw(base_size = 10.5) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9.5),
      axis.text.x = element_text(angle = 35, hjust = 1),
      panel.grid = element_blank()
    )
  
  print(p_heat)
  
  ggsave(
    file.path(fig_dir, "Integrated_DEHP_mechanism_evidence_heatmap.png"),
    p_heat,
    width = 13,
    height = 6,
    dpi = 300
  )
  
  ggsave(
    file.path(fig_dir, "Integrated_DEHP_mechanism_evidence_heatmap.pdf"),
    p_heat,
    width = 13,
    height = 6
  )
}

# ------------------------------------------------------------
# 16. Export
# ------------------------------------------------------------

write_xlsx(
  list(
    chemical_targets = chemical_targets,
    matched_CTD_chemicals = matched_chemicals %>%
      select(
        chemical_label,
        role,
        casrn_query,
        dtxsid_query,
        ChemicalName,
        ChemicalID,
        CasRN,
        Synonyms
      ),
    CTD_gene_key = ctd_gene_key,
    CTD_gene_panel_summary = ctd_mechanism_gene_summary,
    CTD_gene_panel_enrichment = panel_enrichment,
    CTD_disease_evidence = ctd_disease_summary,
    CTD_disease_panel_summary = ctd_disease_panel_summary,
    CTD_phenotype_evidence = ctd_pheno_summary,
    CTD_phenotype_panel_summary = ctd_pheno_panel_summary,
    API_status = toxcast_status,
    CompTox_details = comptox_chemical_details,
    ToxCast_summary = toxcast_mechanism_summary,
    integrated_mech_evidence = integrated_mechanism_evidence,
    mechanism_gene_panels = mechanism_gene_panels,
    mechanism_keyword_panels = mechanism_keyword_panels
  ),
  file.path(result_dir, "mechanism_database_CTD_CompTox_ToxCast_results.xlsx")
)

write_csv(
  integrated_mechanism_evidence,
  file.path(result_dir, "mechanism_integrated_DEHP_evidence.csv")
)

write_csv(
  ctd_gene_key,
  file.path(result_dir, "CTD_DEHP_gene_key_evidence.csv")
)

write_csv(
  panel_enrichment,
  file.path(result_dir, "CTD_DEHP_gene_panel_enrichment.csv")
)

cat("\nMechanism database analysis completed successfully.\n")
cat("Results saved to:\n")
cat(file.path(result_dir, "mechanism_database_CTD_CompTox_ToxCast_results.xlsx"), "\n")
cat("Figures saved to:\n")
cat(file.path(fig_dir, "CTD_DEHP_mechanism_gene_evidence.png"), "\n")
cat(file.path(fig_dir, "CTD_DEHP_mechanism_panel_enrichment.png"), "\n")
cat(file.path(fig_dir, "Integrated_DEHP_mechanism_evidence_heatmap.png"), "\n")

if (api_key == "") {
  cat("\nNote: ToxCast API section was skipped because CTX_API_KEY was not set.\n")
  cat("This is acceptable for the main CTD-based mechanism analysis.\n")
}