# check CDS/mRNA ratio

suppressMessages(library(dplyr))

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Please provide both the filename and the variable name.")
}

filename <- args[1]
ann_filename <- args[2]

if (!file.exists(filename)) {
  stop(paste("The file", filename, "does not exist."))
}

dt <- read.table(filename, sep = "\t", header = FALSE)
dt <- dt %>%
  mutate(V2 = ifelse(V2 == "misc_feature", "CDS", V2))

result <- dt %>%
  group_by(V3) %>%
  summarise(CDS_present = any(V2 == "CDS"),
            mRNA_present = any(V2 == "mRNA"),
            CDS_count = sum(V2 == "CDS"),
            mRNA_count = sum(V2 == "mRNA"))

result_with_both <- result %>%
  filter(CDS_present & mRNA_present)

warning_messages <- result_with_both %>%
  filter(CDS_count != mRNA_count) %>%
  mutate(warning_message = paste(ann_filename, "warning CDS and mRNA counts differ for", V3, sep = "\t")) %>%
  pull(warning_message)

if (length(warning_messages) > 0) {
  writeLines(warning_messages, "/data/temp_svp/warning_cds_mrna_warnings.b9")
} else {
  cat("No discrepancies between CDS and mRNA was found.\n")
}
