###
# trace_bp.R
###
suppressMessages(library(data.table))
suppressMessages(library(dplyr))
suppressMessages(library(stringr))

# setwd("/home/andreaghelfi/projects/dblink_ddbj/dblink_ddbj_devel/trace")
# from ddbj_mss_validation_sing
directory <- "/home/andrea/scripts/tables"
filename <- paste(directory, "bs_id.bp_id.csv", sep = "/") # table 1/3 (include two other methods to correlate bs_id with bp_id, using attribute)
bs2bp <- fread(filename, header = TRUE, sep = "\t") # change variable bs2bp_via_attribute
filename <- paste(directory, "bp2bs_via_locus_tag_prefix.csv", sep = "/") # table 2/3
bp2bs_via_locus_tag_prefix <- fread(filename, header = TRUE, sep = "\t") # change variable bs2bp_via_locus_tag_prefix
filename <- paste(directory, "bp2bs_via_drr.csv", sep = "/") # table 3/3
bp2bs_via_drr <- fread(filename, header = TRUE, sep = "\t") # change variable bp2bs_via_drr
# new script
bp_locus <- fread("sra/bpDB_submitter_locus_tag.csv", header = FALSE, sep = ",")
colnames(bp_locus) <- c("bp_submitter_id", "bp_submission_id", "project_id_prefix", "project_id_counter", "bp_status_id", "project_type", "bp_locus_tag")
bp_locus$bioproject_id <- paste(bp_locus$project_id_prefix, bp_locus$project_id_counter, sep = "")
bp_locus <- subset(bp_locus, select = -c(project_id_prefix, project_id_counter))
smp_bp <- fread("sra/edited_bsDB_bioproject_smp_id.csv", header = FALSE, sep = ",")
colnames(smp_bp) <- c("smp_id", "bioproject_id")
locus_smp <- fread("sra/bsDB_locus_tag_smp_id.csv", header = FALSE, sep = ",")
colnames(locus_smp) <- c("bs_locus_tag", "smp_id")
bs_tax_smp <- fread("sra/bsDB_taxon_smp_id.csv", header = FALSE, sep = ",")
colnames(bs_tax_smp) <- c("bs_taxon_id", "smp_id")
bs_smp <- fread("sra/bsDB_biosample_smp_id.csv", header = FALSE, sep = ",")
colnames(bs_smp) <- c("biosample_id", "smp_id")
bs_status_smp <- fread("sra/bsDB_submitter_status_smp_id.csv", header = FALSE, sep = ",")
colnames(bs_status_smp) <- c("bs_submitter_id", "bs_submission_id", "bs_status_id", "smp_id")
# biosample
bs_table <- merge(bs_status_smp, bs_smp, by = "smp_id", all.x = TRUE)
bs_table <- merge(bs_table, bs_tax_smp, by = "smp_id", all.x = TRUE)
bs_table <- merge(bs_table, locus_smp, by = "smp_id", all.x = TRUE)
# correlation table: bs -> bp
bp2bs_via_drr <- merge(bp2bs_via_drr, bs_smp, by = "smp_id")
bp2bs_via_drr <- bp2bs_via_drr[, c("biosample_id", "prjdb")]
colnames(bp2bs_via_drr)[1] <- "accession_id"
complete_bs2bp <- unique(rbind(bs2bp, bp2bs_via_drr, bp2bs_via_locus_tag_prefix))
colnames(complete_bs2bp) <- c("biosample_id", "bioproject_id")
# all - biosample
bs_table <- bs_table %>% select(-c("smp_id"))
bs_table <- bs_table %>% mutate_all(~ ifelse(. == "", NA, .))
final_bs_table <- merge(bs_table, complete_bs2bp, by = "biosample_id", all.x = TRUE)
final_bs_table <- unique(final_bs_table)
final_bs_table[is.na(final_bs_table$bs_status_id), ]$bs_status_id <- 0 # there is no data, it was necessary to upload data in psql as INT
final_bs_table[is.na(final_bs_table$bs_taxon_id), ]$bs_taxon_id <- 0
fwrite(final_bs_table, "../../dblink_ddbj_standby/trace/dblink_trace_bs_table.csv", row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE, na = "")
# all - bioproject
bp_table <- bp_locus %>% mutate_all(~ ifelse(. == "", NA, .))
bp_table[is.na(bp_table$bp_status_id), ]$bp_status_id <- 0
fwrite(bp_table, "../../dblink_ddbj_standby/trace/dblink_trace_bp_table.csv", row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE, na = "")