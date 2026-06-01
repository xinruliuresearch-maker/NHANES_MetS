# ============================================================
# 53A_download_CTD_files_robust.R
# Robust downloader and validator for CTD mechanism database files
#
# Run before:
#   53_mechanism_database_analysis_CTD_CompTox_ToxCast.R
#
# Output folder:
#   C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project/data/raw_mechanism_databases/CTD/
# ============================================================

options(timeout = 10000)

# ------------------------------------------------------------
# 0. Packages
# ------------------------------------------------------------

required_packages <- c("curl", "dplyr", "tibble", "stringr")

installed_packages <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed_packages)

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(curl)
library(dplyr)
library(tibble)
library(stringr)

# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

project_dir <- "C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project"

ctd_dir <- file.path(
  project_dir,
  "data",
  "raw_mechanism_databases",
  "CTD"
)

dir.create(ctd_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 2. CTD files
# ------------------------------------------------------------

ctd_files <- tibble::tribble(
  ~file_name, ~url_https, ~url_http, ~min_size_mb,
  
  "CTD_chemicals.tsv.gz",
  "https://ctdbase.org/reports/CTD_chemicals.tsv.gz",
  "http://ctdbase.org/reports/CTD_chemicals.tsv.gz",
  1,
  
  "CTD_chem_gene_ixns.tsv.gz",
  "https://ctdbase.org/reports/CTD_chem_gene_ixns.tsv.gz",
  "http://ctdbase.org/reports/CTD_chem_gene_ixns.tsv.gz",
  35,
  
  "CTD_chemicals_diseases.tsv.gz",
  "https://ctdbase.org/reports/CTD_chemicals_diseases.tsv.gz",
  "http://ctdbase.org/reports/CTD_chemicals_diseases.tsv.gz",
  20,
  
  "CTD_pheno_term_ixns.tsv.gz",
  "https://ctdbase.org/reports/CTD_pheno_term_ixns.tsv.gz",
  "http://ctdbase.org/reports/CTD_pheno_term_ixns.tsv.gz",
  5
) %>%
  mutate(
    destfile = file.path(ctd_dir, file_name)
  )

# ------------------------------------------------------------
# 3. Full gzip integrity check
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

# ------------------------------------------------------------
# 4. Remote size helper
# ------------------------------------------------------------

get_remote_size <- function(url) {
  out <- tryCatch(
    {
      handle <- curl::new_handle(
        nobody = TRUE,
        followlocation = TRUE,
        connecttimeout = 60,
        timeout = 120
      )
      
      response <- curl::curl_fetch_memory(url, handle = handle)
      headers <- rawToChar(response$headers)
      
      matched <- stringr::str_match_all(
        headers,
        stringr::regex(
          "content-length:\\s*([0-9]+)",
          ignore_case = TRUE
        )
      )[[1]]
      
      if (nrow(matched) == 0) {
        return(NA_real_)
      }
      
      as.numeric(tail(matched[, 2], 1))
    },
    error = function(e) {
      NA_real_
    }
  )
  
  return(out)
}

# ------------------------------------------------------------
# 5. File completeness check
# ------------------------------------------------------------

file_complete <- function(path, urls, min_size_mb = 1) {
  if (!file.exists(path)) {
    return(FALSE)
  }
  
  local_size <- file.info(path)$size
  
  remote_sizes <- sapply(urls, get_remote_size)
  remote_size <- remote_sizes[is.finite(remote_sizes) & !is.na(remote_sizes)][1]
  
  if (is.finite(remote_size) && !is.na(remote_size)) {
    size_ok <- local_size >= 0.98 * remote_size
  } else {
    size_ok <- local_size >= min_size_mb * 1024 * 1024
  }
  
  gzip_ok <- is_valid_gzip_full(
    path = path,
    min_size_mb = min_size_mb
  )
  
  return(size_ok && gzip_ok)
}

# ------------------------------------------------------------
# 6. Robust download function
# ------------------------------------------------------------

download_one_ctd <- function(urls, destfile, min_size_mb = 1, max_attempts = 10) {
  dir.create(dirname(destfile), showWarnings = FALSE, recursive = TRUE)
  
  if (file_complete(destfile, urls, min_size_mb = min_size_mb)) {
    cat("\nAlready complete:\n", destfile, "\n")
    cat("Size:", round(file.info(destfile)$size / 1024 / 1024, 2), "MB\n")
    return(TRUE)
  }
  
  if (file.exists(destfile)) {
    cat("\nRemoving incomplete file:\n", destfile, "\n")
    unlink(destfile)
  }
  
  tmpfile <- paste0(destfile, ".part")
  
  if (file.exists(tmpfile)) {
    unlink(tmpfile)
  }
  
  for (url in urls) {
    for (attempt in seq_len(max_attempts)) {
      cat("\n------------------------------------------------------------\n")
      cat("Downloading:", basename(destfile), "\n")
      cat("Attempt:", attempt, "/", max_attempts, "\n")
      cat("URL:", url, "\n")
      cat("------------------------------------------------------------\n")
      
      if (file.exists(tmpfile)) {
        unlink(tmpfile)
      }
      
      ok <- tryCatch(
        {
          handle <- curl::new_handle(
            followlocation = TRUE,
            connecttimeout = 60,
            timeout = 0,
            low_speed_time = 300,
            low_speed_limit = 200
          )
          
          curl::curl_download(
            url = url,
            destfile = tmpfile,
            mode = "wb",
            handle = handle,
            quiet = FALSE
          )
          
          TRUE
        },
        error = function(e) {
          message("curl::curl_download failed: ", e$message)
          FALSE
        }
      )
      
      if (ok && file.exists(tmpfile)) {
        if (file.exists(destfile)) {
          unlink(destfile)
        }
        
        file.rename(tmpfile, destfile)
        
        if (file_complete(destfile, urls, min_size_mb = min_size_mb)) {
          cat("\nDownload completed and validated:\n", destfile, "\n")
          cat("Size:", round(file.info(destfile)$size / 1024 / 1024, 2), "MB\n")
          return(TRUE)
        } else {
          cat("\nDownloaded file failed validation. Removing and retrying.\n")
          unlink(destfile)
        }
      }
      
      # Fallback: Windows curl.exe
      curl_exe <- Sys.which("curl.exe")
      
      if (curl_exe != "") {
        cat("\nTrying fallback curl.exe...\n")
        
        cmd <- sprintf(
          'curl.exe -L --retry 20 --retry-delay 5 --connect-timeout 60 --max-time 0 -o "%s" "%s"',
          tmpfile,
          url
        )
        
        status <- system(cmd)
        
        if (status == 0 && file.exists(tmpfile)) {
          if (file.exists(destfile)) {
            unlink(destfile)
          }
          
          file.rename(tmpfile, destfile)
          
          if (file_complete(destfile, urls, min_size_mb = min_size_mb)) {
            cat("\nDownload completed by curl.exe and validated:\n", destfile, "\n")
            cat("Size:", round(file.info(destfile)$size / 1024 / 1024, 2), "MB\n")
            return(TRUE)
          } else {
            cat("\ncurl.exe downloaded file failed validation. Removing and retrying.\n")
            unlink(destfile)
          }
        }
      }
      
      Sys.sleep(5)
    }
  }
  
  stop("Failed to download complete CTD file: ", destfile)
}

# ------------------------------------------------------------
# 7. Clean invalid or partial files first
# ------------------------------------------------------------

cat("\nCleaning invalid or partial CTD files...\n")

for (i in seq_len(nrow(ctd_files))) {
  path_i <- ctd_files$destfile[i]
  min_size_i <- ctd_files$min_size_mb[i]
  
  if (file.exists(path_i)) {
    valid_i <- is_valid_gzip_full(
      path = path_i,
      min_size_mb = min_size_i
    )
    
    if (!valid_i) {
      cat("Deleting invalid or partial gzip:\n", path_i, "\n")
      unlink(path_i)
    }
  }
  
  part_path_i <- paste0(path_i, ".part")
  
  if (file.exists(part_path_i)) {
    cat("Deleting partial temporary file:\n", part_path_i, "\n")
    unlink(part_path_i)
  }
}

# ------------------------------------------------------------
# 8. Download all CTD files
# ------------------------------------------------------------

cat("\nStarting CTD downloads...\n")

for (i in seq_len(nrow(ctd_files))) {
  download_one_ctd(
    urls = c(ctd_files$url_https[i], ctd_files$url_http[i]),
    destfile = ctd_files$destfile[i],
    min_size_mb = ctd_files$min_size_mb[i],
    max_attempts = 10
  )
}

# ------------------------------------------------------------
# 9. Final validation table
# ------------------------------------------------------------

check_tbl <- ctd_files %>%
  mutate(
    exists = file.exists(destfile),
    size_mb = ifelse(
      exists,
      round(file.info(destfile)$size / 1024 / 1024, 2),
      NA_real_
    ),
    gzip_valid = purrr::map2_lgl(
      destfile,
      min_size_mb,
      ~ is_valid_gzip_full(
        path = .x,
        min_size_mb = .y
      )
    ),
    complete = exists & gzip_valid
  )

cat("\nCTD download validation result:\n")
print(check_tbl)

if (all(check_tbl$complete)) {
  cat("\nAll CTD files downloaded and validated successfully.\n")
  cat("\nYou can now run:\n")
  cat('source("C:/Users/liu12/Documents/Downloads/NHANES_Mets_Project/code/53_mechanism_database_analysis_CTD_CompTox_ToxCast.R")\n')
} else {
  cat("\nSome CTD files are still incomplete.\n")
  cat("Please manually download the failed files into:\n")
  cat(ctd_dir, "\n")
}