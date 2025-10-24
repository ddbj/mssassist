###
# merge umss tables by accession
###
suppressMessages(require(data.table))
# at102
status <- fread("temp/at103_umss_dblink_status_clean.txt", header = FALSE, sep = ",") # nolint
colnames(status) <- c("prefix", "status", "date")
bp <- fread("temp/at103_umss_dblink_taxid_clean.txt", header = FALSE, sep = ",")
colnames(bp) <- c("db", "prefix", "bp", "taxon")
bpstatus <- merge(bp, status, by = "prefix")
bpstatus$count <- 1
bpstatus <- bpstatus[, c("db", "prefix", "bp", "taxon", "status", "date", "count")] # nolint
fwrite(bpstatus, "bp_umssw_actual.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, sep = ",") # nolint
# at101
status <- fread("temp/at101_umss_dblink_status_clean.txt", header = FALSE, sep = ",") # nolint
colnames(status) <- c("prefix", "status", "date")
bp <- fread("temp/at101_umss_dblink_taxid_clean.txt", header = FALSE, sep = ",")
colnames(bp) <- c("db", "prefix", "bp", "taxon")
bpstatus <- merge(bp, status, by = "prefix")
bpstatus$count <- 1
bpstatus <- bpstatus[, c("db", "prefix", "bp", "taxon", "status", "date", "count")] # nolint
fwrite(bpstatus, "bp_umsse_actual.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, sep = ",") # nolint