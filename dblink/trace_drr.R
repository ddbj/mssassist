###
# trace_drr.R
###
suppressMessages(library(data.table))
suppressMessages(library(stringr))
dir_trace <- "/home/andrea/projects/dblink_ddbj/dblink_ddbj_devel/trace"
dir_tables <- "/home/andrea/scripts/tables"
# table smp_id to drx
filename <- "sra/drmdb.drx_status.csv"
if (file.exists(filename)) {
    drx <- fread(filename, header = FALSE, sep = ",")
    drx <- drx[!is.na(drx$V4), ]
    drx$temp <- formatC(drx$V4, width = 6, format = "d", flag = "0")
    drx$drx <- paste(drx$V3, drx$temp, sep = "")
    ssub <- drx[V1 == "SSUB", c("V2", "drx")]
    colnames(ssub)[1] <- "smp_id"
    ssub <- ssub[grep("\\D", ssub$smp_id, invert = TRUE), ] # removed SSUB in the smp_id column
    fwrite(ssub, "drmdb.drx_ssub.csv", col.names = TRUE, row.names = FALSE, quote = FALSE, sep = ",") # fixed this table
    # psub
    psub <- drx[V1 == "PSUB", c("V2", "drx")]
    colnames(psub)[1] <- "psub"
    fwrite(psub, "drmdb.drx_psub.csv", col.names = TRUE, row.names = FALSE, quote = FALSE, sep = ",") # redundancy with trace_drr.R
} else {
    message <- paste("File", filename, "was not found.", sep = " ")
    print(message)
}

filename1 <- paste(dir_trace, "sra/trace_alias_dra_drx_drr.csv", sep = "/")
filename2 <- paste(dir_trace, "sra/trace_alias_status.csv", sep = "/")
filename3 <- paste(dir_tables, "bs_smp2drr.csv", sep = "/") # can't find it
filename4 <- paste(dir_tables, "bp2bs_via_drr.csv", sep = "/")
filename5 <- paste(dir_tables, "drmdb.drx_psub.csv", sep = "/")
filename6 <- paste(dir_tables, "bioproject_psub.csv", sep = "/")
filename7 <- paste(dir_tables, "drmdb.drx_ssub.csv", sep = "/")
filename8 <- paste(dir_tables, "biosample.accession.csv", sep = "/")

if (file.exists(filename1) && file.exists(filename2) && file.exists(filename3)) {
    # relations dra, drx, drr, alias
    rel <- fread(filename1, header = FALSE, sep = ",")
    colnames(rel) <- c("alias", "acc_type", "acc_no")
    rel$temp <- formatC(rel$acc_no, width = 6, format = "d", flag = "0")
    rel$rel <- paste(rel$acc_type, rel$temp, sep = "")
    rel <- subset(rel, select = -c(acc_no, temp))
    rel$submission_id <- as.data.frame(str_split(rel$alias, "_Submission", simplify = TRUE))[, 1]
    rel$submission_id <- as.data.frame(str_split(rel$submission_id, "_Experiment", simplify = TRUE))[, 1]
    rel$submission_id <- as.data.frame(str_split(rel$submission_id, "_Run", simplify = TRUE))[, 1]
    rel <- subset(rel, select = -c(alias))
    # status, dra, alias
    status <- fread(filename2, header = FALSE, sep = ",")
    colnames(status) <- c("submitter_id", "submission_id", "dra", "status")
    rest <- merge(status, rel, by = "submission_id")
    # drr2bs
    drr2bs <- fread(filename3, header = FALSE, sep = "\t")
    colnames(drr2bs) <- c("biosample", "drr")
    # drr2bp
    drr2bp <- fread(filename4, header = TRUE, sep = "\t")[, 1:2]
    drr2bp$temp <- substr(drr2bp$drr, 4, nchar(drr2bp$drr))
    drr2bp$temp <- as.numeric(drr2bp$temp)
    drr2bp$temp <- formatC(drr2bp$temp, width = 6, format = "d", flag = "0")
    drr2bp$drr <- paste("DRR", drr2bp$temp, sep = "")
    drr2bp <- subset(drr2bp, select = -c(temp))
    # drx to psub to bioproject
    drx2bp <- fread(filename5, header = TRUE, sep = ",")
    psub2bp <- fread(filename6, header = TRUE, sep = ",")
    temp1 <- drx2bp[grep("PSUB", drx2bp$psub), ]
    temp1 <- merge(psub2bp, temp1, by = "psub")
    temp1 <- subset(temp1, select = -c(psub))
    temp2 <- drx2bp[grep("PSUB", drx2bp$psub, invert = TRUE), ]
    colnames(temp2)[1] <- "prjdb"
    drx2bp <- rbind(temp1, temp2)
    # drx to ssub
    drx2bs <- fread(filename7, header = TRUE, sep = ",")
    # drx to ssub to biosample
    smp2bs <- fread(filename8, header = FALSE, sep = ",")
    colnames(smp2bs) <- c("biosample", "smp_id")
    drx2bs$smp_id <- as.numeric(drx2bs$smp_id)
    drx2bs <- drx2bs[!is.na(drx2bs$smp_id), ]
    drx2bs <- merge(drx2bs, smp2bs, by = "smp_id")
    drx2bs <- subset(drx2bs, select = -c(smp_id))
    # drr -> bs/bp table
    drr <- merge(drr2bs, drr2bp, by = "drr", all = TRUE)
    fwrite(drr, "dblink_trace_drr_table.csv", row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE)
    # drx -> bs/bp table
    fwrite(drx2bs, "dblink_trace_drx2bs_table.csv", row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE)
    fwrite(drx2bp, "dblink_trace_drx2bp_table.csv", row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE)
    # drr -> bs/bp table, include status
    drr <- merge(drr2bs, drr2bp, by = "drr", all = TRUE)
    colnames(rest)[colnames(rest) == "rel"] <- "drr"
    drr <- merge(drr, rest, by = "drr", all.x = TRUE)
    drr <- drr[, c("drr", "prjdb", "biosample", "submitter_id", "status")]
    drr <- as.data.frame(drr)
    drr <- drr[!is.na(drr$status), ]
    fwrite(drr, "../../dblink_ddbj_standby/trace/dblink_trace_drr_table_status.csv", row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE)
} else {
    message <- paste("Files", filename1, filename2, filename3, "were not found.", sep = " ")
    print(message)
}