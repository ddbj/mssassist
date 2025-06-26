#####################################################
# Part of ddbj_mss_validation singularity container
# Validate the chromosome qualifier values according to the INSDC/DDBJ rules.
# Usage: python check_chr_qualifier.R <ann_filename>
# Implements rule: SVP0210
# Developed by Andrea Ghelfi
# 2024-12-11
#####################################################

library(stringr)

validate_column <- function(value) {
  original_value <- value
  value <- str_trim(value)

  # 1. Must not be empty.
  if (value == "") {
    return(list(valid = FALSE, reason = "Empty"))
  }

  # 2. Must begin with a letter or number.
  if (!str_detect(value, "^[A-Za-z0-9]")) {
    return(list(valid = FALSE, reason = paste("'", original_value, "'", sep = "")))
  }

  # 3. Must not be longer than 32 characters.
  if (nchar(value) > 32) {
    return(list(valid = FALSE, reason = paste("'", original_value, "'", sep = "")))
  }

  # 4. Must not contain a tab.
  if (str_detect(value, "\t")) {
    return(list(valid = FALSE, reason = paste("'", original_value, "', contains tab", sep = "")))
  }

  val_lower <- tolower(value)

  # 5. Forbidden substrings.
  forbidden_substrings <- c(
    "plasmid", "chromosome", "linkage group", "chr", "chrm", "chrom",
    "linkage-group", "linkage_group", "un", "unk", "unknown", "na"
  )

  for (fs in forbidden_substrings) {
    if (str_detect(val_lower, fs)) {
      return(list(valid = FALSE, reason = paste("'", original_value, "'", sep = "")))
    }
  }

  # 6. Strings composed solely of '0'.
  if (all(strsplit(value, "")[[1]] == "0")) {
    return(list(valid = FALSE, reason = paste("'", original_value, "'", sep = "")))
  }

  return(list(valid = TRUE, reason = ""))
}

# File paths
input_file <- "/data/temp_svp/temp_chromosome_qualifier.txt"
output_file <- "/data/temp_svp/warning_chr_qualifier.b9"

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: Rscript script.R <ann_filename>")
}
ann <- args[1]

# Check if input file exists
if (!file.exists(input_file)) {
  stop("Input file not found.")
}

invalid_found <- FALSE

tryCatch({
  # Open input and output files
  infile <- file(input_file, "r")
  outfile <- file(output_file, "w")
  
  # Process each line
  line_number <- 1
  while (TRUE) {
    line <- readLines(infile, n = 1, warn = FALSE)
    if (length(line) == 0) break

    columns <- strsplit(line, "\t")[[1]]

    if (length(columns) < 3) {
      invalid_found <- TRUE
      cat("Error: '/data/temp_svp/temp_chromosome_qualifier.txt'\n")
      next
    }

    col3 <- columns[3]
    validation_result <- validate_column(col3)

    if (!validation_result$valid) {
      invalid_found <- TRUE
      entry <- columns[1]
      message <- paste(ann, "\twarning", "\tSVP0210\tValue:", validation_result$reason, "\n", sep = "")
      # cat(message)
      writeLines(message, outfile)
    }

    line_number <- line_number + 1
  }

  close(infile)
  close(outfile)
}, error = function(e) {
  cat("File operation failed:", e$message, "\n")
})
